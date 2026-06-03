import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'profile_screen.dart'; // Pentru ProfileGradientHeading si ProfileBackButton

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  static const Color _surface = Color(0xFF101010);
  static const Color _surfaceSoft = Color(0xFF181818);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _textDim = Colors.white70;

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

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status?.toLowerCase()) {
      case 'paid':
      case 'success':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        label = 'Plătit';
        break;
      case 'pending':
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFF59E0B);
        label = 'În procesare';
        break;
      case 'failed':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Eșuat';
        break;
      case 'refunded':
        bgColor = const Color(0xFF6366F1).withValues(alpha: 0.15);
        textColor = const Color(0xFF6366F1);
        label = 'Returnat';
        break;
      default:
        bgColor = Colors.white.withValues(alpha: 0.1);
        textColor = Colors.white70;
        label = status ?? 'Necunoscut';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final title = transaction['content_title'] as String? ?? 'Tranzacție PULSE';
    final type = transaction['content_type'] as String?;
    final amount = transaction['amount'] ?? 0.0;
    final currency = transaction['currency'] ?? 'RON';
    final status = transaction['status'] as String?;
    final cardBrand = transaction['card_brand'] as String?;
    final cardLast4 = transaction['card_last4'] as String?;
    final provider = transaction['provider'] as String? ?? 'N/A';
    final providerTxId =
        transaction['provider_transaction_id'] as String? ?? 'N/A';
    final paidAt = transaction['paid_at'] ?? transaction['created_at'];
    final createdAt = transaction['created_at'];
    final contentItemId = transaction['content_item_id'];
    final subscriptionId = transaction['subscription_id'];
    final registrationStatus = transaction['registration_status'] as String?;
    final ticketCode = transaction['ticket_code'] as String?;

    final iconPath = _getIconForContentType(type);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    // Main Card
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _surfaceSoft,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                            child: SvgPicture.asset(
                              iconPath,
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                _pink,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$amount $currency',
                            style: const TextStyle(
                              color: _pink,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ),

                    if (ticketCode != null && type == 'event') ...[
                      const SizedBox(height: 24),
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
                            const Text(
                              'Bilet eveniment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: ticketCode,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Cod bilet: $ticketCode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status participare: ${registrationStatus ?? "necunoscut"}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sumar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Data plății', _formatDate(paidAt)),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          _buildDetailRow(
                            'Metodă plată',
                            _formatPaymentMethod(cardBrand, cardLast4),
                          ),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          _buildDetailRow('Suma', '$amount $currency'),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          _buildDetailRow(
                            'Tip conținut',
                            type?.toUpperCase() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Technical Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalii tehnice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Procesator', provider),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          _buildDetailRow('ID Tranzacție', providerTxId),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          _buildDetailRow(
                            'Data creării',
                            _formatDate(createdAt),
                          ),
                          if (contentItemId != null) ...[
                            Divider(
                              color: Colors.white.withValues(alpha: 0.06),
                              height: 1,
                            ),
                            _buildDetailRow(
                              'ID Conținut',
                              contentItemId.toString(),
                            ),
                          ],
                          if (subscriptionId != null) ...[
                            Divider(
                              color: Colors.white.withValues(alpha: 0.06),
                              height: 1,
                            ),
                            _buildDetailRow(
                              'ID Abonament',
                              subscriptionId.toString(),
                            ),
                          ],
                        ],
                      ),
                    ),
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
