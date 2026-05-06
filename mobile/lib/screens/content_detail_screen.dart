import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/premium_loading_indicator.dart';

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

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
    _loadDetail();
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

      if (!mounted) return;
      setState(() {
        _item = ContentItem.fromJson(detail);
        _isSaved = savedIds.contains(widget.contentItemId);
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
      'ian',
      'feb',
      'mar',
      'apr',
      'mai',
      'iun',
      'iul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
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

  Widget _buildSaveAction() {
    const favoriteColor = Color(0xFFFF4B4B);
    return IconButton(
      tooltip: _isSaved ? 'Elimina din salvate' : 'Salveaza',
      onPressed: _isSaving ? null : _toggleSaved,
      icon: Icon(
        _isSaved ? Icons.favorite : Icons.favorite_border,
        color: _isSaved ? favoriteColor : PulseTheme.textSecondary,
      ),
    );
  }

  Widget _buildHeroImage(ContentItem item) {
    final imageUrl = _imageUrlFor(item);
    if (imageUrl == null) {
      return Container(
        height: 190,
        color: PulseTheme.primary.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(
            Icons.article_outlined,
            color: PulseTheme.primary,
            size: 42,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 190,
          color: PulseTheme.primary.withValues(alpha: 0.08),
          child: const Center(
            child: Icon(Icons.article_outlined, color: PulseTheme.primary),
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
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 190,
        color: PulseTheme.primary.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.article_outlined, color: PulseTheme.primary),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAiSummaryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAiSummaryLoading ? null : _generateAiSummary,
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PulseTheme.primary.withValues(alpha: 0.58),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        icon: _isAiSummaryLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome_outlined),
        label: Text(
          _isAiSummaryLoading
              ? 'Se generează rezumatul...'
              : 'Generează rezumat AI',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAiSummarySection() {
    if (_aiSummary == null && _aiSummaryError == null) {
      return const SizedBox.shrink();
    }

    final hasSummary = _aiSummary != null && _aiSummary!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasSummary
            ? PulseTheme.primary.withValues(alpha: 0.07)
            : PulseTheme.newsContent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSummary
              ? PulseTheme.primary.withValues(alpha: 0.14)
              : PulseTheme.newsContent.withValues(alpha: 0.18),
        ),
      ),
      child: hasSummary
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: PulseTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Rezumat AI',
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiSummary!,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_aiKeyPoints.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Idei cheie',
                    style: TextStyle(
                      color: PulseTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._aiKeyPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 9),
                            decoration: const BoxDecoration(
                              color: PulseTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                color: PulseTheme.textSecondary,
                                height: 1.42,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_aiDisclaimer != null && _aiDisclaimer!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _aiDisclaimer!,
                    style: const TextStyle(
                      color: PulseTheme.textTertiary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: PulseTheme.newsContent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _aiSummaryError ??
                        'Serviciul AI nu este disponibil momentan.',
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetail(ContentItem item) {
    final title = item.publicationName ?? item.title;
    final body = _cleanBody(item.body);
    final description = item.shortDescription ?? item.publicationDescription;
    final dateLabel = _formatDate(item.publishedAt ?? item.startDate);

    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _buildHeroImage(item),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.categoryName != null &&
                          item.categoryName!.isNotEmpty)
                        _buildChip(item.categoryName!, PulseTheme.primary),
                      if (item.specializationName != null &&
                          item.specializationName!.isNotEmpty)
                        _buildChip(
                          item.specializationName!,
                          PulseTheme.magazineContent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      color: PulseTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (item.authorName != null &&
                          item.authorName!.isNotEmpty)
                        Text(
                          item.authorName!,
                          style: const TextStyle(
                            color: PulseTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (dateLabel != null)
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: PulseTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      description,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildAiSummaryButton(),
                  _buildAiSummarySection(),
                  const SizedBox(height: 24),
                  Text(
                    body.isNotEmpty
                        ? body
                        : 'Continutul complet nu este disponibil.',
                    style: TextStyle(
                      color: body.isNotEmpty
                          ? PulseTheme.textPrimary
                          : PulseTheme.textSecondary,
                      fontSize: 16,
                      height: 1.58,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: PremiumLoadingIndicator(text: 'Se incarca articolul...'),
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
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: const Text('Detalii'),
        actions: [_buildSaveAction()],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}
