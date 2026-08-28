import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app.dart';

void main() {
  testWidgets('AgriLink app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AgriLinkApp()),
    );
    await tester.pump();

    expect(find.text('AgriLink'), findsOneWidget);
    expect(find.text('Connecting farms to markets'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to AgriLink'), findsOneWidget);
  });
}
