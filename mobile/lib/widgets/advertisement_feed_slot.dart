import 'package:flutter/material.dart';
import '../models/ad_item.dart';
import '../theme/pulse_theme.dart';
import 'advertisement_card.dart';

class AdvertisementFeedSlot extends StatelessWidget {
  final List<AdItem> ads;
  final Function(AdItem) onAdTap;
  final bool showDivider;

  const AdvertisementFeedSlot({
    super.key,
    required this.ads,
    required this.onAdTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      // Întoarcem doar spațiul normal dintre secțiuni dacă nu există reclamă
      // pentru a nu lăsa goluri neașteptate
      return const SizedBox(height: 24);
    }

    final ad = ads.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24), // Spațiere înainte de reclamă

        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Row(
                  children: [
                    Text(
                      'RECOMANDAT',
                      style: TextStyle(
                        color: PulseTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Divider(
                        color: PulseTheme.textSecondary.withValues(alpha: 0.15),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        AdvertisementCard(
          ad: ad,
          onTap: () => onAdTap(ad),
        ),

        const SizedBox(height: 32), // Spațiere după reclamă
      ],
    );
  }
}
