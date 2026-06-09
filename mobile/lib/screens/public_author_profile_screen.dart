import 'package:flutter/material.dart';

import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/pulse_animated_background.dart';

class PublicAuthorProfileScreen extends StatefulWidget {
  final int? authorId;
  final int? contributorUserId;
  final String? initialName;
  final String? initialPhotoUrl;
  final String? initialBio;

  const PublicAuthorProfileScreen({
    super.key,
    this.authorId,
    this.contributorUserId,
    this.initialName,
    this.initialPhotoUrl,
    this.initialBio,
  }) : assert(authorId != null || contributorUserId != null);

  @override
  State<PublicAuthorProfileScreen> createState() =>
      _PublicAuthorProfileScreenState();
}

class _PublicAuthorProfileScreenState extends State<PublicAuthorProfileScreen> {
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

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String get _displayName =>
      _clean(_profile?['display_name']) ??
      _clean(_profile?['name']) ??
      _clean(_profile?['full_name']) ??
      _clean(widget.initialName) ??
      'Contributor PULSE';

  String? get _photoUrl =>
      _clean(_profile?['photo_url']) ?? _clean(widget.initialPhotoUrl);

  String? get _bio => _clean(_profile?['bio']) ?? _clean(widget.initialBio);

  String? get _role =>
      _clean(_profile?['public_role']) ??
      _clean(_profile?['role']) ??
      _clean(_profile?['title']) ??
      _clean(_profile?['occupation_name']);

  String? get _specializationName => _clean(_profile?['specialization_name']);

  String? get _institutionName => _clean(_profile?['institution_name']);

  bool get _isVerified => _profile?['is_verified_contributor'] == true;

  int? get _followersCount {
    final value = _profile?['followers_count'] ?? _profile?['follower_count'];
    if (value == null) return null;
    return _asInt(value);
  }

  int get _publishedCount => _asInt(
    _profile?['published_count'] ?? _profile?['published_content_count'],
    fallback: _items.length,
  );

  String? get _followTargetType {
    if (widget.contributorUserId != null) return 'contributor';
    if (widget.authorId != null) return 'author';
    return null;
  }

  int? get _followTargetId => widget.contributorUserId ?? widget.authorId;

  bool get _canFollowProfile =>
      _followTargetType != null && _followTargetId != null;

  String get _followTargetLabel =>
      _followTargetType == 'contributor' ? 'contributor' : 'autor';

  List<String> _stringList(String key) {
    final raw = _profile?[key];
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> get _specializations {
    final values = <String>[
      if (_specializationName != null) _specializationName!,
      ..._stringList('specialization_names'),
    ];
    return values.toSet().toList();
  }

  List<String> get _categories => _stringList('category_names');

  List<String> get _editorialAreas {
    final explicit = _stringList('editorial_areas');
    if (explicit.isNotEmpty) return explicit;
    return [..._specializations, ..._categories].toSet().toList();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authorId = widget.authorId;
      final contributorUserId = widget.contributorUserId;
      final profileFuture = contributorUserId != null
          ? _apiService.getPublicContributorProfile(contributorUserId)
          : _apiService.getAuthorProfile(authorId!);
      final contentFuture = contributorUserId != null
          ? _apiService.getPublicContributorContent(contributorUserId)
          : _apiService.getAuthorContent(authorId!);
      final savedFuture = _apiService.getSavedContentIds();
      final followTargetType = _followTargetType;
      final followTargetId = _followTargetId;
      final followFuture = followTargetType != null && followTargetId != null
          ? _apiService.getFollowStatus(
              targetType: followTargetType,
              targetId: followTargetId,
            )
          : Future<bool>.value(false);

      final profile = await profileFuture;
      final content = await contentFuture;
      var savedIds = <int>{};
      var isFollowing = false;

      try {
        savedIds = await savedFuture;
      } catch (_) {
        savedIds = <int>{};
      }

      try {
        isFollowing = await followFuture;
      } catch (_) {
        isFollowing = false;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _items = content;
        _savedContentIds = savedIds;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut încărca profilul contributorului.';
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
      // The saved state should not block reading a public profile.
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
    final targetType = _followTargetType;
    final targetId = _followTargetId;
    if (targetType == null || targetId == null) return;
    final wasFollowing = _isFollowing;
    final previousFollowersCount = _followersCount;
    setState(() {
      _isFollowing = !wasFollowing;
      _isFollowLoading = true;
      if (previousFollowersCount != null && _profile != null) {
        final nextFollowersCount = wasFollowing
            ? (previousFollowersCount > 0 ? previousFollowersCount - 1 : 0)
            : previousFollowersCount + 1;
        _profile = {
          ..._profile!,
          'follower_count': nextFollowersCount,
          'followers_count': nextFollowersCount,
        };
      }
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: targetType,
          targetId: targetId,
        );
      } else {
        await _apiService.followTarget(
          targetType: targetType,
          targetId: targetId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urmărești acest $_followTargetLabel.'
                : 'Urmărești acest $_followTargetLabel.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowing = wasFollowing;
        if (previousFollowersCount != null && _profile != null) {
          _profile = {
            ..._profile!,
            'follower_count': previousFollowersCount,
            'followers_count': previousFollowersCount,
          };
        }
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

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  Widget _buildAvatar() {
    final photoUrl = _photoUrl;
    return Container(
      width: 94,
      height: 94,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: PulseTheme.primaryGradient,
      ),
      child: ClipOval(
        child:
            photoUrl != null &&
                (photoUrl.startsWith('http://') ||
                    photoUrl.startsWith('https://'))
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAvatarFallback(),
              )
            : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: PulseTheme.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    if (!_isVerified) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: PulseTheme.primaryGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: PulseTheme.coloredShadow(PulseTheme.primary),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text(
            'Contributor verificat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    if (!_canFollowProfile) return const SizedBox.shrink();
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
            : PulseTheme.primary.withValues(alpha: 0.12),
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
        _isFollowing ? 'Urmărești' : 'Urmărește',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PulseTheme.primaryLight),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PulseTheme.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bio = _bio;
    final role = _role;
    final chips = [
      if (_specializationName != null)
        (_specializationName!, Icons.medical_services_outlined),
      if (_institutionName != null) (_institutionName!, Icons.apartment),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: PulseTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: PulseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVerifiedBadge(),
                    if (_isVerified) const SizedBox(height: 10),
                    Text(
                      _displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    if (role != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PulseTheme.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips) _buildInfoChip(chip.$1, chip.$2),
              ],
            ),
          ],
          if (bio != null) ...[
            const SizedBox(height: 18),
            Text(
              bio,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStat(
                '$_publishedCount',
                _publishedCount == 1
                    ? 'contribuție publicată'
                    : 'contribuții publicate',
              ),
              if (_followersCount != null) ...[
                const SizedBox(width: 10),
                _buildStat(
                  '${_followersCount!}',
                  _followersCount == 1 ? 'urmăritor' : 'urmăritori',
                ),
              ],
              const SizedBox(width: 10),
              _buildStat('${_editorialAreas.length}', 'arii editoriale'),
            ],
          ),
          if (_canFollowProfile) ...[
            const SizedBox(height: 18),
            _buildFollowButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildExpertiseSection() {
    final tags = [..._specializations, ..._categories].toSet().toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Arii editoriale',
          style: TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: PulseTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: PulseTheme.primaryLight.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ],
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
          'Nu există contribuții publicate momentan.',
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
          'Contribuții publicate',
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PulseTheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                color: PulseTheme.primaryLight,
                size: 38,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? 'Profilul nu este disponibil.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PulseTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reîncearcă'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PulseTheme.primaryLight),
      );
    }

    if (_errorMessage != null) return _buildErrorState();

    return RefreshIndicator(
      color: PulseTheme.primaryLight,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildExpertiseSection(),
          if (_specializations.isNotEmpty || _categories.isNotEmpty)
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
      appBar: AppBar(
        title: const Text('Profil contributor'),
        backgroundColor: Colors.transparent,
        foregroundColor: PulseTheme.textPrimary,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PulseAnimatedBackground()),
          _buildBody(),
        ],
      ),
    );
  }
}
