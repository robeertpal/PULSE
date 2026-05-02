class ContentItem {
  final int id;
  final String title;
  final String slug;
  final String contentType;
  final String? shortDescription;
  final String? body;
  final String? heroImageUrl;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final String? authorName;
  final bool isFeatured;
  final String? tag; // Virtual field for UI
  final int? emcCredits;
  final String? contentUrl;
  final String? categoryName;
  final String? specializationName;
  final DateTime? startDate;
  final String? cityName;
  final String? venueName;
  final String? provider;
  final DateTime? validUntil;
  final String? publicationName;
  final String? publicationLogoUrl;
  final String? publicationDescription;

  ContentItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.contentType,
    this.shortDescription,
    this.body,
    this.heroImageUrl,
    this.thumbnailUrl,
    this.publishedAt,
    this.authorName,
    this.isFeatured = false,
    this.tag,
    this.emcCredits,
    this.contentUrl,
    this.categoryName,
    this.specializationName,
    this.startDate,
    this.cityName,
    this.venueName,
    this.provider,
    this.validUntil,
    this.publicationName,
    this.publicationLogoUrl,
    this.publicationDescription,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    // Determine tag based on content type
    String? derivedTag;
    if (json['content_type'] == 'article') derivedTag = 'Articol';
    if (json['content_type'] == 'news') derivedTag = 'Știri';
    if (json['content_type'] == 'course') derivedTag = 'Curs';
    if (json['content_type'] == 'event') derivedTag = 'Eveniment';
    if (json['content_type'] == 'publication') derivedTag = 'Revistă';

    // Extract EMC credits if available (from nested event or course)
    int? credits = json['emc_credits'];
    if (json['event'] != null) credits = json['event']['emc_credits'] ?? credits;
    if (json['course'] != null) credits = json['course']['emc_credits'] ?? credits;

    // Extract preferred content URL
    String? url = json['source_url'];
    if (json['event'] != null) {
      url = json['event']['registration_url'] ?? json['event']['event_page_url'] ?? url;
    }
    if (json['course'] != null) {
      url = json['course']['enrollment_url'] ?? url;
    }
    if (json['publication'] != null) {
      url = json['publication']['subscription_url'] ?? url;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return ContentItem(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      contentType: json['content_type'],
      shortDescription: json['short_description'],
      body: json['body'],
      heroImageUrl: json['hero_image_url'],
      thumbnailUrl: json['thumbnail_url'],
      publishedAt: parseDate(json['published_at']),
      authorName: json['author_name'],
      isFeatured: json['is_featured'] ?? false,
      tag: derivedTag,
      emcCredits: credits,
      contentUrl: url,
      categoryName: json['category_name'],
      specializationName: json['specialization_name'],
      startDate: parseDate(json['start_date'] ?? json['event']?['start_date']),
      cityName: json['city_name'] ?? json['event']?['city_name'],
      venueName: json['venue_name'] ?? json['event']?['venue_name'],
      provider: json['provider'] ?? json['course']?['provider'],
      validUntil: parseDate(json['valid_until'] ?? json['course']?['valid_until']),
      publicationName: json['name'] ?? json['publication']?['name'],
      publicationLogoUrl: json['logo_url'] ?? json['publication']?['logo_url'],
      publicationDescription:
          json['description'] ?? json['publication']?['description'],
    );
  }
}
