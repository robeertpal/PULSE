class PublicationIssue {
  final int id;
  final int publicationId;
  final String? publicationName;
  final String? publicationLogoUrl;
  final String? publicationDescription;
  final String? publicationEmcCreditsText;
  final String? publicationCreditationText;
  final String? publicationIndexingText;
  final String? publicationSubscriptionUrl;
  final int year;
  final int issueNumber;
  final String? issueLabel;
  final String? coverImageUrl;
  final String? description;
  final DateTime? publishedAt;
  final String? issueUrl;

  const PublicationIssue({
    required this.id,
    required this.publicationId,
    this.publicationName,
    this.publicationLogoUrl,
    this.publicationDescription,
    this.publicationEmcCreditsText,
    this.publicationCreditationText,
    this.publicationIndexingText,
    this.publicationSubscriptionUrl,
    required this.year,
    required this.issueNumber,
    this.issueLabel,
    this.coverImageUrl,
    this.description,
    this.publishedAt,
    this.issueUrl,
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
      publicationEmcCreditsText: json['publication_emc_credits_text'],
      publicationCreditationText: json['publication_creditation_text'],
      publicationIndexingText: json['publication_indexing_text'],
      publicationSubscriptionUrl: json['publication_subscription_url'],
      year: json['year'],
      issueNumber: json['issue_number'],
      issueLabel: json['issue_label'],
      coverImageUrl: json['cover_image_url'],
      description: json['description'],
      publishedAt: parseDate(json['published_at']),
      issueUrl: json['pdf_url'] ?? json['document_url'] ?? json['issue_url'],
    );
  }

  String? get pdfUrl => issueUrl;

  String get displayLabel => issueLabel?.trim().isNotEmpty == true
      ? issueLabel!
      : 'Nr. $issueNumber / $year';
}
