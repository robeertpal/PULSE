import 'package:flutter/material.dart';
import '../models/ad_item.dart';
import 'advertisement_card.dart';

class AdvertisementFeedSlot extends StatelessWidget {
  final List<AdItem> ads;
  final Function(AdItem) onAdTap;

  const AdvertisementFeedSlot({
    super.key,
    required this.ads,
    required this.onAdTap,
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

        AdvertisementCard(ad: ad, onTap: () => onAdTap(ad)),

        const SizedBox(height: 32), // Spațiere după reclamă
      ],
    );
  }
}
