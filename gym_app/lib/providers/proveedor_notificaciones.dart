import 'package:flutter/material.dart';
import '../services/servicio_notificaciones.dart';

/// Provider para manejar notificaciones con Supabase
class ProveedorNotificaciones extends ChangeNotifier {
  final ServicioNotificaciones _servicioNotificaciones = ServicioNotificaciones();

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

      // Inicializar servicio de notificaciones
      await _servicioNotificaciones.inicializar();

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
  void alternarNotificaciones(bool valor) {
    _notificacionesHabilitadas = valor;
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
