import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../utils/validators.dart' as validators;

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
    this.requiresTitluUniversitar = false,
    this.registrationCodeLabel = 'Cod înregistrare',
  });

  final bool requiresCuim;
  final bool requiresCodParafa;
  final bool requiresRegistrationCode;
  final bool requiresSecondarySpecialization;
  final bool requiresTitluUniversitar;
  final String registrationCodeLabel;
}

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
  final _professionalCodeController = TextEditingController();
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

  static const List<String> _defaultOccupationNames = [
    'Medic',
    'Farmacist',
    'Asistent',
    'Medic Veterinar',
    'Student',
    'Medic Rezident',
    'Pensionar',
    'Psiholog',
    'Alta ocupatie',
    'Nutritionist-Dietetician',
    'Stomatolog',
  ];

  // Titluri universitare (must match backend ACADEMIC_TITLES)
  final List<String> _titluriUniversitare = [
    'Fără titlu universitar',
    'Asistent universitar',
    'Preparator universitar',
    'Șef de lucrări',
    'Conferențiar',
    'Profesor universitar',
    'Altul',
  ];

  String? _selectedTitluUniversitar;
  static const List<String> _defaultSpecializationNames = [
    'Alergologie',
    'Anatomie patologica',
    'Anestezie si terapie intensiva',
    'Asistent de farmacie',
    'Asistent medical',
    'Balneofizioterapie',
    'Boli infectioase',
    'Cardiologie',
    'Chirurgie cardiovasculara',
    'Chirurgie generala',
    'Chirurgie pediatrica',
    'Chirurgie maxilofaciala',
    'Chirurgie plastica',
    'Chirurgie toracica',
    'Chirurgie vasculara',
    'Dermato-venerologie',
    'Diabetologie/Nutritie si Boli Metabolice',
    'Ecografie',
    'Endocrinologie',
    'Epidemiologie',
    'Expertiza medicala',
    'Farmacie',
    'Farmacologie Clinica',
    'Fiziokinetoterapie/Recuperare medicala',
    'Gastroenterologie',
    'Genetica medicala',
    'Geriatrie si gerontologie',
    'Hematologie',
    'Homeopatie',
    'Igiena si sanatate publica',
    'Imunologie clinica',
    'Medicina de familie',
    'Medicina de intreprindere',
    'Medicina de laborator',
    'Medicina de urgenta',
    'Medicina fizica si de reabilitare',
    'Medicina generala',
    'Medicina interna',
    'Medicina legala',
    'Medicina muncii',
    'Medicina nucleara',
    'Medicina scolara',
    'Medicina sportiva',
    'Medicina veterinara',
    'Nefrologie',
    'Neonatologie',
    'Neurochirurgie',
    'Neurologie',
    'Neurologie pediatrica',
    'Obstetrica-Ginecologie',
    'Oftalmologie',
    'Oncologie',
    'ORL',
    'Ortopedie pediatrica',
    'Ortopedie si traumatologie',
    'Pediatrie',
    'Planificare Familiala',
    'Pneumologie',
    'Psihiatrie',
    'Psihiatrie pediatrica',
    'Psihologie medicala',
    'Radiologie si imagistica medicala',
    'Radioterapie',
    'Reumatologie',
    'Sanatate publica',
    'Stomatologie',
    'Urologie',
  ];

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

    if (occupationName.isEmpty) return const _ProfessionalRule();

    // Medic (excluding veterinari): CUIM, Cod parafă, Specializare secundară, Titlu Universitar
    if (occupationName.contains('medic') && !occupationName.contains('veterinar')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresCodParafa: true,
        requiresSecondarySpecialization: true,
        requiresTitluUniversitar: true,
      );
    }

    // Medic rezident: Specializare secundară, CUIM
    if (occupationName.contains('medic rezident') || occupationName.contains('rezident')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresSecondarySpecialization: true,
      );
    }

    // Pensionar: Specializare secundară + Titlu Universitar
    if (occupationName.contains('pensionar')) {
      return const _ProfessionalRule(
        requiresSecondarySpecialization: true,
        requiresTitluUniversitar: true,
      );
    }

    // Medic veterinar: registration code (CMV) + Titlu Universitar
    if (occupationName.contains('medic veterinar') || occupationName.contains('veterinar')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        requiresTitluUniversitar: true,
        registrationCodeLabel: 'Nr. carte identitate CMV',
      );
    }

    // Farmacist: Titlu Universitar
    if (occupationName.contains('farmacist')) {
      return const _ProfessionalRule(requiresTitluUniversitar: true);
    }

    // Default: no extra requirements
    return const _ProfessionalRule();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnpController.dispose();
    _phoneController.dispose();
    _cityIdController.dispose();
    _occupationIdController.dispose();
    _specializationIdController.dispose();
    _cuimController.dispose();
    _codParafaController.dispose();
    _professionalCodeController.dispose();
    // titlu universitar now uses dropdown selection
    _secondarySpecializationController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });

    try {
      final counties = <_OptionItem>[];
      final cities = <_OptionItem>[];
      final occupations = List<_OptionItem>.generate(
        _defaultOccupationNames.length,
        (i) => _OptionItem(id: 1000 + i, name: _defaultOccupationNames[i]),
      );
      List<_OptionItem> professionalGrades = [];
      // try fetching professional grades from backend; fallback to local list
      try {
        final resp = await http.get(Uri.parse(_professionalGradesUrl));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = jsonDecode(resp.body);
          if (data is List) {
            if (data.isNotEmpty && data.first is Map && data.first.containsKey('id') && data.first.containsKey('name')) {
              professionalGrades = (data as List).map((e) => _OptionItem(id: e['id'] as int, name: e['name'] as String)).toList();
            } else if (data.isNotEmpty && data.first is String) {
              professionalGrades = (data as List).asMap().entries.map((entry) => _OptionItem(id: 3000 + entry.key, name: entry.value as String)).toList();
            }
          }
        }
      } catch (_) {
        // ignore and fallback below
      }

      if (professionalGrades.isEmpty) {
        final fallback = [
          'Asistent de Farmacie',
          'Asistent Medical',
          'Asistent Veterinar',
          'Biolog',
          'Cercetător Științific',
          'Conferențiar Universitar',
          'Director',
          'Director Adjunct',
          'Director General',
          'Director Medical',
          'Doctor in Medicina',
          'Doctor in stiinte medicale',
          'Farmacist',
          'Farmacist Diriginte',
          'Farmacist pensionar',
          'Farmacist Primar',
          'Farmacist Sef',
          'Farmacist Specialist',
          'Farmacolog',
          'Grad profesional',
          'Inspector',
          'Medic Pensionar',
          'Medic Primar',
          'Medic Rezident',
          'Medic Specialist',
          'Medic Stagiar',
          'Medic veterinar',
          'Sef Sectie',
          'Sef Clinica',
          'Sef Depozit',
          'Sef Laborator',
          'Sef Lucrari',
          'Sef Policlinica',
        ];
        professionalGrades = fallback.asMap().entries.map((entry) => _OptionItem(id: 3000 + entry.key, name: entry.value)).toList();
      }

      try {
        final csv = await rootBundle.loadString('assets/locations.csv');
        final countyMap = <String, int>{};
        var countyIdSeed = 5000;
        var cityIdSeed = 6000;
        final lines = csv.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        for (var index = 1; index < lines.length; index++) {
          final row = lines[index];
          final commaIndex = row.indexOf(',');
          if (commaIndex <= 0 || commaIndex >= row.length - 1) continue;
          final countyName = row.substring(0, commaIndex).trim();
          final cityName = row.substring(commaIndex + 1).trim();
          if (countyName.isEmpty || cityName.isEmpty) continue;
          final countyId = countyMap.putIfAbsent(countyName, () => countyIdSeed++);
          if (!counties.any((county) => county.name == countyName)) {
            counties.add(_OptionItem(id: countyId, name: countyName));
          }
          cities.add(_OptionItem(id: cityIdSeed++, name: cityName, countyId: countyId));
        }
      } catch (_) {
        // If the asset is missing for any reason, keep empty lists and let the UI show hints.
      }

      if (!mounted) return;
      setState(() {
        _counties = counties;
        _cities = cities;
        _occupations = occupations;
        _professionalGrades = professionalGrades;
        _selectedCountyId = counties.isNotEmpty ? counties.first.id : null;
        _selectedCityId = _selectedCountyId == null ? null : _filteredCities.isNotEmpty ? _filteredCities.first.id : null;
        _selectedOccupationId = null;
        _selectedSpecializationId = null;
        _selectedSecondarySpecializationId = null;
        _selectedProfessionalGradeId = professionalGrades.isNotEmpty ? professionalGrades.first.id : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _counties = const [];
        _cities = const [];
        _occupations = List<_OptionItem>.generate(
          _defaultOccupationNames.length,
          (i) => _OptionItem(id: 1000 + i, name: _defaultOccupationNames[i]),
        );
        _specializations = List<_OptionItem>.generate(
          _defaultSpecializationNames.length,
          (i) => _OptionItem(id: 2000 + i, name: _defaultSpecializationNames[i]),
        );
        _professionalGrades = const [];
        _selectedCountyId = null;
        _selectedCityId = null;
        _selectedOccupationId = null;
        _selectedSpecializationId = null;
        _selectedSecondarySpecializationId = null;
        _selectedProfessionalGradeId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Future<void> _loadSpecializationsForOccupation(int? occupationId) async {
    final items = List<_OptionItem>.generate(
      _defaultSpecializationNames.length,
      (i) => _OptionItem(id: 2000 + i, name: _defaultSpecializationNames[i]),
    );

    if (!mounted) return;
    setState(() {
      _specializations = items;
      _selectedSpecializationId = null;
      _selectedSecondarySpecializationId = null;
    });
  }

  String? _requiredValidator(String? value, {String label = 'Câmp'}) {
    return validators.requiredValidator(value, label: label);
  }

  String? _emailValidator(String? value) {
    return validators.emailValidator(value);
  }

  String? _passwordValidator(String? value) {
    return validators.passwordValidator(value);
  }

  String? _confirmPasswordValidator(String? value) {
    return validators.confirmPasswordValidator(value, _passwordController.text);
  }


  String? _cnpValidator(String? value) {
    return validators.cnpValidator(value);
  }

  String? _cuimValidator(String? value) {
    return validators.cuimValidator(value);
  }

  String? _codParafaValidator(String? value) {
    return validators.codParafaValidator(value);
  }

  String? _phoneValidator(String? value) {
    return validators.phoneValidator(value);
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
        final hasTitluUniversitar = !rule.requiresTitluUniversitar || (_selectedTitluUniversitar != null && _selectedTitluUniversitar!.trim().isNotEmpty);
        final hasCuim = !rule.requiresCuim || _cuimValidator(_cuimController.text) == null;
        final hasParafa = !rule.requiresCodParafa || _codParafaValidator(_codParafaController.text) == null;
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
          hasTitluUniversitar &&
            hasCuim &&
            hasParafa &&
            hasRegCode &&
            hasSecondary;
      default:
        return false;
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
      'titlu_universitar': rule.requiresTitluUniversitar ? _selectedTitluUniversitar : null,
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
    bool isPasswordField = false,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: isPasswordField ? !_showPassword : obscure,
        validator: validator,
        decoration: _fieldDecoration(label).copyWith(
          hintText: hintText,
          helperText: helperText,
              counterText: '',
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 13,
              helperText: '13 cifre',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PulseTheme.border),
                    ),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _phonePrefix,
                        isDense: true,
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                      maxLength: 20,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(height: 1.0),
                      onChanged: (v) {
                        final formatted = _formatLocalPhoneDigits(v);
                        if (formatted != v) {
                          _phoneController.text = formatted;
                          _phoneController.selection = TextSelection.fromPosition(TextPosition(offset: _phoneController.text.length));
                        }
                      },
                      decoration: _fieldDecoration('Telefon').copyWith(counterText: ''),
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
            const SizedBox(height: 12),
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
                validator: (value) => _cuimValidator(value),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                helperText: 'Numai cifre, recomandat 8 cifre',
              ),
            if (rule.requiresCodParafa)
              _textField(
                controller: _codParafaController,
                label: 'Cod parafă',
                validator: (value) => _codParafaValidator(value),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))],
                maxLength: 12,
                helperText: 'Litere, cifre sau -/_ (3-12 caractere)',
              ),
            if (rule.requiresTitluUniversitar)
              DropdownButtonFormField<String>(
                value: _selectedTitluUniversitar,
                decoration: _fieldDecoration('Titlu universitar'),
                items: _titluriUniversitare
                    .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedTitluUniversitar = value),
                validator: (value) => rule.requiresTitluUniversitar ? _requiredValidator(value, label: 'Titlu universitar') : null,
              ),
            if (rule.requiresRegistrationCode)
              _textField(
                controller: _professionalCodeController,
                label: rule.registrationCodeLabel,
                validator: (value) => _requiredValidator(value, label: rule.registrationCodeLabel),
              ),
            _dropdownField(
              label: 'Grad profesional',
              value: _selectedProfessionalGradeId,
              options: _professionalGrades,
              onChanged: (value) {
                setState(() {
                  _selectedProfessionalGradeId = value;
                });
              },
              emptyHint: 'Nu există grade profesionale disponibile.',
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
