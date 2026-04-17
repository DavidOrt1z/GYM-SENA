import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/servicio_notificaciones.dart';

/// Provider para manejar notificaciones con Supabase
class ProveedorNotificaciones extends ChangeNotifier {
  static const String _claveNotificaciones = 'notificaciones_habilitadas';
  final ServicioNotificaciones _servicioNotificaciones =
      ServicioNotificaciones();

  bool _notificacionesHabilitadas = true;
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = false;

  bool get notificacionesHabilitadas => _notificacionesHabilitadas;
  List<Map<String, dynamic>> get notificaciones => _notificaciones;
  bool get cargando => _cargando;

  /// Inicializar el proveedor y escuchar notificaciones
  Future<void> inicializar() async {
    try {
      _cargando = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      _notificacionesHabilitadas = prefs.getBool(_claveNotificaciones) ?? true;

      // Inicializar servicio de notificaciones
      if (_notificacionesHabilitadas) {
        await _servicioNotificaciones.inicializar();
      }

      // Cargar notificaciones guardadas
      await cargarNotificaciones();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error inicializando proveedor: $e');
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cargar notificaciones del usuario
  Future<void> cargarNotificaciones() async {
    if (!_notificacionesHabilitadas) {
      _notificaciones = [];
      _cargando = false;
      notifyListeners();
      return;
    }

    try {
      _cargando = true;
      notifyListeners();

      _notificaciones = await _servicioNotificaciones.obtenerNotificaciones();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
      _cargando = false;
      notifyListeners();
    }
  }

  /// Habilitar/deshabilitar notificaciones
  Future<void> alternarNotificaciones(bool valor) async {
    _notificacionesHabilitadas = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveNotificaciones, valor);

    if (valor) {
      await _servicioNotificaciones.inicializar();
      await cargarNotificaciones();
    } else {
      await _servicioNotificaciones.destruir();
      _notificaciones = [];
    }

    notifyListeners();
  }

  /// Marcar notificación como abierta
  Future<void> marcarComoAbierta(String notificacionId) async {
    try {
      await _servicioNotificaciones.marcarComoAbierta(notificacionId);
      await cargarNotificaciones();
    } catch (e) {
      print('❌ Error marcando notificación: $e');
    }
  }

  /// Limpiar notificaciones antiguas
  Future<void> limpiarNotificacionesAntiguas(int dias) async {
    try {
      await _servicioNotificaciones.limpiarNotificacionesAntiguas(dias);
      await cargarNotificaciones();
    } catch (e) {
      print('❌ Error limpiando notificaciones: $e');
    }
  }

  /// Destruir el proveedor
  Future<void> destruir() async {
    await _servicioNotificaciones.destruir();
  }
}
