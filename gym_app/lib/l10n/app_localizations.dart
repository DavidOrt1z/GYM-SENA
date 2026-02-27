import 'package:flutter/material.dart';
import 'es.dart' as translations_es;
import 'en.dart' as translations_en;

/// Clase para acceder a las traducciones de la aplicación
class AppLocalizations {
  static const String es = 'es';
  static const String en = 'en';
  
  static const List<String> idiomas = [es, en];
  static const List<String> idiomas_nombres = ['Español', 'English'];

  static final Map<String, Map<String, String>> locales = {
    es: translations_es.es,
    en: translations_en.en,
  };

  late Map<String, String> _textos;
  late String _idiomaActual;

  AppLocalizations(String idioma) {
    _idiomaActual = idioma;
    _textos = locales[idioma] ?? locales[es]!;
  }

  /// Obtener traducción por clave
  static String of(BuildContext context, String clave) {
    final locale = Localizations.localeOf(context);
    final idioma = locale.languageCode;
    final mapa = locales[idioma] ?? locales[es]!;
    return mapa[clave] ?? clave;
  }

  /// Obtener traducción directa (requiere contexto)
  String get(String clave) => _textos[clave] ?? clave;

  /// Obtener idioma actual
  String get idioma => _idiomaActual;

  /// Cambiar idioma
  void setIdioma(String idioma) {
    _idiomaActual = idioma;
    _textos = locales[idioma] ?? locales[es]!;
  }
}

/// Delegate para flutter_localizations
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.idiomas.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Provider para manejar cambios de idioma
class AppLocalizationsProvider extends InheritedWidget {
  final AppLocalizations localizations;
  final ValueNotifier<String> idioma;

  const AppLocalizationsProvider({
    Key? key,
    required this.localizations,
    required this.idioma,
    required Widget child,
  }) : super(key: key, child: child);

  static AppLocalizations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLocalizationsProvider>()
        ?.localizations;
  }

  static String nombreIdioma(String codigo) {
    final index = AppLocalizations.idiomas.indexOf(codigo);
    return index >= 0 ? AppLocalizations.idiomas_nombres[index] : 'Español';
  }

  @override
  bool updateShouldNotify(AppLocalizationsProvider oldWidget) {
    return oldWidget.idioma.value != idioma.value;
  }
}

/// Función helper para acceder a textos en cualquier lugar
String getTexto(String clave, {String idioma = 'es'}) {
  final mapa = idioma == 'es' ? translations_es.es : translations_en.en;
  return mapa[clave] ?? clave;
}
