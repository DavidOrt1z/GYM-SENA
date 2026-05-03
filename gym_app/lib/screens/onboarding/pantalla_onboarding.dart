import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('_onboarding_completed', true);
  }

  void _completeOnboarding() async {
    await _markOnboardingAsCompleted();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              // Pantalla 1: Logo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isEnglish ? 'Welcome to JACEK GYM' : 'Bienvenido a JACEK GYM',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WHITE,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      isEnglish
                          ? 'Your app to manage workouts and bookings'
                          : 'Tu aplicación para gestionar entrenamientos y reservas de horarios',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              _buildOnboardingPage(
                assetPath: 'assets/icons/onboarding_calendario.svg',
                title: isEnglish
                    ? 'Book Your Time Slots'
                    : 'Reserva tus Horarios',
                description: isEnglish
                    ? 'Choose the days and times that work best for your training'
                    : 'Selecciona los días y horas que te convengan para entrenar',
                color: const Color(0xFF2196F3),
              ),
              _buildOnboardingPage(
                assetPath: 'assets/icons/onboarding_peso.svg',
                title: isEnglish
                    ? 'Track Your Progress'
                    : 'Monitorea tu Progreso',
                description: isEnglish
                    ? 'Log your weight and view your progress with visual charts'
                    : 'Registra tu peso y observa tu avance con gráficas visuales',
                color: const Color(0xFF00BCD4),
              ),
              _buildOnboardingPage(
                assetPath: 'assets/icons/onboarding_idioma.svg',
                title: isEnglish
                    ? 'Customize Your Experience!'
                    : '¡Personaliza tu Experiencia!',
                description: isEnglish
                    ? 'Change language, notifications, and more in settings'
                    : 'Cambia idioma, notificaciones y más en configuración',
                color: const Color(0xFF4CAF50),
              ),
            ],
          ),

          // Skip Button (Arriba a la derecha)
          Positioned(
            top: 40,
            right: 24,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                isEnglish ? 'Skip' : 'Saltar',
                style: TextStyle(
                  color: PRIMARY_COLOR,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Indicadores de página (Abajo)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: _currentPage == index
                          ? PRIMARY_COLOR
                          : SECONDARY_COLOR.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Botones de Navegación (Abajo)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Anterior
                if (_currentPage > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(isEnglish ? 'Back' : 'Anterior'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DARK_BG,
                      foregroundColor: WHITE,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: PRIMARY_COLOR, width: 1),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),

                // Botón Siguiente / Comenzar
                if (_currentPage < 3)
                  ElevatedButton.icon(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    label: Text(isEnglish ? 'Next' : 'Siguiente'),
                    icon: const Icon(Icons.arrow_forward),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PRIMARY_COLOR,
                      foregroundColor: WHITE,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _completeOnboarding,
                    label: Text(isEnglish ? 'Start!' : '¡Comenzar!'),
                    icon: const Icon(Icons.check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: WHITE,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String assetPath,
    required String title,
    required String description,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono Grande
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: 70,
              height: 70,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Título
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WHITE,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        // Descripción
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SECONDARY_COLOR,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
