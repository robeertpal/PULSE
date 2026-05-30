import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/validators.dart' as validators;
import '../widgets/auth_shell.dart';
import 'interests_selection_screen.dart';

class _OptionItem {
  const _OptionItem({
    required this.id,
    required this.name,
    this.countyId,
    this.cityId,
  });

  final int id;
  final String name;
  final int? countyId;
  final int? cityId;

  factory _OptionItem.fromJson(Map<String, dynamic> json) {
    return _OptionItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      countyId: json['county_id'] is num
          ? (json['county_id'] as num).toInt()
          : null,
      cityId: json['city_id'] is num ? (json['city_id'] as num).toInt() : null,
    );
  }
}

class _ProfessionalRule {
  const _ProfessionalRule({
    this.requiresCuim = false,
    this.requiresCodParafa = false,
    this.requiresRegistrationCode = false,
    this.requiresSecondarySpecialization = false,
    this.requiresTitluUniversitar = false,
    this.registrationCodeLabel = 'Cod profesional',
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
  static const _backIcon = 'assets/icons/arrow.backward.svg';
  static const _emailIcon = 'assets/icons/envelope.fill.svg';
  static const _passwordIcon = 'assets/icons/key.fill.svg';
  static const _confirmIcon = _passwordIcon;
  static const _personIcon = 'assets/icons/person.text.rectangle.fill.svg';
  static const _numbersIcon = 'assets/icons/numbers.rectangle.fill.svg';
  static const _phoneIcon = 'assets/icons/phone.fill.svg';
  static const _homeIcon = 'assets/icons/house.svg';
  static const _countyIcon = 'assets/icons/globe.svg';
  static const _cityIcon = 'assets/icons/location.fill.svg';
  static const _occupationIcon = 'assets/icons/case.fill.svg';
  static const _specializationIcon = 'assets/icons/cross.case.fill.svg';
  static const _secondarySpecializationIcon =
      'assets/icons/cross.case.circle.svg';
  static const _gradeIcon = 'assets/icons/checkmark.seal.fill.svg';
  static const _institutionIcon = 'assets/icons/building.svg';
  static const _professionalCodeIcon =
      'assets/icons/numbers.rectangle.fill.svg';
  static const _signatureIcon = 'assets/icons/signature.svg';
  static const _titleIcon = 'assets/icons/graduation.svg';
  static const _dropdownIcon = 'assets/icons/arrow.right.svg';
  static const _eyeIcon = 'assets/icons/eye.fill.svg';
  static const _eyeSlashIcon = 'assets/icons/eye.slash.fill.svg';

  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cuimController = TextEditingController();
  final _codParafaController = TextEditingController();
  final _professionalCodeController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acordEmail = false;
  bool _acordSms = false;
  bool _gdprConsent = false;
  bool _isLoadingOptions = false;
  bool _isSubmitting = false;
  int _currentStep = 0;
  String _phonePrefix = '+40';
  String? _loadError;
  String? _selectedTitluUniversitar;

  List<_OptionItem> _counties = const [];
  List<_OptionItem> _cities = const [];
  List<_OptionItem> _occupations = const [];
  List<_OptionItem> _specializations = const [];
  List<_OptionItem> _professionalGrades = const [];
  List<_OptionItem> _institutions = const [];

  int? _selectedCountyId;
  int? _selectedCityId;
  int? _selectedOccupationId;
  int? _selectedSpecializationId;
  int? _selectedSecondarySpecializationId;
  int? _selectedProfessionalGradeId;
  int? _selectedInstitutionId;

  static const List<String> _titluriUniversitare = [
    'Fără titlu universitar',
    'Asistent universitar',
    'Preparator universitar',
    'Șef de lucrări',
    'Conferențiar',
    'Profesor universitar',
    'Altul',
  ];

  static String get _countiesUrl => '${ApiService.baseUrl}/counties';
  static String get _citiesUrl => '${ApiService.baseUrl}/cities';
  static String get _occupationsUrl => '${ApiService.baseUrl}/occupations';
  static String get _specializationsUrl =>
      '${ApiService.baseUrl}/specializations';
  static String get _professionalGradesUrl =>
      '${ApiService.baseUrl}/professional-grades';
  static String get _institutionsUrl => '${ApiService.baseUrl}/institutions';

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
    _addressController.dispose();
    _cuimController.dispose();
    _codParafaController.dispose();
    _professionalCodeController.dispose();
    super.dispose();
  }

  List<_OptionItem> get _filteredCities {
    if (_selectedCountyId == null) return const [];
    return _cities.where((city) => city.countyId == _selectedCountyId).toList();
  }

  List<_OptionItem> get _filteredInstitutions {
    if (_selectedCityId == null) return _institutions;
    final cityItems = _institutions
        .where((item) => item.cityId == _selectedCityId)
        .toList();
    return cityItems.isEmpty ? _institutions : cityItems;
  }

  _OptionItem? get _selectedOccupation =>
      _optionById(_occupations, _selectedOccupationId);
  _OptionItem? get _selectedSecondarySpecialization =>
      _optionById(_specializations, _selectedSecondarySpecializationId);

  _ProfessionalRule get _selectedOccupationRule {
    final occupationName = (_selectedOccupation?.name ?? '').toLowerCase();

    if (occupationName.isEmpty) return const _ProfessionalRule();

    if (occupationName.contains('rezident')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresSecondarySpecialization: true,
      );
    }

    if (occupationName.contains('medic') &&
        !occupationName.contains('veterinar')) {
      return const _ProfessionalRule(
        requiresCuim: true,
        requiresCodParafa: true,
        requiresSecondarySpecialization: true,
        requiresTitluUniversitar: true,
      );
    }

    if (occupationName.contains('veterinar')) {
      return const _ProfessionalRule(
        requiresRegistrationCode: true,
        requiresTitluUniversitar: true,
        registrationCodeLabel: 'Nr. carte identitate CMV',
      );
    }

    if (occupationName.contains('farmacist')) {
      return const _ProfessionalRule(requiresTitluUniversitar: true);
    }

    if (occupationName.contains('pensionar')) {
      return const _ProfessionalRule(
        requiresSecondarySpecialization: true,
        requiresTitluUniversitar: true,
      );
    }

    return const _ProfessionalRule();
  }

  List<_OptionItem> get _filteredSpecializations {
    final occupationName = (_selectedOccupation?.name ?? '').toLowerCase();
    if (occupationName.contains('asistent')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Asistent medical' ||
                item.name == 'Asistent de farmacie' ||
                item.name == 'Fiziokinetoterapie/Recuperare medicala',
          )
          .toList();
    }
    if (occupationName.contains('farmacist')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Farmacie' ||
                item.name == 'Farmacologie Clinica' ||
                item.name == 'Homeopatie',
          )
          .toList();
    }
    if (occupationName.contains('veterinar')) {
      return _specializations
          .where((item) => item.name == 'Medicina veterinara')
          .toList();
    }
    if (occupationName.contains('psiholog')) {
      return _specializations
          .where((item) => item.name == 'Psihologie medicala')
          .toList();
    }
    if (occupationName.contains('nutritionist')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Diabetologie/Nutritie si Boli Metabolice' ||
                item.name == 'Sanatate publica',
          )
          .toList();
    }
    if (occupationName.contains('stomatolog')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Stomatologie' ||
                item.name == 'Chirurgie maxilofaciala',
          )
          .toList();
    }
    return _specializations;
  }

  List<_OptionItem> get _filteredSecondarySpecializations {
    return _filteredSpecializations
        .where((item) => item.id != _selectedSpecializationId)
        .toList();
  }

  _OptionItem? _optionById(List<_OptionItem> options, int? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  Future<List<_OptionItem>> _fetchOptions(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Nu am putut încărca nomenclatorul.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_OptionItem.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _fetchOptions(_countiesUrl),
        _fetchOptions(_citiesUrl),
        _fetchOptions(_occupationsUrl),
        _fetchOptions(_specializationsUrl),
        _fetchOptions(_professionalGradesUrl),
        _fetchOptions(_institutionsUrl),
      ]);

      if (!mounted) return;
      setState(() {
        _counties = results[0];
        _cities = results[1];
        _occupations = results[2];
        _specializations = results[3];
        _professionalGrades = results[4];
        _institutions = results[5];

        _selectedCountyId = null;
        _selectedCityId = null;
        _selectedOccupationId = _occupations.isNotEmpty
            ? _occupations.first.id
            : null;
        _selectedSpecializationId = _filteredSpecializations.isNotEmpty
            ? _filteredSpecializations.first.id
            : null;
        _selectedProfessionalGradeId = _professionalGrades.isNotEmpty
            ? _professionalGrades.first.id
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  String? _requiredValidator(String? value, {String label = 'Câmp'}) {
    return validators.requiredValidator(value, label: label);
  }

  String? _emailValidator(String? value) => validators.emailValidator(value);

  String? _passwordValidator(String? value) =>
      validators.passwordValidator(value);

  String? _confirmPasswordValidator(String? value) {
    return validators.confirmPasswordValidator(value, _passwordController.text);
  }

  String? _cnpValidator(String? value) => validators.cnpValidator(value);

  String? _phoneValidator(String? value) => validators.phoneValidator(value);

  String? _cuimValidator(String? value) => validators.cuimValidator(value);

  String? _codParafaValidator(String? value) =>
      validators.codParafaValidator(value);

  String? _numberValidator(int? value, {required String label}) {
    if (value == null) return '$label este obligatoriu';
    return null;
  }

  String _fullPhoneNumber() {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return '$_phonePrefix$digits';
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _emailValidator(_emailController.text) == null &&
            _passwordValidator(_passwordController.text) == null &&
            _confirmPasswordValidator(_confirmPasswordController.text) == null;
      case 1:
        return _requiredValidator(_firstNameController.text, label: 'Nume') ==
                null &&
            _requiredValidator(_lastNameController.text, label: 'Prenume') ==
                null &&
            _cnpValidator(_cnpController.text) == null &&
            _phoneValidator(_phoneController.text) == null &&
            _requiredValidator(
                  _addressController.text,
                  label: 'Adresă corespondență',
                ) ==
                null &&
            _numberValidator(_selectedCountyId, label: 'Județ') == null &&
            _numberValidator(_selectedCityId, label: 'Oraș') == null;
      case 2:
        final rule = _selectedOccupationRule;
        return _numberValidator(_selectedOccupationId, label: 'Ocupație') ==
                null &&
            _numberValidator(
                  _selectedSpecializationId,
                  label: 'Specializare',
                ) ==
                null &&
            _numberValidator(
                  _selectedProfessionalGradeId,
                  label: 'Grad profesional',
                ) ==
                null &&
            (!rule.requiresSecondarySpecialization ||
                _numberValidator(
                  _selectedSecondarySpecializationId,
                  label: 'Specializare secundară',
                ) ==
                    null) &&
            (!rule.requiresCuim ||
                _cuimValidator(_cuimController.text) == null) &&
            (!rule.requiresCodParafa ||
                _codParafaValidator(_codParafaController.text) == null) &&
            (!rule.requiresRegistrationCode ||
                _requiredValidator(
                  _professionalCodeController.text,
                      label: rule.registrationCodeLabel,
                    ) ==
                    null) &&
            (!rule.requiresTitluUniversitar ||
                _requiredValidator(
                      _selectedTitluUniversitar,
                      label: 'Titlu universitar',
                    ) ==
                    null) &&
            _gdprConsent;
      default:
        return false;
    }
  }

  Future<void> _continueStep() async {
    if (_currentStep < 2) {
      if (!_validateStep(_currentStep)) {
        _formKey.currentState?.validate();
        setState(() {});
        return;
      }
      setState(() => _currentStep += 1);
      return;
    }
    await _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_validateStep(2)) {
      setState(() {});
      return;
    }

    final rule = _selectedOccupationRule;
    final email = _emailController.text.trim();
    final payload = <String, dynamic>{
      'email': email,
      'firebase_uid': 'local_${email.toLowerCase().hashCode.abs()}',
      'password': _passwordController.text,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'cnp': _cnpController.text.trim(),
      'phone': _fullPhoneNumber(),
      'correspondence_address': _addressController.text.trim(),
      'county_id': _selectedCountyId,
      'city_id': _selectedCityId,
      'occupation_id': _selectedOccupationId,
      'specialization_id': _selectedSpecializationId,
      'specialization_secondary_name': _selectedSecondarySpecialization?.name,
      'professional_grade_id': _selectedProfessionalGradeId,
      'institution_id': _selectedInstitutionId,
      'cuim': rule.requiresCuim ? _cuimController.text.trim() : null,
      'cod_parafa': rule.requiresCodParafa
          ? _codParafaController.text.trim()
          : null,
      'professional_registration_code': rule.requiresRegistrationCode
          ? _professionalCodeController.text.trim()
          : null,
      'titlu_universitar': rule.requiresTitluUniversitar
          ? _selectedTitluUniversitar
          : null,
      'acord_email': _acordEmail,
      'acord_sms': _acordSms,
      'gdpr_consent': _gdprConsent,
    };

    payload.removeWhere((_, value) => value == null);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final data = await _apiService.register(payload);
      await AuthStorage().saveUserName(
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      );
      if (!mounted) return;
      final verificationRequired = data['email_verification_required'] == true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InterestsSelectionScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            verificationRequired: verificationRequired,
          ),
        ),
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

  InputDecoration _fieldDecoration(
    String label, {
    String? hintText,
    String? iconAsset,
  }) {
    return InputDecoration(
      hintText: hintText ?? label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: iconAsset == null ? null : _decorativeIconSlot(iconAsset),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 44,
        maxWidth: 44,
        minHeight: 58,
      ),
      filled: true,
      fillColor: AuthShell.fieldFill,
      isDense: false,
      hintStyle: const TextStyle(
        color: AuthShell.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      contentPadding: const EdgeInsets.fromLTRB(12, 19, 12, 19),
      errorMaxLines: 3,
      helperMaxLines: 2,
      errorStyle: const TextStyle(height: 1.25),
      helperStyle: const TextStyle(height: 1.25),
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

  Widget _svgIcon(
    String asset, {
    double size = 19,
    Color color = AuthShell.pulsePurple,
  }) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _decorativeIconSlot(String asset) {
    return SizedBox(
      width: 44,
      height: 58,
      child: Center(child: _svgIcon(asset)),
    );
  }

  Widget _passwordVisibilityButton({
    required bool isPasswordVisible,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 48,
      height: 58,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 58),
        icon: Opacity(
          opacity: 0.62,
          child: _svgIcon(
            isPasswordVisible ? _eyeSlashIcon : _eyeIcon,
            size: 20,
            color: AuthShell.pulsePurple,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _dropdownArrowIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: RotatedBox(
        quarterTurns: 1,
        child: _svgIcon(_dropdownIcon, size: 18),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showPasswordToggle = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? helperText,
    String? hintText,
    String? iconAsset,
    int maxLines = 1,
    double bottomPadding = 12,
    bool reserveHelperSpace = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLines: maxLines,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: showPasswordToggle ? !isPasswordVisible : obscureText,
        style: const TextStyle(
          color: AuthShell.textPrimary,
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
        validator: validator,
        decoration:
            _fieldDecoration(
              label,
              hintText: hintText,
              iconAsset: iconAsset,
            ).copyWith(
              helperText: helperText ?? (reserveHelperSpace ? ' ' : null),
              counterText: '',
              suffixIcon: showPasswordToggle
                  ? _passwordVisibilityButton(
                      isPasswordVisible: isPasswordVisible,
                      onPressed: onTogglePassword,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                maxWidth: 48,
                minHeight: 58,
              ),
            ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required int? value,
    required List<_OptionItem> options,
    required ValueChanged<int?> onChanged,
    bool required = true,
    bool enabled = true,
    String? emptyHint,
    String? hintText,
    String? helperText,
    String? iconAsset,
  }) {
    if (!enabled) {
      return _disabledDropdownField(
        label: label,
        hintText: hintText ?? label,
        helperText: helperText,
        iconAsset: iconAsset,
      );
    }

    if (options.isEmpty) {
      return _disabledDropdownField(
        label: label,
        hintText: emptyHint ?? 'Nu există opțiuni disponibile pentru $label.',
        iconAsset: iconAsset,
      );
    }

    final effectiveValue = options.any((item) => item.id == value)
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$effectiveValue-${options.length}'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: _dropdownArrowIcon(),
        hint: Text(
          hintText ?? label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AuthShell.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        decoration: _fieldDecoration(
          label,
          iconAsset: iconAsset,
        ).copyWith(helperText: helperText),
        items: options
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: required
            ? (value) => _numberValidator(value, label: label)
            : null,
      ),
    );
  }

  Widget _disabledDropdownField({
    required String label,
    required String hintText,
    String? helperText,
    String? iconAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('disabled-$label-$hintText'),
        initialValue: null,
        isExpanded: true,
        icon: _dropdownArrowIcon(),
        hint: Text(
          hintText,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AuthShell.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        decoration: _fieldDecoration(
          label,
          iconAsset: iconAsset,
        ).copyWith(helperText: helperText, enabled: false),
        items: const [],
        onChanged: null,
      ),
    );
  }

  Widget _phoneFieldsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: DropdownButtonFormField<String>(
              key: ValueKey('phone-prefix-$_phonePrefix'),
              initialValue: _phonePrefix,
              isExpanded: true,
              icon: _dropdownArrowIcon(),
              decoration: _fieldDecoration(
                'Prefix',
              ).copyWith(helperText: ' ', counterText: ''),
              items: ['+40', '+373', '+1']
                  .map(
                    (prefix) => DropdownMenuItem(
                      value: prefix,
                      child: Text(prefix, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _phonePrefix = value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _textField(
              controller: _phoneController,
              label: 'Telefon',
              validator: _phoneValidator,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              maxLength: 20,
              iconAsset: _phoneIcon,
              bottomPadding: 0,
              reserveHelperSpace: true,
            ),
          ),
        ],
      ),
    );
  }

  List<Step> _buildSteps() {
    final rule = _selectedOccupationRule;
    return [
      Step(
        title: const Text('Cont'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            _textField(
              controller: _emailController,
              label: 'Email',
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
              iconAsset: _emailIcon,
            ),
            _textField(
              controller: _passwordController,
              label: 'Parolă',
              validator: _passwordValidator,
              showPasswordToggle: true,
              isPasswordVisible: _showPassword,
              onTogglePassword: () =>
                  setState(() => _showPassword = !_showPassword),
              iconAsset: _passwordIcon,
            ),
            _textField(
              controller: _confirmPasswordController,
              label: 'Confirmă',
              validator: _confirmPasswordValidator,
              showPasswordToggle: true,
              isPasswordVisible: _showConfirmPassword,
              onTogglePassword: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              iconAsset: _confirmIcon,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Date personale'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            _textField(
              controller: _firstNameController,
              label: 'Nume',
              validator: (value) => _requiredValidator(value, label: 'Nume'),
              iconAsset: _personIcon,
            ),
            _textField(
              controller: _lastNameController,
              label: 'Prenume',
              validator: (value) => _requiredValidator(value, label: 'Prenume'),
              iconAsset: _personIcon,
            ),
            _textField(
              controller: _cnpController,
              label: 'CNP',
              validator: _cnpValidator,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 13,
              iconAsset: _numbersIcon,
            ),
            _phoneFieldsRow(),
            _textField(
              controller: _addressController,
              label: 'Adresă corespondență',
              validator: (value) =>
                  _requiredValidator(value, label: 'Adresă corespondență'),
              hintText: 'Stradă, număr, bloc, apartament',
              iconAsset: _homeIcon,
            ),
            _dropdownField(
              label: 'Județ',
              value: _selectedCountyId,
              options: _counties,
              onChanged: (value) {
                setState(() {
                  _selectedCountyId = value;
                  _selectedCityId = null;
                  _selectedInstitutionId = null;
                });
              },
              hintText: 'Alegeți județul',
              iconAsset: _countyIcon,
            ),
            _dropdownField(
              label: 'Oraș',
              value: _selectedCityId,
              options: _filteredCities,
              enabled: _selectedCountyId != null,
              onChanged: (value) {
                setState(() {
                  _selectedCityId = value;
                  _selectedInstitutionId = null;
                });
              },
              hintText: 'Alegeți orașul',
              emptyHint: _selectedCountyId == null
                  ? 'Alegeți județul mai întâi'
                  : 'Nu există orașe pentru județul selectat.',
              helperText: _selectedCountyId == null
                  ? 'Selectați județul pentru a vedea orașele.'
                  : null,
              iconAsset: _cityIcon,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Profesional'),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            _dropdownField(
              label: 'Ocupație',
              value: _selectedOccupationId,
              options: _occupations,
              onChanged: (value) {
                setState(() {
                  _selectedOccupationId = value;
                  _selectedSpecializationId =
                      _filteredSpecializations.isNotEmpty
                      ? _filteredSpecializations.first.id
                      : null;
                  _selectedSecondarySpecializationId = null;
                  _selectedTitluUniversitar = null;
                  _cuimController.clear();
                  _codParafaController.clear();
                  _professionalCodeController.clear();
                });
              },
              iconAsset: _occupationIcon,
            ),
            _dropdownField(
              label: 'Specializare',
              value: _selectedSpecializationId,
              options: _filteredSpecializations,
              onChanged: (value) {
                setState(() {
                  _selectedSpecializationId = value;
                  if (_selectedSecondarySpecializationId == value) {
                    _selectedSecondarySpecializationId = null;
                  }
                });
              },
              iconAsset: _specializationIcon,
            ),
            if (rule.requiresSecondarySpecialization)
              _dropdownField(
                label: 'Specializare secundară',
                value: _selectedSecondarySpecializationId,
                options: _filteredSecondarySpecializations,
                onChanged: (value) =>
                    setState(() => _selectedSecondarySpecializationId = value),
                iconAsset: _secondarySpecializationIcon,
              ),
            _dropdownField(
              label: 'Grad profesional',
              value: _selectedProfessionalGradeId,
              options: _professionalGrades,
              onChanged: (value) =>
                  setState(() => _selectedProfessionalGradeId = value),
              iconAsset: _gradeIcon,
            ),
            _dropdownField(
              label: 'Instituție',
              value: _selectedInstitutionId,
              options: _filteredInstitutions,
              required: false,
              onChanged: (value) =>
                  setState(() => _selectedInstitutionId = value),
              emptyHint: 'Instituția poate fi completată ulterior.',
              iconAsset: _institutionIcon,
            ),
            if (rule.requiresCuim)
              _textField(
                controller: _cuimController,
                label: 'CUIM',
                validator: _cuimValidator,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                iconAsset: _professionalCodeIcon,
              ),
            if (rule.requiresCodParafa)
              _textField(
                controller: _codParafaController,
                label: 'Cod parafă',
                validator: _codParafaValidator,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
                ],
                maxLength: 12,
                iconAsset: _signatureIcon,
              ),
            if (rule.requiresRegistrationCode)
              _textField(
                controller: _professionalCodeController,
                label: rule.registrationCodeLabel,
                validator: (value) => _requiredValidator(
                  value,
                  label: rule.registrationCodeLabel,
                ),
                iconAsset: _professionalCodeIcon,
              ),
            if (rule.requiresTitluUniversitar)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  key: ValueKey('titlu-universitar-$_selectedTitluUniversitar'),
                  initialValue: _selectedTitluUniversitar,
                  isExpanded: true,
                  icon: _dropdownArrowIcon(),
                  decoration: _fieldDecoration(
                    'Titlu universitar',
                    iconAsset: _titleIcon,
                  ),
                  items: _titluriUniversitare
                      .map(
                        (title) =>
                            DropdownMenuItem(value: title, child: Text(title)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTitluUniversitar = value),
                  validator: (value) =>
                      _requiredValidator(value, label: 'Titlu universitar'),
                ),
              ),
            CheckboxListTile(
              value: _acordEmail,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AuthShell.pulsePurple,
              checkColor: Colors.white,
              title: const Text('Sunt de acord să primesc email-uri'),
              onChanged: (value) =>
                  setState(() => _acordEmail = value ?? false),
            ),
            CheckboxListTile(
              value: _acordSms,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AuthShell.pulsePurple,
              checkColor: Colors.white,
              title: const Text('Sunt de acord să primesc SMS-uri'),
              onChanged: (value) => setState(() => _acordSms = value ?? false),
            ),
            CheckboxListTile(
              value: _gdprConsent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AuthShell.pulsePurple,
              checkColor: Colors.white,
              title: const Text('Accept prelucrarea datelor personale'),
              subtitle: !_gdprConsent && _currentStep == 2
                  ? Text(
                      'Consimțământul GDPR este obligatoriu.',
                      style: TextStyle(color: Colors.red.shade700),
                    )
                  : null,
              onChanged: (value) =>
                  setState(() => _gdprConsent = value ?? false),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoadingOptions) {
      return AuthShell.background(
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_loadError != null) {
      return AuthShell.background(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FrostedAuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AuthShell.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  AuthPrimaryButton(
                    label: 'Reîncearcă',
                    onPressed: _loadOptions,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AuthShell.background(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: _svgIcon(_backIcon, size: 22, color: Colors.white),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuthHeaderText(
                    title: 'Creează cont',
                    subtitle:
                        'Completează datele profesionale pentru o experiență personalizată.',
                    light: true,
                    align: TextAlign.left,
                  ),
                  const SizedBox(height: 22),
                  FrostedAuthCard(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                    child: Form(
                      key: _formKey,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AuthShell.pulsePurple,
                            secondary: AuthShell.pulseOrange,
                          ),
                        ),
                        child: Stepper(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          currentStep: _currentStep,
                          connectorColor: WidgetStateProperty.resolveWith(
                            (_) =>
                                AuthShell.pulseOrange.withValues(alpha: 0.28),
                          ),
                          controlsBuilder: (context, details) {
                            final isLastStep = _currentStep == 2;
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AuthPrimaryButton(
                                      label: isLastStep
                                          ? 'Finalizează înregistrarea'
                                          : 'Continuă',
                                      isLoading: _isSubmitting,
                                      onPressed: details.onStepContinue,
                                    ),
                                  ),
                                  if (_currentStep > 0) ...[
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : details.onStepCancel,
                                      child: const Text(
                                        'Înapoi',
                                        style: TextStyle(
                                          color: AuthShell.pulsePurple,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                          onStepTapped: (step) {
                            if (step <= _currentStep ||
                                _validateStep(_currentStep)) {
                              setState(() => _currentStep = step);
                            } else {
                              _formKey.currentState?.validate();
                            }
                          },
                          onStepContinue: _isSubmitting ? null : _continueStep,
                          onStepCancel: _currentStep == 0
                              ? null
                              : () => setState(() => _currentStep -= 1),
                          steps: _buildSteps(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                          },
                    child: const Text(
                      'Ai deja cont? Autentifică-te',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AuthShell.deepGreen, body: _buildBody());
  }
}
