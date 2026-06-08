import 'package:flutter/material.dart';

import '../models/content_submission.dart';
import '../models/filter_option.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/pulse_animated_background.dart';

class ContentSubmissionFormScreen extends StatefulWidget {
  final int? submissionId;

  const ContentSubmissionFormScreen({super.key, this.submissionId});

  @override
  State<ContentSubmissionFormScreen> createState() =>
      _ContentSubmissionFormScreenState();
}

class _ContentSubmissionFormScreenState
    extends State<ContentSubmissionFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sourceUrlController = TextEditingController();

  ContentSubmission? _submission;
  List<FilterOption> _categories = [];
  List<FilterOption> _specializations = [];
  String _contentType = 'article';
  int _categoryId = 0;
  int _specializationId = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const Map<String, String> _contentTypes = {
    'article': 'Articol',
    'news': 'Stire',
    'course': 'Curs',
    'event': 'Eveniment',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  bool get _canEdit => _submission?.canEdit ?? true;

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoriesFuture = _apiService.getCategories();
      final specializationsFuture = _apiService.getSpecializations();
      final submissionFuture = widget.submissionId == null
          ? Future<ContentSubmission?>.value()
          : _apiService.getContentSubmission(widget.submissionId!);

      final categories = await categoriesFuture;
      final specializations = await specializationsFuture;
      final submission = await submissionFuture;

      if (submission != null) {
        _submission = submission;
        _titleController.text = submission.title;
        _summaryController.text = submission.summary ?? '';
        _bodyController.text = submission.body;
        _imageUrlController.text = submission.imageUrl ?? '';
        _sourceUrlController.text = submission.sourceUrl ?? '';
        _contentType = submission.contentType;
        _categoryId = submission.categoryId ?? 0;
        _specializationId = submission.specializationId ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _specializations = specializations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Camp obligatoriu';
    }
    return null;
  }

  String? _optionalUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return 'URL-ul trebuie sa inceapa cu http:// sau https://';
    }
    return null;
  }

  Map<String, dynamic> _payload() {
    return {
      'title': _titleController.text.trim(),
      'content_type': _contentType,
      if (_categoryId > 0) 'category_id': _categoryId,
      if (_specializationId > 0) 'specialization_id': _specializationId,
      if (_summaryController.text.trim().isNotEmpty)
        'summary': _summaryController.text.trim(),
      'body': _bodyController.text.trim(),
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
      if (_sourceUrlController.text.trim().isNotEmpty)
        'source_url': _sourceUrlController.text.trim(),
    };
  }

  Future<ContentSubmission?> _saveDraft({bool showMessage = true}) async {
    if (!_canEdit || _isSaving) return _submission;
    if (!_formKey.currentState!.validate()) return null;

    setState(() {
      _isSaving = true;
    });

    try {
      final saved = _submission == null
          ? await _apiService.createContentSubmission(_payload())
          : await _apiService.updateContentSubmission(
              _submission!.id,
              _payload(),
            );
      if (!mounted) return saved;
      setState(() {
        _submission = saved;
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft salvat.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
      return saved;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _submitForReview() async {
    if (!_canEdit || _isSaving) return;
    final saved = await _saveDraft(showMessage: false);
    if (saved == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final submitted = await _apiService.submitContentSubmission(saved.id);
      if (!mounted) return;
      setState(() {
        _submission = submitted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contributia a fost trimisa pentru review.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _canEdit && !_isSaving,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: PulseTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: PulseTheme.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PulseTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: _canEdit && !_isSaving ? onChanged : null,
      dropdownColor: PulseTheme.surfaceElevated,
      style: const TextStyle(color: PulseTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: PulseTheme.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
    );
  }

  Widget _statusCard() {
    final submission = _submission;
    if (submission == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ${submission.statusLabel}',
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (submission.reviewNotes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              submission.reviewNotes!,
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (!_canEdit) ...[
            const SizedBox(height: 10),
            const Text(
              'Aceasta contributie nu mai poate fi editata in etapa curenta.',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _statusCard(),
          if (_submission != null) const SizedBox(height: 16),
          _field(
            label: 'Titlu',
            controller: _titleController,
            validator: _requiredText,
          ),
          const SizedBox(height: 14),
          _dropdown<String>(
            label: 'Tip continut',
            value: _contentType,
            items: _contentTypes.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _contentType = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _dropdown<int>(
            label: 'Categorie',
            value: _categoryId,
            items: [
              const DropdownMenuItem(value: 0, child: Text('Fara categorie')),
              ..._categories.map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _categoryId = value ?? 0;
              });
            },
          ),
          const SizedBox(height: 14),
          _dropdown<int>(
            label: 'Specializare',
            value: _specializationId,
            items: [
              const DropdownMenuItem(
                value: 0,
                child: Text('Fara specializare'),
              ),
              ..._specializations.map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _specializationId = value ?? 0;
              });
            },
          ),
          const SizedBox(height: 14),
          _field(label: 'Rezumat', controller: _summaryController, maxLines: 3),
          const SizedBox(height: 14),
          _field(
            label: 'Continut',
            controller: _bodyController,
            maxLines: 10,
            validator: _requiredText,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'URL imagine optional',
            controller: _imageUrlController,
            validator: _optionalUrl,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'URL sursa optional',
            controller: _sourceUrlController,
            validator: _optionalUrl,
          ),
          const SizedBox(height: 22),
          if (_canEdit) ...[
            OutlinedButton(
              onPressed: _isSaving ? null : () => _saveDraft(),
              style: OutlinedButton.styleFrom(
                foregroundColor: PulseTheme.primaryLight,
                side: BorderSide(
                  color: PulseTheme.primaryLight.withValues(alpha: 0.42),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(_isSaving ? 'Se salveaza...' : 'Salveaza draft'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitForReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Trimite pentru review',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: Text(
          widget.submissionId == null ? 'Trimite continut' : 'Contributie',
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PulseAnimatedBackground()),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: PulseTheme.primaryLight,
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PulseTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: _loadInitialData,
                            child: const Text('Reincearca'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildForm(),
          ),
        ],
      ),
    );
  }
}
