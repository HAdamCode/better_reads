import 'package:flutter_test/flutter_test.dart';
import 'package:better_reads_app/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const BetterReadsApp());
    await tester.pumpAndSettle();

    // Verify the app renders (will show sign in screen since not authenticated)
    expect(find.text('Better Reads'), findsOneWidget);
  });
}
