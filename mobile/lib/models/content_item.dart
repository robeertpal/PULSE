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
  final int? authorId;
  final String? authorName;
  final int? contributorUserId;
  final String? contributorName;
  final bool contributorIsVerified;
  final String? contributorSpecializationName;
  final String? contributorInstitutionName;
  final bool isFeatured;
  final String? tag; // Virtual field for UI
  final int? emcCredits;
  final String? contentUrl;
  final int? categoryId;
  final int? specializationId;
  final String? categoryName;
  final String? specializationName;
  final DateTime? startDate;
  final String? cityName;
  final String? venueName;
  final DateTime? endDate;
  final String? attendanceMode;
  final String? priceType;
  final num? priceAmount;
  final int? eventId;
  final int? courseId;
  final String? accreditationStatus;
  final String? provider;
  final String? courseStatus;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? progressPercent;
  final int? publicationId;
  final String? publicationName;
  final String? publicationLogoUrl;
  final String? publicationDescription;
  final String? publicationEmcCreditsText;
  final String? publicationCreditationText;
  final String? publicationIndexingText;
  final String? publicationSubscriptionUrl;
  final List<PublicationAuthor> publicationAuthors;
  final List<EventPartner> eventPartners;
  final EventPriceChange? nextPriceChange;

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
    this.authorId,
    this.authorName,
    this.contributorUserId,
    this.contributorName,
    this.contributorIsVerified = false,
    this.contributorSpecializationName,
    this.contributorInstitutionName,
    this.isFeatured = false,
    this.tag,
    this.emcCredits,
    this.contentUrl,
    this.categoryId,
    this.specializationId,
    this.categoryName,
    this.specializationName,
    this.startDate,
    this.cityName,
    this.venueName,
    this.endDate,
    this.attendanceMode,
    this.priceType,
    this.priceAmount,
    this.eventId,
    this.courseId,
    this.accreditationStatus,
    this.provider,
    this.courseStatus,
    this.validFrom,
    this.validUntil,
    this.progressPercent,
    this.publicationId,
    this.publicationName,
    this.publicationLogoUrl,
    this.publicationDescription,
    this.publicationEmcCreditsText,
    this.publicationCreditationText,
    this.publicationIndexingText,
    this.publicationSubscriptionUrl,
    this.publicationAuthors = const [],
    this.eventPartners = const [],
    this.nextPriceChange,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    // Determine tag based on content type
    String? derivedTag;
    if (json['content_type'] == 'article') derivedTag = 'Articol';
    if (json['content_type'] == 'news') derivedTag = 'Știri';
    if (json['content_type'] == 'course') derivedTag = 'Curs';
    if (json['content_type'] == 'event') derivedTag = 'Eveniment';
    if (json['content_type'] == 'publication') derivedTag = 'Revistă';

    int? parseEmcCredits(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
      if (match == null) return null;
      final normalized = match.group(0)!.replaceAll(',', '.');
      final parsed = num.tryParse(normalized);
      return parsed?.toInt();
    }

    // Extract EMC credits if available (from nested content entities)
    int? credits = parseEmcCredits(json['emc_credits']);
    if (json['event'] != null) {
      credits = parseEmcCredits(json['event']['emc_credits']) ?? credits;
    }
    if (json['course'] != null) {
      credits = parseEmcCredits(json['course']['emc_credits']) ?? credits;
    }
    if (json['publication'] != null) {
      credits = parseEmcCredits(json['publication']['emc_credits']) ?? credits;
    }

    // Extract preferred content URL
    String? url = json['source_url'];
    if (json['event'] != null) {
      url =
          json['event']['registration_url'] ??
          json['event']['event_page_url'] ??
          url;
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

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final rawPartners = json['partners'] ?? json['event']?['partners'];
    final partners = rawPartners is List
        ? rawPartners
              .whereType<Map<String, dynamic>>()
              .map(EventPartner.fromJson)
              .toList()
        : <EventPartner>[];
    partners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final rawAuthors = json['authors'] ?? json['publication']?['authors'];
    final publicationAuthors = rawAuthors is List
        ? rawAuthors
              .whereType<Map<String, dynamic>>()
              .map(PublicationAuthor.fromJson)
              .toList()
        : <PublicationAuthor>[];
    publicationAuthors.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final rawNextPriceChange =
        json['next_price_change'] ?? json['event']?['next_price_change'];
    final nextPriceChange = rawNextPriceChange is Map<String, dynamic>
        ? EventPriceChange.fromJson(rawNextPriceChange)
        : null;

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
      authorId: parseInt(json['author_id'] ?? json['author']?['id']),
      authorName: json['author_name'],
      contributorUserId: parseInt(
        json['contributor_user_id'] ?? json['public_contributor']?['user_id'],
      ),
      contributorName:
          json['contributor_name'] ??
          json['public_contributor']?['display_name'],
      contributorIsVerified:
          json['contributor_is_verified'] == true ||
          json['public_contributor']?['is_verified_contributor'] == true,
      contributorSpecializationName:
          json['contributor_specialization_name'] ??
          json['public_contributor']?['specialization_name'],
      contributorInstitutionName:
          json['contributor_institution_name'] ??
          json['public_contributor']?['institution_name'],
      isFeatured: json['is_featured'] ?? false,
      tag: derivedTag,
      emcCredits: credits,
      contentUrl: url,
      categoryId: json['category_id'],
      specializationId: json['specialization_id'],
      categoryName: json['category_name'],
      specializationName: json['specialization_name'],
      startDate: parseDate(json['start_date'] ?? json['event']?['start_date']),
      cityName: json['city_name'] ?? json['event']?['city_name'],
      venueName: json['venue_name'] ?? json['event']?['venue_name'],
      endDate: parseDate(json['end_date'] ?? json['event']?['end_date']),
      attendanceMode:
          json['attendance_mode'] ?? json['event']?['attendance_mode'],
      priceType: json['price_type'] ?? json['event']?['price_type'],
      priceAmount: json['price_amount'] ?? json['event']?['price_amount'],
      eventId: json['event']?['id'],
      courseId: json['course_id'] ?? json['course']?['id'],
      accreditationStatus:
          json['accreditation_status'] ??
          json['event']?['accreditation_status'],
      provider: json['provider'] ?? json['course']?['provider'],
      courseStatus: json['course_status'] ?? json['course']?['course_status'],
      validFrom: parseDate(json['valid_from'] ?? json['course']?['valid_from']),
      validUntil: parseDate(
        json['valid_until'] ?? json['course']?['valid_until'],
      ),
      progressPercent:
          json['progress_percent'] ??
          json['course_progress_percent'] ??
          json['course']?['progress_percent'],
      publicationId: json['publication_id'] ?? json['publication']?['id'],
      publicationName: json['name'] ?? json['publication']?['name'],
      publicationLogoUrl: json['logo_url'] ?? json['publication']?['logo_url'],
      publicationDescription:
          json['description'] ?? json['publication']?['description'],
      publicationEmcCreditsText:
          json['emc_credits_text'] ?? json['publication']?['emc_credits_text'],
      publicationCreditationText:
          json['creditation_text'] ?? json['publication']?['creditation_text'],
      publicationIndexingText:
          json['indexing_text'] ?? json['publication']?['indexing_text'],
      publicationSubscriptionUrl:
          json['subscription_url'] ?? json['publication']?['subscription_url'],
      publicationAuthors: publicationAuthors,
      eventPartners: partners,
      nextPriceChange: nextPriceChange,
    );
  }
}

class PublicationAuthor {
  final int id;
  final String firstName;
  final String lastName;
  final String? title;
  final String? bio;
  final String? photoUrl;
  final String? role;
  final int displayOrder;

  const PublicationAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.title,
    this.bio,
    this.photoUrl,
    this.role,
    this.displayOrder = 1,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayName {
    final prefix = title?.trim();
    if (prefix == null || prefix.isEmpty) return fullName;
    return '$prefix $fullName'.trim();
  }

  String get initials {
    final parts = [
      firstName,
      lastName,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  factory PublicationAuthor.fromJson(Map<String, dynamic> json) {
    return PublicationAuthor(
      id: json['author_id'] ?? json['id'],
      firstName: (json['first_name'] ?? json['author']?['first_name'] ?? '')
          .toString(),
      lastName: (json['last_name'] ?? json['author']?['last_name'] ?? '')
          .toString(),
      title: json['title']?.toString() ?? json['author']?['title']?.toString(),
      bio: json['bio']?.toString() ?? json['author']?['bio']?.toString(),
      photoUrl:
          json['photo_url']?.toString() ??
          json['author']?['photo_url']?.toString(),
      role: json['role']?.toString(),
      displayOrder: json['display_order'] ?? 1,
    );
  }
}

class EventPriceChange {
  final String priceType;
  final num? priceAmount;
  final String? currency;
  final DateTime? effectiveFrom;
  final String? message;

  const EventPriceChange({
    required this.priceType,
    this.priceAmount,
    this.currency,
    this.effectiveFrom,
    this.message,
  });

  factory EventPriceChange.fromJson(Map<String, dynamic> json) {
    return EventPriceChange(
      priceType: (json['price_type'] ?? '').toString(),
      priceAmount: json['price_amount'],
      currency: json['currency']?.toString(),
      effectiveFrom: json['effective_from'] == null
          ? null
          : DateTime.tryParse(json['effective_from'].toString()),
      message: json['message']?.toString(),
    );
  }
}

class EventPartner {
  final int id;
  final String name;
  final String? logoUrl;
  final String? websiteUrl;
  final int displayOrder;

  const EventPartner({
    required this.id,
    required this.name,
    this.logoUrl,
    this.websiteUrl,
    this.displayOrder = 0,
  });

  factory EventPartner.fromJson(Map<String, dynamic> json) {
    return EventPartner(
      id: json['partner_id'] ?? json['id'],
      name: (json['name'] ?? json['partner']?['name'] ?? '').toString(),
      logoUrl: json['logo_url'] ?? json['partner']?['logo_url'],
      websiteUrl: json['website_url'] ?? json['partner']?['website_url'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}
