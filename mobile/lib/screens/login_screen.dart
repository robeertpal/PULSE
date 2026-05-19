import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/auth_shell.dart';
import 'home_screen.dart';
import 'register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _backIcon = 'assets/icons/arrow.backward.svg';
  static const _emailIcon = 'assets/icons/envelope.fill.svg';
  static const _passwordIcon = 'assets/icons/key.fill.svg';
  static const _eyeIcon = 'assets/icons/eye.fill.svg';
  static const _eyeSlashIcon = 'assets/icons/eye.slash.fill.svg';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _authStorage = AuthStorage();

  bool _isSubmitting = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return '$label este obligatoriu';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _requiredValidator(value, label: 'Email');
    if (required != null) return required;
    final email = value!.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Introdu un email valid';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final required = _requiredValidator(value, label: 'Parolă');
    if (required != null) return required;
    if (value!.trim().length < 8) {
      return 'Parola trebuie să aibă minimum 8 caractere';
    }
    return null;
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final data = await _apiService.login(email: email, password: password);
      if (!mounted) return;

      final userId = data['user_id'];
      final sessionToken = data['session_token'] as String? ?? '';
      await _authStorage.saveSession(
        userId: userId is int ? userId : int.parse(userId.toString()),
        sessionToken: sessionToken,
        email: email,
      );

      // Pre-fetch and cache user name for immediate display on HomeScreen
      try {
        final profileData = await _apiService.getMyProfile();
        final name = profileData['display_name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          await _authStorage.saveUserName(name.trim());
        }
      } catch (e) {
        debugPrint('Failed to pre-fetch profile name on login: $e');
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  Widget _passwordVisibilityButton() {
    return SizedBox(
      width: 48,
      height: 56,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 56),
        icon: Opacity(
          opacity: 0.62,
          child: _svgIcon(
            _showPassword ? _eyeSlashIcon : _eyeIcon,
            size: 20,
            color: AuthShell.pulsePurple,
          ),
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String hint,
    String iconAsset, {
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
                    const AuthHeaderText(
                      title: 'Bine ai revenit',
                      subtitle:
                          'Autentifică-te pentru a continua experiența ta medicală personalizată.',
                      light: true,
                      align: TextAlign.left,
                    ),
                    const SizedBox(height: 30),
                    FrostedAuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: AuthShell.pulsePurple,
                              style: const TextStyle(
                                color: AuthShell.textPrimary,
                                fontSize: 15,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: _emailValidator,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: _fieldDecoration('Email', _emailIcon),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              cursorColor: AuthShell.pulsePurple,
                              style: const TextStyle(
                                color: AuthShell.textPrimary,
                                fontSize: 15,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: _passwordValidator,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: _fieldDecoration(
                                'Parolă',
                                _passwordIcon,
                                suffixIcon: _passwordVisibilityButton(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthPrimaryButton(
                              label: 'Intră în cont',
                              isLoading: _isSubmitting,
                              onPressed: _submitLogin,
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Nu ai cont? Creează unul',
                                style: TextStyle(
                                  color: AuthShell.pulsePurple,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
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
