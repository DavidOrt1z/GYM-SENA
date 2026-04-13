import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/providers/auth_provider.dart';
import 'package:gym_app/providers/proveedor_notificaciones.dart';
import 'package:gym_app/providers/proveedor_idioma.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'package:gym_app/screens/autenticacion/pantalla_inicio.dart';
import 'package:gym_app/screens/autenticacion/pantalla_bienvenida.dart';
import 'package:gym_app/screens/autenticacion/pantalla_login.dart';
import 'package:gym_app/screens/autenticacion/pantalla_registro.dart';
import 'package:gym_app/screens/autenticacion/pantalla_olvide_contrasena.dart';
import 'package:gym_app/screens/onboarding/pantalla_onboarding.dart';
import 'package:gym_app/screens/navegacion_principal.dart';
import 'package:gym_app/screens/configuracion/pantalla_configuracion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DARKER_BG,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);

  final proveedor = ProveedorIdioma();
  await proveedor.inicializar();

  runApp(MyApp(proveedorIdioma: proveedor));
}

class MyApp extends StatelessWidget {
  final ProveedorIdioma proveedorIdioma;

  const MyApp({super.key, required this.proveedorIdioma});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProveedorNotificaciones()),
        ChangeNotifierProvider.value(value: proveedorIdioma),
      ],
      child: MaterialApp(
        title: 'Gym SENA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: DARKER_BG,
          fontFamily: 'Manrope',
          appBarTheme: const AppBarTheme(shadowColor: Colors.transparent),
          dividerColor: Colors.transparent,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale(AppLocalizations.es),
          Locale(AppLocalizations.en),
        ],
        home: const HomeRouterScreen(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class HomeRouterScreen extends StatefulWidget {
  const HomeRouterScreen({super.key});

  @override
  State<HomeRouterScreen> createState() => _HomeRouterScreenState();
}

class _HomeRouterScreenState extends State<HomeRouterScreen> {
  late Future<bool> _checkOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding = _hasCompletedOnboarding();
  }

  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('_onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboarding,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: DARKER_BG,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == false) {
          // Primera vez: mostrar Onboarding
          return const OnboardingScreen();
        } else {
          // Ya completó: mostrar Splash Screen normal
          return const SplashScreen();
        }
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        final isAuthenticated = session != null;

        if (isAuthenticated) {
          return const MainNavigationScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
