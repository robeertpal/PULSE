import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/in-app-logo.png', // Noul logo PULSE
                  height: 80,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Bun venit în pulse',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PulseTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secțiunea de Autentificare este\nîn curs de dezvoltare.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: PulseTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Butonul care sare peste login spre pagină
              ElevatedButton(
                onPressed: () {
                  // Tranziție fină către Home
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 0.05); // Ușor glisaj de jos
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseTheme.primary, // Premium Blue
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Formă de lux iOS
                  ),
                  shadowColor: PulseTheme.primary.withOpacity(0.5),
                ),
                child: const Text(
                  'Continuă către Acasă',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
