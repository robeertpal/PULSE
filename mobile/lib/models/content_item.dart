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
    int? credits;
    if (json['event'] != null) credits = json['event']['emc_credits'];
    if (json['course'] != null) credits = json['course']['emc_credits'];

    return ContentItem(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      contentType: json['content_type'],
      shortDescription: json['short_description'],
      body: json['body'],
      heroImageUrl: json['hero_image_url'],
      thumbnailUrl: json['thumbnail_url'],
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at']) 
          : null,
      authorName: json['author_name'],
      isFeatured: json['is_featured'] ?? false,
      tag: derivedTag,
      emcCredits: credits,
    );
  }
}
