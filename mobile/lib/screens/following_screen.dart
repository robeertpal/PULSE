import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import 'author_profile_screen.dart';
import 'partner_profile_screen.dart';
import 'publication_issues_screen.dart';
import 'public_author_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<_FollowItem> _items = const [];
  final Set<String> _unfollowingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFollows();
  }

  Future<void> _loadFollows() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _apiService.getFollows();
      if (!mounted) return;
      setState(() {
        _items = rows.map(_FollowItem.fromJson).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollow(_FollowItem item) async {
    if (_unfollowingKeys.contains(item.key)) return;
    setState(() {
      _unfollowingKeys.add(item.key);
    });

    try {
      await _apiService.unfollowTarget(
        targetType: item.targetType,
        targetId: item.targetId,
      );
      if (!mounted) return;
      setState(() {
        _items = _items
            .where((candidate) => candidate.key != item.key)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nu mai urmărești ${item.displayName}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut elimina follow-ul.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _unfollowingKeys.remove(item.key);
        });
      }
    }
  }

  void _openTarget(_FollowItem item) {
    if (!item.isNavigable) return;

    Widget? screen;
    if (item.targetType == 'author') {
      screen = AuthorProfileScreen(
        authorId: item.targetId,
        initialName: item.displayName,
      );
    } else if (item.targetType == 'publication') {
      screen = PublicationIssuesScreen(
        publicationId: item.targetId,
        publicationName: item.displayName,
      );
    } else if (item.targetType == 'partner') {
      screen = PartnerProfileScreen(
        partnerId: item.targetId,
        initialName: item.displayName,
      );
    } else if (item.targetType == 'contributor') {
      screen = PublicAuthorProfileScreen(
        contributorUserId: item.targetId,
        initialName: item.displayName,
      );
    }

    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
  }

  Map<String, List<_FollowItem>> get _groupedItems {
    final grouped = <String, List<_FollowItem>>{
      'author': [],
      'publication': [],
      'partner': [],
      'contributor': [],
      'category': [],
      'specialization': [],
    };
    for (final item in _items) {
      grouped.putIfAbsent(item.targetType, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PulseTheme.textPrimary,
        title: const Text('Urmăresc'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadFollows);
    }

    if (_items.isEmpty) {
      return const _EmptyState();
    }

    final grouped = _groupedItems;
    final sections = [
      _FollowSectionDefinition('author', 'Autori', Icons.edit_rounded),
      _FollowSectionDefinition(
        'publication',
        'Publicații',
        Icons.menu_book_rounded,
      ),
      _FollowSectionDefinition('partner', 'Parteneri', Icons.business_rounded),
      _FollowSectionDefinition(
        'contributor',
        'Contributori',
        Icons.person_add_alt_1_rounded,
      ),
      _FollowSectionDefinition('category', 'Categorii', Icons.category_rounded),
      _FollowSectionDefinition(
        'specialization',
        'Specializări',
        Icons.medical_services_rounded,
      ),
    ];

    return RefreshIndicator(
      color: PulseTheme.primaryLight,
      onRefresh: _loadFollows,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const _Header(),
          const SizedBox(height: 18),
          for (final section in sections)
            if ((grouped[section.type] ?? const <_FollowItem>[]).isNotEmpty)
              _FollowSection(
                definition: section,
                items: grouped[section.type]!,
                loadingKeys: _unfollowingKeys,
                onOpen: _openTarget,
                onUnfollow: _unfollow,
              ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PulseTheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: PulseTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: PulseTheme.primaryGradient,
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urmăresc',
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Toate sursele, categoriile și specializările pe care le urmărești.',
                  style: TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _FollowSection extends StatelessWidget {
  const _FollowSection({
    required this.definition,
    required this.items,
    required this.loadingKeys,
    required this.onOpen,
    required this.onUnfollow,
  });

  final _FollowSectionDefinition definition;
  final List<_FollowItem> items;
  final Set<String> loadingKeys;
  final ValueChanged<_FollowItem> onOpen;
  final ValueChanged<_FollowItem> onUnfollow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(definition.icon, size: 18, color: PulseTheme.primaryLight),
                const SizedBox(width: 8),
                Text(
                  definition.title,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: PulseTheme.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FollowCard(
                item: item,
                isLoading: loadingKeys.contains(item.key),
                onOpen: item.isNavigable ? () => onOpen(item) : null,
                onUnfollow: () => onUnfollow(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowCard extends StatelessWidget {
  const _FollowCard({
    required this.item,
    required this.isLoading,
    required this.onUnfollow,
    this.onOpen,
  });

  final _FollowItem item;
  final bool isLoading;
  final VoidCallback? onOpen;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PulseTheme.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: PulseTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PulseTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PulseTheme.primaryLight.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(item.icon, color: PulseTheme.primaryLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        item.typeLabel,
                        if (item.followedAtLabel != null) item.followedAtLabel!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.isVerifiedContributor) ...[
                      const SizedBox(height: 7),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: PulseTheme.primaryLight,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Contributor verificat',
                            style: TextStyle(
                              color: PulseTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: isLoading ? null : onUnfollow,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Nu mai urmări'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PulseTheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: PulseTheme.cardShadow,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: PulseTheme.primaryLight,
                size: 40,
              ),
              SizedBox(height: 14),
              Text(
                'Nu urmărești nimic momentan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Urmărește autori, publicații, parteneri, categorii sau specializări pentru recomandări mai relevante.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseTheme.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: PulseTheme.primaryLight,
              size: 38,
            ),
            const SizedBox(height: 14),
            Text(
              'Nu am putut încărca lista.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reîncearcă'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowSectionDefinition {
  const _FollowSectionDefinition(this.type, this.title, this.icon);

  final String type;
  final String title;
  final IconData icon;
}

class _FollowItem {
  const _FollowItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.displayName,
    required this.createdAt,
    this.isVerifiedContributor = false,
    this.specializationName,
    this.institutionName,
  });

  final int id;
  final String targetType;
  final int targetId;
  final String displayName;
  final DateTime? createdAt;
  final bool isVerifiedContributor;
  final String? specializationName;
  final String? institutionName;

  String get key => '$targetType:$targetId';

  bool get isNavigable =>
      targetType == 'author' ||
      targetType == 'contributor' ||
      targetType == 'publication' ||
      targetType == 'partner';

  IconData get icon {
    switch (targetType) {
      case 'author':
        return Icons.edit_rounded;
      case 'contributor':
        return Icons.person_add_alt_1_rounded;
      case 'publication':
        return Icons.menu_book_rounded;
      case 'partner':
        return Icons.business_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'specialization':
        return Icons.medical_services_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  String get typeLabel {
    switch (targetType) {
      case 'author':
        return 'Autor';
      case 'contributor':
        return [
          'Contributor',
          if (specializationName != null) specializationName!,
          if (institutionName != null) institutionName!,
        ].join(' • ');
      case 'publication':
        return 'Publicație';
      case 'partner':
        return 'Partener';
      case 'category':
        return 'Categorie';
      case 'specialization':
        return 'Specializare';
      default:
        return 'Urmărit';
    }
  }

  String? get followedAtLabel {
    final value = createdAt;
    if (value == null) return null;
    return 'urmărit din ${_formatDate(value)}';
  }

  factory _FollowItem.fromJson(Map<String, dynamic> json) {
    final targetType = json['target_type']?.toString().trim().toLowerCase();
    final targetId = _asInt(json['target_id']);
    return _FollowItem(
      id: _asInt(json['id']) ?? 0,
      targetType: targetType?.isNotEmpty == true ? targetType! : 'unknown',
      targetId: targetId ?? 0,
      displayName:
          _firstText([
            json['target_name'],
            json['contributor_name'],
            json['publication_name'],
            json['category_name'],
            json['specialization_name'],
            _nestedText(json['public_contributor'], 'display_name'),
            _nestedText(json['author'], 'full_name'),
            _nestedText(json['author'], 'name'),
            _nestedText(json['partner'], 'name'),
          ]) ??
          _fallbackName(targetType, targetId),
      createdAt: _parseDate(json['created_at']),
      isVerifiedContributor:
          json['is_verified_contributor'] == true ||
          json['contributor_is_verified'] == true ||
          json['public_contributor']?['is_verified_contributor'] == true,
      specializationName: _firstText([
        json['specialization_name'],
        json['contributor_specialization_name'],
        _nestedText(json['public_contributor'], 'specialization_name'),
      ]),
      institutionName: _firstText([
        json['institution_name'],
        json['contributor_institution_name'],
        _nestedText(json['public_contributor'], 'institution_name'),
      ]),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _nestedText(Object? value, String key) {
    if (value is! Map) return null;
    final raw = value[key];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _firstText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static DateTime? _parseDate(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _fallbackName(String? targetType, int? targetId) {
    final id = targetId == null || targetId <= 0 ? '' : ' #$targetId';
    switch (targetType) {
      case 'author':
        return 'Autor$id';
      case 'contributor':
        return 'Contributor$id';
      case 'publication':
        return 'Publicație$id';
      case 'partner':
        return 'Partener$id';
      case 'category':
        return 'Categorie$id';
      case 'specialization':
        return 'Specializare$id';
      default:
        return 'Element urmărit$id';
    }
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
