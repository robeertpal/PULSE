import 'package:flutter/material.dart';

import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/pulse_animated_background.dart';

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

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<ContentItem> _items = [];
  Set<int> _savedContentIds = {};
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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

  int get _contentCount {
    final value = _profile?['content_count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return _items.length;
  }

  int get _upcomingEventCount {
    final value = _profile?['upcoming_event_count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _apiService.getPartnerProfile(widget.partnerId);
      final contentFuture = _apiService.getPartnerContent(widget.partnerId);
      final savedFuture = _apiService.getSavedContentIds();
      final followFuture = _apiService.getFollowStatus(
        targetType: 'partner',
        targetId: widget.partnerId,
      );

      final profile = await profileFuture;
      final items = await contentFuture;
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut incarca profilul partenerului.';
      });
    }
  }

  Future<void> _loadSavedIds() async {
    try {
      final savedIds = await _apiService.getSavedContentIds();
      if (!mounted) return;
      setState(() {
        _savedContentIds = savedIds;
      });
    } catch (_) {
      // Saved state is useful, but not required for reading this page.
    }
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
          behavior: SnackBarBehavior.floating,
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
        const SnackBar(
          content: Text('Nu am putut actualiza salvarea'),
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowing = wasFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut actualiza follow-ul.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  Widget _buildLogo() {
    final logoUrl = _logoUrl;
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: PulseTheme.primaryGradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: logoUrl != null &&
                (logoUrl.startsWith('http://') ||
                    logoUrl.startsWith('https://'))
            ? Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoFallback(),
              )
            : _buildLogoFallback(),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      color: PulseTheme.surfaceElevated,
      child: Center(
        child: Text(
          _initials(_displayName),
          style: const TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return OutlinedButton.icon(
      onPressed: _isFollowLoading ? null : _toggleFollow,
      style: OutlinedButton.styleFrom(
        foregroundColor: _isFollowing
            ? PulseTheme.textPrimary
            : PulseTheme.primaryLight,
        side: BorderSide(
          color: _isFollowing
              ? Colors.white.withValues(alpha: 0.18)
              : PulseTheme.primaryLight.withValues(alpha: 0.42),
        ),
        backgroundColor: _isFollowing
            ? Colors.white.withValues(alpha: 0.10)
            : PulseTheme.primary.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: _isFollowLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFollowing
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              size: 18,
            ),
      label: Text(
        _isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final websiteUrl = _websiteUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: PulseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    if (websiteUrl != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        websiteUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PulseTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  _contentCount.toString(),
                  _contentCount == 1 ? 'material public' : 'materiale publice',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStat(
                  _upcomingEventCount.toString(),
                  _upcomingEventCount == 1
                      ? 'eveniment viitor'
                      : 'evenimente viitoare',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFollowButton(),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Text(
          'Nu exista continut public pentru acest partener momentan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continut asociat',
          style: TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PulseTheme.primaryLight),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PulseTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _loadProfile,
                child: const Text('Reincearca'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: PulseTheme.primaryLight,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildContentList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(title: const Text('Profil partener')),
      body: Stack(
        children: [
          const Positioned.fill(child: PulseAnimatedBackground()),
          _buildBody(),
        ],
      ),
    );
  }
}
