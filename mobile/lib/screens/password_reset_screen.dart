import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/otp_code_input.dart';
import 'login_screen.dart';

enum _PasswordResetStep { email, code, password }

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  static const _backIcon = 'assets/icons/arrow.backward.svg';
  static const _emailIcon = 'assets/icons/envelope.fill.svg';
  static const _passwordIcon = 'assets/icons/key.fill.svg';
  static const _eyeIcon = 'assets/icons/eye.fill.svg';
  static const _eyeSlashIcon = 'assets/icons/eye.slash.fill.svg';

  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _PasswordResetStep _step = _PasswordResetStep.email;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  int _otpInputVersion = 0;
  String _email = '';
  String _otpCode = '';
  String? _emailErrorText;
  String? _otpErrorText;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail.trim();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _resetOtp() {
    setState(() {
      _otpInputVersion += 1;
      _otpCode = '';
      _otpErrorText = null;
    });
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _emailErrorText = 'Introdu o adresă de email validă.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailErrorText = null;
    });

    try {
      await _apiService.requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() {
        _email = email;
        _step = _PasswordResetStep.code;
      });
      _resetOtp();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Am trimis codul pe email.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_step == _PasswordResetStep.code) {
          _otpErrorText = _errorText(e);
        } else {
          _emailErrorText = _errorText(e);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
      await _apiService.verifyPasswordResetCode(email: _email, otpCode: code);
      if (!mounted) return;
      setState(() {
        _step = _PasswordResetStep.password;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpErrorText = _errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmPasswordReset() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (password.length < 8) {
      setState(() {
        _passwordErrorText = 'Parola trebuie să aibă minimum 8 caractere.';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _passwordErrorText = 'Parolele introduse nu coincid.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _passwordErrorText = null;
    });

    try {
      await _apiService.confirmPasswordReset(
        email: _email,
        otpCode: _otpCode,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parola a fost resetată cu succes.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordErrorText = _errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _svgIcon(String asset, {double size = 21, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? AuthShell.pulsePurple,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _decorativeIconSlot(String asset) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Center(child: _svgIcon(asset, size: 21)),
    );
  }

  Widget _passwordVisibilityButton({
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 48,
      height: 56,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 56),
        icon: Opacity(
          opacity: 0.62,
          child: _svgIcon(
            visible ? _eyeSlashIcon : _eyeIcon,
            size: 20,
            color: AuthShell.pulsePurple,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String hint,
    String iconAsset, {
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: _decorativeIconSlot(iconAsset),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        maxWidth: 48,
        minHeight: 56,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 48,
        maxWidth: 48,
        minHeight: 56,
      ),
      filled: true,
      fillColor: AuthShell.fieldFill,
      isDense: false,
      contentPadding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
      errorText: errorText,
      errorMaxLines: 3,
      hintStyle: const TextStyle(
        color: AuthShell.textSecondary,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      errorStyle: const TextStyle(height: 1.25),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.3),
      ),
    );
  }

  Widget _emailStep() {
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
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          decoration: _fieldDecoration(
            'Email',
            _emailIcon,
            errorText: _emailErrorText,
          ),
          onSubmitted: (_) => _isSubmitting ? null : _requestCode(),
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          label: 'Trimite codul',
          isLoading: _isSubmitting,
          onPressed: _requestCode,
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Am trimis codul la $_email',
          style: const TextStyle(
            color: AuthShell.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
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
        AuthPrimaryButton(
          label: 'Verifică codul',
          isLoading: _isSubmitting,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSubmitting ? null : _requestCode,
          child: const Text('Trimite un cod nou'),
        ),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.next,
          cursorColor: AuthShell.pulsePurple,
          style: const TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          decoration: _fieldDecoration(
            'Parolă nouă',
            _passwordIcon,
            errorText: _passwordErrorText,
            suffixIcon: _passwordVisibilityButton(
              visible: _showPassword,
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          onChanged: (_) {
            if (_passwordErrorText != null) {
              setState(() => _passwordErrorText = null);
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          textInputAction: TextInputAction.done,
          cursorColor: AuthShell.pulsePurple,
          style: const TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          decoration: _fieldDecoration(
            'Confirmă parola',
            _passwordIcon,
            suffixIcon: _passwordVisibilityButton(
              visible: _showConfirmPassword,
              onPressed: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
          onSubmitted: (_) => _isSubmitting ? null : _confirmPasswordReset(),
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          label: 'Setează parola nouă',
          isLoading: _isSubmitting,
          onPressed: _confirmPasswordReset,
        ),
      ],
    );
  }

  String get _title {
    switch (_step) {
      case _PasswordResetStep.email:
        return 'Resetează parola';
      case _PasswordResetStep.code:
        return 'Introdu codul';
      case _PasswordResetStep.password:
        return 'Parolă nouă';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _PasswordResetStep.email:
        return 'Introdu emailul contului tău și îți trimitem un cod de resetare.';
      case _PasswordResetStep.code:
        return 'Verifică mesajul primit și introdu codul de 6 cifre.';
      case _PasswordResetStep.password:
        return 'Codul este valid. Alege o parolă nouă pentru contul tău.';
    }
  }

  Widget get _stepContent {
    switch (_step) {
      case _PasswordResetStep.email:
        return _emailStep();
      case _PasswordResetStep.code:
        return _codeStep();
      case _PasswordResetStep.password:
        return _passwordStep();
    }
  }

  void _goBack() {
    if (_step == _PasswordResetStep.password) {
      setState(() => _step = _PasswordResetStep.code);
      return;
    }
    if (_step == _PasswordResetStep.code) {
      setState(() => _step = _PasswordResetStep.email);
      return;
    }
    Navigator.of(context).maybePop();
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: _isSubmitting ? null : _goBack,
                        icon: _svgIcon(
                          _backIcon,
                          size: 22,
                          color: Colors.white,
                        ),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    AuthHeaderText(
                      title: _title,
                      subtitle: _subtitle,
                      light: true,
                      align: TextAlign.left,
                    ),
                    const SizedBox(height: 30),
                    FrostedAuthCard(child: _stepContent),
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
