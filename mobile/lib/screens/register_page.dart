import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/pulse_theme.dart';

class _OptionItem {
  const _OptionItem({required this.id, required this.name, this.countyId});

  final int id;
  final String name;
  final int? countyId;
}

class _ProfessionalRule {
  const _ProfessionalRule({
    this.requiresCuim = false,
    this.requiresCodParafa = false,
    this.requiresRegistrationCode = false,
    this.requiresSecondarySpecialization = false,
    this.registrationCodeLabel = 'Cod înregistrare',
  });

  final bool requiresCuim;
  final bool requiresCodParafa;
  final bool requiresRegistrationCode;
  final bool requiresSecondarySpecialization;
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
  String _phonePrefix = '+40';

  final _manualCountyController = TextEditingController();
  final _manualCityController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;

  final _cuimController = TextEditingController();
  final _codParafaController = TextEditingController();
  final _professionalCodeController = TextEditingController();
  final _titluUniversitarController = TextEditingController();
  final _secondarySpecializationController = TextEditingController();

  bool _acordEmail = false;
  bool _acordSms = false;
  bool _isSubmitting = false;
  bool _isLoadingOptions = false;
  int _currentStep = 0;

  List<_OptionItem> _counties = const [];
  List<_OptionItem> _cities = const [];
  List<_OptionItem> _occupations = const [];
  List<_OptionItem> _specializations = const [];
  List<_OptionItem> _professionalGrades = const [];

  int? _selectedCountyId;
  int? _selectedCityId;
  int? _selectedOccupationId;
  int? _selectedSpecializationId;
  int? _selectedSecondarySpecializationId;
  int? _selectedProfessionalGradeId;

  // manual county/city entry removed per UX request

  static String get _registerUrl => '${ApiService.baseUrl}/api/register';
  static String get _countiesUrl => '${ApiService.baseUrl}/counties';
  static String get _citiesUrl => '${ApiService.baseUrl}/cities';
  static String get _occupationsUrl => '${ApiService.baseUrl}/occupations';
  static String get _specializationsUrl => '${ApiService.baseUrl}/specializations';
  static String get _professionalGradesUrl => '${ApiService.baseUrl}/professional-grades';

  List<_OptionItem> get _filteredCities {
    if (_selectedCountyId == null) {
      return const [];
    }
    return _cities.where((city) => city.countyId == _selectedCountyId).toList();
  }

  _OptionItem? get _selectedOccupation {
    if (_selectedOccupationId == null) return null;
    for (final item in _occupations) {
      if (item.id == _selectedOccupationId) {
        return item;
      }
    }
    return null;
  }

  _OptionItem? get _selectedSpecialization {
    if (_selectedSpecializationId == null) return null;
    for (final item in _specializations) {
      if (item.id == _selectedSpecializationId) {
        return item;
      }
    }
    return null;
  }

  _OptionItem? get _selectedSecondarySpecialization {
    if (_selectedSecondarySpecializationId == null) return null;
    for (final item in _specializations) {
      if (item.id == _selectedSecondarySpecializationId) {
        return item;
      }
    }
    return null;
  }

  _OptionItem? get _selectedProfessionalGrade {
    if (_selectedProfessionalGradeId == null) return null;
    for (final item in _professionalGrades) {
      if (item.id == _selectedProfessionalGradeId) {
        return item;
      }
    }
    return null;
  }

  int? _optionIdByName(List<_OptionItem> items, String name) {
    for (final item in items) {
      if (item.name.toLowerCase() == name.toLowerCase()) {
        return item.id;
      }
    }
    return null;
  }

  List<_OptionItem> get _filteredSpecializations {
    final occupationName = _selectedOccupation?.name.toLowerCase() ?? '';
    if (occupationName.contains('asistent')) {
      return _specializations
          .where((item) =>
              item.name == 'Asistent medical' ||
              item.name == 'Asistent de farmacie' ||
              item.name == 'Fiziokinetoterapie/Recuperare medicala')
          .toList();
    }
    if (occupationName.contains('farmacist')) {
      return _specializations
          .where((item) =>
              item.name == 'Farmacie' ||
              item.name == 'Farmacologie Clinica' ||
              item.name == 'Homeopatie')
          .toList();
    }
    if (occupationName.contains('veterinar')) {
      return _specializations.where((item) => item.name == 'Medicina veterinara').toList();
    }
    if (occupationName.contains('psiholog')) {
      return _specializations.where((item) => item.name == 'Psihologie medicala').toList();
    }
    if (occupationName.contains('nutritionist')) {
      return _specializations
          .where((item) =>
              item.name == 'Diabetologie/Nutritie si Boli Metabolice' ||
              item.name == 'Sanatate publica')
          .toList();
    }
    if (occupationName.contains('stomatolog')) {
      return _specializations
          .where((item) =>
              item.name == 'Stomatologie' || item.name == 'Chirurgie maxilofaciala')
          .toList();
    }
    return _specializations;
  }

  List<_OptionItem> get _filteredSecondarySpecializations {
    final selectedPrimaryId = _selectedSpecializationId;
    return _filteredSpecializations
        .where((item) => item.id != selectedPrimaryId)
        .toList();
  }

  _ProfessionalRule get _professionalRule {
    final occupationName = (_selectedOccupation?.name ?? '').toLowerCase();
    final specializationName = (_selectedSpecialization?.name ?? '').toLowerCase();

    final isDoctor = occupationName.contains('medic');
    final isVeterinary = occupationName.contains('veterinar');
    final isPharmacist = occupationName.contains('farmacist');
    final isPsychologist = occupationName.contains('psiholog');
    final isNurse = occupationName.contains('asistent');

    if (isDoctor && isVeterinary) {
      return const _ProfessionalRule(
        requiresCodParafa: true,
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod înregistrare CMV',
      );
    }

    if (isDoctor) {
      final requiresSecondary = specializationName.contains('chirurgie') ||
          specializationName.contains('rezident') ||
          specializationName.contains('ati') ||
          specializationName.contains('medicina interna');

      return _ProfessionalRule(
        requiresCuim: true,
        requiresCodParafa: true,
        requiresSecondarySpecialization: requiresSecondary,
      );
    }

    if (isNurse) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod înregistrare OAMGMAMR',
      );
    }

    if (isPharmacist) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod Colegiul Farmaciștilor',
      );
    }

    if (isPsychologist) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        registrationCodeLabel: 'Cod Colegiul Psihologilor',
      );
    }

    return const _ProfessionalRule(
      requiresRegistrationCode: true,
      registrationCodeLabel: 'Cod înregistrare profesională',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnpController.dispose();
    _phoneController.dispose();
    _manualCountyController.dispose();
    _manualCityController.dispose();
    _cuimController.dispose();
    _codParafaController.dispose();
    _professionalCodeController.dispose();
    _titluUniversitarController.dispose();
    _secondarySpecializationController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(_countiesUrl)),
        http.get(Uri.parse(_citiesUrl)),
        http.get(Uri.parse(_occupationsUrl)),
        http.get(Uri.parse(_professionalGradesUrl)),
      ]);

      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Nu s-au putut încărca opțiunile de formular (${response.statusCode}).');
        }
      }

      List<_OptionItem> parseList(String body, {bool hasCountyId = false}) {
        final decoded = jsonDecode(body);
        if (decoded is! List) return const [];
        final items = <_OptionItem>[];
        for (final raw in decoded) {
          if (raw is! Map<String, dynamic>) continue;
          final id = raw['id'];
          final name = raw['name'];
          final countyId = raw['county_id'];
          if (id is int && name is String && name.trim().isNotEmpty) {
            items.add(
              _OptionItem(
                id: id,
                name: name.trim(),
                countyId: hasCountyId && countyId is int ? countyId : null,
              ),
            );
          }
        }
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      }

      final counties = parseList(responses[0].body);
      final cities = parseList(responses[1].body, hasCountyId: true);
      final occupations = parseList(responses[2].body);
      final professionalGrades = parseList(responses[3].body);

      if (!mounted) return;
      setState(() {
        _counties = counties;
        _cities = cities;
        _occupations = occupations;
        _professionalGrades = professionalGrades;
        _selectedCountyId = counties.isNotEmpty ? counties.first.id : null;
        _selectedOccupationId = _optionIdByName(occupations, 'Medic') ??
            (occupations.isNotEmpty ? occupations.first.id : null);
        _selectedProfessionalGradeId = _optionIdByName(
              professionalGrades,
              'Fără titlu universitar',
            ) ??
            (professionalGrades.isNotEmpty ? professionalGrades.first.id : null);

        final citiesForCounty = _filteredCities;
        _selectedCityId = citiesForCounty.isNotEmpty ? citiesForCounty.first.id : null;
      });

      await _loadSpecializationsForOccupation(_selectedOccupationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea opțiunilor: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Future<void> _loadSpecializationsForOccupation(int? occupationId) async {
    try {
      final uri = occupationId == null
          ? Uri.parse(_specializationsUrl)
          : Uri.parse('$_specializationsUrl?occupation_id=$occupationId');
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Nu s-au putut încărca specializările (${response.statusCode}).');
      }

      final items = <_OptionItem>[];
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        for (final raw in decoded) {
          if (raw is! Map<String, dynamic>) continue;
          final id = raw['id'];
          final name = raw['name'];
          if (id is int && name is String && name.trim().isNotEmpty) {
            items.add(_OptionItem(id: id, name: name.trim()));
          }
        }
      }
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _specializations = items;
        _selectedSpecializationId = items.isNotEmpty ? items.first.id : null;
        final filteredSecondary = _filteredSecondarySpecializations;
        _selectedSecondarySpecializationId = filteredSecondary.isNotEmpty ? filteredSecondary.first.id : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea specializărilor: $e')),
      );
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
    if (value == null || value.trim().isEmpty) return 'Parola este obligatorie';
    if (value.trim().length < 8) return 'Parola trebuie să aibă cel puțin 8 caractere';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Rescrie parola';
    if (value.trim() != _passwordController.text.trim()) return 'Parolele nu coincid';
    return null;
  }


  String? _cnpValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'CNP este obligatoriu';
    final digits = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{13}$').hasMatch(digits)) return 'CNP-ul trebuie să conțină 13 cifre';
    return null;
  }

  String? _phoneValidator(String? value) {
    final required = _requiredValidator(value, label: 'Telefon');
    if (required != null) return required;
    final digitsOnly = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Numărul de telefon trebuie să conțină între 7 și 15 cifre';
    }
    return null;
  }

  String _formatLocalPhoneDigits(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final parts = <String>[];
    for (var i = 0; i < digits.length; i += 3) {
      parts.add(digits.substring(i, (i + 3).clamp(0, digits.length)));
    }
    return parts.join(' ');
  }

  bool _validateStep(int step) {
    setState(() {});
    switch (step) {
      case 0:
        return _emailValidator(_emailController.text) == null &&
            _passwordValidator(_passwordController.text) == null &&
            _confirmPasswordValidator(_confirmPasswordController.text) == null;
      case 1:
        final hasCounty = _selectedCountyId != null;
        final hasCity = _selectedCityId != null;

        return _requiredValidator(_firstNameController.text, label: 'Nume') == null &&
            _requiredValidator(_lastNameController.text, label: 'Prenume') == null &&
            _cnpValidator(_cnpController.text) == null &&
            _phoneValidator(_phoneController.text) == null &&
            hasCounty &&
            hasCity;
      case 2:
        final rule = _professionalRule;
        final hasOccupation = _selectedOccupationId != null;
        final hasSpecialization = _selectedSpecializationId != null;
        final hasTitle = _selectedProfessionalGradeId != null;
        final hasCuim = !rule.requiresCuim ||
            _requiredValidator(_cuimController.text, label: 'CUIM') == null;
        final hasParafa = !rule.requiresCodParafa ||
            _requiredValidator(_codParafaController.text, label: 'Cod parafă') == null;
        final hasRegCode = !rule.requiresRegistrationCode ||
            _requiredValidator(
                  _professionalCodeController.text,
                  label: rule.registrationCodeLabel,
                ) ==
                null;
        final hasSecondary = !rule.requiresSecondarySpecialization ||
            _selectedSecondarySpecializationId != null;

        return hasOccupation &&
            hasSpecialization &&
            hasTitle &&
            hasCuim &&
            hasParafa &&
            hasRegCode &&
            hasSecondary;
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

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final rule = _professionalRule;

    final payload = {
      'email': email,
      'firebase_uid': _generateFirebaseUid(email),
      'password': _passwordController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'cnp': _cnpController.text.trim(),
      'city_id': _selectedCityId,
      'county_id': _selectedCountyId,
      'occupation_id': _selectedOccupationId,
      'occupation_name': _selectedOccupation?.name,
      'specialization_id': _selectedSpecializationId,
      'specialization_name': _selectedSpecialization?.name,
      'specialization_secondary_name': _selectedSecondarySpecialization?.name,
      'professional_grade_id': _selectedProfessionalGradeId,
      'professional_grade_name': _selectedProfessionalGrade?.name,
      'cuim': rule.requiresCuim ? _cuimController.text.trim() : null,
      'cod_parafa': rule.requiresCodParafa ? _codParafaController.text.trim() : null,
      'professional_registration_code':
          rule.requiresRegistrationCode ? _professionalCodeController.text.trim() : null,
      'titlu_universitar': _selectedProfessionalGrade?.name,
      'acord_email': _acordEmail,
      'acord_sms': _acordSms,
      'phone': '$_phonePrefix${_phoneController.text.replaceAll(RegExp(r'\\s+'), '')}',
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
        await AuthStorage().saveUserName('${_firstNameController.text.trim()} ${_lastNameController.text.trim()}');
        //ScaffoldMessenger.of(context).showSnackBar(
        //  SnackBar(content: Text('Cont creat cu succes. ID utilizator: $userId')),
        //);
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
    bool isPasswordField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: isPasswordField ? !_showPassword : obscure,
        validator: validator,
        decoration: _fieldDecoration(label).copyWith(
          hintText: hintText,
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Future<int?> _showSelectionDialog(List<_OptionItem> options, String title, {int? selectedId}) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: options.map((opt) {
            final selected = opt.id == selectedId;
            return SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(opt.id),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(opt.name)),
                  if (selected) const Icon(Icons.check, color: Colors.green),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _selectField({
    required String label,
    required String? selectedName,
    required VoidCallback onTap,
    String? emptyHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _fieldDecoration(label),
          child: Row(
            children: [
              Expanded(
                child: Text(selectedName ?? (emptyHint ?? 'Selectați $label')),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  // Prefill removed per UX


  Widget _dropdownField({
    required String label,
    required int? value,
    required List<_OptionItem> options,
    required ValueChanged<int?> onChanged,
    String? emptyHint,
  }) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          emptyHint ?? 'Nu există opțiuni disponibile pentru $label.',
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: _fieldDecoration(label),
        items: options
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  List<Step> _buildSteps() {
    final rule = _professionalRule;

    return [
      Step(
        title: const Text('Cont'),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            const SizedBox(height: 8),
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
              isPasswordField: true,
            ),
            _textField(
              controller: _confirmPasswordController,
              label: 'Rescrie parola',
              validator: _confirmPasswordValidator,
              isPasswordField: true,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PulseTheme.border),
                    ),
                    child: DropdownButton<String>(
                      value: _phonePrefix,
                      underline: const SizedBox.shrink(),
                      items: ['+40', '+373', '+1']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _phonePrefix = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                      onChanged: (v) {
                        final formatted = _formatLocalPhoneDigits(v);
                        if (formatted != v) {
                          _phoneController.text = formatted;
                          _phoneController.selection = TextSelection.fromPosition(TextPosition(offset: _phoneController.text.length));
                        }
                      },
                      decoration: _fieldDecoration('Telefon'),
                    ),
                  ),
                ],
              ),
            ),
            _dropdownField(
              label: 'Județ',
              value: _selectedCountyId,
              options: _counties,
              onChanged: (value) {
                setState(() {
                  _selectedCountyId = value;
                  final citiesForCounty = _filteredCities;
                  _selectedCityId = citiesForCounty.isNotEmpty ? citiesForCounty.first.id : null;
                });
              },
              emptyHint: 'Nu există județe în baza de date.',
            ),
            _dropdownField(
              label: 'Oraș',
              value: _selectedCityId,
              options: _filteredCities,
              onChanged: (value) {
                setState(() {
                  _selectedCityId = value;
                });
              },
              emptyHint: 'Nu există orașe pentru județul selectat.',
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
            _selectField(
              label: 'Ocupație',
              selectedName: _selectedOccupation?.name,
              emptyHint: 'Selectați ocupație',
              onTap: () async {
                final selected = await _showSelectionDialog(_occupations, 'Alege ocupație', selectedId: _selectedOccupationId);
                if (selected != null) {
                  setState(() {
                    _selectedOccupationId = selected;
                    _selectedSpecializationId = null;
                    _selectedSecondarySpecializationId = null;
                  });
                  _loadSpecializationsForOccupation(selected);
                }
              },
            ),
            const SizedBox(height: 12),
            _selectField(
              label: 'Specializare',
              selectedName: _selectedSpecialization?.name,
              emptyHint: 'Selectați specializare',
              onTap: () async {
                final selected = await _showSelectionDialog(_filteredSpecializations, 'Alege specializare', selectedId: _selectedSpecializationId);
                if (selected != null) {
                  setState(() {
                    _selectedSpecializationId = selected;
                    if (_selectedSecondarySpecializationId == selected) {
                      _selectedSecondarySpecializationId = null;
                    }
                  });
                }
              },
            ),
            if (rule.requiresSecondarySpecialization)
              _dropdownField(
                label: 'Specializare secundară',
                value: _selectedSecondarySpecializationId,
                options: _filteredSecondarySpecializations,
                onChanged: (value) {
                  setState(() {
                    _selectedSecondarySpecializationId = value;
                  });
                },
                emptyHint: 'Nu există specializări secundare disponibile.',
              ),
            if (rule.requiresCuim)
              _textField(
                controller: _cuimController,
                label: 'CUIM',
                validator: (value) => _requiredValidator(value, label: 'CUIM'),
              ),
            if (rule.requiresCodParafa)
              _textField(
                controller: _codParafaController,
                label: 'Cod parafă',
                validator: (value) => _requiredValidator(value, label: 'Cod parafă'),
              ),
            if (rule.requiresRegistrationCode)
              _textField(
                controller: _professionalCodeController,
                label: rule.registrationCodeLabel,
                validator: (value) => _requiredValidator(value, label: rule.registrationCodeLabel),
              ),
            _dropdownField(
              label: 'Titlu universitar',
              value: _selectedProfessionalGradeId,
              options: _professionalGrades,
              onChanged: (value) {
                setState(() {
                  _selectedProfessionalGradeId = value;
                });
              },
              emptyHint: 'Nu există titluri universitare disponibile.',
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
        child: _isLoadingOptions
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
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
    );
  }
}
