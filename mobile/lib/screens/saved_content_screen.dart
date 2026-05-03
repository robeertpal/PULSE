import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_loading_indicator.dart';

class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  final ApiService _apiService = ApiService();
  List<ContentItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedContent();
  }

  Future<void> _loadSavedContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getSavedContent();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nu am putut incarca salvarile.';
        });
      }
    }
  }

  Future<void> _removeSaved(int contentItemId) async {
    final previousItems = List<ContentItem>.from(_items);
    setState(() {
      _items = _items.where((item) => item.id != contentItemId).toList();
    });

    try {
      await _apiService.unsaveContent(contentItemId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eliminat din salvate'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = previousItems;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut elimina continutul salvat'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: PremiumLoadingIndicator(text: 'Se incarca salvarile...'),
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
                onPressed: _loadSavedContent,
                child: const Text('Reincearca'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 36, 20, 0),
        child: EmptyStateCard(
          message: 'Nu ai continut salvat inca.',
          iconAsset: 'assets/icons/heart.svg',
          baseColor: PulseTheme.primary,
        ),
      );
    }

    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadSavedContent,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        itemBuilder: (context, index) {
          final item = _items[index];
          return SizedBox(
            height: 300,
            child: Center(
              child: ContentCard.fromModel(
                item,
                isSaved: true,
                onSaveToggle: _removeSaved,
                cardWidth: double.infinity,
                margin: EdgeInsets.zero,
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 18),
        itemCount: _items.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        title: const Text('Salvate'),
        backgroundColor: PulseTheme.background,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}
