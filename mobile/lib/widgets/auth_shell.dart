import 'dart:ui';

import 'package:flutter/material.dart';

class AuthShell {
  static const heroImageUrl =
      'https://storageforpulse.blob.core.windows.net/content-images/images/2026/05/Screenshot%202026-05-19%20at%2015.33.30.png';

  static const pulsePurple = Color(0xFF5B2DAA);
  static const deepPurple = Color(0xFF35156F);
  static const pulseOrange = Color(0xFFFF8A3D);
  static const softOrange = Color(0xFFFFB36B);
  static const fieldFill = Color(0xFFF8F4FB);
  static const warmSurface = Color(0xFFFFFBF8);
  static const textPrimary = Color(0xFF21162D);
  static const textSecondary = Color(0xFF74677F);
  static const deepGreen = deepPurple;
  static const forestGreen = pulsePurple;

  static const LinearGradient pulseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pulsePurple, pulseOrange],
  );

  static BoxDecoration backgroundDecoration() {
    return const BoxDecoration(
      image: DecorationImage(
        image: NetworkImage(heroImageUrl),
        fit: BoxFit.cover,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: gradientBegin,
            end: gradientEnd,
            colors: const [
              Color(0xA915092B),
              Color(0x9935156F),
              Color(0xB8FF8A3D),
              Color(0xF7FFFBF8),
            ],
            stops: [0, 0.48, 0.78, 1],
          ),
        ),
        child: child,
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
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 34,
                offset: const Offset(0, 18),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AuthShell.pulseOrange.withValues(alpha: 0.26),
              blurRadius: 18,
              offset: const Offset(0, 10),
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
              borderRadius: BorderRadius.circular(20),
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
          foregroundColor: light ? Colors.white : AuthShell.pulsePurple,
          side: BorderSide(
            color: light
                ? Colors.white.withValues(alpha: 0.72)
                : AuthShell.pulseOrange,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
            Colors.white.withValues(alpha: 0.68),
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
    final titleColor = light ? Colors.white : AuthShell.textPrimary;
    final subtitleColor = light
        ? Colors.white.withValues(alpha: 0.82)
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
