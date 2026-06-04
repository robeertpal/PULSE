import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _surfaceSoft = Color(0xFF181818);
  static const Color _pink = Color(0xFFFF4FA3);

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getMyPayments();
      if (!mounted) return;
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openTransactionDetail(Map<String, dynamic> transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Ian',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Iun',
        'Iul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatAmountValue(dynamic amount) {
    if (amount is num) return amount.toStringAsFixed(2);

    final parsed = num.tryParse(amount?.toString() ?? '');
    if (parsed != null) return parsed.toStringAsFixed(2);

    return amount?.toString() ?? '0.00';
  }

  Widget _buildAmountText(dynamic amount, dynamic currency) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.15,
        ),
        children: [
          TextSpan(text: '-${_formatAmountValue(amount)} '),
          TextSpan(
            text: currency?.toString() ?? 'RON',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = tx['amount'] ?? 0.0;
    final currency = tx['currency'] ?? 'RON';
    final dateStr = tx['paid_at'] ?? tx['created_at'];
    final cardBrand = tx['card_brand'] as String?;
    final cardLast4 = tx['card_last4'] as String?;
    final title = tx['content_title'] as String? ?? 'Tranzacție PULSE';
    final type = tx['content_type'] as String?;

    String iconPath;
    switch (type) {
      case 'event':
        iconPath = 'assets/icons/events.svg';
        break;
      case 'course':
        iconPath = 'assets/icons/graduation.svg';
        break;
      case 'publication':
        iconPath = 'assets/icons/books.svg';
        break;
      case 'news':
        iconPath = 'assets/icons/newspaper.svg';
        break;
      case 'article':
        iconPath = 'assets/icons/book.pages.svg';
        break;
      default:
        iconPath = 'assets/icons/wallet.svg';
    }

    return GestureDetector(
      onTap: () => _openTransactionDetail(tx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: SvgPicture.asset(
                                    iconPath,
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      _pink,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        height: 1.18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(dateStr),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 98,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _openTransactionDetail(tx),
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/arrow.right.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withValues(alpha: 0.76),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildAmountText(amount, currency),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _pink.withValues(alpha: 0.14),
                      const Color(0xFFFF8A3D).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _pink.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/creditcard.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.72),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cardBrand != null && cardLast4 != null
                            ? '$cardBrand •••• $cardLast4'
                            : 'Metodă de plată indisponibilă',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: cardBrand != null && cardLast4 != null
                                ? 0.78
                                : 0.52,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: SvgPicture.asset(
              'assets/icons/wallet.svg',
              width: 48,
              height: 48,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nu există tranzacții',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Când vei efectua o plată,\naceasta va apărea aici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: _pink, size: 48),
            const SizedBox(height: 16),
            const Text(
              'A apărut o eroare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Eroare necunoscută',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceSoft,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Reîncearcă',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SkeletonBlock(width: 40, height: 40, radius: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBlock(width: 100, height: 16, radius: 4),
                          SizedBox(height: 6),
                          SkeletonBlock(width: 120, height: 12, radius: 4),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      SkeletonBlock(width: 70, height: 16, radius: 4),
                      SizedBox(height: 8),
                      SkeletonBlock(width: 60, height: 20, radius: 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SkeletonBlock(
                width: double.infinity,
                height: 40,
                radius: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        leadingWidth: 72,
        titleSpacing: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ProfileBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const ProfileGradientHeading('Tranzacțiile mele'),
      ),
      body: _isLoading
          ? _buildSkeletons()
          : _errorMessage != null
          ? _buildErrorState()
          : _transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _pink,
              backgroundColor: _surfaceSoft,
              onRefresh: _loadTransactions,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 40),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(_transactions[index]);
                },
              ),
            ),
    );
  }
}
