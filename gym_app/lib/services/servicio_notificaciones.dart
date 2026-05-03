import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones usando Supabase Realtime + Local Notifications
/// Maneja notificaciones para usuarios y admins sin dependencias externas
class ServicioNotificaciones {
  static final ServicioNotificaciones _instancia =
      ServicioNotificaciones._interno();

  factory ServicioNotificaciones() {
    return _instancia;
  }

  ServicioNotificaciones._interno();

  final supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin? _localNotifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  bool _timezoneInicializado = false;
  RealtimeChannel? _realtime;
  String? _notificationUserColumn;

  /// Tipos de notificaciones
  static const String tipoReservaConfirmada = 'reserva_confirmada';
  static const String tipoRecordatorio = 'recordatorio_reserva';
  static const String tipoAlertaEquipamiento = 'alerta_equipamiento';
  static const String tipoCambioHorario = 'cambio_horario';

  /// Inicializar el servicio de notificaciones
  Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      // Configurar notificaciones locales (no soportado en web)
      if (!kIsWeb) {
        await _configurarNotificacionesLocales();
      }

      if (!_timezoneInicializado) {
        tz.initializeTimeZones();
        _timezoneInicializado = true;
      }

      // Crear canales de notificación (Android)
      await crearCanales();

      // Escuchar notificaciones en tiempo real
      _escucharNotificacionesRealtimeSupabase();

      _inicializado = true;
      debugPrint(
        '✅ Servicio de notificaciones inicializado (Supabase Realtime)',
      );
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  int _reservationReminderId(String reservationId) {
    var hash = 0;
    for (final unit in reservationId.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return 100000 + (hash % 900000);
  }

  Future<void> programarRecordatorioReserva({
    required String reservationId,
    required String fecha,
    required String horaInicio,
    String? horaFin,
  }) async {
    try {
      if (kIsWeb) return;
      final notifications = _localNotifications;
      if (notifications == null) return;

      if (!_inicializado) {
        await inicializar();
      }

      final startIso = '${fecha}T$horaInicio';
      final startDate = DateTime.tryParse(startIso);
      if (startDate == null) return;

      final reminderDate = startDate.subtract(const Duration(minutes: 15));
      if (!reminderDate.isAfter(DateTime.now())) return;

      const androidDetails = AndroidNotificationDetails(
        'jacek_gym_reservas',
        'Reservas',
        channelDescription: 'Notificaciones de reservas y recordatorios',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final reminderTz = tz.TZDateTime.from(reminderDate, tz.local);
      final rangeText = (horaFin != null && horaFin.isNotEmpty)
          ? '$horaInicio - $horaFin'
          : horaInicio;

      await notifications.zonedSchedule(
        _reservationReminderId(reservationId),
        'Recordatorio de reserva',
        'Tu reserva inicia en 15 minutos ($rangeText).',
        reminderTz,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: tipoRecordatorio,
      );
    } catch (e) {
      debugPrint('❌ Error programando recordatorio: $e');
    }
  }

  Future<void> cancelarRecordatorioReserva(String reservationId) async {
    try {
      if (kIsWeb) return;
      final notifications = _localNotifications;
      if (notifications == null) return;
      await notifications.cancel(_reservationReminderId(reservationId));
    } catch (e) {
      debugPrint('❌ Error cancelando recordatorio: $e');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _configurarNotificacionesLocales() async {
    final notifications = _localNotifications;
    if (notifications == null) return;

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(settings);
  }

  /// Escuchar cambios en tabla notificaciones_historial vía Realtime
  void _escucharNotificacionesRealtimeSupabase() {
    try {
      final usuarioId = supabase.auth.currentUser?.id;
      if (usuarioId == null) {
        debugPrint(
          '⚠️ Usuario no autenticado, no se pueden escuchar notificaciones',
        );
        return;
      }

      // Crear canal para notificaciones del usuario actual
      _realtime = supabase.channel('notificaciones:$usuarioId');

      // Escuchar cambios en la tabla
      _realtime!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notificaciones_historial',
            callback: (payload) {
              _procesarNotificacion(payload);
            },
          )
          .subscribe();

      debugPrint(
        '✅ Escuchando notificaciones en tiempo real vía Supabase Realtime',
      );
    } catch (e) {
      debugPrint('❌ Error configurando realtime: $e');
    }
  }

  /// Procesar notificación recibida
  Future<void> _procesarNotificacion(PostgresChangePayload payload) async {
    try {
      final datos = payload.newRecord as Map<String, dynamic>?;
      if (datos == null) return;

      // Verificar que sea para el usuario actual
      final userIds = await _resolverIdsUsuarioNotificaciones();
      if (userIds.isEmpty) return;
      final payloadUserId =
          datos['id_usuario_notif']?.toString() ??
          datos['id_usuario']?.toString() ??
          datos['usuario_id']?.toString();
      if (payloadUserId == null || !userIds.contains(payloadUserId)) return;

      // Solo mostrar si no ha sido abierta
      if (datos['abierta'] != true) {
        await mostrarNotificacion(
          titulo: datos['titulo']?.toString() ?? 'JACEK GYM',
          cuerpo: datos['cuerpo']?.toString() ?? '',
          tipo: datos['tipo']?.toString() ?? '',
          datos: <String, dynamic>{
            'notificacion_id': datos['id']?.toString() ?? '',
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error procesando notificación: $e');
    }
  }

  /// Mostrar notificación local
  Future<void> mostrarNotificacion({
    required String titulo,
    required String cuerpo,
    String tipo = '',
    Map<String, dynamic>? datos,
  }) async {
    try {
      if (kIsWeb) return;
      final notifications = _localNotifications;
      if (notifications == null) return;

      // Configuración de Android
      const androidDetails = AndroidNotificationDetails(
        'jacek_gym_canal',
        'JACEK GYM Notificaciones',
        channelDescription: 'Notificaciones de JACEK GYM',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      // Configuración de iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const detalles = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await notifications.show(
        DateTime.now().millisecond,
        titulo,
        cuerpo,
        detalles,
        payload: tipo,
      );

      debugPrint('✅ Notificación mostrada: $titulo');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación: $e');
    }
  }

  /// Crear canales de notificación (Android)
  Future<void> crearCanales() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final notifications = _localNotifications;
    if (notifications == null) return;

    final canales = [
      const AndroidNotificationChannel(
        'jacek_gym_canal',
        'JACEK GYM Notificaciones',
        description: 'Notificaciones principales de JACEK GYM',
        importance: Importance.high,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'jacek_gym_reservas',
        'Reservas',
        description: 'Notificaciones de reservas y recordatorios',
        importance: Importance.high,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'jacek_gym_alertas',
        'Alertas',
        description: 'Alertas de equipamiento (solo admin)',
        importance: Importance.high,
        showBadge: true,
      ),
    ];

    for (final canal in canales) {
      await notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(canal);
    }
  }

  /// Marcar notificación como abierta
  Future<void> marcarComoAbierta(String notificacionId) async {
    try {
      await supabase
          .from('notificaciones_historial')
          .update({
            'abierta': true,
            'fecha_apertura': DateTime.now().toIso8601String(),
          })
          .eq('id', notificacionId);
    } catch (e) {
      debugPrint('❌ Error marcando notificación: $e');
    }
  }

  /// Obtener notificaciones del usuario actual
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    try {
      final userIds = await _resolverIdsUsuarioNotificaciones();
      if (userIds.isEmpty) return [];

      return await _obtenerNotificacionesConFallback(userIds);
    } catch (e) {
      debugPrint('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerNotificacionesConFallback(
    List<String> userIds,
  ) async {
    final columnas = <String>{
      if (_notificationUserColumn != null) _notificationUserColumn!,
      'id_usuario_notif',
      'id_usuario',
      'usuario_id',
      'user_id',
    }.toList();

    PostgrestException? lastError;

    for (final columna in columnas) {
      try {
        final baseQuery = supabase.from('notificaciones_historial').select();
        final filteredQuery = userIds.length == 1
            ? baseQuery.eq(columna, userIds.first)
            : baseQuery.inFilter(columna, userIds);

        final datos = await filteredQuery
            .order('fecha_creacion', ascending: false)
            .limit(50);

        _notificationUserColumn = columna;
        return (datos as List).cast<Map<String, dynamic>>();
      } on PostgrestException catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) throw lastError;
    return [];
  }

  Future<List<String>> _resolverIdsUsuarioNotificaciones() async {
    final authId = supabase.auth.currentUser?.id;
    if (authId == null || authId.isEmpty) return [];

    final ids = <String>{authId};

    try {
      final userByAuth = await supabase
          .from('users')
          .select('id')
          .eq('id_autenticacion', authId)
          .maybeSingle();

      final dbId = userByAuth?['id']?.toString();
      if (dbId != null && dbId.isNotEmpty) {
        ids.add(dbId);
      }
    } on PostgrestException catch (error) {
      // Si la columna no existe en otro esquema, mantenemos auth.uid como fallback.
      if (error.code != 'PGRST204') {
        debugPrint(
          '⚠️ No se pudo resolver id de users por id_autenticacion: $error',
        );
      }
    } catch (_) {}

    return ids.toList();
  }

  /// Limpiar notificaciones antiguas
  Future<void> limpiarNotificacionesAntiguas(int diasAntiguos) async {
    try {
      final fecha = DateTime.now()
          .subtract(Duration(days: diasAntiguos))
          .toIso8601String();

      await supabase
          .from('notificaciones_historial')
          .delete()
          .lt('fecha_creacion', fecha);

      debugPrint('✅ Notificaciones antiguas eliminadas');
    } catch (e) {
      debugPrint('❌ Error limpiando notificaciones: $e');
    }
  }

  /// Desuscribirse de realtime
  Future<void> desuscribirse() async {
    if (_realtime != null) {
      await supabase.removeChannel(_realtime!);
      _realtime = null;
    }
  }

  /// Destruir servicio
  Future<void> destruir() async {
    await desuscribirse();
    _inicializado = false;
  }
}
