import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'home_screen.dart';
import '../services/auth_storage.dart';
import '../theme/pulse_theme.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _startApp();
  }

  Future<void> _startApp() async {
    // 1. Promisiunea de minim 1.2 secunde pentru brand awareness (handoff de la logo nativ)
    final brandDelay = Future.delayed(const Duration(milliseconds: 1200));

    // 2. Controlul de timeout absolut de 60 secunde (cerință utilizator)
    final timeout = Future.delayed(const Duration(seconds: 60));

    // 3. Task de sănătate backend care rulează în buclă până la succes
    final healthCheck = () async {
      bool isOnline = false;
      while (mounted && !isOnline) {
        isOnline = await _apiService.checkHealth();
        if (isOnline) break;
        await Future.delayed(const Duration(seconds: 3)); // Reîncearcă la fiecare 3 secunde
      }
    }();

    // Așteptăm fie succesul backend + delay mini, fie atingerea celor 60 secunde
    await Future.any([
      Future.wait([brandDelay, healthCheck]),
      timeout,
    ]);

    if (mounted) {
      final isAuthenticated = await _authStorage.isAuthenticated();
      if (!mounted) return;
      if (isAuthenticated) {
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000), // Cinematic slow fade
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 90, // Mult mai discret și elegant
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
