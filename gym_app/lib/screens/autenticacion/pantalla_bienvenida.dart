import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'package:gym_app/screens/autenticacion/pantalla_login.dart';
import 'package:gym_app/widgets/dot_triangle_loader.dart';
import 'package:video_player/video_player.dart';
import '../../utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final VideoPlayerController _videoController;
  bool _isLoginLoading = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/images/VideoFondoLogin.mp4')
          ..setLooping(true)
          ..setVolume(0);

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    if (_isLoginLoading) return;

    setState(() => _isLoginLoading = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        transitionsBuilder: (_, animation, _, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    if (mounted) {
      setState(() => _isLoginLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: DARKER_BG)),
          if (_videoController.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    DARKER_BG.withValues(alpha: 0.35),
                    DARKER_BG.withValues(alpha: 0.95),
                  ],
                  stops: const [0, 0.58, 1],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 34),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/logo.svg',
                        height: 82,
                        width: 82,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'JACEK GYM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons at bottom
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Log in Button
                      ElevatedButton(
                        onPressed: _isLoginLoading ? null : _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PRIMARY_COLOR,
                          disabledBackgroundColor: PRIMARY_COLOR.withValues(
                            alpha: 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _isLoginLoading
                              ? SizedBox(
                                  key: const ValueKey('login-loader'),
                                  height: 34,
                                  width: 48,
                                  child: DotTriangleLoader(),
                                )
                              : Text(
                                  AppLocalizations.of(
                                    context,
                                    'iniciar_sesion',
                                  ),
                                  key: const ValueKey('login-text'),
                                  style: const TextStyle(
                                    color: WHITE,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context, 'no_tienes_cuenta'),
                            style: const TextStyle(
                              color: SECONDARY_COLOR,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              AppLocalizations.of(context, 'registrarse'),
                              style: const TextStyle(
                                color: PRIMARY_COLOR,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
