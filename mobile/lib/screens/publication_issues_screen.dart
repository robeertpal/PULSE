import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication_issue.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/emc_badge.dart';

const Color _editorialNavy = Color(0xFF102A43);
const Color _medicalTeal = Color(0xFF0F766E);
const Color _softGold = Color(0xFFC8A14A);
const Color _warmCanvas = Color(0xFFF7F5F0);
const Color _warmSurface = Color(0xFFFFFEFC);
const String _bookPagesIconAsset = 'assets/icons/book.pages.svg';
const String _globeIconAsset = 'assets/icons/globe.svg';
const String _checkmarkIconAsset = 'assets/icons/checkmark.svg';
const String _arrowRightIconAsset = 'assets/icons/arrow.right.svg';
const String _arrowBackwardIconAsset = 'assets/icons/arrow.backward.svg';
const String _pdfOpenErrorMessage =
    'Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.';

class PublicationIssuesScreen extends StatefulWidget {
  final int publicationId;
  final String publicationName;
  final String? contentTitle;
  final String? contentShortDescription;
  final String? contentBody;
  final String? contentHeroImageUrl;
  final String? contentThumbnailUrl;
  final DateTime? contentPublishedAt;
  final String? publicationDescription;
  final String? publicationLogoUrl;
  final String? emcCreditsText;
  final String? creditationText;
  final String? indexingText;
  final String? subscriptionUrl;

  const PublicationIssuesScreen({
    super.key,
    required this.publicationId,
    required this.publicationName,
    this.contentTitle,
    this.contentShortDescription,
    this.contentBody,
    this.contentHeroImageUrl,
    this.contentThumbnailUrl,
    this.contentPublishedAt,
    this.publicationDescription,
    this.publicationLogoUrl,
    this.emcCreditsText,
    this.creditationText,
    this.indexingText,
    this.subscriptionUrl,
  });

  @override
  State<PublicationIssuesScreen> createState() =>
      _PublicationIssuesScreenState();
}

class _PublicationIssuesScreenState extends State<PublicationIssuesScreen> {
  final ApiService _apiService = ApiService();
  List<PublicationIssue> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final issues = await _apiService.getPublicationIssues(
        widget.publicationId,
      );
      if (!mounted) return;
      setState(() {
        _issues = _sortIssues(issues);
        _selectedYear = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut încărca numerele publicației.';
      });
    }
  }

  List<PublicationIssue> _sortIssues(List<PublicationIssue> issues) {
    return [...issues]..sort((a, b) {
      final byDate = _compareNullableDates(b.publishedAt, a.publishedAt);
      if (byDate != 0) return byDate;
      final byYear = b.year.compareTo(a.year);
      if (byYear != 0) return byYear;
      return b.issueNumber.compareTo(a.issueNumber);
    });
  }

  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  List<int> get _years {
    return _issues.map((issue) => issue.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
  }

  PublicationIssue? get _latestIssue =>
      _issues.isNotEmpty ? _issues.first : null;

  List<PublicationIssue> get _archiveIssues {
    final latest = _latestIssue;
    final issues = _selectedYear == null
        ? _issues
        : _issues.where((issue) => issue.year == _selectedYear).toList();
    if (latest == null) return issues;
    return issues.where((issue) => issue.id != latest.id).toList();
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _plainText(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;
    return cleaned
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

  String get _issueCountLabel {
    if (_issues.isEmpty) return 'Arhivă în pregătire';
    if (_issues.length == 1) return '1 număr disponibil';
    return '${_issues.length} numere disponibile';
  }

  String get _publicationName {
    return _clean(_latestIssue?.publicationName) ??
        _clean(widget.publicationName) ??
        _clean(widget.contentTitle) ??
        'Publicație';
  }

  String? get _publicationLogoUrl {
    return _clean(widget.publicationLogoUrl) ??
        _clean(_latestIssue?.publicationLogoUrl);
  }

  String? get _publicationDescription {
    return _clean(widget.publicationDescription) ??
        _clean(_latestIssue?.publicationDescription) ??
        _clean(widget.contentShortDescription) ??
        _plainText(widget.contentBody);
  }

  String? get _publicationBackgroundUrl {
    return _clean(widget.contentHeroImageUrl) ??
        _clean(widget.contentThumbnailUrl) ??
        _publicationLogoUrl;
  }

  String? get _emcCreditsText {
    return _clean(widget.emcCreditsText) ??
        _clean(_latestIssue?.publicationEmcCreditsText);
  }

  String? get _creditationText {
    return _clean(widget.creditationText) ??
        _clean(_latestIssue?.publicationCreditationText);
  }

  String? get _indexingText {
    return _clean(widget.indexingText) ??
        _clean(_latestIssue?.publicationIndexingText);
  }

  String? get _subscriptionUrl {
    return _clean(widget.subscriptionUrl) ??
        _clean(_latestIssue?.publicationSubscriptionUrl);
  }

  Future<void> _openUrl(String url, String errorMessage) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openIssue(PublicationIssue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PublicationIssueDetailScreen(
          issueId: issue.id,
          initialIssue: issue,
        ),
      ),
    );
  }

  Widget _remoteOrAssetImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color accent = _medicalTeal,
  }) {
    final value = _clean(url);
    if (value == null) {
      return _imageFallback(width: width, height: height, accent: accent);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _imageFallback(width: width, height: height, accent: accent),
      );
    }

    final assetPath = value.startsWith('assets/')
        ? value
        : value.startsWith('images/')
        ? 'assets/$value'
        : 'assets/images/$value';
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _imageFallback(width: width, height: height, accent: accent),
    );
  }

  Widget _imageFallback({
    double? width,
    double? height,
    required Color accent,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.10),
            _softGold.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(child: _BookPagesIcon(color: accent, size: 34)),
    );
  }

  Widget _heroBackground(String? url) {
    final value = _clean(url);
    if (value == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1F33), Color(0xFF0F766E), Color(0xFFEBE3D0)],
            stops: [0.0, 0.62, 1.0],
          ),
        ),
      );
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _heroBackground(null),
      );
    }

    final assetPath = value.startsWith('assets/')
        ? value
        : value.startsWith('images/')
        ? 'assets/$value'
        : 'assets/images/$value';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _heroBackground(null),
    );
  }

  Widget _buildHero() {
    final description = _publicationDescription;
    final subscriptionUrl = _subscriptionUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Container(
        decoration: BoxDecoration(
          color: _warmSurface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _medicalTeal.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: _editorialNavy.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -18,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: 390,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _heroBackground(_publicationBackgroundUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.58),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.30),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                if (_emcCreditsText != null)
                  Positioned(
                    left: 18,
                    top: 18,
                    child: EmcBadge(points: _emcCreditsText!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _publicationName,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    fontWeight: FontWeight.w900,
                                    height: 1.06,
                                  ),
                                ),
                                if (description != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    description,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      fontSize: 15,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _HeroLogo(
                            logoUrl: _publicationLogoUrl,
                            imageBuilder: (url) => _remoteOrAssetImage(
                              url,
                              fit: BoxFit.contain,
                              accent: _medicalTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.contentPublishedAt != null)
                            _PremiumPill(
                              label:
                                  'Publicat ${_formatDate(widget.contentPublishedAt)!}',
                              icon: Icons.event_available_outlined,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              borderColor: Colors.white.withValues(alpha: 0.20),
                            ),
                          _PremiumPill(
                            label: _issueCountLabel,
                            svgAsset: _bookPagesIconAsset,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            borderColor: Colors.white.withValues(alpha: 0.20),
                          ),
                          if (_creditationText != null)
                            _PremiumPill(
                              label: _creditationText!,
                              svgAsset: _checkmarkIconAsset,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              borderColor: Colors.white.withValues(alpha: 0.20),
                            ),
                          if (_indexingText != null)
                            _PremiumPill(
                              label: _indexingText!,
                              svgAsset: _globeIconAsset,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              borderColor: Colors.white.withValues(alpha: 0.20),
                            ),
                        ],
                      ),
                      if (subscriptionUrl != null) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openUrl(
                              subscriptionUrl,
                              'Nu am putut deschide pagina revistei.',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _editorialNavy,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'Accesează revista',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearFilter() {
    if (_years.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _YearChip(
              label: 'Toate',
              selected: _selectedYear == null,
              onTap: () => setState(() => _selectedYear = null),
            ),
            ..._years.map(
              (year) => _YearChip(
                label: year.toString(),
                selected: _selectedYear == year,
                onTap: () => setState(() => _selectedYear = year),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSection() {
    final latest = _latestIssue;
    if (latest == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Cea mai recentă ediție',
            subtitle: 'Acces rapid la cel mai nou număr publicat',
          ),
          const SizedBox(height: 14),
          _FeaturedIssueCard(
            issue: latest,
            dateLabel: _formatDate(latest.publishedAt),
            imageBuilder: (url) =>
                _remoteOrAssetImage(url, width: 132, height: 182),
            onTap: () => _openIssue(latest),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveSection() {
    final archive = _archiveIssues;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _selectedYear == null
                ? 'Arhivă editorială'
                : 'Ediții $_selectedYear',
            subtitle: _selectedYear == null
                ? 'Numere anterioare organizate pentru consultare rapidă'
                : 'Numere publicate în anul selectat',
          ),
          const SizedBox(height: 14),
          if (archive.isEmpty)
            _InlineEmptyState(
              title: 'Nu există alte ediții în această selecție',
              message:
                  'Schimbă filtrul de an sau revino când apare un număr nou.',
            )
          else
            ...archive.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ArchiveIssueCard(
                  issue: issue,
                  dateLabel: _formatDate(issue.publishedAt),
                  imageBuilder: (url) =>
                      _remoteOrAssetImage(url, width: 78, height: 108),
                  onTap: () => _openIssue(issue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      children: const [_PublicationSkeleton()],
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: _medicalTeal,
      onRefresh: _loadIssues,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 32),
        children: [
          _InlineEmptyState(
            title: 'Edițiile nu s-au putut încărca',
            message:
                _errorMessage ?? 'Verifică conexiunea și încearcă din nou.',
            actionLabel: 'Reîncearcă',
            onAction: _loadIssues,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: _medicalTeal,
      onRefresh: _loadIssues,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHero(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _InlineEmptyState(
              title: 'Arhiva este în pregătire',
              message:
                  'Această publicație nu are încă numere publicate în aplicație.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_issues.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: _medicalTeal,
      onRefresh: _loadIssues,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          _buildHero(),
          _buildYearFilter(),
          _buildLatestSection(),
          _buildArchiveSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmCanvas,
      appBar: AppBar(
        title: const Text('Publicație'),
        backgroundColor: _warmCanvas,
        elevation: 0,
        leading: _BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}

class PublicationIssueDetailScreen extends StatefulWidget {
  final int issueId;
  final PublicationIssue? initialIssue;

  const PublicationIssueDetailScreen({
    super.key,
    required this.issueId,
    this.initialIssue,
  });

  @override
  State<PublicationIssueDetailScreen> createState() =>
      _PublicationIssueDetailScreenState();
}

class _PublicationIssueDetailScreenState
    extends State<PublicationIssueDetailScreen> {
  final ApiService _apiService = ApiService();
  PublicationIssue? _issue;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAiSummaryLoading = false;
  String? _aiSummary;
  List<String> _aiKeyPoints = [];
  String? _aiDisclaimer;
  String? _aiSummaryError;

  @override
  void initState() {
    super.initState();
    _issue = widget.initialIssue;
    if (_issue != null) {
      _logIssuePdf('initial', _issue!);
      _logPdfDiagnostics(_issue!);
    }
    _loadIssue();
  }

  Future<void> _loadIssue() async {
    setState(() {
      _isLoading = _issue == null;
      _errorMessage = null;
    });

    try {
      final issue = await _apiService.getPublicationIssueDetail(widget.issueId);
      if (!mounted) return;
      setState(() {
        _issue = issue;
        _isLoading = false;
      });
      _logIssuePdf('detail', issue);
      _logPdfDiagnostics(issue);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut încărca ediția.';
      });
    }
  }

  void _logIssuePdf(String source, PublicationIssue issue) {
    if (!kDebugMode) return;
    debugPrint(
      'PublicationIssueDetail PDF [$source]: '
      'id=${issue.id}, '
      'issue.pdfUrl=${issue.pdfUrl}, '
      'viewerUrl=${issue.pdfUrl?.trim().isEmpty == false ? _apiService.getPublicationIssuePdfUrl(issue.id) : null}',
    );
  }

  Future<void> _logPdfDiagnostics(PublicationIssue issue) async {
    final sourcePdfUrl = issue.pdfUrl?.trim();
    if (sourcePdfUrl == null || sourcePdfUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'PublicationIssueDetail PDF diagnostics skipped: pdf_url missing for issue ${issue.id}',
        );
      }
      return;
    }
    await _apiService.getPublicationIssuePdfDiagnostics(issue.id);
  }

  String _friendlyAiError(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );
    return message.trim().isEmpty
        ? 'Rezumatul nu a putut fi generat. Încearcă din nou.'
        : message;
  }

  Future<void> _generateAiSummary() async {
    final issue = _issue;
    final pdfUrl = issue?.pdfUrl?.trim();
    if (_isAiSummaryLoading ||
        issue == null ||
        pdfUrl == null ||
        pdfUrl.isEmpty) {
      return;
    }

    setState(() {
      _isAiSummaryLoading = true;
      _aiSummaryError = null;
    });

    try {
      final result = await _apiService.generatePublicationIssueAiSummaryResult(
        issue.id,
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
        _aiSummaryError = null;
        _isAiSummaryLoading = false;
      });
    } catch (e) {
      final message = _friendlyAiError(e);
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

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      children: const [
        _SkeletonBox(height: 420, radius: 34),
        SizedBox(height: 22),
        _SkeletonBox(width: 190, height: 24, radius: 10),
        SizedBox(height: 14),
        _SkeletonBox(height: 110, radius: 24),
        SizedBox(height: 18),
        _SkeletonBox(height: 270, radius: 28),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _InlineEmptyState(
          title: 'Ediția nu s-a putut încărca',
          message: _errorMessage ?? 'Încearcă din nou în câteva momente.',
          actionLabel: 'Reîncearcă',
          onAction: _loadIssue,
        ),
      ),
    );
  }

  void _openPdfViewer(PublicationIssue issue, String pdfUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PublicationIssuePdfViewerScreen(issue: issue, pdfUrl: pdfUrl),
      ),
    );
  }

  Widget _buildHero(PublicationIssue issue, String? dateLabel) {
    final publicationName = issue.publicationName?.trim();
    final description = issue.description?.trim();
    final hasPdf = issue.pdfUrl?.trim().isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: _warmSurface,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: _medicalTeal.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: _editorialNavy.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -18,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Color(0xFF1E1E1E)],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _EditorialCover(
                      image: _IssueImage(
                        url: issue.coverImageUrl,
                        fit: BoxFit.cover,
                      ),
                      width: 132,
                      height: 184,
                      radius: 18,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (publicationName != null &&
                              publicationName.isNotEmpty) ...[
                            _PremiumPill(
                              label: publicationName,
                              svgAsset: _bookPagesIconAsset,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.13,
                              ),
                              borderColor: Colors.white.withValues(alpha: 0.20),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            issue.displayLabel,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            dateLabel == null
                                ? 'An ${issue.year} • Nr. ${issue.issueNumber}'
                                : 'An ${issue.year} • Nr. ${issue.issueNumber} • $dateLabel',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateLabel != null)
                      _PremiumPill(
                        label: dateLabel,
                        icon: Icons.event_available_outlined,
                        color: _medicalTeal,
                      ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        title: 'Descriere editorială',
                        subtitle: 'Contextul acestui număr',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(
                          color: PulseTheme.textPrimary,
                          fontSize: 16,
                          height: 1.58,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (hasPdf) ...[
                      SizedBox(
                        height: description != null && description.isNotEmpty
                            ? 18
                            : dateLabel != null
                            ? 16
                            : 0,
                      ),
                      AiSummaryButton(
                        isLoading: _isAiSummaryLoading,
                        onGenerate: _generateAiSummary,
                      ),
                      if (_aiSummary?.trim().isNotEmpty == true ||
                          _aiSummaryError?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        AiSummaryInlineSection(
                          summary: _aiSummary,
                          keyPoints: _aiKeyPoints,
                          disclaimer: _aiDisclaimer,
                          error: _aiSummaryError,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null && _issue == null) return _buildError();

    final issue = _issue!;
    final dateLabel = _formatDate(issue.publishedAt);
    final sourcePdfUrl = issue.pdfUrl?.trim();
    final viewerPdfUrl = sourcePdfUrl == null || sourcePdfUrl.isEmpty
        ? null
        : _apiService.getPublicationIssuePdfUrl(issue.id);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 34),
      children: [
        _buildHero(issue, dateLabel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PdfPreviewCard(
            issue: issue,
            pdfUrl: viewerPdfUrl,
            onRead: viewerPdfUrl == null
                ? null
                : () => _openPdfViewer(issue, viewerPdfUrl),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmCanvas,
      appBar: AppBar(
        title: const Text('Detalii ediție'),
        backgroundColor: _warmCanvas,
        elevation: 0,
        leading: _BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}

class PdfPreviewCard extends StatefulWidget {
  final PublicationIssue issue;
  final String? pdfUrl;
  final VoidCallback? onRead;

  const PdfPreviewCard({
    super.key,
    required this.issue,
    required this.pdfUrl,
    required this.onRead,
  });

  @override
  State<PdfPreviewCard> createState() => _PdfPreviewCardState();
}

class AiSummaryInlineSection extends StatelessWidget {
  final String? summary;
  final List<String> keyPoints;
  final String? disclaimer;
  final String? error;

  const AiSummaryInlineSection({
    super.key,
    required this.summary,
    required this.keyPoints,
    required this.disclaimer,
    required this.error,
  });

  bool get _hasSummary => summary?.trim().isNotEmpty == true;
  bool get _hasError => error?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    if (!_hasSummary && !_hasError) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _medicalTeal.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _medicalTeal.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 14),
            color: _medicalTeal.withValues(alpha: 0.12),
          ),
          if (_hasError) _AiSummaryErrorState(error: error),
          if (_hasSummary)
            _AiSummaryContent(
              summary: summary!.trim(),
              keyPoints: keyPoints,
              disclaimer: disclaimer,
            ),
        ],
      ),
    );
  }
}

class AiSummaryButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGenerate;

  const AiSummaryButton({
    super.key,
    required this.isLoading,
    required this.onGenerate,
  });

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onGenerate,
        style: FilledButton.styleFrom(
          backgroundColor: PulseTheme.textPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PulseTheme.textPrimary.withValues(
            alpha: 0.62,
          ),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.auto_awesome_outlined, size: 19),
            const SizedBox(width: 9),
            Text(
              isLoading ? 'Se generează rezumatul...' : 'Generează rezumat AI',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildGenerateButton();
}

class _AiSummaryContent extends StatelessWidget {
  final String summary;
  final List<String> keyPoints;
  final String? disclaimer;

  const _AiSummaryContent({
    required this.summary,
    required this.keyPoints,
    required this.disclaimer,
  });

  Widget _buildSummaryState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: _medicalTeal, size: 20),
            SizedBox(width: 8),
            Text(
              'Rezumat AI',
              style: TextStyle(
                color: _editorialNavy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          summary.trim(),
          style: const TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (keyPoints.isNotEmpty) ...[
          const SizedBox(height: 15),
          const Text(
            'Idei cheie',
            style: TextStyle(
              color: _editorialNavy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ...keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 9),
                    decoration: const BoxDecoration(
                      color: _medicalTeal,
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
        if (disclaimer?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            disclaimer!.trim(),
            style: const TextStyle(
              color: PulseTheme.textTertiary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _buildSummaryState();
}

class _AiSummaryErrorState extends StatelessWidget {
  final String? error;

  const _AiSummaryErrorState({required this.error});

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.newsContent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PulseTheme.newsContent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
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
              error ?? 'Rezumatul nu a putut fi generat. Încearcă din nou.',
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

  @override
  Widget build(BuildContext context) => _buildErrorState();
}

class _PdfPreviewCardState extends State<PdfPreviewCard> {
  bool _isPreviewLoading = true;
  String? _previewError;

  String? get _pdfUrl {
    final value = widget.pdfUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  @override
  void didUpdateWidget(covariant PdfPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfUrl != widget.pdfUrl) {
      setState(() {
        _isPreviewLoading = _pdfUrl != null;
        _previewError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfUrl = _pdfUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warmSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _medicalTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _editorialNavy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Preview PDF',
            subtitle: 'Consultă ediția direct în aplicație',
          ),
          const SizedBox(height: 14),
          if (pdfUrl == null)
            const _InlineEmptyState(
              title: 'PDF-ul ediției nu este disponibil momentan.',
              message:
                  'Când fișierul va fi publicat, îl vei putea citi direct aici.',
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 320,
                decoration: const BoxDecoration(color: Color(0xFFF3F4F0)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: SfPdfViewer.network(
                          pdfUrl,
                          canShowScrollHead: false,
                          canShowPaginationDialog: false,
                          pageLayoutMode: PdfPageLayoutMode.single,
                          onDocumentLoaded: (_) {
                            if (!mounted) return;
                            setState(() => _isPreviewLoading = false);
                          },
                          onDocumentLoadFailed: (details) {
                            if (kDebugMode) {
                              debugPrint(
                                'SfPdfViewer preview failed: '
                                'url=$pdfUrl, '
                                'error=${details.error}, '
                                'description=${details.description}',
                              );
                            }
                            if (!mounted) return;
                            setState(() {
                              _isPreviewLoading = false;
                              _previewError = _pdfOpenErrorMessage;
                            });
                          },
                        ),
                      ),
                    ),
                    if (!_isPreviewLoading && _previewError == null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                      ),
                    if (_isPreviewLoading) const _PdfLoadingOverlay(),
                    if (_previewError != null)
                      _PdfErrorOverlay(
                        title: 'Documentul nu a putut fi deschis.',
                        message: _previewError!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onRead,
                style: FilledButton.styleFrom(
                  backgroundColor: PulseTheme.textPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Citește ediția',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(width: 8),
                    _ArrowRightIcon(color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PublicationIssuePdfViewerScreen extends StatefulWidget {
  final PublicationIssue issue;
  final String pdfUrl;

  const PublicationIssuePdfViewerScreen({
    super.key,
    required this.issue,
    required this.pdfUrl,
  });

  @override
  State<PublicationIssuePdfViewerScreen> createState() =>
      _PublicationIssuePdfViewerScreenState();
}

class _PublicationIssuePdfViewerScreenState
    extends State<PublicationIssuePdfViewerScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmCanvas,
      appBar: AppBar(
        title: Text(
          widget.issue.displayLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _warmCanvas,
        elevation: 0,
        leading: _BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          decoration: BoxDecoration(
            color: _warmSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _medicalTeal.withValues(alpha: 0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: SfPdfViewer.network(
                  widget.pdfUrl,
                  canShowScrollHead: true,
                  canShowPaginationDialog: true,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  onDocumentLoaded: (_) {
                    if (!mounted) return;
                    setState(() {
                      _isLoading = false;
                      _hasError = false;
                    });
                  },
                  onDocumentLoadFailed: (details) {
                    if (kDebugMode) {
                      debugPrint(
                        'SfPdfViewer full screen failed: '
                        'url=${widget.pdfUrl}, '
                        'error=${details.error}, '
                        'description=${details.description}',
                      );
                    }
                    if (!mounted) return;
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                  },
                ),
              ),
              if (_isLoading) const _PdfLoadingOverlay(),
              if (_hasError)
                const _PdfErrorOverlay(
                  title: 'Documentul nu a putut fi deschis.',
                  message: _pdfOpenErrorMessage,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfLoadingOverlay extends StatelessWidget {
  const _PdfLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _warmSurface.withValues(alpha: 0.92)),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                color: _medicalTeal,
                strokeWidth: 2.8,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Se pregătește preview-ul...',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfErrorOverlay extends StatelessWidget {
  final String title;
  final String message;

  const _PdfErrorOverlay({
    this.title = 'Documentul nu a putut fi deschis.',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _warmSurface.withValues(alpha: 0.96)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BookPagesIcon(color: _medicalTeal, size: 34),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _editorialNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message.isEmpty
                    ? 'PDF-ul ediției nu s-a putut încărca momentan.'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PulseTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
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

class _FeaturedIssueCard extends StatelessWidget {
  final PublicationIssue issue;
  final String? dateLabel;
  final Widget Function(String? url) imageBuilder;
  final VoidCallback onTap;

  const _FeaturedIssueCard({
    required this.issue,
    required this.dateLabel,
    required this.imageBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = issue.description?.trim();

    return _Pressable(
      onTap: onTap,
      borderRadius: 30,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _warmSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _medicalTeal.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: _editorialNavy.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditorialCover(
              image: imageBuilder(issue.coverImageUrl),
              width: 132,
              height: 182,
              radius: 18,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PremiumPill(
                    label: 'Cea mai recentă',
                    color: _medicalTeal,
                    backgroundColor: Color(0x180F766E),
                    borderColor: Color(0x330F766E),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    issue.displayLabel,
                    style: const TextStyle(
                      color: _editorialNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dateLabel == null
                        ? 'An ${issue.year} • Nr. ${issue.issueNumber}'
                        : 'An ${issue.year} • Nr. ${issue.issueNumber} • $dateLabel',
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 13,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Vezi numărul',
                        style: TextStyle(
                          color: PulseTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 6),
                      _ArrowRightIcon(color: PulseTheme.textPrimary, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveIssueCard extends StatelessWidget {
  final PublicationIssue issue;
  final String? dateLabel;
  final Widget Function(String? url) imageBuilder;
  final VoidCallback onTap;

  const _ArchiveIssueCard({
    required this.issue,
    required this.dateLabel,
    required this.imageBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = issue.description?.trim();

    return _Pressable(
      onTap: onTap,
      borderRadius: 26,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _warmSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _medicalTeal.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: _editorialNavy.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 12),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditorialCover(
              image: imageBuilder(issue.coverImageUrl),
              width: 78,
              height: 108,
              radius: 13,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.displayLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _editorialNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    dateLabel == null
                        ? 'An ${issue.year} • Nr. ${issue.issueNumber}'
                        : 'An ${issue.year} • Nr. ${issue.issueNumber} • $dateLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: PulseTheme.textPrimary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: _ArrowRightIcon(color: PulseTheme.textPrimary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const _IssueImage({required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return _IssueFallback();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _IssueFallback(),
      );
    }

    final assetPath = value.startsWith('assets/')
        ? value
        : value.startsWith('images/')
        ? 'assets/$value'
        : 'assets/images/$value';
    return Image.asset(
      assetPath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _IssueFallback(),
    );
  }
}

class _IssueFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F3F1), Color(0xFFFFF8E6)],
        ),
      ),
      child: const Center(child: _BookPagesIcon(color: _medicalTeal, size: 36)),
    );
  }
}

class _BookPagesIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _BookPagesIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _bookPagesIconAsset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _ArrowRightIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _ArrowRightIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _arrowRightIconAsset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Înapoi',
      onPressed: onPressed,
      icon: SvgPicture.asset(
        _arrowBackwardIconAsset,
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          PulseTheme.textPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  final String? logoUrl;
  final Widget Function(String? url) imageBuilder;

  const _HeroLogo({required this.logoUrl, required this.imageBuilder});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(width: 86, height: 86, child: imageBuilder(logoUrl));
  }
}

class _EditorialCover extends StatelessWidget {
  final Widget image;
  final double width;
  final double height;
  final double radius;

  const _EditorialCover({
    required this.image,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: _editorialNavy,
        backgroundColor: _warmSurface,
        side: BorderSide(
          color: selected
              ? _editorialNavy
              : _medicalTeal.withValues(alpha: 0.12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : PulseTheme.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? svgAsset;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;

  const _PremiumPill({
    required this.label,
    this.icon,
    this.svgAsset,
    required this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null) ...[
            SvgPicture.asset(
              svgAsset!,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _editorialNavy,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineEmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _warmSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _medicalTeal.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _medicalTeal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const _BookPagesIcon(color: _medicalTeal, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _editorialNavy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: _medicalTeal,
                side: BorderSide(color: _medicalTeal.withValues(alpha: 0.28)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  const _Pressable({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: PulseTheme.animFast,
        curve: PulseTheme.animCurve,
        child: widget.child,
      ),
    );
  }
}

class _PublicationSkeleton extends StatelessWidget {
  const _PublicationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(height: 314, radius: 32),
          const SizedBox(height: 28),
          const _SkeletonBox(width: 190, height: 24, radius: 10),
          const SizedBox(height: 12),
          const _SkeletonBox(height: 218, radius: 30),
          const SizedBox(height: 28),
          const _SkeletonBox(width: 150, height: 22, radius: 10),
          const SizedBox(height: 14),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: _SkeletonBox(height: 136, radius: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBox({this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.76),
            const Color(0xFFEAE5D8),
            Colors.white.withValues(alpha: 0.76),
          ],
        ),
      ),
    );
  }
}
