import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Servicio de notificaciones usando Supabase Realtime + Local Notifications
/// Maneja notificaciones para usuarios y admins sin dependencias externas
class ServicioNotificaciones {
  static final ServicioNotificaciones _instancia = ServicioNotificaciones._interno();

  factory ServicioNotificaciones() {
    return _instancia;
  }

  ServicioNotificaciones._interno();

  final supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  RealtimeChannel? _realtime;

  /// Tipos de notificaciones
  static const String TIPO_RESERVA_CONFIRMADA = 'reserva_confirmada';
  static const String TIPO_RECORDATORIO = 'recordatorio_reserva';
  static const String TIPO_ALERTA_EQUIPAMIENTO = 'alerta_equipamiento';
  static const String TIPO_CAMBIO_HORARIO = 'cambio_horario';

  /// Inicializar el servicio de notificaciones
  Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      // Configurar notificaciones locales
      await _configurarNotificacionesLocales();

      // Crear canales de notificación (Android)
      await crearCanales();

      // Escuchar notificaciones en tiempo real
      _escucharNotificacionesRealtimeSupabase();

      _inicializado = true;
      print('✅ Servicio de notificaciones inicializado (Supabase Realtime)');
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _configurarNotificacionesLocales() async {
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

    await _localNotifications.initialize(settings);
  }

  /// Escuchar cambios en tabla notificaciones_historial vía Realtime
  void _escucharNotificacionesRealtimeSupabase() {
    try {
      final usuarioId = supabase.auth.currentUser?.id;
      if (usuarioId == null) {
        print('⚠️ Usuario no autenticado, no se pueden escuchar notificaciones');
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

      print('✅ Escuchando notificaciones en tiempo real vía Supabase Realtime');
    } catch (e) {
      print('❌ Error configurando realtime: $e');
    }
  }

  /// Procesar notificación recibida
  Future<void> _procesarNotificacion(PostgresChangePayload payload) async {
    try {
      final datos = payload.newRecord as Map<String, dynamic>?;
      if (datos == null) return;

      // Verificar que sea para el usuario actual
      final usuarioId = supabase.auth.currentUser?.id;
      if (datos['usuario_id'] != usuarioId) return;

      // Solo mostrar si no ha sido abierta
      if (datos['abierta'] != true) {
        await mostrarNotificacion(
          titulo: datos['titulo']?.toString() ?? 'GYM SENA',
          cuerpo: datos['cuerpo']?.toString() ?? '',
          tipo: datos['tipo']?.toString() ?? '',
          datos: <String, dynamic>{
            'notificacion_id': datos['id']?.toString() ?? '',
          },
        );
      }
    } catch (e) {
      print('❌ Error procesando notificación: $e');
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
      // Configuración de Android
      const androidDetails = AndroidNotificationDetails(
        'gym_sena_canal',
        'GYM SENA Notificaciones',
        channelDescription: 'Notificaciones de GYM SENA',
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

      await _localNotifications.show(
        DateTime.now().millisecond,
        titulo,
        cuerpo,
        detalles,
        payload: tipo,
      );

      print('✅ Notificación mostrada: $titulo');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  /// Crear canales de notificación (Android)
  Future<void> crearCanales() async {
    if (!Platform.isAndroid) return;

    final canales = [
      const AndroidNotificationChannel(
        'gym_sena_canal',
        'GYM SENA Notificaciones',
        description: 'Notificaciones principales de GYM SENA',
        importance: Importance.high,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'gym_sena_reservas',
        'Reservas',
        description: 'Notificaciones de reservas y recordatorios',
        importance: Importance.high,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'gym_sena_alertas',
        'Alertas',
        description: 'Alertas de equipamiento (solo admin)',
        importance: Importance.high,
        showBadge: true,
      ),
    ];

    for (final canal in canales) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
      print('❌ Error marcando notificación: $e');
    }
  }

  /// Obtener notificaciones del usuario actual
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    try {
      final usuarioId = supabase.auth.currentUser?.id;
      if (usuarioId == null) return [];

      final datos = await supabase
          .from('notificaciones_historial')
          .select()
          .eq('usuario_id', usuarioId)
          .order('created_at', ascending: false)
          .limit(50);

      return (datos as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Limpiar notificaciones antiguas
  Future<void> limpiarNotificacionesAntiguas(int diasAntiguos) async {
    try {
      final fecha =
          DateTime.now().subtract(Duration(days: diasAntiguos)).toIso8601String();

      await supabase
          .from('notificaciones_historial')
          .delete()
          .lt('created_at', fecha);

      print('✅ Notificaciones antiguas eliminadas');
    } catch (e) {
      print('❌ Error limpiando notificaciones: $e');
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

