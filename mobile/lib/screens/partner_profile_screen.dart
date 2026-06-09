import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content_item.dart';
import '../services/api_service.dart';
import '../widgets/content_card.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';

class PartnerProfileScreen extends StatefulWidget {
  final int partnerId;
  final String? initialName;
  final String? initialLogoUrl;
  final String? initialWebsiteUrl;

  const PartnerProfileScreen({
    super.key,
    required this.partnerId,
    this.initialName,
    this.initialLogoUrl,
    this.initialWebsiteUrl,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _black = Color(0xFFFFFBFE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceSoft = Color(0xFFF7F2F8);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _orange = Color(0xFFFF8A2A);
  static const LinearGradient _accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_pink, _orange],
  );

  // ── State ──────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<ContentItem> _items = [];
  Set<int> _savedContentIds = {};
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  String? _errorMessage;

  late final AnimationController _heroController;
  late final Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  // ── Data helpers ───────────────────────────────────────────────────────────
  String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String get _displayName =>
      _clean(_profile?['name']) ?? _clean(widget.initialName) ?? 'Partener';

  String? get _logoUrl =>
      _clean(_profile?['logo_url']) ?? _clean(widget.initialLogoUrl);

  String? get _websiteUrl =>
      _clean(_profile?['website_url']) ?? _clean(widget.initialWebsiteUrl);

  String? get _description => _clean(_profile?['description']);

  int get _followersCount {
    final value = _profile?['followers_count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _formatFollowers(int count) {
    // Romanian locale-style thousands separator with dot
    final String grouped;
    if (count >= 1000) {
      final thousands = count ~/ 1000;
      final remainder = count % 1000;
      grouped = remainder == 0
          ? '$thousands.000'
          : '$thousands.${remainder.toString().padLeft(3, '0')}';
    } else {
      grouped = count.toString();
    }
    return count == 1 ? '$grouped urmăritor' : '$grouped urmăritori';
  }

  List<ContentItem> _parseContentItems(dynamic rawContents) {
    if (rawContents is! List) return const [];
    final items = <ContentItem>[];
    for (final rawItem in rawContents) {
      if (rawItem is! Map<String, dynamic>) continue;
      try {
        items.add(ContentItem.fromJson(rawItem));
      } catch (error) {
        debugPrint('Ignored invalid partner content item: $error');
      }
    }
    return items;
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  // ── API calls ──────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _apiService.getPartnerProfile(widget.partnerId);
      final savedFuture = _apiService.getSavedContentIds();
      final followFuture = _apiService.getFollowStatus(
        targetType: 'partner',
        targetId: widget.partnerId,
      );

      final profile = await profileFuture;
      final rawContents = profile['contents'];
      final items = rawContents is List
          ? _parseContentItems(rawContents)
          : await _apiService.getPartnerContent(widget.partnerId);

      Set<int> savedIds = {};
      var isFollowing = false;
      try {
        savedIds = await savedFuture;
      } catch (_) {
        savedIds = {};
      }
      try {
        isFollowing = await followFuture;
      } catch (_) {
        isFollowing = false;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _items = items;
        _savedContentIds = savedIds;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
      _heroController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut incarca profilul partenerului.';
      });
    }
  }

  Future<void> _openWebsite() async {
    final websiteUrl = _websiteUrl;
    if (websiteUrl == null) return;

    final normalized =
        websiteUrl.startsWith('http://') || websiteUrl.startsWith('https://')
        ? websiteUrl
        : 'https://$websiteUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nu am putut deschide site-ul partenerului.'),
          backgroundColor: _surfaceSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _loadSavedIds() async {
    try {
      final savedIds = await _apiService.getSavedContentIds();
      if (!mounted) return;
      setState(() => _savedContentIds = savedIds);
    } catch (_) {}
  }

  Future<void> _toggleSavedContent(int contentItemId) async {
    final wasSaved = _savedContentIds.contains(contentItemId);
    setState(() {
      if (wasSaved) {
        _savedContentIds.remove(contentItemId);
      } else {
        _savedContentIds.add(contentItemId);
      }
    });

    try {
      if (wasSaved) {
        await _apiService.unsaveContent(contentItemId);
      } else {
        await _apiService.saveContent(contentItemId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSaved ? 'Eliminat din salvate' : 'Salvat'),
          backgroundColor: _surfaceSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedContentIds.add(contentItemId);
        } else {
          _savedContentIds.remove(contentItemId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nu am putut actualiza salvarea'),
          backgroundColor: _surfaceSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _isFollowLoading = true;
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: 'partner',
          targetId: widget.partnerId,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'partner',
          targetId: widget.partnerId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urmaresti aceasta organizatie.'
                : 'Urmaresti aceasta organizatie.',
          ),
          backgroundColor: _surfaceSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFollowing = wasFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nu am putut actualiza follow-ul.'),
          backgroundColor: _surfaceSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  /// Renders a small SVG icon with optional color filter.
  Widget _svgIcon(String asset, {double size = 16, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Glass card consistent with profile_screen _GlassCard.
  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.86),
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

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogoImage() {
    final logoUrl = _logoUrl;
    final hasValidUrl =
        logoUrl != null &&
        (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'));

    if (!hasValidUrl) {
      return _buildLogoFallback();
    }
    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildLogoFallback(),
    );
  }

  Widget _buildLogoFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _accentGradient),
      child: Center(
        child: Text(
          _initials(_displayName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // Gradient ring (roz-portocaliu) — 3px ring — dark gap — logo inside
    return Container(
      width: 106,
      height: 106,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _accentGradient,
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFFFFF), // thin light gap between ring and logo
        ),
        padding: const EdgeInsets.all(4),
        child: ClipOval(child: _buildLogoImage()),
      ),
    );
  }

  // ── Follow button ─────────────────────────────────────────────────────────
  Widget _buildFollowButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: _isFollowing
          ? Ink(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: InkWell(
                onTap: _isFollowLoading ? null : _toggleFollow,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isFollowLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : _svgIcon(
                              'assets/icons/checkmark.svg',
                              size: 15,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 8),
                      const Text(
                        'Urmărești',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Ink(
              decoration: BoxDecoration(
                gradient: _accentGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: InkWell(
                onTap: _isFollowLoading ? null : _toggleFollow,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isFollowLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : _svgIcon(
                              'assets/icons/people.svg',
                              size: 16,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 8),
                      const Text(
                        'Urmărește',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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

  // ── Website button ────────────────────────────────────────────────────────
  Widget _buildWebsiteButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _orange.withValues(alpha: 0.30)),
        ),
        child: InkWell(
          onTap: _openWebsite,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _svgIcon('assets/icons/globe.svg', size: 16, color: _orange),
                const SizedBox(width: 8),
                const Text(
                  'Site partener',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  // ── Hero / Header card ─────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final websiteUrl = _websiteUrl;
    final description = _description;

    return _glassCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo ────────────────────────────────────────────────────────
          _buildLogo(),

          const SizedBox(height: 18),

          // ── Partner name + verified icon ────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) =>
                    _accentGradient.createShader(bounds),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Followers count ────────────────────────────────────────────
          Text(
            _formatFollowers(_followersCount),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.46),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),

          if (description != null) ...[
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 24),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

          const SizedBox(height: 24),

          // ── Action buttons — centered ─────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFollowButton(),
              if (websiteUrl != null) _buildWebsiteButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ── Content section label ─────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: _accentGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Content list ───────────────────────────────────────────────────────────
  Widget _buildContentList() {
    if (_items.isEmpty) {
      return _glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: _svgIcon(
                  'assets/icons/books.svg',
                  size: 34,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Niciun conținut publicat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acest partener nu are conținut publicat momentan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Conținut publicat'),
        const SizedBox(height: 16),
        ..._items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 260,
              child: ContentCard.fromModel(
                item,
                isSaved: _savedContentIds.contains(item.id),
                onSaveToggle: _toggleSavedContent,
                onDetailClosed: _loadSavedIds,
                cardWidth: double.infinity,
                margin: EdgeInsets.zero,
                darkMode: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────
  Widget _buildSkeletons() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        const SkeletonBlock(height: 320, radius: 26),
        const SizedBox(height: 24),
        const SkeletonBlock(height: 20, radius: 8),
        const SizedBox(height: 14),
        const SkeletonBlock(height: 260, radius: 20),
        const SizedBox(height: 16),
        const SkeletonBlock(height: 260, radius: 20),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: _svgIcon(
                  'assets/icons/globe.svg',
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: _loadProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child: Text(
                      'Încearcă din nou',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
    );
  }

  // ── Main body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildSkeletons();
    if (_errorMessage != null) return _buildErrorState();

    return RefreshIndicator(
      color: _pink,
      backgroundColor: _surface,
      onRefresh: _loadProfile,
      child: FadeTransition(
        opacity: _heroFade,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 28),
            _buildContentList(),
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
        title: const ProfileGradientHeading('Profil partener'),
      ),
      body: _buildBody(),
    );
  }
}
