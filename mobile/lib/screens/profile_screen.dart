import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'emc_activity_screen.dart';
import 'following_screen.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../utils/validators.dart' as validators;
import '../widgets/skeleton_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _emcIcon = 'assets/icons/EMC.svg';
  static const _emailIcon = 'assets/icons/envelope.fill.svg';
  static const _personIcon = 'assets/icons/person.text.rectangle.fill.svg';
  static const _plusIcon = 'assets/icons/plus.circle.fill.svg';
  static const _pencilIcon = 'assets/icons/pencil.svg';
  static const _onlyCheckIcon = 'assets/icons/onlycheckmark.svg';
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
  static const _cardIcon = 'assets/icons/creditcard.svg';
  static const _keyIcon = 'assets/icons/key.fill.svg';
  static const _eyeIcon = 'assets/icons/eye.fill.svg';
  static const _eyeSlashIcon = 'assets/icons/eye.slash.fill.svg';
  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _surfaceSoft = Color(0xFF181818);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _orange = Color(0xFFFF8A2A);
  static const LinearGradient _accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_pink, _orange],
  );
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _profile;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isChangingPhoto = false;
  bool _isLoadingPaymentMethods = true;
  bool _isPersonalExpanded = false;
  bool _isProfessionalExpanded = false;
  bool _isContactExpanded = false;
  bool _isPaymentMethodsExpanded = false;
  String? _errorMessage;
  String? _paymentMethodsError;
  String? _localAvatarUrl;
  Uint8List? _localAvatarBytes;
  List<_PaymentMethodItem> _paymentMethods = const [];
  final Set<int> _deletingPaymentMethodIds = <int>{};
  final Set<int> _settingDefaultPaymentMethodIds = <int>{};
  int? _expandedCardId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPaymentMethods();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _apiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(profile);
        _isLoading = false;
        _localAvatarBytes = null;
        _localAvatarUrl = _firstString([
          _read('avatar_url'),
          _read('profile_photo_url'),
          _read('photo_url'),
          _read('image_url'),
        ]);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Object? _read(String key) {
    final data = _profile;
    if (data == null) return null;
    if (data.containsKey(key)) return data[key];

    final profile = data['profile'];
    if (profile is Map && profile.containsKey(key)) return profile[key];

    final user = data['user'];
    if (user is Map && user.containsKey(key)) return user[key];
    return null;
  }

  String _text(String key, {String fallback = 'Necompletat'}) {
    final value = _read(key);
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _optionalText(String key) {
    final value = _read(key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _firstString(List<Object?> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  int _readTotalEmcPoints() {
    final value = _read('total_emc_points');
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get _displayName {
    final direct = _optionalText('display_name');
    if (direct != null) return direct;
    final parts = [
      _optionalText('first_name'),
      _optionalText('last_name'),
    ].whereType<String>().toList();
    return parts.isEmpty ? 'Profil medical' : parts.join(' ');
  }

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'P' : parts;
  }

  List<_InfoItem> get _personalItems => [
    _InfoItem('Nume', _text('first_name'), _personIcon),
    _InfoItem('Prenume', _text('last_name'), 'assets/icons/people.svg'),
    _InfoItem(
      'Data nașterii',
      _text('birth_date'),
      'assets/icons/calendar.svg',
    ),
    _InfoItem('Județ', _text('county_name'), _countyIcon),
    _InfoItem('Oraș', _text('city_name'), _cityIcon),
  ];

  List<_InfoItem> get _professionalItems => [
    _InfoItem('Rol / ocupație', _text('occupation_name'), _occupationIcon),
    _InfoItem(
      'Specializare',
      _text('specialization_name'),
      _specializationIcon,
    ),
    _InfoItem(
      'Specializare secundară',
      _text('specialization_secondary_name'),
      _secondarySpecializationIcon,
    ),
    _InfoItem('Grad profesional', _text('professional_grade_name'), _gradeIcon),
    _InfoItem(
      'Instituție / clinică / spital',
      _firstString([
            _read('institution_name'),
            _read('clinic_name'),
            _read('hospital_name'),
          ]) ??
          'Necompletat',
      _institutionIcon,
    ),
    _InfoItem(
      'CUIM',
      _firstString([_read('cuim'), _read('professional_registration_code')]) ??
          'Necompletat',
      _professionalCodeIcon,
    ),
    _InfoItem('Cod parafă', _text('cod_parafa'), _signatureIcon),
    _InfoItem('Titlu universitar', _text('titlu_universitar'), _titleIcon),
  ];

  List<_InfoItem> get _contactItems => [
    _InfoItem('Email', _text('email'), _emailIcon),
    _InfoItem('Telefon', _text('phone'), _phoneIcon),
    _InfoItem(
      'Adresă corespondență',
      _text('correspondence_address'),
      _homeIcon,
    ),
  ];

  Future<void> _openImagePicker() async {
    if (_isChangingPhoto) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _isChangingPhoto = true;
        _localAvatarBytes = bytes;
        _errorMessage = null;
      });

      final uploadResult = await _apiService.uploadMyProfileAvatar(
        bytes: bytes,
        fileName: image.name.isNotEmpty ? image.name : 'profile-avatar.jpg',
      );
      final freshProfile = await _apiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(freshProfile);
        _localAvatarUrl =
            _firstString([
              uploadResult['avatar_url'],
              uploadResult['profile_photo_url'],
              uploadResult['photo_url'],
              freshProfile['avatar_url'],
              freshProfile['profile_photo_url'],
              freshProfile['photo_url'],
            ]) ??
            _localAvatarUrl;
        _localAvatarBytes = null;
      });
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localAvatarBytes = null;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnack('Nu am putut salva poza de profil.', isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPhoto = false);
    }
  }

  Future<void> _openEditPersonal() async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPersonalSheet(
        readObject: _read,
        readValue: (key) => _text(key, fallback: ''),
        onSave: _saveProfile,
      ),
    );
    if (didSave == true && mounted) {
      await _showSuccessDialog(
        title: 'Date personale actualizate',
        message: 'Datele personale au fost salvate cu succes.',
      );
    }
  }

  Future<void> _openEditProfessional() async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfessionalSheet(
        readObject: _read,
        readValue: (key) => _text(key, fallback: ''),
        onSave: _saveProfile,
      ),
    );
    if (didSave == true && mounted) {
      await _showSuccessDialog(
        title: 'Date profesionale actualizate',
        message: 'Datele profesionale au fost salvate cu succes.',
      );
    }
  }

  Future<void> _openEditContact() async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditContactSheet(
        readValue: (key) => _text(key, fallback: ''),
        onSave: _saveProfile,
      ),
    );
    if (didSave == true && mounted) {
      await _showSuccessDialog(
        title: 'Date de contact actualizate',
        message: 'Datele de contact au fost salvate cu succes.',
      );
    }
  }

  Future<void> _openChangePassword() async {
    final didChange = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordSheet(
        onSave: (currentPassword, newPassword) => _apiService.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      ),
    );
    if (didChange == true && mounted) {
      await _showSuccessDialog(
        title: 'Parolă schimbată',
        message: 'Parola ta a fost actualizată cu succes.',
      );
    }
  }

  Future<void> _openFollowing() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FollowingScreen()));
  }

  Future<bool> _saveProfile(Map<String, String> changes) async {
    setState(() => _errorMessage = null);

    try {
      final updatedProfile = await _persistProfileChanges(changes);
      if (!mounted) return false;
      setState(() {
        _profile = Map<String, dynamic>.from(updatedProfile);
        _localAvatarUrl = _firstString([
          _read('avatar_url'),
          _read('profile_photo_url'),
          _read('photo_url'),
          _read('image_url'),
        ]);
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      final message = e.toString().replaceFirst('Exception: ', '');
      debugPrint(
        'Profile save failed for fields ${changes.keys.toList()}: $message',
      );
      setState(() {
        _errorMessage = message;
      });
      _showSnack(message, isError: true);
      return false;
    }
  }

  Future<Map<String, dynamic>> _persistProfileChanges(
    Map<String, String> changes,
  ) {
    return _apiService.updateMyProfile(_profileUpdatePayload(changes));
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
      _paymentMethodsError = null;
    });
    try {
      final rows = await _apiService.getMyPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = rows.map(_PaymentMethodItem.fromJson).toList();
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paymentMethodsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPaymentMethods = false;
      });
    }
  }

  Future<void> _openAddPaymentMethod() async {
    final didAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPaymentMethodSheet(onSubmit: _addPaymentMethod),
    );
    if (didAdd == true && mounted) {
      await _showSuccessDialog(
        title: 'Card adăugat',
        message: 'Cardul a fost adăugat cu succes.',
      );
    }
  }

  Future<bool> _addPaymentMethod({
    required String cardBrand,
    required String cardLast4,
    required int expMonth,
    required int expYear,
  }) async {
    setState(() {
      _paymentMethodsError = null;
    });
    try {
      await _apiService.addMyPaymentMethod(
        cardBrand: cardBrand,
        cardLast4: cardLast4,
        expMonth: expMonth,
        expYear: expYear,
      );
      await _loadPaymentMethods();
      return true;
    } catch (e) {
      if (!mounted) return false;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _paymentMethodsError = message);
      _showSnack(message, isError: true);
      return false;
    }
  }

  Future<void> _confirmDeletePaymentMethod(_PaymentMethodItem method) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _ConfirmDeletePaymentMethodDialog(
          method: method,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (shouldDelete == true) await _deletePaymentMethod(method);
  }

  Future<void> _deletePaymentMethod(_PaymentMethodItem method) async {
    setState(() {
      _deletingPaymentMethodIds.add(method.id);
      _paymentMethodsError = null;
    });
    try {
      await _apiService.deleteMyPaymentMethod(method.id);
      await _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _paymentMethodsError = message);
      _showSnack(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _deletingPaymentMethodIds.remove(method.id));
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(_PaymentMethodItem method) async {
    setState(() {
      _settingDefaultPaymentMethodIds.add(method.id);
      _paymentMethodsError = null;
    });
    try {
      await _apiService.setDefaultMyPaymentMethod(method.id);
      await _loadPaymentMethods();
      if (!mounted) return;
      await _showSuccessDialog(
        title: 'Card implicit',
        message: 'Cardul a fost setat ca metodă implicită.',
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _paymentMethodsError = message);
      _showSnack(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _settingDefaultPaymentMethodIds.remove(method.id));
      }
    }
  }

  Map<String, dynamic> _profileUpdatePayload(Map<String, String> changes) {
    final payload = <String, dynamic>{};
    const intFields = {
      'city_id',
      'occupation_id',
      'specialization_id',
      'professional_grade_id',
      'institution_id',
    };
    const ignoredFields = {
      'county_id',
      'county_name',
      'city_name',
      'occupation_name',
      'specialization_name',
      'professional_grade_name',
      'institution_name',
    };

    for (final entry in changes.entries) {
      final key = entry.key;
      final value = entry.value.trim();
      if (ignoredFields.contains(key)) continue;
      if (intFields.contains(key)) {
        final parsed = int.tryParse(value);
        if (parsed != null) payload[key] = parsed;
        continue;
      }
      payload[key] = value;
    }
    return payload;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB91C1C) : _surfaceSoft,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSuccessDialog({
    String title = 'Profil actualizat',
    String message = 'Profilul a fost actualizat cu succes.',
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _SuccessDialogCard(
          title: title,
          message: message,
          onConfirm: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PulseTheme.textPrimary,
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ProfileBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const ProfileGradientHeading('Profilul meu'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const SkeletonLoading.profile();

    if (_errorMessage != null && _profile == null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadProfile);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      children: [
        _ProfileHero(
          displayName: _displayName,
          subtitle: _firstString([
            _read('specialization_name'),
            _read('occupation_name'),
            _read('role'),
          ]),
          email: _text('email', fallback: 'Email necunoscut'),
          avatarUrl: _localAvatarUrl,
          avatarBytes: _localAvatarBytes,
          initials: _initials,
          onChangePhoto: _openImagePicker,
          isChangingPhoto: _isChangingPhoto,
          accentGradient: _accentGradient,
        ),
        const SizedBox(height: 16),
        _EmcMetricCard(
          points: _readTotalEmcPoints(),
          onActivityTap: _openEmcActivity,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          _StatusBanner(message: _errorMessage!, isError: true),
        ],
        const SizedBox(height: 16),
        _ProfileActionCard(
          icon: Icons.favorite_rounded,
          title: 'Urmăresc',
          subtitle:
              'Autori, publicații, parteneri, categorii și specializări urmărite.',
          onTap: _openFollowing,
        ),
        const SizedBox(height: 14),
        _InfoSection(
          title: 'Date personale',
          items: _personalItems,
          isExpanded: _isPersonalExpanded,
          onToggle: () =>
              setState(() => _isPersonalExpanded = !_isPersonalExpanded),
          onEdit: _openEditPersonal,
          editLabel: 'Editează datele personale',
        ),
        const SizedBox(height: 14),
        _InfoSection(
          title: 'Date profesionale',
          items: _professionalItems,
          isExpanded: _isProfessionalExpanded,
          onToggle: () => setState(
            () => _isProfessionalExpanded = !_isProfessionalExpanded,
          ),
          onEdit: _openEditProfessional,
          editLabel: 'Editează datele profesionale',
        ),
        const SizedBox(height: 14),
        _InfoSection(
          title: 'Contact',
          items: _contactItems,
          isExpanded: _isContactExpanded,
          onToggle: () =>
              setState(() => _isContactExpanded = !_isContactExpanded),
          onEdit: _openEditContact,
          editLabel: 'Editează datele de contact',
        ),
        const SizedBox(height: 14),
        _PaymentMethodsSection(
          methods: _paymentMethods,
          isLoading: _isLoadingPaymentMethods,
          errorMessage: _paymentMethodsError,
          deletingIds: _deletingPaymentMethodIds,
          settingDefaultIds: _settingDefaultPaymentMethodIds,
          isExpanded: _isPaymentMethodsExpanded,
          expandedCardId: _expandedCardId,
          onToggle: () => setState(
            () => _isPaymentMethodsExpanded = !_isPaymentMethodsExpanded,
          ),
          onCardTap: (id) => setState(
            () => _expandedCardId = _expandedCardId == id ? null : id,
          ),
          onAdd: _openAddPaymentMethod,
          onDelete: _confirmDeletePaymentMethod,
          onSetDefault: _setDefaultPaymentMethod,
          onRetry: _loadPaymentMethods,
        ),
        const SizedBox(height: 14),
        _ChangePasswordButton(onPressed: _openChangePassword),
      ],
    );
  }

  Future<void> _openEmcActivity() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EmcActivityScreen()));
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.subtitle,
    required this.email,
    required this.avatarUrl,
    required this.avatarBytes,
    required this.initials,
    required this.onChangePhoto,
    required this.isChangingPhoto,
    required this.accentGradient,
  });

  final String displayName;
  final String? subtitle;
  final String email;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String initials;
  final VoidCallback onChangePhoto;
  final bool isChangingPhoto;
  final LinearGradient accentGradient;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProfileAvatar(
            avatarUrl: avatarUrl,
            avatarBytes: avatarBytes,
            initials: initials,
            onChangePhoto: onChangePhoto,
            isChangingPhoto: isChangingPhoto,
            accentGradient: accentGradient,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle ?? 'Rol necompletat',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileScreenState._orange,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialogCard extends StatelessWidget {
  const _SuccessDialogCard({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _ProfileScreenState._accentGradient,
            ),
            child: const Center(
              child: _SvgIcon(
                _ProfileScreenState._onlyCheckIcon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _GradientDialogButton(onPressed: onConfirm, label: 'OK'),
        ],
      ),
    );
  }
}

class _GradientDialogButton extends StatelessWidget {
  const _GradientDialogButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _ProfileScreenState._accentGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileGradientHeading extends StatelessWidget {
  const ProfileGradientHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          _ProfileScreenState._accentGradient.createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Înapoi',
      child: Material(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: _SvgIcon(
                'assets/icons/arrow.backward.svg',
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.avatarBytes,
    required this.initials,
    required this.onChangePhoto,
    required this.isChangingPhoto,
    required this.accentGradient,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String initials;
  final VoidCallback onChangePhoto;
  final bool isChangingPhoto;
  final LinearGradient accentGradient;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final hasLocalImage = avatarBytes != null && avatarBytes!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 118,
          height: 118,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: accentGradient,
            boxShadow: [
              BoxShadow(
                color: _ProfileScreenState._pink.withValues(alpha: 0.28),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: _ProfileScreenState._surface,
              child: hasLocalImage
                  ? Image.memory(
                      avatarBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : hasImage
                  ? Image.network(
                      avatarUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _AvatarInitials(initials: initials),
                    )
                  : _AvatarInitials(initials: initials),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isChangingPhoto ? null : onChangePhoto,
              customBorder: const CircleBorder(),
              child: isChangingPhoto
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const _SvgIcon(
                      _ProfileScreenState._plusIcon,
                      size: 31,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: _ProfileScreenState._accentGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmcMetricCard extends StatelessWidget {
  const _EmcMetricCard({required this.points, required this.onActivityTap});

  final int points;
  final VoidCallback onActivityTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241015), Color(0xFF30170D), Color(0xFF0D0D0D)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _ProfileScreenState._orange.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _ProfileScreenState._accentGradient,
                ),
                child: const Center(
                  child: _SvgIcon(
                    _ProfileScreenState._emcIcon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Puncte EMC',
                      style: TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total acumulat în profil',
                      style: TextStyle(color: PulseTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                points.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _ProfileScreenState._orange.withValues(alpha: 0.28),
                  ),
                ),
                child: InkWell(
                  onTap: onActivityTap,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Activitatea mea',
                          style: TextStyle(
                            color: PulseTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        _SvgIcon(
                          'assets/icons/arrow.right.svg',
                          color: _ProfileScreenState._orange,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.items,
    required this.isExpanded,
    required this.onToggle,
    this.onEdit,
    this.editLabel,
  });

  final String title;
  final List<_InfoItem> items;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final String? editLabel;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CollapsibleSectionHeader(
            title: title,
            isExpanded: isExpanded,
            onToggle: onToggle,
          ),
          _CollapsibleBody(
            isExpanded: isExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                ...items.map((item) => _InfoRow(item: item)),
                if (onEdit != null) ...[
                  const SizedBox(height: 10),
                  _SectionEditButton(
                    label: editLabel ?? 'Editează',
                    onPressed: onEdit!,
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSectionHeader extends StatelessWidget {
  const _CollapsibleSectionHeader({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: PulseTheme.textSecondary,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsibleBody extends StatelessWidget {
  const _CollapsibleBody({required this.isExpanded, required this.child});

  final bool isExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: isExpanded
            ? AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 180),
                child: child,
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _PaymentMethodsSection extends StatelessWidget {
  const _PaymentMethodsSection({
    required this.methods,
    required this.isLoading,
    required this.errorMessage,
    required this.deletingIds,
    required this.settingDefaultIds,
    required this.isExpanded,
    required this.expandedCardId,
    required this.onToggle,
    required this.onCardTap,
    required this.onAdd,
    required this.onDelete,
    required this.onSetDefault,
    required this.onRetry,
  });

  final List<_PaymentMethodItem> methods;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> deletingIds;
  final Set<int> settingDefaultIds;
  final bool isExpanded;
  final int? expandedCardId;
  final VoidCallback onToggle;
  final ValueChanged<int> onCardTap;
  final VoidCallback onAdd;
  final ValueChanged<_PaymentMethodItem> onDelete;
  final ValueChanged<_PaymentMethodItem> onSetDefault;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CollapsibleSectionHeader(
            title: 'Cardurile mele',
            isExpanded: isExpanded,
            onToggle: onToggle,
          ),
          _CollapsibleBody(
            isExpanded: isExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                if (isLoading)
                  const _PaymentMethodsLoading()
                else if (errorMessage != null)
                  _PaymentMethodsError(message: errorMessage!, onRetry: onRetry)
                else if (methods.isEmpty)
                  const _PaymentMethodsEmptyState()
                else
                  ...methods.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentMethodCard(
                        method: method,
                        isExpanded: expandedCardId == method.id,
                        isDeleting: deletingIds.contains(method.id),
                        isSettingDefault: settingDefaultIds.contains(method.id),
                        onTap: () => onCardTap(method.id),
                        onDelete: () => onDelete(method),
                        onSetDefault: () => onSetDefault(method),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                _AddPaymentMethodButton(onPressed: onAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsLoading extends StatelessWidget {
  const _PaymentMethodsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Se încarcă cardurile...',
            style: TextStyle(
              color: PulseTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsError extends StatelessWidget {
  const _PaymentMethodsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reîncarcă')),
        ],
      ),
    );
  }
}

class _PaymentMethodsEmptyState extends StatelessWidget {
  const _PaymentMethodsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          _SvgIcon(
            _ProfileScreenState._cardIcon,
            color: PulseTheme.textTertiary,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nu ai carduri salvate încă.',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isExpanded,
    required this.isDeleting,
    required this.isSettingDefault,
    required this.onTap,
    required this.onDelete,
    required this.onSetDefault,
  });

  final _PaymentMethodItem method;
  final bool isExpanded;
  final bool isDeleting;
  final bool isSettingDefault;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final isExpanded = widget.isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isExpanded
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? _ProfileScreenState._pink.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: _ProfileScreenState._pink.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _SvgIcon(
                      _ProfileScreenState._cardIcon,
                      color: _ProfileScreenState._pink,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${method.brandLabel} •••• ${method.cardLast4}',
                                style: const TextStyle(
                                  color: PulseTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (method.isDefault)
                                const _DefaultPaymentBadge(),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Expiră ${method.expiryLabel}',
                            style: const TextStyle(
                              color: PulseTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron indicator
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isExpanded
                            ? _ProfileScreenState._pink
                            : PulseTheme.textTertiary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                // ── Expandable actions ───────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              if (!method.isDefault)
                                _CardActionButton(
                                  label: 'Setează implicit',
                                  color: _ProfileScreenState._orange,
                                  isLoading: widget.isSettingDefault,
                                  onPressed: widget.isSettingDefault
                                      ? null
                                      : widget.onSetDefault,
                                ),
                              if (!method.isDefault) const SizedBox(width: 8),
                              _CardActionButton(
                                label: 'Șterge',
                                color: const Color(0xFFFF5C72),
                                isLoading: widget.isDeleting,
                                onPressed: widget.isDeleting
                                    ? null
                                    : widget.onDelete,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DefaultPaymentBadge extends StatelessWidget {
  const _DefaultPaymentBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _ProfileScreenState._accentGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          'Implicit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AddPaymentMethodButton extends StatelessWidget {
  const _AddPaymentMethodButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: _ProfileScreenState._accentGradient,
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SvgIcon(
                  _ProfileScreenState._plusIcon,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 9),
                Text(
                  'Adaugă card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final isMissing = item.value == 'Necompletat';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _SvgIcon(
                item.iconAsset,
                color: isMissing
                    ? PulseTheme.textTertiary
                    : _ProfileScreenState._pink,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: PulseTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  softWrap: true,
                  style: TextStyle(
                    color: isMissing
                        ? PulseTheme.textSecondary.withValues(alpha: 0.65)
                        : PulseTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: isMissing ? FontWeight.w600 : FontWeight.w800,
                    fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEditButton extends StatelessWidget {
  const _SectionEditButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: _ProfileScreenState._accentGradient,
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SvgIcon(
                  _ProfileScreenState._pencilIcon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isError ? Colors.redAccent : Colors.greenAccent).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isError ? Colors.redAccent : Colors.greenAccent).withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.redAccent : Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                'Nu am putut încărca profilul',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PulseTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: _ProfileScreenState._surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 14),
                spreadRadius: -14,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _ProfileScreenState._accentGradient,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: _ProfileScreenState._pink.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: PulseTheme.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon(this.asset, {this.size = 19, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? _ProfileScreenState._pink,
        BlendMode.srcIn,
      ),
    );
  }
}

class _DecorativeIconSlot extends StatelessWidget {
  const _DecorativeIconSlot(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Center(child: _SvgIcon(asset, size: 20)),
    );
  }
}

class _AddPaymentMethodSheet extends StatefulWidget {
  const _AddPaymentMethodSheet({required this.onSubmit});

  final Future<bool> Function({
    required String cardBrand,
    required String cardLast4,
    required int expMonth,
    required int expYear,
  })
  onSubmit;

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  static const _brands = [
    'Visa',
    'Mastercard',
    'Maestro',
    'American Express',
    'Card',
  ];

  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  String _brand = 'Visa';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _detectBrand(String value) {
    final digits = _digitsOnly(value);
    String nextBrand = _brand;
    if (digits.startsWith('4')) {
      nextBrand = 'Visa';
    } else if (digits.startsWith(RegExp(r'5[1-5]')) ||
        digits.startsWith(RegExp(r'2[2-7]'))) {
      nextBrand = 'Mastercard';
    } else if (digits.startsWith('34') || digits.startsWith('37')) {
      nextBrand = 'American Express';
    } else if (digits.startsWith('50') ||
        digits.startsWith('56') ||
        digits.startsWith('57') ||
        digits.startsWith('58') ||
        digits.startsWith('6')) {
      nextBrand = 'Maestro';
    }
    if (nextBrand != _brand) {
      setState(() => _brand = nextBrand);
    }
  }

  String? _validateCardNumber(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.length < 12) {
      return 'Introdu un număr de card valid pentru demo.';
    }
    if (digits.length != 16) {
      return 'Pentru demo, numărul cardului trebuie să aibă 16 cifre.';
    }
    return null;
  }

  String? _validateMonth(String? value) {
    final month = int.tryParse((value ?? '').trim());
    if (month == null || month < 1 || month > 12) {
      return 'Luna trebuie să fie între 1 și 12.';
    }
    return null;
  }

  String? _validateYear(String? value) {
    final year = int.tryParse((value ?? '').trim());
    final currentYear = DateTime.now().year;
    if (year == null || year < currentYear || year > currentYear + 25) {
      return 'Anul expirării nu este valid.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final digits = _digitsOnly(_numberController.text);
    final success = await widget.onSubmit(
      cardBrand: _brand,
      cardLast4: digits.substring(digits.length - 4),
      expMonth: int.parse(_monthController.text.trim()),
      expYear: int.parse(_yearController.text.trim()),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage =
            'Nu am putut salva cardul. Verifică datele și încearcă din nou.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Adaugă card',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    const Text(
                      'Pentru demo se salvează doar brandul, ultimele 4 cifre și data expirării. Numărul complet nu este trimis către server.',
                      style: TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _holderController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _paymentFieldDecoration(
                        'Nume deținător card',
                        iconAsset: _ProfileScreenState._personIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: const [_CardNumberInputFormatter()],
                      validator: _validateCardNumber,
                      onChanged: _detectBrand,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _paymentFieldDecoration(
                        'Număr card demo',
                        iconAsset: _ProfileScreenState._cardIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _brand,
                      isExpanded: true,
                      icon: const _SvgIcon(
                        'assets/icons/arrow.right.svg',
                        color: PulseTheme.textSecondary,
                        size: 15,
                      ),
                      decoration: _paymentFieldDecoration(
                        'Brand card',
                        iconAsset: _ProfileScreenState._cardIcon,
                      ),
                      items: _brands
                          .map(
                            (brand) => DropdownMenuItem<String>(
                              value: brand,
                              child: Text(brand),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _brand = value ?? _brand),
                      dropdownColor: _ProfileScreenState._surface,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _monthController,
                            keyboardType: TextInputType.number,
                            validator: _validateMonth,
                            style: const TextStyle(
                              color: PulseTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _paymentFieldDecoration(
                              'Lună expirare',
                              iconAsset: 'assets/icons/calendar.svg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            validator: _validateYear,
                            style: const TextStyle(
                              color: PulseTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _paymentFieldDecoration(
                              'An expirare',
                              iconAsset: 'assets/icons/calendar.svg',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(message: _errorMessage!, isError: true),
                    ],
                    const SizedBox(height: 18),
                    _GradientSheetButton(
                      label: _isSubmitting ? 'Se salvează...' : 'Salvează card',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _paymentFieldDecoration(
    String label, {
    required String iconAsset,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }
}

class _GradientSheetButton extends StatelessWidget {
  const _GradientSheetButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLoading ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: _ProfileScreenState._accentGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
}

class _ConfirmDeletePaymentMethodDialog extends StatelessWidget {
  const _ConfirmDeletePaymentMethodDialog({
    required this.method,
    required this.onCancel,
    required this.onConfirm,
  });

  final _PaymentMethodItem method;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SvgIcon(
            _ProfileScreenState._cardIcon,
            color: _ProfileScreenState._orange,
            size: 34,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ștergi cardul?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${method.brandLabel} •••• ${method.cardLast4} va fi eliminat din cardurile salvate.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PulseTheme.textPrimary,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Renunță'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _ProfileScreenState._accentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: onConfirm,
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Text(
                          'Șterge',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.readObject,
    required this.readValue,
    required this.onSave,
  });

  final Object? Function(String key) readObject;
  final String Function(String key) readValue;
  final Future<bool> Function(Map<String, String> changes) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static const List<String> _titluriUniversitare = [
    'Fără titlu universitar',
    'Asistent universitar',
    'Preparator universitar',
    'Șef de lucrări',
    'Conferențiar',
    'Profesor universitar',
    'Altul',
  ];

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
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
  String? _selectedTitluUniversitar;
  bool _isLoadingOptions = false;
  bool _isSaving = false;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in _textEditableFields)
        field.key: TextEditingController(text: widget.readValue(field.key)),
    };
    _selectedCountyId = _readInt('county_id');
    _selectedCityId = _readInt('city_id');
    _selectedOccupationId = _readInt('occupation_id');
    _selectedSpecializationId = _readInt('specialization_id');
    _selectedProfessionalGradeId = _readInt('professional_grade_id');
    _selectedInstitutionId = _readInt('institution_id');
    _selectedTitluUniversitar = _clean(widget.readValue('titlu_universitar'));
    _loadOptions();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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

  int? _readInt(String key) {
    final value = widget.readObject(key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == 'Necompletat') return null;
    return text;
  }

  _OptionItem? _optionById(List<_OptionItem> options, int? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  Future<List<_OptionItem>> _fetchOptions(String path) async {
    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Nu am putut încărca opțiunile.');
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
      _optionsError = null;
    });
    try {
      final results = await Future.wait([
        _fetchOptions('/counties'),
        _fetchOptions('/cities'),
        _fetchOptions('/occupations'),
        _fetchOptions('/specializations'),
        _fetchOptions('/professional-grades'),
        _fetchOptions('/institutions'),
      ]);
      if (!mounted) return;
      setState(() {
        _counties = results[0];
        _cities = results[1];
        _occupations = results[2];
        _specializations = results[3];
        _professionalGrades = results[4];
        _institutions = results[5];
        _selectedCountyId ??= _findId(_counties, 'county_name');
        _selectedCityId ??= _findId(_cities, 'city_name');
        _selectedOccupationId ??= _findId(_occupations, 'occupation_name');
        _selectedSpecializationId ??= _findId(
          _specializations,
          'specialization_name',
        );
        _selectedProfessionalGradeId ??= _findId(
          _professionalGrades,
          'professional_grade_name',
        );
        _selectedInstitutionId ??= _findId(_institutions, 'institution_name');
        _selectedSecondarySpecializationId ??= _findId(
          _specializations,
          'specialization_secondary_name',
        );
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingOptions = false;
      });
    }
  }

  int? _findId(List<_OptionItem> options, String nameKey) {
    final name = _clean(widget.readValue(nameKey));
    if (name == null) return null;
    for (final option in options) {
      if (option.name.toLowerCase() == name.toLowerCase()) return option.id;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final changes = <String, String>{
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
    _addOption(
      changes,
      idKey: 'county_id',
      nameKey: 'county_name',
      id: _selectedCountyId,
      options: _counties,
    );
    _addOption(
      changes,
      idKey: 'city_id',
      nameKey: 'city_name',
      id: _selectedCityId,
      options: _cities,
    );
    _addOption(
      changes,
      idKey: 'occupation_id',
      nameKey: 'occupation_name',
      id: _selectedOccupationId,
      options: _occupations,
    );
    _addOption(
      changes,
      idKey: 'specialization_id',
      nameKey: 'specialization_name',
      id: _selectedSpecializationId,
      options: _specializations,
    );
    _addOption(
      changes,
      idKey: 'professional_grade_id',
      nameKey: 'professional_grade_name',
      id: _selectedProfessionalGradeId,
      options: _professionalGrades,
    );
    _addOption(
      changes,
      idKey: 'institution_id',
      nameKey: 'institution_name',
      id: _selectedInstitutionId,
      options: _institutions,
    );
    final secondary = _optionById(
      _specializations,
      _selectedSecondarySpecializationId,
    );
    changes['specialization_secondary_name'] = secondary?.name ?? '';
    changes['titlu_universitar'] = _selectedTitluUniversitar ?? '';
    final success = await widget.onSave(changes);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) Navigator.of(context).pop(true);
  }

  void _addOption(
    Map<String, String> changes, {
    required String idKey,
    required String nameKey,
    required int? id,
    required List<_OptionItem> options,
  }) {
    final option = _optionById(options, id);
    changes[idKey] = id?.toString() ?? '';
    changes[nameKey] = option?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editează profilul',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    if (_isLoadingOptions) const _OptionsLoadingBanner(),
                    if (_optionsError != null)
                      _OptionsErrorBanner(
                        message: _optionsError!,
                        onRetry: _loadOptions,
                      ),
                    ..._textEditableFields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _controllers[field.key],
                          validator: field.validator,
                          keyboardType: field.keyboardType,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: PulseTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _fieldDecoration(
                            field.label,
                            iconAsset: field.iconAsset,
                          ),
                        ),
                      ),
                    ),
                    _dropdownField(
                      label: 'Județ',
                      value: _selectedCountyId,
                      options: _counties,
                      iconAsset: _ProfileScreenState._countyIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedCountyId = value;
                          _selectedCityId = null;
                          _selectedInstitutionId = null;
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Oraș',
                      value: _selectedCityId,
                      options: _filteredCities,
                      enabled: _selectedCountyId != null,
                      emptyHint: _selectedCountyId == null
                          ? 'Alege mai întâi județul.'
                          : 'Nu există orașe pentru județul ales.',
                      iconAsset: _ProfileScreenState._cityIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedCityId = value;
                          _selectedInstitutionId = null;
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Rol / ocupație',
                      value: _selectedOccupationId,
                      options: _occupations,
                      iconAsset: _ProfileScreenState._occupationIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedOccupationId = value;
                          _selectedSpecializationId = null;
                          _selectedSecondarySpecializationId = null;
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Specializare',
                      value: _selectedSpecializationId,
                      options: _filteredSpecializations,
                      iconAsset: _ProfileScreenState._specializationIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecializationId = value;
                          if (_selectedSecondarySpecializationId == value) {
                            _selectedSecondarySpecializationId = null;
                          }
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Specializare secundară',
                      value: _selectedSecondarySpecializationId,
                      options: _filteredSecondarySpecializations,
                      required: false,
                      iconAsset:
                          _ProfileScreenState._secondarySpecializationIcon,
                      onChanged: (value) => setState(
                        () => _selectedSecondarySpecializationId = value,
                      ),
                    ),
                    _dropdownField(
                      label: 'Grad profesional',
                      value: _selectedProfessionalGradeId,
                      options: _professionalGrades,
                      iconAsset: _ProfileScreenState._gradeIcon,
                      onChanged: (value) =>
                          setState(() => _selectedProfessionalGradeId = value),
                    ),
                    _dropdownField(
                      label: 'Instituție / clinică / spital',
                      value: _selectedInstitutionId,
                      options: _filteredInstitutions,
                      required: false,
                      iconAsset: _ProfileScreenState._institutionIcon,
                      onChanged: (value) =>
                          setState(() => _selectedInstitutionId = value),
                    ),
                    _titleDropdown(),
                    const SizedBox(height: 6),
                    _GradientSaveButton(
                      isSaving: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required int? value,
    required List<_OptionItem> options,
    required ValueChanged<int?> onChanged,
    required String iconAsset,
    bool required = true,
    bool enabled = true,
    String? emptyHint,
  }) {
    final effectiveValue = options.any((item) => item.id == value)
        ? value
        : null;
    final hasOptions = options.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$effectiveValue-${options.length}-$enabled'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: const _SvgIcon(
          'assets/icons/arrow.right.svg',
          color: PulseTheme.textSecondary,
          size: 15,
        ),
        hint: Text(
          !enabled || !hasOptions ? (emptyHint ?? label) : label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        decoration: _fieldDecoration(
          label,
          iconAsset: iconAsset,
        ).copyWith(enabled: enabled && hasOptions),
        items: options
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: enabled && hasOptions ? onChanged : null,
        dropdownColor: _ProfileScreenState._surface,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        validator: required
            ? (value) => value == null ? '$label este obligatoriu' : null
            : null,
      ),
    );
  }

  Widget _titleDropdown() {
    final effectiveValue =
        _titluriUniversitare.contains(_selectedTitluUniversitar)
        ? _selectedTitluUniversitar
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('titlu-universitar-$effectiveValue'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: const _SvgIcon(
          'assets/icons/arrow.right.svg',
          color: PulseTheme.textSecondary,
          size: 15,
        ),
        hint: const Text('Titlu universitar'),
        decoration: _fieldDecoration(
          'Titlu universitar',
          iconAsset: _ProfileScreenState._titleIcon,
        ),
        items: _titluriUniversitare
            .map(
              (title) => DropdownMenuItem<String>(
                value: title,
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedTitluUniversitar = value),
        dropdownColor: _ProfileScreenState._surface,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {required String iconAsset}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }
}

// ─── Edit Personal Sheet ────────────────────────────────────────────────────

class _EditPersonalSheet extends StatefulWidget {
  const _EditPersonalSheet({
    required this.readObject,
    required this.readValue,
    required this.onSave,
  });

  final Object? Function(String key) readObject;
  final String Function(String key) readValue;
  final Future<bool> Function(Map<String, String> changes) onSave;

  @override
  State<_EditPersonalSheet> createState() => _EditPersonalSheetState();
}

class _EditPersonalSheetState extends State<_EditPersonalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  List<_OptionItem> _counties = const [];
  List<_OptionItem> _cities = const [];
  int? _selectedCountyId;
  int? _selectedCityId;
  bool _isLoadingOptions = false;
  bool _isSaving = false;
  String? _optionsError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.readValue('first_name'),
    );
    _lastNameController = TextEditingController(
      text: widget.readValue('last_name'),
    );
    _selectedCountyId = _readInt('county_id');
    _selectedCityId = _readInt('city_id');
    _loadOptions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  int? _readInt(String key) {
    final value = widget.readObject(key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == 'Necompletat') return null;
    return text;
  }

  _OptionItem? _optionById(List<_OptionItem> options, int? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  int? _findId(List<_OptionItem> options, String nameKey) {
    final name = _clean(widget.readValue(nameKey));
    if (name == null) return null;
    for (final option in options) {
      if (option.name.toLowerCase() == name.toLowerCase()) return option.id;
    }
    return null;
  }

  Future<List<_OptionItem>> _fetchOptions(String path) async {
    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Nu am putut încărca opțiunile.');
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
      _optionsError = null;
    });
    try {
      final results = await Future.wait([
        _fetchOptions('/counties'),
        _fetchOptions('/cities'),
      ]);
      if (!mounted) return;
      setState(() {
        _counties = results[0];
        _cities = results[1];
        _selectedCountyId ??= _findId(_counties, 'county_name');
        _selectedCityId ??= _findId(_cities, 'city_name');
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingOptions = false;
      });
    }
  }

  List<_OptionItem> get _filteredCities {
    if (_selectedCountyId == null) return const [];
    return _cities.where((c) => c.countyId == _selectedCountyId).toList();
  }

  void _addOption(
    Map<String, String> changes, {
    required String idKey,
    required String nameKey,
    required int? id,
    required List<_OptionItem> options,
  }) {
    final option = _optionById(options, id);
    changes[idKey] = id?.toString() ?? '';
    changes[nameKey] = option?.name ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final changes = <String, String>{
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
    };
    _addOption(
      changes,
      idKey: 'county_id',
      nameKey: 'county_name',
      id: _selectedCountyId,
      options: _counties,
    );
    _addOption(
      changes,
      idKey: 'city_id',
      nameKey: 'city_name',
      id: _selectedCityId,
      options: _cities,
    );
    final success = await widget.onSave(changes);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = 'Nu am putut salva. Încearcă din nou.');
    }
  }

  InputDecoration _fieldDecoration(String label, {required String iconAsset}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }

  Widget _dropdownField({
    required String label,
    required int? value,
    required List<_OptionItem> options,
    required ValueChanged<int?> onChanged,
    required String iconAsset,
    bool required = true,
    bool enabled = true,
    String? emptyHint,
  }) {
    final effectiveValue = options.any((item) => item.id == value)
        ? value
        : null;
    final hasOptions = options.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$effectiveValue-${options.length}-$enabled'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: const _SvgIcon(
          'assets/icons/arrow.right.svg',
          color: PulseTheme.textSecondary,
          size: 15,
        ),
        hint: Text(
          !enabled || !hasOptions ? (emptyHint ?? label) : label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        decoration: _fieldDecoration(
          label,
          iconAsset: iconAsset,
        ).copyWith(enabled: enabled && hasOptions),
        items: options
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: enabled && hasOptions ? onChanged : null,
        dropdownColor: _ProfileScreenState._surface,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        validator: required
            ? (value) => value == null ? '$label este obligatoriu' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final birthDate = widget.readValue('birth_date');
    final hasBirthDate = birthDate.isNotEmpty && birthDate != 'Necompletat';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editează datele personale',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    if (_isLoadingOptions) const _OptionsLoadingBanner(),
                    if (_optionsError != null)
                      _OptionsErrorBanner(
                        message: _optionsError!,
                        onRetry: _loadOptions,
                      ),
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: (value) =>
                          validators.requiredValidator(value, label: 'Nume'),
                      decoration: _fieldDecoration(
                        'Nume',
                        iconAsset: _ProfileScreenState._personIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: (value) =>
                          validators.requiredValidator(value, label: 'Prenume'),
                      decoration: _fieldDecoration(
                        'Prenume',
                        iconAsset: 'assets/icons/people.svg',
                      ),
                    ),
                    if (hasBirthDate) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const _SvgIcon(
                              'assets/icons/calendar.svg',
                              color: PulseTheme.textTertiary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data nașterii',
                                    style: TextStyle(
                                      color: PulseTheme.textTertiary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    birthDate,
                                    style: const TextStyle(
                                      color: PulseTheme.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Nu se poate edita',
                                style: TextStyle(
                                  color: PulseTheme.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: 'Județ',
                      value: _selectedCountyId,
                      options: _counties,
                      iconAsset: _ProfileScreenState._countyIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedCountyId = value;
                          _selectedCityId = null;
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Oraș',
                      value: _selectedCityId,
                      options: _filteredCities,
                      enabled: _selectedCountyId != null,
                      emptyHint: _selectedCountyId == null
                          ? 'Alege mai întâi județul.'
                          : 'Nu există orașe pentru județul ales.',
                      iconAsset: _ProfileScreenState._cityIcon,
                      onChanged: (value) {
                        setState(() => _selectedCityId = value);
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      _StatusBanner(message: _errorMessage!, isError: true),
                    ],
                    const SizedBox(height: 6),
                    _GradientSaveButton(
                      isSaving: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Professional Sheet ─────────────────────────────────────────────────

class _EditProfessionalSheet extends StatefulWidget {
  const _EditProfessionalSheet({
    required this.readObject,
    required this.readValue,
    required this.onSave,
  });

  final Object? Function(String key) readObject;
  final String Function(String key) readValue;
  final Future<bool> Function(Map<String, String> changes) onSave;

  @override
  State<_EditProfessionalSheet> createState() => _EditProfessionalSheetState();
}

class _EditProfessionalSheetState extends State<_EditProfessionalSheet> {
  static const List<String> _titluriUniversitare = [
    'Fără titlu universitar',
    'Asistent universitar',
    'Preparator universitar',
    'Șef de lucrări',
    'Conferențiar',
    'Profesor universitar',
    'Altul',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cuimController;
  late final TextEditingController _codParafaController;
  List<_OptionItem> _occupations = const [];
  List<_OptionItem> _specializations = const [];
  List<_OptionItem> _professionalGrades = const [];
  List<_OptionItem> _institutions = const [];
  int? _selectedOccupationId;
  int? _selectedSpecializationId;
  int? _selectedSecondarySpecializationId;
  int? _selectedProfessionalGradeId;
  int? _selectedInstitutionId;
  String? _selectedTitluUniversitar;
  bool _isLoadingOptions = false;
  bool _isSaving = false;
  String? _optionsError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cuimController = TextEditingController(text: widget.readValue('cuim'));
    _codParafaController = TextEditingController(
      text: widget.readValue('cod_parafa'),
    );
    _selectedOccupationId = _readInt('occupation_id');
    _selectedSpecializationId = _readInt('specialization_id');
    _selectedProfessionalGradeId = _readInt('professional_grade_id');
    _selectedInstitutionId = _readInt('institution_id');
    _selectedTitluUniversitar = _clean(widget.readValue('titlu_universitar'));
    _loadOptions();
  }

  @override
  void dispose() {
    _cuimController.dispose();
    _codParafaController.dispose();
    super.dispose();
  }

  int? _readInt(String key) {
    final value = widget.readObject(key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == 'Necompletat') return null;
    return text;
  }

  _OptionItem? _optionById(List<_OptionItem> options, int? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  _OptionItem? get _selectedOccupation =>
      _optionById(_occupations, _selectedOccupationId);

  List<_OptionItem> get _filteredSpecializations {
    final name = (_selectedOccupation?.name ?? '').toLowerCase();
    if (name.contains('asistent')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Asistent medical' ||
                item.name == 'Asistent de farmacie' ||
                item.name == 'Fiziokinetoterapie/Recuperare medicala',
          )
          .toList();
    }
    if (name.contains('farmacist')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Farmacie' ||
                item.name == 'Farmacologie Clinica' ||
                item.name == 'Homeopatie',
          )
          .toList();
    }
    if (name.contains('veterinar')) {
      return _specializations
          .where((item) => item.name == 'Medicina veterinara')
          .toList();
    }
    if (name.contains('psiholog')) {
      return _specializations
          .where((item) => item.name == 'Psihologie medicala')
          .toList();
    }
    if (name.contains('nutritionist')) {
      return _specializations
          .where(
            (item) =>
                item.name == 'Diabetologie/Nutritie si Boli Metabolice' ||
                item.name == 'Sanatate publica',
          )
          .toList();
    }
    if (name.contains('stomatolog')) {
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

  List<_OptionItem> get _filteredSecondarySpecializations =>
      _filteredSpecializations
          .where((item) => item.id != _selectedSpecializationId)
          .toList();

  int? _findId(List<_OptionItem> options, String nameKey) {
    final name = _clean(widget.readValue(nameKey));
    if (name == null) return null;
    for (final option in options) {
      if (option.name.toLowerCase() == name.toLowerCase()) return option.id;
    }
    return null;
  }

  Future<List<_OptionItem>> _fetchOptions(String path) async {
    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Nu am putut încărca opțiunile.');
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
      _optionsError = null;
    });
    try {
      final results = await Future.wait([
        _fetchOptions('/occupations'),
        _fetchOptions('/specializations'),
        _fetchOptions('/professional-grades'),
        _fetchOptions('/institutions'),
      ]);
      if (!mounted) return;
      setState(() {
        _occupations = results[0];
        _specializations = results[1];
        _professionalGrades = results[2];
        _institutions = results[3];
        _selectedOccupationId ??= _findId(_occupations, 'occupation_name');
        _selectedSpecializationId ??= _findId(
          _specializations,
          'specialization_name',
        );
        _selectedProfessionalGradeId ??= _findId(
          _professionalGrades,
          'professional_grade_name',
        );
        _selectedInstitutionId ??= _findId(_institutions, 'institution_name');
        _selectedSecondarySpecializationId ??= _findId(
          _specializations,
          'specialization_secondary_name',
        );
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingOptions = false;
      });
    }
  }

  void _addOption(
    Map<String, String> changes, {
    required String idKey,
    required String nameKey,
    required int? id,
    required List<_OptionItem> options,
  }) {
    final option = _optionById(options, id);
    changes[idKey] = id?.toString() ?? '';
    changes[nameKey] = option?.name ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final changes = <String, String>{
      'cuim': _cuimController.text,
      'cod_parafa': _codParafaController.text,
    };
    _addOption(
      changes,
      idKey: 'occupation_id',
      nameKey: 'occupation_name',
      id: _selectedOccupationId,
      options: _occupations,
    );
    _addOption(
      changes,
      idKey: 'specialization_id',
      nameKey: 'specialization_name',
      id: _selectedSpecializationId,
      options: _specializations,
    );
    _addOption(
      changes,
      idKey: 'professional_grade_id',
      nameKey: 'professional_grade_name',
      id: _selectedProfessionalGradeId,
      options: _professionalGrades,
    );
    _addOption(
      changes,
      idKey: 'institution_id',
      nameKey: 'institution_name',
      id: _selectedInstitutionId,
      options: _institutions,
    );
    final secondary = _optionById(
      _specializations,
      _selectedSecondarySpecializationId,
    );
    changes['specialization_secondary_name'] = secondary?.name ?? '';
    changes['titlu_universitar'] = _selectedTitluUniversitar ?? '';
    final success = await widget.onSave(changes);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = 'Nu am putut salva. Încearcă din nou.');
    }
  }

  InputDecoration _fieldDecoration(String label, {required String iconAsset}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }

  Widget _dropdownField({
    required String label,
    required int? value,
    required List<_OptionItem> options,
    required ValueChanged<int?> onChanged,
    required String iconAsset,
    bool required = true,
    bool enabled = true,
    String? emptyHint,
  }) {
    final effectiveValue = options.any((item) => item.id == value)
        ? value
        : null;
    final hasOptions = options.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$effectiveValue-${options.length}-$enabled'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: const _SvgIcon(
          'assets/icons/arrow.right.svg',
          color: PulseTheme.textSecondary,
          size: 15,
        ),
        hint: Text(
          !enabled || !hasOptions ? (emptyHint ?? label) : label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        decoration: _fieldDecoration(
          label,
          iconAsset: iconAsset,
        ).copyWith(enabled: enabled && hasOptions),
        items: options
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: enabled && hasOptions ? onChanged : null,
        dropdownColor: _ProfileScreenState._surface,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        validator: required
            ? (value) => value == null ? '$label este obligatoriu' : null
            : null,
      ),
    );
  }

  Widget _titleDropdown() {
    final effectiveValue =
        _titluriUniversitare.contains(_selectedTitluUniversitar)
        ? _selectedTitluUniversitar
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('titlu-pro-$effectiveValue'),
        initialValue: effectiveValue,
        isExpanded: true,
        icon: const _SvgIcon(
          'assets/icons/arrow.right.svg',
          color: PulseTheme.textSecondary,
          size: 15,
        ),
        hint: const Text('Titlu universitar'),
        decoration: _fieldDecoration(
          'Titlu universitar',
          iconAsset: _ProfileScreenState._titleIcon,
        ),
        items: _titluriUniversitare
            .map(
              (title) => DropdownMenuItem<String>(
                value: title,
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedTitluUniversitar = v),
        dropdownColor: _ProfileScreenState._surface,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editează datele profesionale',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    if (_isLoadingOptions) const _OptionsLoadingBanner(),
                    if (_optionsError != null)
                      _OptionsErrorBanner(
                        message: _optionsError!,
                        onRetry: _loadOptions,
                      ),
                    _dropdownField(
                      label: 'Rol / ocupație',
                      value: _selectedOccupationId,
                      options: _occupations,
                      iconAsset: _ProfileScreenState._occupationIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedOccupationId = value;
                          _selectedSpecializationId = null;
                          _selectedSecondarySpecializationId = null;
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Specializare',
                      value: _selectedSpecializationId,
                      options: _filteredSpecializations,
                      iconAsset: _ProfileScreenState._specializationIcon,
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecializationId = value;
                          if (_selectedSecondarySpecializationId == value) {
                            _selectedSecondarySpecializationId = null;
                          }
                        });
                      },
                    ),
                    _dropdownField(
                      label: 'Specializare secundară',
                      value: _selectedSecondarySpecializationId,
                      options: _filteredSecondarySpecializations,
                      required: false,
                      iconAsset:
                          _ProfileScreenState._secondarySpecializationIcon,
                      onChanged: (value) => setState(
                        () => _selectedSecondarySpecializationId = value,
                      ),
                    ),
                    _dropdownField(
                      label: 'Grad profesional',
                      value: _selectedProfessionalGradeId,
                      options: _professionalGrades,
                      iconAsset: _ProfileScreenState._gradeIcon,
                      onChanged: (value) =>
                          setState(() => _selectedProfessionalGradeId = value),
                    ),
                    _dropdownField(
                      label: 'Instituție / clinică / spital',
                      value: _selectedInstitutionId,
                      options: _institutions,
                      required: false,
                      iconAsset: _ProfileScreenState._institutionIcon,
                      onChanged: (value) =>
                          setState(() => _selectedInstitutionId = value),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _cuimController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: PulseTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          'CUIM',
                          iconAsset: _ProfileScreenState._professionalCodeIcon,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _codParafaController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: PulseTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          'Cod parafă',
                          iconAsset: _ProfileScreenState._signatureIcon,
                        ),
                      ),
                    ),
                    _titleDropdown(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      _StatusBanner(message: _errorMessage!, isError: true),
                    ],
                    const SizedBox(height: 6),
                    _GradientSaveButton(
                      isSaving: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Contact Sheet ───────────────────────────────────────────────────────

class _EditContactSheet extends StatefulWidget {
  const _EditContactSheet({required this.readValue, required this.onSave});

  final String Function(String key) readValue;
  final Future<bool> Function(Map<String, String> changes) onSave;

  @override
  State<_EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<_EditContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.readValue('email'));
    _phoneController = TextEditingController(text: widget.readValue('phone'));
    _addressController = TextEditingController(
      text: widget.readValue('correspondence_address'),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final changes = <String, String>{
      'email': _emailController.text,
      'phone': _phoneController.text,
      'correspondence_address': _addressController.text,
    };
    final success = await widget.onSave(changes);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = 'Nu am putut salva. Încearcă din nou.');
    }
  }

  InputDecoration _fieldDecoration(String label, {required String iconAsset}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editează datele de contact',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: validators.emailValidator,
                      decoration: _fieldDecoration(
                        'Email',
                        iconAsset: _ProfileScreenState._emailIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: validators.phoneValidator,
                      decoration: _fieldDecoration(
                        'Telefon',
                        iconAsset: _ProfileScreenState._phoneIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _fieldDecoration(
                        'Adresă corespondență',
                        iconAsset: _ProfileScreenState._homeIcon,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(message: _errorMessage!, isError: true),
                    ],
                    const SizedBox(height: 18),
                    _GradientSaveButton(
                      isSaving: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isSaving ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: _ProfileScreenState._accentGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            onTap: isSaving ? null : onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSaving) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Text(
                    isSaving ? 'Se salvează...' : 'Salvează',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
}

class _OptionsLoadingBanner extends StatelessWidget {
  const _OptionsLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Se încarcă opțiunile...',
            style: TextStyle(color: PulseTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OptionsErrorBanner extends StatelessWidget {
  const _OptionsErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Încearcă din nou')),
        ],
      ),
    );
  }
}

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

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory _OptionItem.fromJson(Map<String, dynamic> json) {
    return _OptionItem(
      id: _readInt(json['id']) ?? 0,
      name: (json['name'] ?? json['label'] ?? '').toString(),
      countyId: _readInt(json['county_id']),
      cityId: _readInt(json['city_id']),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value, this.iconAsset);

  final String label;
  final String value;
  final String iconAsset;
}

class _PaymentMethodItem {
  const _PaymentMethodItem({
    required this.id,
    required this.cardBrand,
    required this.cardLast4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  final int id;
  final String cardBrand;
  final String cardLast4;
  final int? expMonth;
  final int? expYear;
  final bool isDefault;

  String get brandLabel {
    final text = cardBrand.trim();
    return text.isEmpty ? 'Card' : text;
  }

  String get expiryLabel {
    if (expMonth == null || expYear == null) return 'Necompletat';
    return '${expMonth.toString().padLeft(2, '0')}/$expYear';
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _readNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory _PaymentMethodItem.fromJson(Map<String, dynamic> json) {
    return _PaymentMethodItem(
      id: _readInt(json['id']),
      cardBrand: (json['card_brand'] ?? 'Card').toString(),
      cardLast4: (json['card_last4'] ?? '----').toString(),
      expMonth: _readNullableInt(json['exp_month']),
      expYear: _readNullableInt(json['exp_year']),
      isDefault: json['is_default'] == true,
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  const _CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 16 ? digits.substring(0, 16) : digits;
    final groups = <String>[];
    for (var index = 0; index < limitedDigits.length; index += 4) {
      final end = (index + 4).clamp(0, limitedDigits.length);
      groups.add(limitedDigits.substring(index, end));
    }
    final formatted = groups.join(' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _EditableField {
  const _EditableField({
    required this.key,
    required this.label,
    required this.iconAsset,
    this.keyboardType,
    this.validator,
  });

  final String key;
  final String label;
  final String iconAsset;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
}

final List<_EditableField> _textEditableFields = [
  _EditableField(
    key: 'first_name',
    label: 'Nume',
    iconAsset: _ProfileScreenState._personIcon,
    validator: (value) => validators.requiredValidator(value, label: 'Nume'),
  ),
  _EditableField(
    key: 'last_name',
    label: 'Prenume',
    iconAsset: 'assets/icons/people.svg',
    validator: (value) => validators.requiredValidator(value, label: 'Prenume'),
  ),
  _EditableField(
    key: 'email',
    label: 'Email',
    iconAsset: _ProfileScreenState._emailIcon,
    keyboardType: TextInputType.emailAddress,
    validator: validators.emailValidator,
  ),
  _EditableField(
    key: 'phone',
    label: 'Telefon',
    iconAsset: _ProfileScreenState._phoneIcon,
    keyboardType: TextInputType.phone,
    validator: validators.phoneValidator,
  ),
  const _EditableField(
    key: 'correspondence_address',
    label: 'Adresă corespondență',
    iconAsset: _ProfileScreenState._homeIcon,
  ),
  const _EditableField(
    key: 'cuim',
    label: 'CUIM',
    iconAsset: _ProfileScreenState._professionalCodeIcon,
  ),
  const _EditableField(
    key: 'cod_parafa',
    label: 'Cod parafă',
    iconAsset: _ProfileScreenState._signatureIcon,
  ),
];

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.onSave});

  final Future<void> Function(String currentPassword, String newPassword)
  onSave;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_currentController.text, _newController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _fieldDecoration(
    String label, {
    required String iconAsset,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: _DecorativeIconSlot(iconAsset),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ProfileScreenState._pink,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      labelStyle: const TextStyle(color: PulseTheme.textSecondary),
    );
  }

  Widget _visibilityButton({
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: _SvgIcon(
        visible
            ? _ProfileScreenState._eyeSlashIcon
            : _ProfileScreenState._eyeIcon,
        color: PulseTheme.textSecondary,
        size: 18,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Schimbă parola',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: PulseTheme.textSecondary,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _StatusBanner(message: _errorMessage!, isError: true),
              ),
            ],
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    TextFormField(
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: (val) => validators.requiredValidator(
                        val,
                        label: 'Parola curentă',
                      ),
                      decoration: _fieldDecoration(
                        'Parola curentă',
                        iconAsset: _ProfileScreenState._keyIcon,
                        suffixIcon: _visibilityButton(
                          visible: !_obscureCurrent,
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newController,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: validators.passwordValidator,
                      decoration: _fieldDecoration(
                        'Parola nouă',
                        iconAsset: _ProfileScreenState._keyIcon,
                        suffixIcon: _visibilityButton(
                          visible: !_obscureNew,
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: (val) => validators.confirmPasswordValidator(
                        val,
                        _newController.text,
                      ),
                      decoration: _fieldDecoration(
                        'Confirmă parola nouă',
                        iconAsset: _ProfileScreenState._keyIcon,
                        suffixIcon: _visibilityButton(
                          visible: !_obscureConfirm,
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) => _isSaving ? null : _submit(),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                      child: Ink(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: _ProfileScreenState._accentGradient,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: InkWell(
                          onTap: _isSaving ? null : _submit,
                          borderRadius: BorderRadius.circular(17),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Salvează',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
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
    );
  }
}

class _ChangePasswordButton extends StatelessWidget {
  const _ChangePasswordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: _ProfileScreenState._accentGradient,
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SvgIcon(
                  _ProfileScreenState._keyIcon,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 9),
                Text(
                  'Schimbă parola',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
