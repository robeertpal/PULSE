import 'dart:ui';

import 'package:flutter/material.dart';

class AuthShell {
  static const pulsePink = Color(0xFFFF4D8D);
  static const pulsePurple = pulsePink;
  static const deepPurple = Color(0xFF5A102F);
  static const pulseOrange = Color(0xFFFF8A3D);
  static const softOrange = Color(0xFFFFB36B);
  static const pulseViolet = Color(0xFFFF6FA3);
  static const fieldFill = Color(0xFFFFFFFF);
  static const warmSurface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF171018);
  static const textSecondary = Color(0xFF625766);
  static const authErrorColor = Color(0xFFFF4D5E);
  static const deepGreen = deepPurple;
  static const forestGreen = pulsePurple;

  static const LinearGradient pulseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pulsePink, pulseOrange],
  );

  static BoxDecoration backgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFBFE),
          Color(0xFFF8F2F8),
          Color(0xFFFFF4F8),
          Color(0xFFFFFFFF),
        ],
        stops: [0, 0.36, 0.72, 1],
      ),
    );
  }

  static Widget background({
    required Widget child,
    Alignment gradientBegin = Alignment.topCenter,
    Alignment gradientEnd = Alignment.bottomCenter,
  }) {
    return DecoratedBox(
      decoration: backgroundDecoration(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.58, -0.92),
                  radius: 0.82,
                  colors: [
                    pulsePurple.withValues(alpha: 0.18),
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
                  center: const Alignment(0.82, -0.32),
                  radius: 0.82,
                  colors: [
                    pulseViolet.withValues(alpha: 0.16),
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
                  center: const Alignment(0.18, 0.92),
                  radius: 0.7,
                  colors: [
                    pulseOrange.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: gradientBegin,
                end: gradientEnd,
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.46),
                ],
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class AuthAnimatedGradientBackground extends StatefulWidget {
  const AuthAnimatedGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuthAnimatedGradientBackground> createState() =>
      _AuthAnimatedGradientBackgroundState();
}

class _AuthAnimatedGradientBackgroundState
    extends State<AuthAnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _glow({
    required Color color,
    required double size,
    required Alignment alignment,
    required Offset travel,
    required double opacity,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        final dx = travel.dx * (value - 0.5) * 2;
        final dy = travel.dy * (value - 0.5) * 2;
        return Align(
          alignment: alignment,
          child: Transform.translate(offset: Offset(dx, dy), child: child),
        );
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AuthShell.backgroundDecoration(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _glow(
            color: AuthShell.pulsePurple,
            size: 280,
            alignment: const Alignment(-0.82, -0.78),
            travel: const Offset(32, 18),
            opacity: 0.17,
          ),
          _glow(
            color: AuthShell.pulseOrange,
            size: 230,
            alignment: const Alignment(0.86, 0.82),
            travel: const Offset(-24, -30),
            opacity: 0.12,
          ),
          _glow(
            color: AuthShell.deepPurple,
            size: 320,
            alignment: const Alignment(0.64, -0.34),
            travel: const Offset(-18, 26),
            opacity: 0.13,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.56),
                ],
              ),
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class FrostedAuthCard extends StatelessWidget {
  const FrostedAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B475C).withValues(alpha: 0.12),
                blurRadius: 34,
                offset: const Offset(0, 20),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: AuthShell.pulsePurple.withValues(alpha: 0.08),
                blurRadius: 26,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading || onPressed == null
              ? LinearGradient(
                  colors: [
                    AuthShell.pulsePurple.withValues(alpha: 0.48),
                    AuthShell.pulseOrange.withValues(alpha: 0.48),
                  ],
                )
              : AuthShell.pulseGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AuthShell.pulsePurple.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 14),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthShell.textPrimary,
          backgroundColor: AuthShell.warmSurface.withValues(
            alpha: light ? 0.88 : 0.82,
          ),
          side: BorderSide(
            color: AuthShell.textSecondary.withValues(
              alpha: light ? 0.28 : 0.18,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({super.key, this.size = 112, this.showGlow = true});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AuthShell.pulsePurple.withValues(alpha: 0.34),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AuthShell.pulseOrange.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }
}

class AuthHeaderText extends StatelessWidget {
  const AuthHeaderText({
    super.key,
    required this.title,
    required this.subtitle,
    this.light = false,
    this.align = TextAlign.center,
  });

  final String title;
  final String subtitle;
  final bool light;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? AuthShell.textPrimary : AuthShell.textPrimary;
    final subtitleColor = light
        ? AuthShell.textSecondary
        : AuthShell.textSecondary;
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: titleColor,
            fontSize: light ? 44 : 30,
            fontWeight: FontWeight.w900,
            height: 1.04,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: align,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: subtitleColor,
            fontSize: 15.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthShell.authErrorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AuthShell.authErrorColor.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AuthShell.authErrorColor,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String pulseDisplayErrorMessage(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isEmpty) return 'A apărut o eroare. Te rugăm să încerci din nou.';
  final technicalMarkers = [
    'URL apelat:',
    'Status code:',
    'Body backend:',
    'Tip eroare:',
    'Detalii:',
  ];
  var message = raw.split('\n').first.trim();
  for (final marker in technicalMarkers) {
    final index = message.indexOf(marker);
    if (index >= 0) {
      message = message.substring(0, index).trim();
    }
  }
  if (message.isEmpty) {
    return 'A apărut o eroare. Te rugăm să încerci din nou.';
  }
  return message;
}

Future<void> showPulseErrorDialog(
  BuildContext context,
  Object error, {
  String title = 'Nu am putut continua',
}) {
  final message = pulseDisplayErrorMessage(error);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Închide',
    barrierColor: const Color(0xFF5B475C).withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: FrostedAuthCard(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AuthShell.pulseGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AuthShell.pulsePurple.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AuthShell.textPrimary,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AuthShell.textSecondary,
                        fontSize: 15,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    AuthPrimaryButton(
                      label: 'Am înțeles',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
