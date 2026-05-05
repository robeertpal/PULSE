import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/pulse_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityIdController = TextEditingController();
  final _occupationIdController = TextEditingController(text: '1');
  final _specializationIdController = TextEditingController();
  final _cuimController = TextEditingController();
  final _codParafaController = TextEditingController();
  final _titluUniversitarController = TextEditingController();

  bool _acordEmail = false;
  bool _acordSms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnpController.dispose();
    _phoneController.dispose();
    _cityIdController.dispose();
    _occupationIdController.dispose();
    _specializationIdController.dispose();
    _cuimController.dispose();
    _codParafaController.dispose();
    _titluUniversitarController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, {String label = 'Câmp'}) {
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

  String? _numberValidator(String? value, {required String label}) {
    final required = _requiredValidator(value, label: label);
    if (required != null) return required;
    if (int.tryParse(value!.trim()) == null) {
      return '$label trebuie să fie un număr valid';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final payload = {
      'email': email,
      'firebase_uid': 'local_${email.toLowerCase().hashCode.abs()}',
      'password': _passwordController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'cnp': _cnpController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city_id': int.parse(_cityIdController.text.trim()),
      'occupation_id': int.parse(_occupationIdController.text.trim()),
      'specialization_id': int.parse(_specializationIdController.text.trim()),
      'cuim': _cuimController.text.trim(),
      'cod_parafa': _codParafaController.text.trim(),
      'titlu_universitar': _titluUniversitarController.text.trim(),
      'acord_email': _acordEmail,
      'acord_sms': _acordSms,
    };

    try {
      final data = await _apiService.register(payload);
      await AuthStorage().saveUserName(
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cont creat cu succes. ID utilizator: ${data['user_id']}')),
      );
      Navigator.of(context).pop();
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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _fieldDecoration(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(title: const Text('Înregistrare cont')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _textField(
                  controller: _emailController,
                  label: 'Email',
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                ),
                _textField(
                  controller: _passwordController,
                  label: 'Parolă',
                  validator: _passwordValidator,
                  obscure: true,
                ),
                _textField(
                  controller: _firstNameController,
                  label: 'Nume',
                  validator: (value) => _requiredValidator(value, label: 'Nume'),
                ),
                _textField(
                  controller: _lastNameController,
                  label: 'Prenume',
                  validator: (value) => _requiredValidator(value, label: 'Prenume'),
                ),
                _textField(
                  controller: _cnpController,
                  label: 'CNP',
                  validator: (value) => _requiredValidator(value, label: 'CNP'),
                  keyboardType: TextInputType.number,
                ),
                _textField(
                  controller: _phoneController,
                  label: 'Telefon',
                  validator: (value) => _requiredValidator(value, label: 'Telefon'),
                  keyboardType: TextInputType.phone,
                ),
                _textField(
                  controller: _cityIdController,
                  label: 'ID oraș',
                  validator: (value) => _numberValidator(value, label: 'Oraș'),
                  keyboardType: TextInputType.number,
                ),
                _textField(
                  controller: _occupationIdController,
                  label: 'ID ocupație',
                  validator: (value) => _numberValidator(value, label: 'Ocupație'),
                  keyboardType: TextInputType.number,
                ),
                _textField(
                  controller: _specializationIdController,
                  label: 'ID specializare',
                  validator: (value) => _numberValidator(value, label: 'Specializare'),
                  keyboardType: TextInputType.number,
                ),
                _textField(
                  controller: _cuimController,
                  label: 'CUIM',
                  validator: (_) => null,
                ),
                _textField(
                  controller: _codParafaController,
                  label: 'Cod parafă',
                  validator: (_) => null,
                ),
                _textField(
                  controller: _titluUniversitarController,
                  label: 'Titlu universitar',
                  validator: (_) => null,
                ),
                CheckboxListTile(
                  value: _acordEmail,
                  contentPadding: EdgeInsets.zero,
                  activeColor: PulseTheme.primary,
                  title: const Text('Sunt de acord să primesc email-uri'),
                  onChanged: (value) {
                    setState(() {
                      _acordEmail = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  value: _acordSms,
                  contentPadding: EdgeInsets.zero,
                  activeColor: PulseTheme.primary,
                  title: const Text('Sunt de acord să primesc SMS-uri'),
                  onChanged: (value) {
                    setState(() {
                      _acordSms = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Finalizează'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
