import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'content_detail_screen.dart';
import 'profile_screen.dart';
import 'ticket_detail_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _textDim = Colors.white70;

  bool _summaryExpanded = false;
  bool _technicalExpanded = false;

  Map<String, dynamic> get transaction => widget.transaction;

  String _formatDate(Object? isoDate) {
    if (isoDate == null) return 'Indisponibil';
    final value = isoDate.toString();
    try {
      final dt = DateTime.parse(value).toLocal();
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
      return value;
    }
  }

  String _formatAmountValue(Object? amount) {
    if (amount is num) return amount.toStringAsFixed(2);
    final parsed = num.tryParse(amount?.toString() ?? '');
    if (parsed != null) return parsed.toStringAsFixed(2);
    return (amount ?? '0.00').toString();
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _contentTypeLabel(String? type) {
    switch (type) {
      case 'event':
        return 'Eveniment';
      case 'course':
        return 'Curs';
      case 'publication':
        return 'Revistă';
      case 'article':
        return 'Articol';
      case 'news':
        return 'Știre';
      case 'subscription':
        return 'Abonament';
      default:
        return 'Conținut';
    }
  }

  String _getIconForContentType(String? type) {
    switch (type) {
      case 'event':
        return 'assets/icons/events.svg';
      case 'course':
        return 'assets/icons/graduation.svg';
      case 'publication':
        return 'assets/icons/books.svg';
      case 'news':
        return 'assets/icons/newspaper.svg';
      case 'article':
        return 'assets/icons/book.pages.svg';
      default:
        return 'assets/icons/wallet.svg';
    }
  }

  String _formatPaymentMethod(String? brand, String? last4) {
    if (brand != null && last4 != null && last4.isNotEmpty) {
      return '$brand •••• $last4';
    }
    return 'Metodă de plată indisponibilă';
  }

  void _openContentDetail(int contentItemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentItemId: contentItemId),
      ),
    );
  }

  void _openTicketDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(
          ticket: {
            'event_id': transaction['event_id'],
            'content_item_id': transaction['content_item_id'],
            'event_title': transaction['content_title'],
            'short_description': transaction['content_short_description'],
            'hero_image_url': transaction['content_hero_image_url'],
            'thumbnail_url': transaction['content_thumbnail_url'],
            'ticket_code': transaction['ticket_code'],
            'registration_status': transaction['registration_status'],
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: _textDim,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool orangeOnly,
  }) {
    final enabled = onPressed != null;
    final foregroundColor = enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: orangeOnly
                      ? const [Color(0xFFFF8A3D), Color(0xFFFFB15C)]
                      : const [Color(0xFFFF2D72), Color(0xFFFF8A3D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color:
                        (orangeOnly
                                ? const Color(0xFFFF8A3D)
                                : const Color(0xFFFF2D72))
                            .withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    spreadRadius: -12,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountText(String amount, String currency) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: const TextStyle(
              color: _pink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          TextSpan(
            text: ' $currency',
            style: const TextStyle(
              color: _pink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: _textDim,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(children: [const SizedBox(height: 16), ...children])
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = transaction['content_title'] as String? ?? 'Tranzacție PULSE';
    final type = transaction['content_type'] as String?;
    final amount = transaction['amount'];
    final currency = transaction['currency'] as String? ?? 'RON';
    final cardBrand = transaction['card_brand'] as String?;
    final cardLast4 = transaction['card_last4'] as String?;
    final provider = transaction['provider'] as String? ?? 'Indisponibil';
    final providerTxId =
        transaction['provider_transaction_id'] as String? ?? 'Indisponibil';
    final paidAt = transaction['paid_at'] ?? transaction['created_at'];
    final createdAt = transaction['created_at'];
    final contentItemId = _readInt(transaction['content_item_id']);
    final subscriptionId = transaction['subscription_id'];
    final ticketCode = transaction['ticket_code'] as String?;
    final hasTicket = type == 'event' && ticketCode?.trim().isNotEmpty == true;
    final iconPath = _getIconForContentType(type);
    final amountValue = _formatAmountValue(amount);
    final amountLabel = '$amountValue $currency';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ProfileBackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: ProfileGradientHeading('Detalii tranzacție'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            iconPath,
                            width: 34,
                            height: 34,
                            colorFilter: const ColorFilter.mode(
                              _pink,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAmountText(amountValue, currency),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCollapsibleCard(
                      title: 'Sumar',
                      expanded: _summaryExpanded,
                      onToggle: () =>
                          setState(() => _summaryExpanded = !_summaryExpanded),
                      children: [
                        _buildDetailRow('Data plății', _formatDate(paidAt)),
                        _divider(),
                        _buildDetailRow(
                          'Metodă plată',
                          _formatPaymentMethod(cardBrand, cardLast4),
                        ),
                        _divider(),
                        _buildDetailRow('Suma', amountLabel),
                        _divider(),
                        _buildDetailRow(
                          'Tip conținut',
                          _contentTypeLabel(type),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCollapsibleCard(
                      title: 'Detalii tehnice',
                      expanded: _technicalExpanded,
                      onToggle: () => setState(
                        () => _technicalExpanded = !_technicalExpanded,
                      ),
                      children: [
                        _buildDetailRow('Procesator', provider),
                        _divider(),
                        _buildDetailRow('ID tranzacție', providerTxId),
                        _divider(),
                        _buildDetailRow(
                          'Data tranzacției',
                          _formatDate(createdAt),
                        ),
                        if (subscriptionId != null) ...[
                          _divider(),
                          _buildDetailRow(
                            'ID abonament',
                            subscriptionId.toString(),
                          ),
                        ],
                      ],
                    ),
                    if (contentItemId != null || hasTicket) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (hasTicket)
                            Expanded(
                              child: _buildActionButton(
                                label: 'Vezi bilet',
                                onPressed: _openTicketDetail,
                                orangeOnly: false,
                              ),
                            ),
                          if (hasTicket && contentItemId != null)
                            const SizedBox(width: 10),
                          if (contentItemId != null)
                            Expanded(
                              child: _buildActionButton(
                                label: 'Vezi detalii',
                                onPressed: () =>
                                    _openContentDetail(contentItemId),
                                orangeOnly: true,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
