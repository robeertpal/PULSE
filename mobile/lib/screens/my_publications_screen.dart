import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/skeleton_loading.dart';
import 'publication_issues_screen.dart';
import 'profile_screen.dart';

class MyPublicationsScreen extends StatefulWidget {
  const MyPublicationsScreen({super.key});

  @override
  State<MyPublicationsScreen> createState() => _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends State<MyPublicationsScreen> {
  static const Color _black = Color(0xFFFFFBFE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _pink = PulseTheme.magazineContent;
  static const String _subscriptionIcon = 'assets/icons/books.svg';
  static const String _calendarIcon = 'assets/icons/calendar.svg';
  static const String _cardIcon = 'assets/icons/creditcard.svg';
  static const String _arrowIcon = 'assets/icons/arrow.right.svg';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getMySubscriptions();
      if (!mounted) return;
      setState(() {
        _subscriptions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(Object? isoDate) {
    if (isoDate == null) return 'permanent';
    try {
      final dt = DateTime.parse(isoDate.toString()).toLocal();
      const months = [
        'Ian',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Iun',
        'Iul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      return '$day ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate.toString();
    }
  }

  String _periodLabel(Map<String, dynamic> subscription) {
    final start = _formatDate(subscription['start_date']);
    final end = _formatDate(subscription['end_date']);
    return 'de la $start până la $end';
  }

  String _statusLabel(Object? value, bool accessValid) {
    switch (value?.toString()) {
      case 'active':
        return 'Activ';
      case 'cancelled':
        return accessValid ? 'Anulat, acces activ' : 'Anulat';
      case 'expired':
        return 'Expirat';
      case 'suspended':
        return 'Suspendat';
      default:
        return 'Abonament';
    }
  }

  Widget _assetIcon(String asset, {double size = 16, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _buildMetaRow(String iconAsset, String text) {
    return Row(
      children: [
        _assetIcon(
          iconAsset,
          size: 14,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(String text, bool accessValid) {
    final color = accessValid ? _pink : Colors.white.withValues(alpha: 0.45);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSubscription(Map<String, dynamic> subscription) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionDetailScreen(subscription: subscription),
      ),
    );
    if (updated == true) {
      _loadSubscriptions();
    }
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final title =
        subscription['publication_name']?.toString() ??
        subscription['title']?.toString() ??
        subscription['plan_name']?.toString() ??
        'Abonament PULSE';
    final planName = subscription['plan_name']?.toString() ?? 'Revistă PULSE';
    final billing = subscription['billing_period_label']?.toString() ?? '';
    final price = subscription['price'];
    final currency = subscription['currency']?.toString() ?? 'RON';
    final accessValid = subscription['access_valid'] == true;
    final status = _statusLabel(subscription['status'], accessValid);
    final priceText = price == null ? currency : '$price $currency';

    return GestureDetector(
      onTap: () => _openSubscription(subscription),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: _assetIcon(_subscriptionIcon, size: 24, color: _pink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatus(status, accessValid),
                    const SizedBox(height: 6),
                    _buildMetaRow(_calendarIcon, _periodLabel(subscription)),
                    const SizedBox(height: 6),
                    _buildMetaRow(_cardIcon, '$planName, $billing, $priceText'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _openSubscription(subscription),
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _assetIcon(
                        _arrowIcon,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SkeletonBlock(height: 128, radius: 20),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _assetIcon(
              _subscriptionIcon,
              size: 52,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 16),
            const Text(
              'A apărut o eroare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadSubscriptions,
              style: TextButton.styleFrom(foregroundColor: _pink),
              child: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _assetIcon(
              _subscriptionIcon,
              size: 52,
              color: _pink.withValues(alpha: 0.86),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nu ai abonamente încă.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Abonamentele la reviste vor apărea aici după activare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
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
        toolbarHeight: 76,
        leadingWidth: 72,
        titleSpacing: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ProfileBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const ProfileGradientHeading('Abonamentele mele'),
      ),
      body: _isLoading
          ? _buildSkeletons()
          : _errorMessage != null
          ? _buildErrorState()
          : _subscriptions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _pink,
              backgroundColor: _surface,
              onRefresh: _loadSubscriptions,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _subscriptions.length,
                itemBuilder: (context, index) {
                  return _buildSubscriptionCard(_subscriptions[index]);
                },
              ),
            ),
    );
  }
}

class SubscriptionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  static const Color _black = Color(0xFFFFFBFE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _pink = PulseTheme.magazineContent;

  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _subscription;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subscription = Map<String, dynamic>.from(widget.subscription);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = _readInt(_subscription['id']);
    if (id == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await _apiService.getMySubscriptionDetail(id);
      if (!mounted) return;
      setState(() {
        _subscription = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _readText(Object? value, String fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _formatDate(Object? isoDate) {
    if (isoDate == null) return 'permanent';
    try {
      final dt = DateTime.parse(isoDate.toString()).toLocal();
      const months = [
        'Ian',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Iun',
        'Iul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      return '$day ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate.toString();
    }
  }

  String _subscriptionPeriodText() {
    final start = _formatDate(_subscription['start_date']);
    final endRaw = _subscription['end_date'];
    if (endRaw == null) {
      return 'de la $start, acces permanent';
    }
    return 'de la $start până la ${_formatDate(endRaw)}';
  }

  String _statusLabel(Object? value, bool accessValid) {
    switch (value?.toString()) {
      case 'active':
        return 'Activ';
      case 'cancelled':
        return accessValid ? 'Anulat, acces activ' : 'Anulat';
      case 'expired':
        return 'Expirat';
      case 'suspended':
        return 'Suspendat';
      default:
        return 'Abonament';
    }
  }

  Widget _assetIcon(String asset, {double size = 18, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Future<void> _confirmCancel() async {
    final id = _readInt(_subscription['id']);
    if (id == null || _isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Dezabonare',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Reînnoirea automată va fi dezactivată. Accesul tău rămâne activ până la data deja plătită.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Renunță',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmă',
              style: TextStyle(color: _pink, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final result = await _apiService.cancelMySubscription(id);
      if (!mounted) return;
      setState(() {
        _subscription = result;
        _isCancelling = false;
      });
      await _showCancelledPopup(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCancelledPopup(Map<String, dynamic> result) {
    final endDate = _formatDate(result['end_date']);
    final message =
        'Dezabonarea a fost înregistrată. Vei avea acces la revistă până la $endDate, iar abonamentul nu se va mai reînnoi automat.';

    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _pink.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: _pink, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirmat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Închide',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String iconAsset, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _assetIcon(
          iconAsset,
          size: 20,
          color: Colors.white.withValues(alpha: 0.38),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection({
    required String title,
    required String description,
    required String? imageUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF7F2F8),
                  child: Center(
                    child: _assetIcon(
                      'assets/icons/books.svg',
                      size: 42,
                      color: _pink,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                if (imageUrl == null) ...[
                  _assetIcon('assets/icons/books.svg', size: 36, color: _pink),
                  const SizedBox(height: 18),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPublication() {
    final publicationId = _readInt(_subscription['publication_id']);
    if (publicationId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PublicationIssuesScreen(
          publicationId: publicationId,
          contentItemId: _readInt(_subscription['content_item_id']),
          publicationName: _readText(
            _subscription['publication_name'],
            'Revistă PULSE',
          ),
          contentTitle: _optionalText(_subscription['content_title']),
          contentShortDescription: _optionalText(
            _subscription['publication_description'],
          ),
          contentHeroImageUrl: _optionalText(_subscription['hero_image_url']),
          contentThumbnailUrl: _optionalText(_subscription['thumbnail_url']),
          publicationDescription: _optionalText(
            _subscription['publication_description'],
          ),
          publicationLogoUrl: _optionalText(
            _subscription['publication_logo_url'],
          ),
          emcCreditsText: _optionalText(
            _subscription['publication_emc_credits_text'],
          ),
          creditationText: _optionalText(
            _subscription['publication_creditation_text'],
          ),
          indexingText: _optionalText(
            _subscription['publication_indexing_text'],
          ),
          subscriptionUrl: _optionalText(
            _subscription['publication_subscription_url'],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
  }) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          color: enabled
              ? destructive
                    ? Colors.white.withValues(alpha: 0.08)
                    : _pink
              : Colors.white.withValues(alpha: 0.06),
          border: destructive
              ? Border.all(color: _pink.withValues(alpha: 0.4))
              : null,
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Center(
            child: _isCancelling && destructive
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _pink,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? destructive
                                ? _pink
                                : Colors.white
                          : Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _readText(_subscription['plan_name'], 'Abonament revistă');
    final publication = _readText(
      _subscription['publication_name'] ?? _subscription['publication_title'],
      'Revistă PULSE',
    );
    final accessValid = _subscription['access_valid'] == true;
    final status = _statusLabel(_subscription['status'], accessValid);
    final billing = _readText(
      _subscription['billing_period_label'],
      'abonament',
    );
    final price = _subscription['price'];
    final currency = _readText(_subscription['currency'], 'RON');
    final priceText = price == null ? currency : '$price $currency';
    final isRecurring = _subscription['is_recurring'] == true;
    final autoRenew = _subscription['auto_renew'] == true;
    final canCancel = autoRenew && _subscription['status'] != 'cancelled';
    final emcPoints = _readText(
      _subscription['publication_emc_credits_text'],
      'Neconfigurate',
    );
    final canOpenPublication =
        _readInt(_subscription['publication_id']) != null;
    final heroImage =
        _optionalText(_subscription['hero_image_url']) ??
        _optionalText(_subscription['thumbnail_url']) ??
        _optionalText(_subscription['publication_logo_url']);
    final heroDescription = _readText(
      _subscription['publication_description'] ??
          _subscription['content_title'],
      publication,
    );

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  ProfileBackButton(
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: ProfileGradientHeading('Detalii abonament'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _pink))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          _buildHeroSection(
                            title: title,
                            description: heroDescription,
                            imageUrl: heroImage,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'assets/icons/calendar.svg',
                                    'Perioadă abonament',
                                    _subscriptionPeriodText(),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/checkmark.svg',
                                    'Status abonament',
                                    status,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/settings.svg',
                                    'Auto Renew',
                                    autoRenew ? 'Activ' : 'Inactiv',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/EMC.svg',
                                    'Puncte EMC',
                                    emcPoints,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/creditcard.svg',
                                    'Facturare',
                                    billing,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/wallet.svg',
                                    'Preț',
                                    priceText,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'assets/icons/AI.svg',
                                    'Recurență',
                                    isRecurring ? 'Recurent' : 'Nerecurent',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildActionButton(
                            label: 'Vezi revista',
                            onPressed: canOpenPublication
                                ? _openPublication
                                : null,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _buildActionButton(
                            label: 'Dezabonare',
                            onPressed: canCancel ? _confirmCancel : null,
                            destructive: true,
                          ),
                          const SizedBox(height: 32),
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
