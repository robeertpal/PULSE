class PublicationIssue {
  final int id;
  final int publicationId;
  final String? publicationName;
  final String? publicationLogoUrl;
  final String? publicationDescription;
  final int year;
  final int issueNumber;
  final String? issueLabel;
  final String? coverImageUrl;
  final String? description;
  final DateTime? publishedAt;

  const PublicationIssue({
    required this.id,
    required this.publicationId,
    this.publicationName,
    this.publicationLogoUrl,
    this.publicationDescription,
    required this.year,
    required this.issueNumber,
    this.issueLabel,
    this.coverImageUrl,
    this.description,
    this.publishedAt,
  });

  factory PublicationIssue.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PublicationIssue(
      id: json['id'],
      publicationId: json['publication_id'],
      publicationName: json['publication_name'],
      publicationLogoUrl: json['publication_logo_url'],
      publicationDescription: json['publication_description'],
      year: json['year'],
      issueNumber: json['issue_number'],
      issueLabel: json['issue_label'],
      coverImageUrl: json['cover_image_url'],
      description: json['description'],
      publishedAt: parseDate(json['published_at']),
    );
  }

  String get displayLabel => issueLabel?.trim().isNotEmpty == true
      ? issueLabel!
      : 'Nr. $issueNumber / $year';
}
