import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_tutor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpanishTutorApp());
    expect(find.byType(SpanishTutorApp), findsOneWidget);
  });
}
