class ContentSubmission {
  final int id;
  final String title;
  final String contentType;
  final int? categoryId;
  final String? categoryName;
  final int? specializationId;
  final String? specializationName;
  final String? summary;
  final String body;
  final String? imageUrl;
  final String? sourceUrl;
  final String status;
  final String? reviewNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? publishedContentItemId;

  const ContentSubmission({
    required this.id,
    required this.title,
    required this.contentType,
    this.categoryId,
    this.categoryName,
    this.specializationId,
    this.specializationName,
    this.summary,
    required this.body,
    this.imageUrl,
    this.sourceUrl,
    required this.status,
    this.reviewNotes,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.publishedContentItemId,
  });

  bool get canEdit => {'draft', 'needs_changes', 'rejected'}.contains(status);

  String get statusLabel {
    return switch (status) {
      'draft' => 'Draft',
      'submitted' => 'Trimis',
      'under_review' => 'In review',
      'needs_changes' => 'Necesita modificari',
      'approved' => 'Aprobat',
      'published' => 'Publicat',
      'rejected' => 'Respins',
      'archived' => 'Arhivat',
      _ => status,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory ContentSubmission.fromJson(Map<String, dynamic> json) {
    return ContentSubmission(
      id: _parseInt(json['id']) ?? 0,
      title: (json['title'] ?? '').toString(),
      contentType: (json['content_type'] ?? 'article').toString(),
      categoryId: _parseInt(json['category_id']),
      categoryName: json['category_name']?.toString(),
      specializationId: _parseInt(json['specialization_id']),
      specializationName: json['specialization_name']?.toString(),
      summary: json['summary']?.toString(),
      body: (json['body'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      sourceUrl: json['source_url']?.toString(),
      status: (json['status'] ?? 'draft').toString(),
      reviewNotes: json['review_notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      submittedAt: _parseDate(json['submitted_at']),
      reviewedAt: _parseDate(json['reviewed_at']),
      publishedContentItemId: _parseInt(json['published_content_item_id']),
    );
  }

  Map<String, dynamic> toPayload({
    required String title,
    required String contentType,
    int? categoryId,
    int? specializationId,
    String? summary,
    required String body,
    String? imageUrl,
    String? sourceUrl,
  }) {
    final payload = <String, dynamic>{
      'title': title,
      'content_type': contentType,
      'body': body,
    };
    if (categoryId != null) {
      payload['category_id'] = categoryId;
    }
    if (specializationId != null) {
      payload['specialization_id'] = specializationId;
    }
    final trimmedSummary = summary?.trim();
    if (trimmedSummary != null && trimmedSummary.isNotEmpty) {
      payload['summary'] = trimmedSummary;
    }
    final trimmedImageUrl = imageUrl?.trim();
    if (trimmedImageUrl != null && trimmedImageUrl.isNotEmpty) {
      payload['image_url'] = trimmedImageUrl;
    }
    final trimmedSourceUrl = sourceUrl?.trim();
    if (trimmedSourceUrl != null && trimmedSourceUrl.isNotEmpty) {
      payload['source_url'] = trimmedSourceUrl;
    }
    return payload;
  }
}
