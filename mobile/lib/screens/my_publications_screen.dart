import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';
import '../widgets/profile_ui_helpers.dart';

class MyPublicationsScreen extends StatelessWidget {
  const MyPublicationsScreen({super.key});

  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _pink = PulseTheme.magazineContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ProfileBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const ProfileGradientHeading('Revistele mele'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: _pink.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nu ai reviste încă.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aici vor apărea revistele tale PULSE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
