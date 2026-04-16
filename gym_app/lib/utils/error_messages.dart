class AppErrorMessages {
  static String map(Object error, {String? fallback}) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('authretryablefetchexception') ||
        normalized.contains('clientfailed to fetch') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network') ||
        normalized.contains('timeout')) {
      return 'No pudimos conectar con el servidor. Revisa tu internet e intenta de nuevo';
    }

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_grant') ||
        normalized.contains('user not found')) {
      return 'Correo o contraseña incorrectos';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Por favor confirma tu correo antes de iniciar sesión';
    }

    if (normalized.contains('already_registered') ||
        normalized.contains('user already registered') ||
        normalized.contains('duplicate key value') ||
        normalized.contains('duplicate')) {
      return 'Este correo ya está registrado';
    }

    if (normalized.contains('rls') ||
        normalized.contains('permission denied') ||
        normalized.contains('not allowed')) {
      return 'No tienes permisos para realizar esta acción';
    }

    if (normalized.contains('jwt') || normalized.contains('token')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente';
    }

    return fallback ?? 'Ocurrió un error. Intenta nuevamente';
  }
}
