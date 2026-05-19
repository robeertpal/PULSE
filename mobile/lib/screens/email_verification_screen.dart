import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../widgets/auth_shell.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _apiService = ApiService();

  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu codul de 6 cifre din email.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.verifyEmailOtp(email: widget.email, otpCode: code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email confirmat cu succes.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _apiService.resendEmailOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Am trimis un cod nou pe email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  InputDecoration _codeDecoration() {
    return InputDecoration(
      hintText: 'Cod verificare',
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: const Icon(
        Icons.numbers_rounded,
        color: AuthShell.pulsePurple,
        size: 21,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
      filled: true,
      fillColor: AuthShell.fieldFill,
      contentPadding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
      hintStyle: const TextStyle(
        color: AuthShell.textSecondary,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AuthShell.pulseOrange, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthShell.background(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeaderText(
                      title: 'Confirmă emailul',
                      subtitle:
                          'Introdu codul primit pentru a activa contul pulse.',
                      light: true,
                      align: TextAlign.left,
                    ),
                    const SizedBox(height: 30),
                    FrostedAuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: AuthShell.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: _codeDecoration(),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _verifyCode,
                              style: FilledButton.styleFrom(
                                backgroundColor: AuthShell.pulsePurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Confirmă codul',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isResending ? null : _resendCode,
                            child: Text(
                              _isResending
                                  ? 'Se retrimite...'
                                  : 'Trimite un cod nou',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
