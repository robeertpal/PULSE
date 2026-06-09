import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Un widget simplu de mock pentru a testa logica de blur și UI states
class MockPremiumReader extends StatelessWidget {
  final bool isPremiumContent;
  final bool hasSubscription;

  const MockPremiumReader({
    super.key,
    required this.isPremiumContent,
    required this.hasSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final showBlur = isPremiumContent && !hasSubscription;

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Text('Conținut Revistă'),
            if (showBlur) ...[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              const Center(
                child: Text('Abonament Necesar'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

void main() {
  group('UI Logic - Premium Blur and Empty States', () {
    testWidgets('Shows blur and lock message when premium and not subscribed', (WidgetTester tester) async {
      await tester.pumpWidget(const MockPremiumReader(
        isPremiumContent: true,
        hasSubscription: false,
      ));

      expect(find.text('Conținut Revistă'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Abonament Necesar'), findsOneWidget);
    });

    testWidgets('Shows no blur when premium and subscribed', (WidgetTester tester) async {
      await tester.pumpWidget(const MockPremiumReader(
        isPremiumContent: true,
        hasSubscription: true,
      ));

      expect(find.text('Conținut Revistă'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Abonament Necesar'), findsNothing);
    });

    testWidgets('Shows no blur when content is not premium', (WidgetTester tester) async {
      await tester.pumpWidget(const MockPremiumReader(
        isPremiumContent: false,
        hasSubscription: false,
      ));

      expect(find.text('Conținut Revistă'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Abonament Necesar'), findsNothing);
    });
  });
}
