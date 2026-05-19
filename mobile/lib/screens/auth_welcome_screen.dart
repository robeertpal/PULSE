import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import 'login_screen.dart';
import 'register_page.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthShell.background(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 580 : 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        const Center(child: AuthLogoMark(size: 118)),
                        const SizedBox(height: 24),
                        const AuthHeaderText(
                          title: 'PULSE',
                          subtitle:
                              'Platforma medicală digitală pentru conținut, evenimente și educație profesională.',
                          light: true,
                        ),
                        SizedBox(height: wide ? 64 : 42),
                        AuthPrimaryButton(
                          label: 'Autentificare',
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const LoginScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AuthSecondaryButton(
                          label: 'Creează cont',
                          light: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const RegisterPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: wide ? 56 : 28),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
