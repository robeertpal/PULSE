import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/pulse_theme.dart';

class _OccupationOption {
  const _OccupationOption({required this.id, required this.name});

  final int id;
  final String name;
}

class _ProfessionalRule {
  const _ProfessionalRule({
    this.requiresCuim = false,
    this.requiresCodParafa = false,
    this.requiresSectie = false,
    this.requiresRegistrationCode = false,
    this.registrationCodeLabel = 'Cod înregistrare',
  });

  final bool requiresCuim;
  final bool requiresCodParafa;
  final bool requiresSectie;
  final bool requiresRegistrationCode;
  final String registrationCodeLabel;
}

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
  final _registrationCodeController = TextEditingController();
  final _sectiaController = TextEditingController();
  final _titluUniversitarController = TextEditingController();
  final _specializationIdController = TextEditingController();

  List<_OccupationOption> _occupations = const [];
  int? _selectedOccupationId;
  bool _isLoadingOccupations = false;
  String? _occupationSelectionError;

  bool _acordEmail = false;
  bool _acordSms = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  static const String _registerUrl = 'http://127.0.0.1:8000/api/register';
  static const String _occupationsUrl = 'http://127.0.0.1:8000/occupations';

  _OccupationOption? get _selectedOccupation {
    if (_selectedOccupationId == null) return null;
    for (final occupation in _occupations) {
      if (occupation.id == _selectedOccupationId) return occupation;
    }
    return null;
  }

  _ProfessionalRule get _professionalRule {
    final occupationName = (_selectedOccupation?.name ?? '').toLowerCase();

    if (occupationName.contains('medic veterinar')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod înregistrare CMV',
        requiresCodParafa: true,
      );
    }
    if (occupationName.contains('stomatolog')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresCodParafa: true,
      );
    }
    if (occupationName.contains('medic')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresCodParafa: true,
      );
    }
    if (occupationName.contains('asistent')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod înregistrare asistent',
        requiresSectie: true,
      );
    }
    if (occupationName.contains('farmacist')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod Colegiul Farmaciștilor',
      );
    }
    if (occupationName.contains('psiholog')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod Colegiul Psihologilor',
      );
    }
    if (occupationName.contains('nutritionist')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod înregistrare nutriționist',
      );
    }

    return const _ProfessionalRule();
  }

  @override
  void initState() {
    super.initState();
    _loadOccupations();
  }

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
    _registrationCodeController.dispose();
    _sectiaController.dispose();
    _titluUniversitarController.dispose();
    _specializationIdController.dispose();
    super.dispose();
  }

  Future<void> _loadOccupations() async {
    setState(() {
      _isLoadingOccupations = true;
      _occupationSelectionError = null;
    });

    try {
      final response = await http.get(Uri.parse(_occupationsUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Nu am putut încărca ocupațiile: ${response.statusCode}');
      }

      final payload = jsonDecode(response.body);
      if (payload is! List) {
        throw Exception('Răspuns invalid pentru ocupații');
      }

      final parsed = <_OccupationOption>[];
      for (final item in payload) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'];
        final name = item['name'];
        if (id is int && name is String && name.trim().isNotEmpty) {
          parsed.add(_OccupationOption(id: id, name: name.trim()));
        }
      }

      if (!mounted) return;
      setState(() {
        _occupations = parsed;
        if (parsed.isNotEmpty) {
          _selectedOccupationId ??= parsed.first.id;
        } else {
          _selectedOccupationId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _occupations = const [];
        _selectedOccupationId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea ocupațiilor: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOccupations = false;
        });
      }
    }
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
        final rule = _professionalRule;
        final hasOccupation = _selectedOccupationId != null;
        _occupationSelectionError = hasOccupation ? null : 'Ocupația este obligatorie';
        final hasTitle =
            _requiredValidator(_titluUniversitarController.text, label: 'Titlu universitar') == null;
        final hasSpecialization =
          _requiredValidator(_specializationIdController.text, label: 'Specializare') == null;

        final hasCuim = !rule.requiresCuim ||
          _requiredValidator(_cuimController.text, label: 'CUIM') == null;
        final hasCodParafa = !rule.requiresCodParafa ||
          _requiredValidator(_codParafaController.text, label: 'Cod Parafă') == null;
        final hasRegistrationCode = !rule.requiresRegistrationCode ||
          _requiredValidator(
              _registrationCodeController.text,
              label: rule.registrationCodeLabel,
            ) ==
            null;
        final hasSectie =
          !rule.requiresSectie || _requiredValidator(_sectiaController.text, label: 'Secție') == null;

        return hasOccupation &&
          hasTitle &&
          hasSpecialization &&
          hasCuim &&
          hasCodParafa &&
          hasRegistrationCode &&
          hasSectie;
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
    final occupationId = _selectedOccupationId;

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
    final rule = _professionalRule;
    final isMedicStyle = rule.requiresCuim;

    final payload = {
      'email': email,
      'firebase_uid': _generateFirebaseUid(email),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'cnp': _cnpController.text.trim(),
      'phone': _phoneController.text.trim(),
      'cuim': isMedicStyle ? _cuimController.text.trim() : _registrationCodeController.text.trim(),
      'cod_parafa': rule.requiresCodParafa ? _codParafaController.text.trim() : '',
      'titlu_universitar': _titluUniversitarController.text.trim(),
      'sectia': rule.requiresSectie ? _sectiaController.text.trim() : '',
      'occupation_name': _selectedOccupation?.name ?? '',
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

  Widget _occupationDropdown() {
    if (_isLoadingOccupations) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (_occupations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nu există ocupații încărcate din backend.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
            TextButton(
              onPressed: _loadOccupations,
              child: const Text('Reîncarcă ocupațiile'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedOccupationId?.toString(),
        decoration: _fieldDecoration('Ocupație'),
        items: _occupations
            .map((occupation) => DropdownMenuItem<String>(
                  value: occupation.id.toString(),
                  child: Text(occupation.name),
                ))
            .toList(),
        onChanged: (value) {
          final parsedId = int.tryParse(value ?? '');
          if (parsedId == null) {
            return;
          }

          final previousRule = _professionalRule;
          setState(() {
            _selectedOccupationId = parsedId;
            _occupationSelectionError = null;
            final nextRule = _professionalRule;

            if (!nextRule.requiresCuim) {
              _cuimController.clear();
            }
            if (!nextRule.requiresCodParafa) {
              _codParafaController.clear();
            }
            if (!nextRule.requiresRegistrationCode) {
              _registrationCodeController.clear();
            }
            if (!nextRule.requiresSectie) {
              _sectiaController.clear();
            }

            if (previousRule.registrationCodeLabel != nextRule.registrationCodeLabel) {
              _registrationCodeController.clear();
            }
          });
        },
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
            _occupationDropdown(),
            if (_occupationSelectionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _occupationSelectionError!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.red.shade700),
                ),
              ),
            if (_professionalRule.requiresCuim)
              _textField(
                controller: _cuimController,
                label: 'CUIM',
                validator: (value) => _requiredValidator(value, label: 'CUIM'),
              ),
            if (_professionalRule.requiresRegistrationCode)
              _textField(
                controller: _registrationCodeController,
                label: _professionalRule.registrationCodeLabel,
                validator: (value) =>
                    _requiredValidator(value, label: _professionalRule.registrationCodeLabel),
              ),
            if (_professionalRule.requiresCodParafa)
              _textField(
                controller: _codParafaController,
                label: 'Cod Parafă',
                validator: (value) => _requiredValidator(value, label: 'Cod Parafă'),
              ),
            if (_professionalRule.requiresSectie)
              _textField(
                controller: _sectiaController,
                label: 'Secție',
                validator: (value) => _requiredValidator(value, label: 'Secție'),
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
