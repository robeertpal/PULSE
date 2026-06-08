import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import 'author_profile_screen.dart';
import 'partner_profile_screen.dart';
import '../widgets/ai_summary.dart';
import '../widgets/content_card.dart';
import '../widgets/content_type_badge.dart';
import '../widgets/emc_badge.dart';
import '../widgets/favorite_button.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/event_payment_modal.dart';

class ContentDetailScreen extends StatefulWidget {
  final int contentItemId;
  final bool initiallySaved;

  const ContentDetailScreen({
    super.key,
    required this.contentItemId,
    this.initiallySaved = false,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  static const String _backIcon = 'assets/icons/arrow.backward.svg';
  static const String _checkIcon = 'assets/icons/checkmark.svg';
  static const String _courseIcon = 'assets/icons/graduation.svg';
  static const String _eventIcon = 'assets/icons/events.svg';
  static const String _newsIcon = 'assets/icons/newspaper.svg';
  static const String _calendarIcon = 'assets/icons/calendar.svg';
  static const String _eyeglassesIcon = 'assets/icons/eyeglasses.svg';
  static const String _buildingIcon = 'assets/icons/building.svg';
  static const String _walletIcon = 'assets/icons/wallet.svg';
  static const String _peopleIcon = 'assets/icons/people.svg';

  final ApiService _apiService = ApiService();
  ContentItem? _item;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isAiSummaryLoading = false;
  String? _errorMessage;
  String? _aiSummary;
  List<String> _aiKeyPoints = [];
  String? _aiDisclaimer;
  String? _aiSummaryError;
  Set<int> _savedContentIds = {};
  List<ContentItem> _recommendations = [];
  DateTime? _openedAt;
  bool _didTrackView = false;
  bool _isEventRegistered = false;
  String? _eventRegistrationStatus;
  String? _eventTicketCode;
  bool _isRegisteringEvent = false;
  bool _isCourseEnrolled = false;
  bool _isEnrollingCourse = false;
  bool _isFollowingAuthor = false;
  bool _isAuthorFollowLoading = false;
  bool _isFollowingCategory = false;
  bool _isCategoryFollowLoading = false;
  bool _isFollowingSpecialization = false;
  bool _isSpecializationFollowLoading = false;
  Set<int> _followedPartnerIds = {};
  final Set<int> _partnerFollowLoadingIds = {};

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
    _loadDetail();
  }

  @override
  void dispose() {
    final item = _item;
    final openedAt = _openedAt;
    if (item != null && openedAt != null) {
      final timeSpentSeconds = DateTime.now().difference(openedAt).inSeconds;
      if (timeSpentSeconds > 0) {
        final estimatedReadSeconds = _estimatedReadSeconds(item);
        unawaited(
          _apiService.trackUserActivity(
            actionType: 'content_dwell',
            contentItemId: item.id,
            metadata: _activityMetadataFor(
              item,
              source: 'content_detail',
              timeSpentSeconds: timeSpentSeconds,
              estimatedReadSeconds: estimatedReadSeconds,
            ),
          ),
        );
      }
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detailFuture = _apiService.getContentItemDetail(
        widget.contentItemId,
      );
      final savedIdsFuture = _apiService.getSavedContentIds();
      final detail = await detailFuture;
      final savedIds = await savedIdsFuture;

      final item = ContentItem.fromJson(detail);
      var isFollowingAuthor = false;
      var isFollowingCategory = false;
      var isFollowingSpecialization = false;
      if (item.authorId != null) {
        try {
          isFollowingAuthor = await _apiService.getFollowStatus(
            targetType: 'author',
            targetId: item.authorId!,
          );
        } catch (e) {
          debugPrint('Author follow status ignored: $e');
        }
      }
      if (item.categoryId != null) {
        try {
          isFollowingCategory = await _apiService.getFollowStatus(
            targetType: 'category',
            targetId: item.categoryId!,
          );
        } catch (e) {
          debugPrint('Category follow status ignored: $e');
        }
      }
      if (item.specializationId != null) {
        try {
          isFollowingSpecialization = await _apiService.getFollowStatus(
            targetType: 'specialization',
            targetId: item.specializationId!,
          );
        } catch (e) {
          debugPrint('Specialization follow status ignored: $e');
        }
      }
      final followedPartnerIds = <int>{};
      for (final partner in item.eventPartners) {
        try {
          final isFollowing = await _apiService.getFollowStatus(
            targetType: 'partner',
            targetId: partner.id,
          );
          if (isFollowing) {
            followedPartnerIds.add(partner.id);
          }
        } catch (e) {
          debugPrint('Partner follow status ignored: $e');
        }
      }
      final recommendations = await _loadRecommendationsFor(item);
      if (!_didTrackView) {
        _didTrackView = true;
        _openedAt = DateTime.now();
        unawaited(
          _apiService.trackUserActivity(
            actionType: 'content_view',
            contentItemId: item.id,
            metadata: _activityMetadataFor(item, source: 'content_detail'),
          ),
        );
      }

      if (item.contentType == 'event' && item.eventId != null) {
        try {
          final regData = await _apiService.checkEventRegistration(
            item.eventId!,
          );
          _isEventRegistered = regData['is_registered'] == true;
          _eventRegistrationStatus = regData['status'];
          _eventTicketCode = regData['ticket_code'];
        } catch (e) {
          debugPrint('Error checking event registration: $e');
        }
      }

      if (item.contentType == 'course' && item.courseId != null) {
        try {
          final enrollmentData = await _apiService.checkCourseEnrollment(
            item.courseId!,
          );
          _isCourseEnrolled = enrollmentData['is_enrolled'] == true;
        } catch (e) {
          debugPrint('Error checking course enrollment: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _item = item;
        _isSaved = savedIds.contains(widget.contentItemId);
        _savedContentIds = savedIds;
        _recommendations = recommendations;
        _isFollowingAuthor = isFollowingAuthor;
        _isFollowingCategory = isFollowingCategory;
        _isFollowingSpecialization = isFollowingSpecialization;
        _followedPartnerIds = followedPartnerIds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut incarca detaliile.';
      });
    }
  }

  int _estimatedReadSeconds(ContentItem item) {
    final text = [
      item.title,
      item.shortDescription,
      _cleanBody(item.body),
    ].whereType<String>().join(' ');
    final seconds = ((text.length / 1000) * 60).ceil();
    return seconds.clamp(30, 3600).toInt();
  }

  Map<String, dynamic> _activityMetadataFor(
    ContentItem item, {
    required String source,
    int? timeSpentSeconds,
    int? estimatedReadSeconds,
  }) {
    final metadata = <String, dynamic>{
      'content_type': item.contentType,
      if (item.categoryId != null) 'category_id': item.categoryId,
      if (item.categoryName != null) 'category_name': item.categoryName,
      if (item.specializationId != null)
        'specialization_id': item.specializationId,
      if (item.specializationName != null)
        'specialization_name': item.specializationName,
      if (item.authorName != null) 'author_name': item.authorName,
      'source': source,
    };

    if (timeSpentSeconds != null) {
      metadata['time_spent_seconds'] = timeSpentSeconds;
    }
    if (estimatedReadSeconds != null) {
      metadata['estimated_read_seconds'] = estimatedReadSeconds;
      if (timeSpentSeconds != null && estimatedReadSeconds > 0) {
        metadata['completion_ratio'] = (timeSpentSeconds / estimatedReadSeconds)
            .clamp(0.0, 1.0);
      }
    }
    return metadata;
  }

  Future<List<ContentItem>> _loadRecommendationsFor(ContentItem item) async {
    try {
      final items = switch (item.contentType) {
        'course' => await _apiService.getCourses(limit: 8),
        'event' => await _apiService.getEvents(limit: 8),
        'publication' => await _apiService.getPublications(limit: 8),
        'news' => await _apiService.getNews(limit: 8),
        _ => await _apiService.getNews(limit: 8),
      };
      return items.where((candidate) => candidate.id != item.id).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching recommendations: $e');
      }
      return const [];
    }
  }

  Future<void> _toggleSaved() async {
    if (_isSaving) return;
    final wasSaved = _isSaved;

    setState(() {
      _isSaving = true;
      _isSaved = !wasSaved;
    });

    try {
      if (wasSaved) {
        await _apiService.unsaveContent(widget.contentItemId);
      } else {
        await _apiService.saveContent(widget.contentItemId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSaved ? 'Eliminat din salvate' : 'Salvat'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaved = wasSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut actualiza salvarea'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleRecommendationSaved(int contentItemId) async {
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
    } catch (e) {
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

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );
    return message.trim().isEmpty
        ? 'Serviciul AI nu este disponibil momentan.'
        : message;
  }

  Future<void> _generateAiSummary() async {
    if (_isAiSummaryLoading) return;

    setState(() {
      _isAiSummaryLoading = true;
      _aiSummaryError = null;
    });

    try {
      final result = await _apiService.generateAiSummaryResult(
        widget.contentItemId,
      );
      final rawKeyPoints = result['key_points'];
      final keyPoints = rawKeyPoints is List
          ? rawKeyPoints
                .map((point) => point.toString().trim())
                .where((point) => point.isNotEmpty)
                .toList()
          : <String>[];

      if (!mounted) return;
      setState(() {
        _aiSummary = result['summary'].toString().trim();
        _aiKeyPoints = keyPoints;
        _aiDisclaimer = result['disclaimer']?.toString();
        _isAiSummaryLoading = false;
      });
    } catch (e) {
      final message = _friendlyError(e);
      if (!mounted) return;
      setState(() {
        _aiSummaryError = message;
        _isAiSummaryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  String? _imageUrlFor(ContentItem item) {
    final candidates = [
      item.heroImageUrl,
      item.thumbnailUrl,
      item.publicationLogoUrl,
    ];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    const months = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _cleanBody(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }

  String _contentLabel(ContentItem item) {
    switch (item.contentType) {
      case 'event':
        return 'Eveniment';
      case 'course':
        return 'Curs';
      case 'news':
        return 'Știri';
      default:
        return item.tag ?? 'Detalii';
    }
  }

  String _contentIconFor(ContentItem item) {
    switch (item.contentType) {
      case 'event':
        return _eventIcon;
      case 'course':
        return _courseIcon;
      case 'news':
      default:
        return _newsIcon;
    }
  }

  Widget _buildAssetIcon(
    String asset, {
    Key? key,
    required Color color,
    double size = 20,
  }) {
    return SvgPicture.asset(
      asset,
      key: key,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Color _accentFor(ContentItem item) {
    switch (item.contentType) {
      case 'event':
        return PulseTheme.eventContent;
      case 'course':
        return PulseTheme.courseContent;
      case 'news':
      default:
        return const Color(0xFF0E7490);
    }
  }

  int _readingMinutes(ContentItem item) {
    final text = '${item.shortDescription ?? ''} ${_cleanBody(item.body)}';
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
    return (words / 220).ceil().clamp(1, 99);
  }

  String _newsAuthorBadgeLabel(ContentItem item) {
    final author = item.authorName?.trim();
    final name = author != null && author.isNotEmpty
        ? author
        : 'Redacția PULSE';
    return name;
  }

  String? _formatTime(DateTime? date) {
    if (date == null) return null;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _humanizeValue(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return 'Nedisponibil';
    switch (raw) {
      case 'online':
        return 'Online';
      case 'onsite':
        return 'Fizic';
      case 'hybrid':
        return 'Hibrid';
      case 'free':
        return 'Gratuit';
      case 'paid':
        return 'Plătit';
      case 'approved':
      case 'accredited':
        return 'Acreditat';
      case 'pending':
        return 'În acreditare';
      case 'rejected':
      case 'not_accredited':
        return 'Neacreditat';
      case 'published':
      case 'active':
        return 'Disponibil';
      case 'draft':
        return 'În pregătire';
      case 'archived':
        return 'Arhivat';
      default:
        return raw
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  String _priceLabel(ContentItem item) {
    if (item.priceAmount != null) {
      return '${item.priceAmount} RON';
    }
    return _humanizeValue(item.priceType ?? 'free');
  }

  String _eventTimeRange(ContentItem item) {
    final start = _formatTime(item.startDate);
    final end = _formatTime(item.endDate);
    if (start != null && end != null) return '$start - $end';
    if (start != null) return 'de la $start';
    return 'Program anunțat curând';
  }

  String _courseMonthYear(DateTime date) {
    const months = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _courseDayMonth(DateTime date) {
    const months = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  ({String title, String? subtitle})? _courseAvailability(ContentItem item) {
    final validFrom = item.validFrom;
    final validUntil = item.validUntil;

    if (validFrom != null && validUntil != null) {
      return (
        title: 'Disponibil din ${_courseMonthYear(validFrom)}',
        subtitle:
            'Din ${_courseDayMonth(validFrom)} până la ${_courseDayMonth(validUntil)}',
      );
    }
    if (validFrom != null) {
      return (
        title: 'Disponibil din ${_courseMonthYear(validFrom)}',
        subtitle: null,
      );
    }
    if (validUntil != null) {
      return (
        title: 'Disponibil până în ${_courseMonthYear(validUntil)}',
        subtitle: 'Până la ${_courseDayMonth(validUntil)}',
      );
    }
    return null;
  }

  Widget _buildHeroImage(ContentItem item) {
    final imageUrl = _imageUrlFor(item);
    if (imageUrl == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accentFor(item).withValues(alpha: 0.18),
              const Color(0xFFE8F6F4),
            ],
          ),
        ),
        child: Center(
          child: _buildAssetIcon(
            _contentIconFor(item),
            color: PulseTheme.textSecondary,
            size: 42,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: PulseTheme.primary.withValues(alpha: 0.08),
          child: Center(
            child: _buildAssetIcon(
              _contentIconFor(item),
              color: PulseTheme.primary,
              size: 34,
            ),
          ),
        ),
      );
    }

    final assetPath = imageUrl.startsWith('assets/')
        ? imageUrl
        : imageUrl.startsWith('images/')
        ? 'assets/$imageUrl'
        : 'assets/images/$imageUrl';
    return Image.asset(
      assetPath,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: PulseTheme.primary.withValues(alpha: 0.08),
        child: Center(
          child: _buildAssetIcon(
            _contentIconFor(item),
            color: PulseTheme.primary,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ContentItem item, double height) {
    final topInset = MediaQuery.of(context).padding.top;
    final isNews = item.contentType == 'news';
    final isCourse = item.contentType == 'course';
    final courseProvider = item.provider?.trim();
    final courseSpecialization = item.specializationName?.trim();
    final hasCourseBadges =
        isCourse &&
        ((courseProvider?.isNotEmpty == true) ||
            (courseSpecialization?.isNotEmpty == true));
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(item),
            if (item.contentType == 'event')
              Container(color: Colors.black.withValues(alpha: 0.4)),
            if (isNews)
              Container(color: Colors.black.withValues(alpha: 0.38))
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.74),
                    ],
                    stops: const [0.18, 0.52, 1],
                  ),
                ),
              ),
            Positioned(
              top: topInset + 12,
              left: 18,
              child: _buildGlassButton(
                tooltip: 'Înapoi',
                iconAsset: _backIcon,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            if ((item.contentType == 'event' || isCourse) &&
                item.emcCredits != null &&
                item.emcCredits! > 0)
              Positioned(
                top: topInset + 12,
                right: 18,
                child: EmcBadge(points: '+${item.emcCredits}'),
              ),
            Positioned(
              left: 22,
              right: 22,
              bottom: item.contentType == 'event' ? 82 : 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.contentType == 'event')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PulseTheme.eventContent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _contentLabel(item).toUpperCase(),
                        style: const TextStyle(
                          color: PulseTheme.eventContent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    )
                  else if (item.contentType == 'news')
                    _buildMainPageBadge(
                      _contentLabel(item),
                      PulseTheme.newsContent,
                    )
                  else if (isCourse)
                    _buildMainPageBadge('Curs', PulseTheme.courseContent)
                  else
                    _buildHeroBadge(_contentLabel(item)),
                  const SizedBox(height: 12),
                  Text(
                    item.publicationName ?? item.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item.contentType == 'news') ...[
                    const SizedBox(height: 12),
                    _buildMainPageBadge(
                      _newsAuthorBadgeLabel(item),
                      PulseTheme.newsContent,
                    ),
                  ],
                  if (hasCourseBadges) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (courseProvider?.isNotEmpty == true)
                          _buildMainPageBadge(
                            courseProvider!,
                            PulseTheme.courseContent,
                            iconAsset: _buildingIcon,
                          ),
                        if (courseSpecialization?.isNotEmpty == true)
                          _buildMainPageBadge(
                            courseSpecialization!,
                            PulseTheme.courseContent,
                            iconAsset: _courseIcon,
                          ),
                      ],
                    ),
                  ],
                  if (item.contentType == 'event') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildHeroSecondaryBadge(
                          _peopleIcon,
                          item.authorName ?? item.provider ?? 'PULSE',
                        ),
                        _buildHeroSecondaryBadge(
                          _checkIcon,
                          _humanizeValue(item.accreditationStatus ?? 'pending'),
                        ),
                        if (item.specializationName?.trim().isNotEmpty == true)
                          _buildHeroSecondaryBadge(
                            _courseIcon,
                            item.specializationName!,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String tooltip,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: _buildAssetIcon(iconAsset, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMainPageBadge(String label, Color color, {String? iconAsset}) {
    return ContentTypeBadge(label: label, color: color, iconAsset: iconAsset);
  }

  Widget _buildHeroSecondaryBadge(String iconAsset, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PulseTheme.eventContent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAssetIcon(iconAsset, color: PulseTheme.eventContent, size: 12),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: PulseTheme.eventContent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return FavoriteButton(
      isSaved: _isSaved,
      onTap: _isSaving ? null : _toggleSaved,
    );
  }

  Widget _buildAiSummaryButton() {
    return AiSummaryButton(
      isLoading: _isAiSummaryLoading,
      onGenerate: _generateAiSummary,
    );
  }

  Widget _buildPanelSectionTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: PulseTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: const TextStyle(
        color: PulseTheme.textSecondary,
        fontSize: 17,
        height: 1.58,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildArticleBody(String value) {
    final text = value.trim().isNotEmpty
        ? value.trim()
        : 'Conținutul complet nu este disponibil.';
    return Text(
      text,
      style: TextStyle(
        color: value.trim().isNotEmpty
            ? PulseTheme.textPrimary
            : PulseTheme.textSecondary,
        fontSize: 17,
        height: 1.68,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNewsMetaRow(ContentItem item) {
    final date = _formatDate(item.publishedAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceElevated.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseTheme.borderLight),
      ),
      child: Row(
        children: [
          _buildAssetIcon(
            _eyeglassesIcon,
            color: PulseTheme.newsContent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              [?date, '${_readingMinutes(item)} min citire'].join(' • '),
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAuthorFollow(ContentItem item) async {
    final authorId = item.authorId;
    if (authorId == null || _isAuthorFollowLoading) return;
    final wasFollowing = _isFollowingAuthor;
    setState(() {
      _isFollowingAuthor = !wasFollowing;
      _isAuthorFollowLoading = true;
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: 'author',
          targetId: authorId,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'author',
          targetId: authorId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urm\u0103re\u0219ti acest autor.'
                : 'Urm\u0103re\u0219ti acest autor.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowingAuthor = wasFollowing;
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
          _isAuthorFollowLoading = false;
        });
      }
    }
  }

  Future<void> _openAuthorProfile(ContentItem item) async {
    final authorId = item.authorId;
    if (authorId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthorProfileScreen(
          authorId: authorId,
          initialName: item.authorName,
        ),
      ),
    );
    try {
      final isFollowing = await _apiService.getFollowStatus(
        targetType: 'author',
        targetId: authorId,
      );
      if (!mounted) return;
      setState(() {
        _isFollowingAuthor = isFollowing;
      });
    } catch (_) {
      // The detail page can keep its current optimistic state.
    }
  }

  Widget _buildAuthorFollowCard(ContentItem item) {
    if (item.authorId == null) return const SizedBox.shrink();
    final authorName = item.authorName?.trim().isNotEmpty == true
        ? item.authorName!.trim()
        : 'Autor PULSE';
    final accent = _accentFor(item);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceElevated.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _openAuthorProfile(item),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Autor',
                              style: TextStyle(
                                color: PulseTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PulseTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: PulseTheme.textSecondary.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _isAuthorFollowLoading
                ? null
                : () => _toggleAuthorFollow(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isFollowingAuthor
                  ? PulseTheme.textPrimary
                  : accent,
              side: BorderSide(
                color: _isFollowingAuthor
                    ? PulseTheme.borderLight
                    : accent.withValues(alpha: 0.42),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: _isAuthorFollowLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isFollowingAuthor ? 'Following' : 'Follow',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCategoryFollow(ContentItem item) async {
    final categoryId = item.categoryId;
    if (categoryId == null || _isCategoryFollowLoading) return;
    final wasFollowing = _isFollowingCategory;

    setState(() {
      _isFollowingCategory = !wasFollowing;
      _isCategoryFollowLoading = true;
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: 'category',
          targetId: categoryId,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'category',
          targetId: categoryId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urmărești categoria.'
                : 'Urmărești categoria.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowingCategory = wasFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut actualiza categoria urmărită.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCategoryFollowLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSpecializationFollow(ContentItem item) async {
    final specializationId = item.specializationId;
    if (specializationId == null || _isSpecializationFollowLoading) return;
    final wasFollowing = _isFollowingSpecialization;

    setState(() {
      _isFollowingSpecialization = !wasFollowing;
      _isSpecializationFollowLoading = true;
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: 'specialization',
          targetId: specializationId,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'specialization',
          targetId: specializationId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Nu mai urmărești specializarea.'
                : 'Urmărești specializarea.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowingSpecialization = wasFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut actualiza specializarea urmărită.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSpecializationFollowLoading = false;
        });
      }
    }
  }

  Widget _buildTaxonomyFollowSection(ContentItem item) {
    final hasCategory = item.categoryId != null;
    final hasSpecialization = item.specializationId != null;
    if (!hasCategory && !hasSpecialization) return const SizedBox.shrink();

    final accent = _accentFor(item);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseTheme.borderLight),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (hasCategory)
            _buildTaxonomyFollowChip(
              icon: Icons.category_rounded,
              label: _isFollowingCategory
                  ? 'Urmărești categoria'
                  : 'Urmărește categoria',
              value: item.categoryName,
              isFollowing: _isFollowingCategory,
              isLoading: _isCategoryFollowLoading,
              accent: accent,
              onTap: () => _toggleCategoryFollow(item),
            ),
          if (hasSpecialization)
            _buildTaxonomyFollowChip(
              icon: Icons.medical_services_rounded,
              label: _isFollowingSpecialization
                  ? 'Urmărești specializarea'
                  : 'Urmărește specializarea',
              value: item.specializationName,
              isFollowing: _isFollowingSpecialization,
              isLoading: _isSpecializationFollowLoading,
              accent: accent,
              onTap: () => _toggleSpecializationFollow(item),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyFollowChip({
    required IconData icon,
    required String label,
    required String? value,
    required bool isFollowing,
    required bool isLoading,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cleanValue = value?.trim();
    final text = cleanValue == null || cleanValue.isEmpty
        ? label
        : '$label · $cleanValue';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: BoxConstraints(
            minHeight: 40,
            maxWidth: MediaQuery.sizeOf(context).width - 58,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isFollowing
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isFollowing
                  ? accent.withValues(alpha: 0.48)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isFollowing ? Icons.check_circle_rounded : icon,
                  color: isFollowing ? accent : PulseTheme.textSecondary,
                  size: 16,
                ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isFollowing
                        ? PulseTheme.textPrimary
                        : PulseTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePartnerFollow(EventPartner partner) async {
    if (_partnerFollowLoadingIds.contains(partner.id)) return;
    final wasFollowing = _followedPartnerIds.contains(partner.id);
    setState(() {
      if (wasFollowing) {
        _followedPartnerIds.remove(partner.id);
      } else {
        _followedPartnerIds.add(partner.id);
      }
      _partnerFollowLoadingIds.add(partner.id);
    });

    try {
      if (wasFollowing) {
        await _apiService.unfollowTarget(
          targetType: 'partner',
          targetId: partner.id,
        );
      } else {
        await _apiService.followTarget(
          targetType: 'partner',
          targetId: partner.id,
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
        if (wasFollowing) {
          _followedPartnerIds.add(partner.id);
        } else {
          _followedPartnerIds.remove(partner.id);
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
          _partnerFollowLoadingIds.remove(partner.id);
        });
      }
    }
  }

  Future<void> _openPartnerProfile(EventPartner partner) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PartnerProfileScreen(
          partnerId: partner.id,
          initialName: partner.name,
          initialLogoUrl: partner.logoUrl,
          initialWebsiteUrl: partner.websiteUrl,
        ),
      ),
    );
    try {
      final isFollowing = await _apiService.getFollowStatus(
        targetType: 'partner',
        targetId: partner.id,
      );
      if (!mounted) return;
      setState(() {
        if (isFollowing) {
          _followedPartnerIds.add(partner.id);
        } else {
          _followedPartnerIds.remove(partner.id);
        }
      });
    } catch (_) {
      // The detail page can keep its current optimistic state.
    }
  }

  String _partnerInitials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  Widget _buildPartnerLogo(EventPartner partner, Color accent) {
    final logoUrl = partner.logoUrl?.trim();
    Widget fallback() {
      return Container(
        color: accent.withValues(alpha: 0.12),
        child: Center(
          child: Text(
            _partnerInitials(partner.name),
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child:
          logoUrl != null &&
              (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'))
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => fallback(),
            )
          : fallback(),
    );
  }

  Widget _buildPartnerFollowRow(EventPartner partner, Color accent) {
    final isFollowing = _followedPartnerIds.contains(partner.id);
    final isLoading = _partnerFollowLoadingIds.contains(partner.id);
    final website = partner.websiteUrl?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => _openPartnerProfile(partner),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: _buildPartnerLogo(partner, accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partner.name.trim().isNotEmpty
                                  ? partner.name.trim()
                                  : 'Organizatie',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PulseTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (website != null && website.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                website,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PulseTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: PulseTheme.textSecondary.withValues(alpha: 0.75),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: isLoading ? null : () => _togglePartnerFollow(partner),
            style: OutlinedButton.styleFrom(
              foregroundColor: isFollowing ? PulseTheme.textPrimary : accent,
              side: BorderSide(
                color: isFollowing
                    ? PulseTheme.borderLight
                    : accent.withValues(alpha: 0.42),
              ),
              backgroundColor: isFollowing
                  ? Colors.white.withValues(alpha: 0.09)
                  : accent.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerFollowSection(ContentItem item, Color accent) {
    if (item.eventPartners.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 4),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceElevated.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business_rounded, color: accent, size: 17),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Organizatii partenere',
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.eventPartners.map(
            (partner) => _buildPartnerFollowRow(partner, accent),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int percent) {
    final clamped = percent.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceElevated.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progres curs',
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$clamped%',
                style: const TextStyle(
                  color: Color(0xFF0E7490),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: clamped / 100,
              backgroundColor: PulseTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0E7490)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsContent(ContentItem item) {
    final description = item.shortDescription ?? item.publicationDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNewsMetaRow(item),
        const SizedBox(height: 24),
        _buildPanelSectionTitle('Descriere'),
        const SizedBox(height: 14),
        _buildDescription(description),
        const SizedBox(height: 20),
        _buildAiSummaryButton(),
        _buildAiSummarySection(),
        const SizedBox(height: 28),
        _buildArticleBody(_cleanBody(item.body)),
      ],
    );
  }

  Widget _buildEventInfoRow({
    required String iconAsset,
    required Color accent,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                  ),
                  if (showBadge)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PulseTheme.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor ?? PulseTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRegistrationButton(ContentItem item) {
    if (item.eventId == null) return const SizedBox.shrink();

    final isFree = item.priceType == 'free' || (item.priceAmount ?? 0) == 0;

    if (_isEventRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: PulseTheme.eventContent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PulseTheme.eventContent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: PulseTheme.eventContent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _eventRegistrationStatus == 'confirmed'
                      ? 'Ești înscris (Confirmat)'
                      : 'Ești înscris',
                  style: const TextStyle(
                    color: PulseTheme.eventContent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_eventTicketCode?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Cod bilet: ${_eventTicketCode!.trim()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseTheme.textPrimary.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isRegisteringEvent
          ? null
          : () => _handleEventRegistration(item, isFree),
      style: ElevatedButton.styleFrom(
        backgroundColor: PulseTheme.eventContent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isRegisteringEvent
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Text(
              isFree ? 'Participă gratuit' : 'Participă la eveniment',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }

  Future<void> _handleEventRegistration(ContentItem item, bool isFree) async {
    if (isFree) {
      setState(() => _isRegisteringEvent = true);
      try {
        final res = await _apiService.registerForEvent(item.eventId!);
        final tCode = res['ticket_code'] as String?;
        if (!mounted) return;
        setState(() {
          _isEventRegistered = true;
          _eventRegistrationStatus = 'registered';
          _eventTicketCode = tCode;
          _isRegisteringEvent = false;
        });
        _showSuccessPopup(
          'Te-ai înscris cu succes la acest eveniment!',
          ticketCode: tCode,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isRegisteringEvent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } else {
      EventPaymentModal.show(
        context: context,
        eventId: item.eventId!,
        title: item.title,
        amount: item.priceAmount?.toDouble() ?? 0.0,
        currency: 'RON',
        onSuccess: (tCode) {
          setState(() {
            _isEventRegistered = true;
            _eventRegistrationStatus = 'confirmed';
            _eventTicketCode = tCode;
          });
          _showSuccessPopup(
            'Plata a fost procesată și ești înscris la eveniment!',
            ticketCode: tCode,
          );
        },
      );
    }
  }

  Widget _buildCourseEnrollmentButton(ContentItem item) {
    if (item.courseId == null) return const SizedBox.shrink();

    if (_isCourseEnrolled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: PulseTheme.courseContent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PulseTheme.courseContent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAssetIcon(
              _checkIcon,
              color: PulseTheme.courseContent,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Ești înscris la acest curs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseTheme.courseContent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PulseTheme.courseContent,
              PulseTheme.courseContent.withValues(alpha: 0.78),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _isEnrollingCourse
              ? null
              : () => _confirmCourseEnrollment(item),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: _isEnrollingCourse
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Înscrie-te',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCourseEnrollment(ContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: PulseTheme.courseContent.withValues(alpha: 0.26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAssetIcon(
                _courseIcon,
                color: PulseTheme.courseContent,
                size: 38,
              ),
              const SizedBox(height: 22),
              const Text(
                'Confirmă înscrierea',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ești sigur că vrei să te înscrii la acest curs? Vei primi curând pe adresa contului detalii legate de acest curs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Anulează',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              PulseTheme.courseContent,
                              Color(0xFFF97316),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(true),
                          borderRadius: BorderRadius.circular(14),
                          child: const SizedBox(
                            height: 48,
                            child: Center(
                              child: Text(
                                'Confirmă înscrierea',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
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
        ),
      ),
    );

    if (confirmed == true) {
      await _handleCourseEnrollment(item);
    }
  }

  Future<void> _handleCourseEnrollment(ContentItem item) async {
    if (item.courseId == null) return;

    setState(() => _isEnrollingCourse = true);
    try {
      await _apiService.enrollInCourse(item.courseId!);
      if (!mounted) return;
      setState(() {
        _isCourseEnrolled = true;
        _isEnrollingCourse = false;
      });
      _showCourseEnrollmentSuccessPopup();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEnrollingCourse = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _showCourseEnrollmentSuccessPopup() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: PulseTheme.courseContent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAssetIcon(
                _checkIcon,
                color: PulseTheme.courseContent,
                size: 42,
              ),
              const SizedBox(height: 24),
              const Text(
                'Te-ai înscris cu succes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Te-ai înscris la curs cu succes. Vei primi curând pe adresa contului detalii legate de acest curs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseTheme.courseContent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Închide',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessPopup(String message, {String? ticketCode}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: PulseTheme.eventContent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseTheme.eventContent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: PulseTheme.eventContent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Felicitări!',
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
              if (ticketCode != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Cod bilet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticketCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseTheme.eventContent,
                  foregroundColor: Colors.black,
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

  Widget _buildEventContent(ContentItem item) {
    final accent = _accentFor(item);

    final date = _formatDate(item.startDate) ?? 'Data anunțată curând';
    final timeRange = _eventTimeRange(item);

    final primaryLocation = item.venueName?.trim().isNotEmpty == true
        ? item.venueName!
        : (item.cityName?.trim().isNotEmpty == true
              ? item.cityName!
              : _humanizeValue(item.attendanceMode));
    final secondaryLocation =
        item.venueName?.trim().isNotEmpty == true &&
            item.cityName?.trim().isNotEmpty == true
        ? item.cityName!
        : null;

    final price = _priceLabel(item);
    final nextPriceMessage = item.nextPriceChange?.message?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventRegistrationButton(item),
        const SizedBox(height: 24),
        _buildPanelSectionTitle('Detalii'),
        const SizedBox(height: 16),
        _buildEventInfoRow(
          iconAsset: _calendarIcon,
          accent: accent,
          title: date,
          subtitle:
              timeRange != 'Program anunțat curând' && timeRange.isNotEmpty
              ? timeRange
              : null,
        ),
        _buildEventInfoRow(
          iconAsset: _buildingIcon,
          accent: accent,
          title: primaryLocation,
          subtitle: secondaryLocation,
        ),
        _buildEventInfoRow(
          iconAsset: _walletIcon,
          accent: accent,
          title: price,
          subtitle: nextPriceMessage?.isNotEmpty == true
              ? nextPriceMessage
              : null,
          subtitleColor: const Color(0xFFEF4444),
          showBadge: nextPriceMessage?.isNotEmpty == true,
        ),
        if (item.eventPartners.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildPartnerFollowSection(item, accent),
          const SizedBox(height: 18),
          _EventPartnerCarousel(partners: item.eventPartners, accent: accent),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 12),
        const SizedBox(height: 22),
        _buildDescription(item.shortDescription),
        if (_cleanBody(item.body).isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildArticleBody(_cleanBody(item.body)),
        ],
      ],
    );
  }

  Widget _buildCourseContent(ContentItem item) {
    final accent = _accentFor(item);
    final availability = _courseAvailability(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availability != null)
          _buildEventInfoRow(
            iconAsset: _calendarIcon,
            accent: accent,
            title: availability.title,
            subtitle: availability.subtitle,
          ),
        if (item.progressPercent != null) ...[
          const SizedBox(height: 20),
          _buildProgress(item.progressPercent!),
        ],
        const SizedBox(height: 24),
        _buildCourseEnrollmentButton(item),
        const SizedBox(height: 24),
        _buildPanelSectionTitle('Despre curs'),
        const SizedBox(height: 14),
        _buildDescription(item.shortDescription),
        if (_cleanBody(item.body).isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildArticleBody(_cleanBody(item.body)),
        ],
      ],
    );
  }

  Widget _buildAiSummarySection() {
    if (_aiSummary == null && _aiSummaryError == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AiSummaryInlineSection(
        summary: _aiSummary,
        keyPoints: _aiKeyPoints,
        disclaimer: _aiDisclaimer,
        error: _aiSummaryError,
      ),
    );
  }

  Widget _buildMoreLikeThisSection() {
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildPanelSectionTitle('Vezi mai mult'),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: ListView.builder(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final item = _recommendations[index];
              return ContentCard.fromModel(
                item,
                isSaved: _savedContentIds.contains(item.id),
                onSaveToggle: _toggleRecommendationSaved,
                cardWidth: 240,
                margin: const EdgeInsets.only(right: 16),
                darkMode: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(ContentItem item) {
    final heroHeight = MediaQuery.sizeOf(context).height < 720 ? 360.0 : 410.0;

    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: _buildHero(item, heroHeight),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 42, 22, 34),
                    decoration: BoxDecoration(
                      color: PulseTheme.surface.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.authorId != null) ...[
                          _buildAuthorFollowCard(item),
                          const SizedBox(height: 22),
                        ],
                        if (item.categoryId != null ||
                            item.specializationId != null) ...[
                          _buildTaxonomyFollowSection(item),
                          const SizedBox(height: 22),
                        ],
                        if (item.contentType == 'event')
                          _buildEventContent(item)
                        else if (item.contentType == 'course')
                          _buildCourseContent(item)
                        else
                          _buildNewsContent(item),
                        _buildMoreLikeThisSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: heroHeight - 57,
              right: 26,
              child: _buildFavoriteButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SkeletonLoading.detail();
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
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Reincearca'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item;
    if (item == null) {
      return const Center(
        child: Text(
          'Articolul nu este disponibil.',
          style: TextStyle(color: PulseTheme.textSecondary),
        ),
      );
    }

    return _buildDetail(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: PulseTheme.background, body: _buildBody());
  }
}

class _EventPartnerCarousel extends StatefulWidget {
  final List<EventPartner> partners;
  final Color accent;

  const _EventPartnerCarousel({required this.partners, required this.accent});

  @override
  State<_EventPartnerCarousel> createState() => _EventPartnerCarouselState();
}

class _EventPartnerCarouselState extends State<_EventPartnerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _EventPartnerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partners.length != widget.partners.length) {
      _currentPage = 0;
      _timer?.cancel();
      _startTimer();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _startTimer() {
    if (widget.partners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || !mounted) return;
      final nextPage = (_currentPage + 1) % widget.partners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.partners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parteneri',
          style: TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.partners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EventPartnerCard(
                  partner: widget.partners[index],
                  accent: widget.accent,
                ),
              );
            },
          ),
        ),
        if (widget.partners.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.partners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? widget.accent.withValues(alpha: 0.72)
                      : PulseTheme.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EventPartnerCard extends StatelessWidget {
  final EventPartner partner;
  final Color accent;

  const _EventPartnerCard({required this.partner, required this.accent});

  @override
  Widget build(BuildContext context) {
    final logoUrl = partner.logoUrl?.trim();
    return Center(
      child: logoUrl != null && logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _PartnerLogoFallback(name: partner.name, accent: accent);
              },
            )
          : _PartnerLogoFallback(name: partner.name, accent: accent),
    );
  }
}

class _PartnerLogoFallback extends StatelessWidget {
  final String name;
  final Color accent;

  const _PartnerLogoFallback({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: accent,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
