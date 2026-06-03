import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/pulse_animated_background.dart';

class AuthorProfileScreen extends StatefulWidget {
  final int authorId;
  final String? initialName;
  final String? initialPhotoUrl;
  final String? initialBio;

  const AuthorProfileScreen({
    super.key,
    required this.authorId,
    this.initialName,
    this.initialPhotoUrl,
    this.initialBio,
  });

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
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

  String get _displayName {
    return _clean(_profile?['display_name']) ??
        _clean(_profile?['full_name']) ??
        _clean(widget.initialName) ??
        'Autor PULSE';
  }

  String? get _photoUrl =>
      _clean(_profile?['photo_url']) ?? _clean(widget.initialPhotoUrl);

  String? get _bio => _clean(_profile?['bio']) ?? _clean(widget.initialBio);

  List<String> get _specializations {
    final raw = _profile?['specialization_names'];
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _apiService.getAuthorProfile(widget.authorId);
      final contentFuture = _apiService.getAuthorContent(widget.authorId);
      final savedFuture = _apiService.getSavedContentIds();
      final followFuture = _apiService.getFollowStatus(
        targetType: 'author',
        targetId: widget.authorId,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut incarca profilul autorului.';
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
      // Saved state is helpful, but not required for reading the author page.
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
          targetType: 'author',
          targetId: widget.authorId,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'author',
          targetId: widget.authorId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urmaresti acest autor.'
                : 'Urmaresti acest autor.',
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

  Widget _buildAvatar() {
    final photoUrl = _photoUrl;
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: PulseTheme.primaryGradient,
      ),
      child: ClipOval(
        child: photoUrl != null &&
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
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'A'
        : parts.map((part) => part[0].toUpperCase()).take(2).join();
    return Container(
      color: PulseTheme.surfaceElevated,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 26,
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

  Widget _buildHeader() {
    final bio = _bio;
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
              _buildAvatar(),
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
                    if (_specializations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _specializations.take(2).join(' • '),
                        maxLines: 2,
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
          if (bio != null) ...[
            const SizedBox(height: 18),
            Text(
              bio,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 14,
                height: 1.48,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _buildFollowButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _items.length == 1
                      ? '1 material publicat'
                      : '${_items.length} materiale publicate',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
          'Nu exista continut publicat de acest autor momentan.',
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
          'Continut publicat',
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
      appBar: AppBar(title: const Text('Profil autor')),
      body: Stack(
        children: [
          const Positioned.fill(child: PulseAnimatedBackground()),
          _buildBody(),
        ],
      ),
    );
  }
}
