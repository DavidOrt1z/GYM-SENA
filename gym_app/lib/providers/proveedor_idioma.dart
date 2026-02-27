import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Provider para manejar cambios de idioma dinámicamente
class ProveedorIdioma extends ChangeNotifier {
  static const String _claveIdioma = 'idioma_app';
  
  String _idiomaActual = AppLocalizations.es;
  late SharedPreferences _prefs;

  String get idiomaActual => _idiomaActual;
  
  String get nombreIdioma => AppLocalizationsProvider.nombreIdioma(_idiomaActual);

  /// Inicializar proveedor
  Future<void> inicializar() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Cargar idioma guardado o usar el del sistema
    final idioma = _prefs.getString(_claveIdioma);
    if (idioma != null) {
      _idiomaActual = idioma;
    } else {
      // Obtener idioma del sistema
      final idiomaLocale = Locale(_idiomaActual).languageCode;
      if (AppLocalizations.idiomas.contains(idiomaLocale)) {
        _idiomaActual = idiomaLocale;
      }
    }
    
    notifyListeners();
  }

  /// Cambiar idioma
  Future<void> cambiarIdioma(String idioma) async {
    if (!AppLocalizations.idiomas.contains(idioma)) return;
    
    _idiomaActual = idioma;
    await _prefs.setString(_claveIdioma, idioma);
    
    notifyListeners();
  }

  /// Cambiar al siguiente idioma (para quick toggle)
  Future<void> siguienteIdioma() async {
    final indiceActual = AppLocalizations.idiomas.indexOf(_idiomaActual);
    final siguienteIndice = (indiceActual + 1) % AppLocalizations.idiomas.length;
    final siguienteIdioma = AppLocalizations.idiomas[siguienteIndice];
    
    await cambiarIdioma(siguienteIdioma);
  }

  /// Obtener código de localización
  Locale get locale => Locale(_idiomaActual);

  /// Obtener lista de idiomas disponibles
  List<String> get idiomasDisponibles => AppLocalizations.idiomas;
  
  List<String> get nombesIdiomas => AppLocalizations.idiomas_nombres;

  /// Obtener traducción por clave
  String texto(String clave) {
    return getTexto(clave, idioma: _idiomaActual);
  }
}
