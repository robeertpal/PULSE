import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/models/content_item.dart';

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
}
