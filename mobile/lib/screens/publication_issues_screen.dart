import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication_issue.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/premium_loading_indicator.dart';

class PublicationIssuesScreen extends StatefulWidget {
  final int publicationId;
  final String publicationName;
  final String? publicationDescription;
  final String? publicationLogoUrl;

  const PublicationIssuesScreen({
    super.key,
    required this.publicationId,
    required this.publicationName,
    this.publicationDescription,
    this.publicationLogoUrl,
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
  int? _selectedIssueNumber;

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
      final years = _yearsFor(issues);
      if (!mounted) return;
      final selectedYear = years.isNotEmpty ? years.first : null;
      final selectedIssues = _issuesForYear(selectedYear, issues);
      setState(() {
        _issues = issues;
        _selectedYear = selectedYear;
        _selectedIssueNumber =
            selectedIssues.isNotEmpty ? selectedIssues.first.issueNumber : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut încărca edițiile revistei.';
      });
    }
  }

  List<int> _yearsFor(List<PublicationIssue> issues) {
    final years = issues.map((issue) => issue.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<PublicationIssue> _issuesForYear(
    int? year, [
    List<PublicationIssue>? source,
  ]) {
    if (year == null) return [];
    final issues = (source ?? _issues)
        .where((issue) => issue.year == year)
        .toList()
      ..sort((a, b) => b.issueNumber.compareTo(a.issueNumber));
    return issues;
  }

  List<PublicationIssue> _issuesForSelectedYearAndIssue() {
    final issuesForYear = _issuesForYear(_selectedYear);
    if (_selectedIssueNumber == null) return issuesForYear;
    return issuesForYear
        .where((issue) => issue.issueNumber == _selectedIssueNumber)
        .toList();
  }

  String _issueCountLabel(int count) {
    if (count == 1) return '1 ediție găsită';
    return '$count ediții găsite';
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

  Widget _imageFor(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    IconData fallbackIcon = Icons.menu_book_outlined,
  }) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return _imageFallback(
        width: width,
        height: height,
        fallbackIcon: fallbackIcon,
      );
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _imageFallback(
          width: width,
          height: height,
          fallbackIcon: fallbackIcon,
        ),
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
      errorBuilder: (context, error, stackTrace) => _imageFallback(
        width: width,
        height: height,
        fallbackIcon: fallbackIcon,
      ),
    );
  }

  Widget _imageFallback({
    double? width,
    double? height,
    required IconData fallbackIcon,
  }) {
    return Container(
      width: width,
      height: height,
      color: PulseTheme.magazineContent.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: PulseTheme.magazineContent,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final description = widget.publicationDescription?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: PulseTheme.magazineContent.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: PulseTheme.magazineContent.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
              spreadRadius: -14,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PulseTheme.magazineContent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: PulseTheme.magazineContent.withValues(alpha: 0.14),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _imageFor(
                  widget.publicationLogoUrl,
                  width: 62,
                  height: 62,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.library_books_outlined,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  widget.publicationName,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Alege anul și ediția dorită',
                  style: TextStyle(
                    color: PulseTheme.magazineContent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
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

  Widget _buildYearSelector(List<int> years) {
    if (years.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alege anul',
            style: TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: years.map((year) {
                final selected = year == _selectedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: AnimatedContainer(
                    duration: PulseTheme.animFast,
                    curve: PulseTheme.animCurve,
                    decoration: BoxDecoration(
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: PulseTheme.magazineContent.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                                spreadRadius: -6,
                              ),
                            ]
                          : const [],
                    ),
                    child: ChoiceChip(
                      label: Text(year.toString()),
                      selected: selected,
                      onSelected: (_) {
                        final issues = _issuesForYear(year);
                        setState(() {
                          _selectedYear = year;
                          _selectedIssueNumber = issues.isNotEmpty
                              ? issues.first.issueNumber
                              : null;
                        });
                      },
                      showCheckmark: false,
                      selectedColor: PulseTheme.magazineContent,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? PulseTheme.magazineContent
                            : PulseTheme.border,
                        width: selected ? 1.2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : PulseTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSelector(List<PublicationIssue> issues) {
    if (issues.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alege ediția',
            style: TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: issues.map((issue) {
                final selected = issue.issueNumber == _selectedIssueNumber;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: AnimatedContainer(
                    duration: PulseTheme.animFast,
                    curve: PulseTheme.animCurve,
                    decoration: BoxDecoration(
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: PulseTheme.magazineContent.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                                spreadRadius: -6,
                              ),
                            ]
                          : const [],
                    ),
                    child: ChoiceChip(
                      label: Text('Nr. ${issue.issueNumber}'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedIssueNumber = issue.issueNumber;
                        });
                      },
                      showCheckmark: false,
                      selectedColor: PulseTheme.magazineContent,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? PulseTheme.magazineContent
                            : PulseTheme.border,
                        width: selected ? 1.2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : PulseTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(PublicationIssue issue) {
    final dateLabel = _formatDate(issue.publishedAt);
    final description = issue.description?.trim();
    final hasIssueUrl = issue.issueUrl?.trim().isNotEmpty == true;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PublicationIssueDetailScreen(
              issueId: issue.id,
              initialIssue: issue,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PulseTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: PulseTheme.magazineContent.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 14),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _imageFor(
                issue.coverImageUrl,
                width: 92,
                height: 126,
                fallbackIcon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue.publicationName ?? widget.publicationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PulseTheme.magazineContent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (hasIssueUrl) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PulseTheme.magazineContent.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PDF',
                            style: TextStyle(
                              color: PulseTheme.magazineContent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.displayLabel,
                    style: const TextStyle(
                      color: PulseTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An ${issue.year} • Ediția ${issue.issueNumber}',
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Publicat la $dateLabel',
                      style: const TextStyle(
                        color: PulseTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSelectionEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: PulseTheme.magazineContent.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            color: PulseTheme.magazineContent,
            size: 30,
          ),
          SizedBox(height: 12),
          Text(
            'Nu există ediții pentru selecția curentă.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: PremiumLoadingIndicator(text: 'Se încarcă edițiile...'),
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
                onPressed: _loadIssues,
                child: const Text('Reîncearcă'),
              ),
            ],
          ),
        ),
      );
    }

    if (_issues.isEmpty) {
      return RefreshIndicator(
        color: PulseTheme.primary,
        onRefresh: _loadIssues,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            _buildHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Center(
                child: Text(
                  'Nu există numere publicate pentru această revistă.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PulseTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final years = _yearsFor(_issues);
    final issuesForSelectedYear = _issuesForYear(_selectedYear);
    final filteredIssues = _issuesForSelectedYearAndIssue();

    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadIssues,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHeader(),
          _buildYearSelector(years),
          _buildIssueSelector(issuesForSelectedYear),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _issueCountLabel(filteredIssues.length),
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (filteredIssues.isEmpty)
                  _buildSelectionEmptyState()
                else
                  ...filteredIssues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildIssueCard(issue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: const Text('Numere / Ediții'),
        backgroundColor: PulseTheme.background,
        elevation: 0,
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

  @override
  void initState() {
    super.initState();
    _issue = widget.initialIssue;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nu am putut încărca ediția.';
      });
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

  Widget _cover(PublicationIssue issue) {
    final url = issue.coverImageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Container(
        height: 280,
        color: PulseTheme.magazineContent.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(
            Icons.menu_book_outlined,
            color: PulseTheme.magazineContent,
            size: 48,
          ),
        ),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: 320,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 280,
          color: PulseTheme.magazineContent.withValues(alpha: 0.08),
        ),
      );
    }

    final assetPath = url.startsWith('assets/')
        ? url
        : url.startsWith('images/')
            ? 'assets/$url'
            : 'assets/images/$url';
    return Image.asset(
      assetPath,
      height: 320,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 280,
        color: PulseTheme.magazineContent.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openIssueUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL ediție invalid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut deschide ediția.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: PremiumLoadingIndicator(text: 'Se încarcă ediția...'),
      );
    }

    if (_errorMessage != null && _issue == null) {
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
                onPressed: _loadIssue,
                child: const Text('Reîncearcă'),
              ),
            ],
          ),
        ),
      );
    }

    final issue = _issue!;
    final dateLabel = _formatDate(issue.publishedAt);
    final description = issue.description?.trim();
    final issueUrl = issue.issueUrl?.trim();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: _cover(issue),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                issue.publicationName ?? 'Revistă',
                style: const TextStyle(
                  color: PulseTheme.magazineContent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.displayLabel,
                style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 18),
              _metaRow('An', issue.year.toString()),
              _metaRow('Ediția', issue.issueNumber.toString()),
              if (dateLabel != null) _metaRow('Publicat la', dateLabel),
              if (issueUrl != null && issueUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openIssueUrl(issueUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseTheme.magazineContent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text(
                      'Deschide ediția',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  description,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: const Text('Detalii ediție'),
        backgroundColor: PulseTheme.background,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}
