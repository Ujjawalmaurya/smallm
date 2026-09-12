import 'package:flutter_test/flutter_test.dart';
import 'package:smollm_app/main.dart';

void main() {
  testWidgets('App mounts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Local LLM'), findsOneWidget);
  });
}
