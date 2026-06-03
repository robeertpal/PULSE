import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/otp_code_input.dart';
import 'interests_selection_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.password,
  });

  final String email;
  final String? password;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  bool _isEditingEmail = false;
  int _otpInputVersion = 0;
  String _currentEmail = '';
  String _otpCode = '';
  String? _otpErrorText;
  String? _emailErrorText;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email.trim();
    _emailController.text = _currentEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  void _resetOtp() {
    setState(() {
      _otpInputVersion += 1;
      _otpCode = '';
      _otpErrorText = null;
    });
  }

  Future<void> _verifyCode() async {
    final code = _otpCode.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _otpErrorText = 'Introdu codul de 6 cifre din email.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _otpErrorText = null;
    });

    try {
      await _apiService.verifyEmailOtp(email: _currentEmail, otpCode: code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email confirmat cu succes.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => widget.password == null || widget.password!.isEmpty
              ? const LoginScreen()
              : InterestsSelectionScreen(
                  email: _currentEmail,
                  password: widget.password,
                ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await showPulseErrorDialog(context, e);
      _resetOtp();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendCode({String? emailOverride}) async {
    final targetEmail = (emailOverride ?? _currentEmail).trim();
    setState(() {
      _isResending = true;
      _otpErrorText = null;
    });

    try {
      await _apiService.resendEmailOtp(email: targetEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Am trimis un cod nou pe email.')),
      );
      _resetOtp();
    } catch (e) {
      if (!mounted) return;
      await showPulseErrorDialog(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _saveChangedEmail() async {
    final newEmail = _emailController.text.trim();
    if (!_isValidEmail(newEmail)) {
      setState(() {
        _emailErrorText = 'Introdu o adresă de email validă.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _emailErrorText = null;
    });

    try {
      await _apiService.resendEmailOtp(email: newEmail);
      if (!mounted) return;
      setState(() {
        _currentEmail = newEmail;
        _isEditingEmail = false;
      });
      _resetOtp();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Am trimis codul pe noua adresă.')),
      );
    } catch (e) {
      if (!mounted) return;
      await showPulseErrorDialog(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  InputDecoration _emailDecoration() {
    return InputDecoration(
      hintText: 'Email',
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: AuthShell.fieldFill,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      errorText: _emailErrorText,
      hintStyle: const TextStyle(
        color: AuthShell.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AuthShell.pulsePurple, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.3),
      ),
    );
  }

  Widget _emailSummary() {
    if (_isEditingEmail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            cursorColor: AuthShell.pulsePurple,
            style: const TextStyle(
              color: AuthShell.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: _emailDecoration(),
            onSubmitted: (_) => _isResending ? null : _saveChangedEmail(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isResending
                      ? null
                      : () {
                          setState(() {
                            _emailController.text = _currentEmail;
                            _emailErrorText = null;
                            _isEditingEmail = false;
                          });
                        },
                  child: const Text('Renunță'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuthPrimaryButton(
                  onPressed: _isResending ? null : _saveChangedEmail,
                  isLoading: _isResending,
                  label: _isResending ? 'Se trimite...' : 'Retrimite',
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(
          'Am trimis codul la $_currentEmail',
          style: const TextStyle(
            color: AuthShell.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        TextButton(
          onPressed: _isSubmitting || _isResending
              ? null
              : () {
                  setState(() {
                    _emailController.text = _currentEmail;
                    _emailErrorText = null;
                    _isEditingEmail = true;
                  });
                },
          style: TextButton.styleFrom(
            foregroundColor: AuthShell.pulsePurple,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Schimbă emailul',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
                          _emailSummary(),
                          const SizedBox(height: 22),
                          OtpCodeInput(
                            key: ValueKey(_otpInputVersion),
                            errorText: _otpErrorText,
                            enabled: !_isSubmitting,
                            autofocus: true,
                            onChanged: (code) {
                              setState(() {
                                _otpCode = code;
                                if (_otpErrorText != null) {
                                  _otpErrorText = null;
                                }
                              });
                            },
                            onSubmitted: (_) => _verifyCode(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            child: AuthPrimaryButton(
                              label: 'Confirmă codul',
                              isLoading: _isSubmitting,
                              onPressed: _isSubmitting ? null : _verifyCode,
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
