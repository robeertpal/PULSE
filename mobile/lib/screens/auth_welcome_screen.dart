import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import 'login_screen.dart';
import 'register_page.dart';

class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen> {
  void _open(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CleanMedicalBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 720;
                final wide = constraints.maxWidth >= 720;
                final visualSize = math.min(
                  wide ? 360.0 : 318.0,
                  constraints.maxWidth - 32,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 36 : 24,
                    compactHeight ? 18 : 28,
                    wide ? 36 : 24,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: compactHeight ? 0 : constraints.maxHeight - 52,
                      maxWidth: wide ? 520 : 430,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TextHero(
                            size: visualSize,
                          ),
                          SizedBox(height: compactHeight ? 14 : 24),
                          const _WelcomeCopy(),
                          SizedBox(height: compactHeight ? 22 : 34),
                          _WelcomeActions(
                            onCreateAccount: () => _open(const RegisterPage()),
                            onLogin: () => _open(const LoginScreen()),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanMedicalBackdrop extends StatelessWidget {
  const _CleanMedicalBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F6FB), Color(0xFFFFFBF8)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.72, -0.82),
                  radius: 0.9,
                  colors: [
                    const Color(0xFFBEEAF5).withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.88, -0.48),
                  radius: 0.96,
                  colors: [
                    AuthShell.pulsePurple.withValues(alpha: 0.11),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.12, 0.98),
                  radius: 0.86,
                  colors: [
                    AuthShell.pulseOrange.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextHero extends StatefulWidget {
  const _TextHero({required this.size});

  final double size;

  @override
  State<_TextHero> createState() => _TextHeroState();
}

class _TextHeroState extends State<_TextHero> {
  int _index = 0;
  late final Timer _timer;

  static const List<String> _words = [
    'articole',
    'reviste',
    'cursuri',
    'evenimente'
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _index = (_index + 1) % _words.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.size * 0.98;

    return Container(
      width: widget.size,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF5B7EE8).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E4FC6).withValues(alpha: 0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dynamic gradient word
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: ShaderMask(
                key: ValueKey<int>(_index),
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF5B7EE8),
                    Color(0xFF6E4FC6),
                    Color(0xFFFF9B72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  _words[_index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, // Required for ShaderMask
                    fontSize: 48,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Static text
            const Text(
              'pentru tine.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthShell.textPrimary,
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'pulse',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ecosistemul medical,\nreimaginat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 38,
            height: 1.04,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Articole, reviste, cursuri, evenimente și insight-uri AI într-o experiență fluidă pentru medici.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthShell.textPrimary.withValues(alpha: 0.58),
            fontSize: 15.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onCreateAccount, required this.onLogin});

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumButton(
          label: 'Creează cont',
          primary: true,
          onPressed: onCreateAccount,
        ),
        const SizedBox(height: 12),
        _PremiumButton(
          label: 'Autentificare',
          primary: false,
          onPressed: onLogin,
        ),
      ],
    );
  }
}

class _PremiumButton extends StatefulWidget {
  const _PremiumButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: widget.primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5B7EE8),
                      Color(0xFF6E4FC6),
                      Color(0xFFFF9B72),
                    ],
                  )
                : null,
            color: widget.primary ? null : Colors.white.withValues(alpha: 0.62),
            border: Border.all(
              color: widget.primary
                  ? Colors.white.withValues(alpha: 0.42)
                  : AuthShell.pulsePurple.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primary
                    ? const Color(0xFF6E4FC6).withValues(alpha: 0.22)
                    : AuthShell.deepPurple.withValues(alpha: 0.07),
                blurRadius: widget.primary ? 24 : 16,
                offset: Offset(0, widget.primary ? 14 : 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.primary ? Colors.white : AuthShell.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
