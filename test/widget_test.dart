import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carevora/main.dart';

void main() {
  testWidgets('Carevora App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CarevoraApp(),
      ),
    );

    // Verify CAREVORA branding displays
    expect(find.text('CAREVORA'), findsWidgets);
  });
}
