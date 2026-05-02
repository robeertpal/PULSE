import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/models/ad_item.dart';
import 'package:mobile/models/content_item.dart';
import 'package:mobile/widgets/advertisement_card.dart';

void main() {
  test('ContentItem parses public card payload metadata', () {
    final item = ContentItem.fromJson({
      'id': 1,
      'title': 'Congres medical',
      'slug': 'congres-medical',
      'content_type': 'event',
      'short_description': 'Eveniment EMC',
      'published_at': '2026-05-02T10:00:00Z',
      'is_featured': true,
      'event': {
        'start_date': '2026-06-10T08:00:00Z',
        'city_name': 'București',
        'venue_name': 'Palatul Parlamentului',
        'emc_credits': 12,
        'registration_url': 'https://example.com/register',
      },
    });

    expect(item.contentType, 'event');
    expect(item.tag, 'Eveniment');
    expect(item.isFeatured, isTrue);
    expect(item.cityName, 'București');
    expect(item.venueName, 'Palatul Parlamentului');
    expect(item.emcCredits, 12);
    expect(item.contentUrl, 'https://example.com/register');
  });

  test('AdItem mergedConfig keeps design_config priority and false values', () {
    final item = AdItem.fromJson({
      'id': 10,
      'title': 'Ad',
      'template_default_config': {
        'show_badge': true,
        'badge_text': 'Template',
        'show_sponsor_logo': true,
      },
      'design_config': {
        'show_badge': false,
        'badge_text': '',
        'show_sponsor_logo': false,
      },
    });

    expect(item.mergedConfig['show_badge'], isFalse);
    expect(item.mergedConfig['badge_text'], '');
    expect(item.mergedConfig['show_sponsor_logo'], isFalse);
  });

  test('AdItem parses title font metadata from ads payload', () {
    final item = AdItem.fromJson({
      'id': 12,
      'title': 'Ad font',
      'title_font_preset_id': 3,
      'title_font_code': 'elegant_serif',
      'title_font_key': 'elegant_serif',
      'title_font_name': 'Elegant Serif',
      'title_flutter_font_family': 'Georgia',
    });

    expect(item.titleFontPresetId, 3);
    expect(item.titleFontCode, 'elegant_serif');
    expect(item.titleFontKey, 'elegant_serif');
    expect(item.titleFontName, 'Elegant Serif');
    expect(item.titleFlutterFontFamily, 'Georgia');
  });

  testWidgets('AdvertisementCard hides badge when design show_badge is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 1,
          title: 'Reclama fara badge',
          templateDefaultConfig: {'show_badge': true, 'badge_text': 'Template'},
          designConfig: {'show_badge': false, 'badge_text': 'Nou'},
        ),
      ),
    );

    expect(find.text('Nou'), findsNothing);
    expect(find.text('Template'), findsNothing);
    expect(find.text('Promovat'), findsNothing);
    expect(find.text('Reclama fara badge'), findsOneWidget);
  });

  testWidgets('AdvertisementCard shows custom badge text when configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 2,
          title: 'Reclama cu badge',
          designConfig: {'show_badge': true, 'badge_text': 'Custom badge'},
        ),
      ),
    );

    expect(find.text('Custom badge'), findsOneWidget);
    expect(find.text('Promovat'), findsNothing);
  });

  testWidgets('AdvertisementCard does not invent badge text when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 7,
          title: 'Reclama fara text badge',
          designConfig: {'show_badge': true, 'badge_text': ''},
        ),
      ),
    );

    expect(find.text('Template'), findsNothing);
    expect(find.text('Promovat'), findsNothing);
    expect(find.text('Reclama fara text badge'), findsOneWidget);
  });

  testWidgets(
    'AdvertisementCard falls back to template badge text when asked',
    (tester) async {
      await tester.pumpWidget(
        _adHost(
          const AdItem(
            id: 8,
            title: 'Reclama cu badge din template',
            templateDefaultConfig: {
              'show_badge': true,
              'badge_text': 'Template',
            },
            designConfig: {'show_badge': true, 'badge_text': ''},
          ),
        ),
      );

      expect(find.text('Template'), findsOneWidget);
      expect(find.text('Promovat'), findsNothing);
    },
  );

  testWidgets(
    'AdvertisementCard uses template show_badge false when design omits it',
    (tester) async {
      await tester.pumpWidget(
        _adHost(
          const AdItem(
            id: 9,
            title: 'Reclama template fara badge',
            templateDefaultConfig: {'show_badge': false, 'badge_text': 'Nou'},
            designConfig: {},
          ),
        ),
      );

      expect(find.text('Nou'), findsNothing);
      expect(find.text('Promovat'), findsNothing);
      expect(find.text('Reclama template fara badge'), findsOneWidget);
    },
  );

  testWidgets(
    'AdvertisementCard does not show Promovat for empty design config',
    (tester) async {
      await tester.pumpWidget(
        _adHost(
          const AdItem(
            id: 10,
            title: 'Reclama fara config badge',
            designConfig: {},
          ),
        ),
      );

      expect(find.text('Promovat'), findsNothing);
      expect(find.text('Reclama fara config badge'), findsOneWidget);
    },
  );

  testWidgets('AdvertisementCard supports centered text_position', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 3,
          title: 'Reclama centrata',
          templateCode: 'hero_banner',
          designConfig: {'text_position': 'center'},
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Align && widget.alignment == Alignment.center,
      ),
      findsWidgets,
    );
    final title = tester.widget<Text>(find.text('Reclama centrata'));
    expect(title.textAlign, TextAlign.center);
  });

  testWidgets('AdvertisementCard maps bottom_center text_position', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 4,
          title: 'Reclama jos centru',
          templateCode: 'hero_banner',
          designConfig: {'text_position': 'bottom_center'},
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Align && widget.alignment == Alignment.bottomCenter,
      ),
      findsWidgets,
    );
    final title = tester.widget<Text>(find.text('Reclama jos centru'));
    expect(title.textAlign, TextAlign.center);
  });

  testWidgets('AdvertisementCard renders mega hero centered and taller', (
    tester,
  ) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 11,
          title: 'Campanie mega hero',
          templateCode: 'mega_hero_banner',
          templateVariant: 'mega_hero',
          templateDefaultConfig: {
            'height': 'large',
            'text_position': 'center',
            'show_badge': false,
            'badge_text': '',
          },
          titleFontKey: 'elegant_serif',
          titleFlutterFontFamily: 'Georgia',
          designConfig: {'text_position': 'center'},
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight == 388 &&
            widget.constraints?.maxHeight == 388,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Align && widget.alignment == Alignment.center,
      ),
      findsWidgets,
    );
    final title = tester.widget<Text>(find.text('Campanie mega hero'));
    expect(title.textAlign, TextAlign.center);
    expect(title.style?.fontFamily, 'Georgia');
    expect(find.text('Promovat'), findsNothing);
  });

  testWidgets('AdvertisementCard respects show_sponsor_logo', (tester) async {
    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 5,
          title: 'Reclama fara logo',
          sponsorLogoUrl: 'https://example.com/logo.png',
          designConfig: {'show_sponsor_logo': false},
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);

    await tester.pumpWidget(
      _adHost(
        const AdItem(
          id: 6,
          title: 'Reclama cu logo',
          sponsorLogoUrl: 'https://example.com/logo.png',
          designConfig: {'show_sponsor_logo': true},
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}

Widget _adHost(AdItem ad) {
  return MaterialApp(
    home: Scaffold(body: AdvertisementCard(ad: ad)),
  );
}
