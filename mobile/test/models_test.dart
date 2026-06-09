import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/publication_issue.dart';

void main() {
  group('Models Parsing Tests', () {
    test('Parse PublicationIssue successfully', () {
      final json = {
        'id': 101,
        'publication_id': 5,
        'year': 2024,
        'issue_number': 1,
        'issue_label': 'Ediție Specială',
        'pdf_url': 'https://example.com/rev.pdf'
      };

      final issue = PublicationIssue.fromJson(json);

      expect(issue.id, 101);
      expect(issue.publicationId, 5);
      expect(issue.year, 2024);
      expect(issue.displayLabel, 'Ediție Specială');
      expect(issue.pdfUrl, 'https://example.com/rev.pdf');
    });

    test('Parse PublicationIssue with fallback displayLabel', () {
      final json = {
        'id': 102,
        'publication_id': 6,
        'year': 2023,
        'issue_number': 12,
      };

      final issue = PublicationIssue.fromJson(json);

      expect(issue.id, 102);
      expect(issue.displayLabel, 'Nr. 12 / 2023'); 
    });
  });
}
