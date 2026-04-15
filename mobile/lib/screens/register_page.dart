import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/pulse_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityIdController = TextEditingController();

  final _cuimController = TextEditingController();
  final _codParafaController = TextEditingController();
  final _titluUniversitarController = TextEditingController();
  final _specializationIdController = TextEditingController();
  final _occupationIdController = TextEditingController(text: '1');

  bool _acordEmail = false;
  bool _acordSms = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  static const String _registerUrl = 'http://127.0.0.1:8000/api/register';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnpController.dispose();
    _phoneController.dispose();
    _cityIdController.dispose();
    _cuimController.dispose();
    _codParafaController.dispose();
    _titluUniversitarController.dispose();
    _specializationIdController.dispose();
    _occupationIdController.dispose();
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

  String? _cnpValidator(String? value) {
    final required = _requiredValidator(value, label: 'CNP');
    if (required != null) return required;
    final cnp = value!.trim();
    if (cnp.length != 13 || int.tryParse(cnp) == null) {
      return 'CNP trebuie să aibă 13 cifre';
    }
    return null;
  }

  bool _validateStep(int step) {
    setState(() {});
    switch (step) {
      case 0:
        return _emailValidator(_emailController.text) == null &&
            _passwordValidator(_passwordController.text) == null;
      case 1:
        return _requiredValidator(_firstNameController.text, label: 'Nume') == null &&
            _requiredValidator(_lastNameController.text, label: 'Prenume') == null &&
            _cnpValidator(_cnpController.text) == null &&
            _requiredValidator(_phoneController.text, label: 'Telefon') == null &&
            _requiredValidator(_cityIdController.text, label: 'Oraș') == null;
      case 2:
        return _requiredValidator(_cuimController.text, label: 'CUIM') == null &&
            _requiredValidator(_codParafaController.text, label: 'Cod Parafă') == null &&
            _requiredValidator(_titluUniversitarController.text, label: 'Titlu universitar') == null &&
            _requiredValidator(_specializationIdController.text, label: 'Specializare') == null &&
            _requiredValidator(_occupationIdController.text, label: 'Ocupație') == null;
      default:
        return false;
    }
  }

  String _generateFirebaseUid(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return 'local_${normalizedEmail.hashCode.abs()}';
  }

  Future<void> _submitRegistration() async {
    if (!_validateStep(2)) return;

    final cityId = int.tryParse(_cityIdController.text.trim());
    final specializationId = int.tryParse(_specializationIdController.text.trim());
    final occupationId = int.tryParse(_occupationIdController.text.trim());

    if (cityId == null || specializationId == null || occupationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID-urile trebuie să fie numere valide.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();

    final payload = {
      'email': email,
      'firebase_uid': _generateFirebaseUid(email),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'cnp': _cnpController.text.trim(),
      'phone': _phoneController.text.trim(),
      'cuim': _cuimController.text.trim(),
      'cod_parafa': _codParafaController.text.trim(),
      'titlu_universitar': _titluUniversitarController.text.trim(),
      'city_id': cityId,
      'occupation_id': occupationId,
      'specialization_id': specializationId,
      'acord_email': _acordEmail,
      'acord_sms': _acordSms,
    };

    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userId = data['user_id'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cont creat cu succes. ID utilizator: $userId')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Înregistrare eșuată: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare de conexiune: $e')),
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
    String? hintText,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        decoration: _fieldDecoration(label).copyWith(hintText: hintText),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Cont'),
        isActive: _currentStep >= 0,
        content: Column(
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
          ],
        ),
      ),
      Step(
        title: const Text('Date Personale'),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
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
              validator: _cnpValidator,
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
              label: 'Oraș',
              hintText: 'ID oraș (ex: 1)',
              validator: (value) => _requiredValidator(value, label: 'Oraș'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Date Profesionale'),
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField(
              controller: _cuimController,
              label: 'CUIM',
              validator: (value) => _requiredValidator(value, label: 'CUIM'),
            ),
            _textField(
              controller: _codParafaController,
              label: 'Cod Parafă',
              validator: (value) => _requiredValidator(value, label: 'Cod Parafă'),
            ),
            _textField(
              controller: _titluUniversitarController,
              label: 'Titlu universitar',
              validator: (value) => _requiredValidator(value, label: 'Titlu universitar'),
            ),
            _textField(
              controller: _specializationIdController,
              label: 'Specializare',
              hintText: 'ID specializare (ex: 2)',
              validator: (value) => _requiredValidator(value, label: 'Specializare'),
              keyboardType: TextInputType.number,
            ),
            _textField(
              controller: _occupationIdController,
              label: 'Ocupație',
              hintText: 'ID ocupație (ex: 1)',
              validator: (value) => _requiredValidator(value, label: 'Ocupație'),
              keyboardType: TextInputType.number,
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
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: const Text('Înregistrare cont'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 2;
              return Row(
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (!_validateStep(_currentStep)) {
                              return;
                            }

                            if (isLastStep) {
                              _submitRegistration();
                            } else {
                              setState(() {
                                _currentStep += 1;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSubmitting && isLastStep
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isLastStep ? 'Finalizează' : 'Continuă'),
                  ),
                  const SizedBox(width: 10),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _currentStep -= 1;
                              });
                            },
                      child: const Text('Înapoi'),
                    ),
                ],
              );
            },
            onStepTapped: (step) {
              setState(() {
                _currentStep = step;
              });
            },
            steps: _buildSteps(),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          'Datele de profil sunt trimise către backend, iar identificatorul tehnic de autentificare este generat automat.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
