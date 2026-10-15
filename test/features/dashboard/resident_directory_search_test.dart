import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/dashboard/presentation/resident_directory_page.dart';

class MockCaregiverAuthNotifier extends AuthNotifier {
  @override
  AuthState get state => const AuthState(
    isAuthenticated: true,
    userName: 'Eleanor Vance',
    role: UserRole.caregiver,
    elderHomeId: 1,
    elderHomeName: 'Serene Valley Senior Living',
    token: 'fake-jwt-token',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({Size surfaceSize = const Size(1200, 800)}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockCaregiverAuthNotifier()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const ResidentDirectoryPage(),
        ),
      ),
    );
  }

  group('Resident Directory Search-First Interface Tests', () {
    testWidgets('1. Page opens with search bar and empty state, NOT all resident cards immediately', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Heading and placeholder
      expect(find.text('Resident Directory'), findsOneWidget);
      expect(find.text('Search residents by name or resident ID'), findsOneWidget);

      // Verify empty search state is visible before selection
      expect(find.text('Search to Select a Resident'), findsOneWidget);
      expect(find.textContaining('Type a resident name or resident ID in the search bar above'), findsOneWidget);

      // Ensure full cards are NOT shown immediately on page load
      expect(find.text('Latest Score (ACRF)'), findsNothing);
      expect(find.text('Cognitive Wellness'), findsNothing);
    });

    testWidgets('2. Searching by name returns matching authorized residents', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search term "sarah" (case-insensitive)
      await tester.enterText(find.byType(TextField), 'sarah');
      await tester.pumpAndSettle();

      // Verify Sarah Jenkins is in the matching results list
      expect(find.text('Matching Residents (1)'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('ID: #1'), findsOneWidget);
      expect(find.text('Arthur Pendelton'), findsNothing);
    });

    testWidgets('3. Searching by resident ID works', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter ID "2"
      await tester.enterText(find.byType(TextField), '2');
      await tester.pumpAndSettle();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('ID: #2'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
    });

    testWidgets('4. No matches produce a clear "No residents found" empty state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentResident999');
      await tester.pumpAndSettle();

      expect(find.text('No residents found'), findsOneWidget);
      expect(find.textContaining('No resident matches "NonExistentResident999"'), findsOneWidget);
    });

    testWidgets('5. Selecting a resident displays three separate wellness cards and details', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Search and select Sarah Jenkins
      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Verification of resident banner details
      expect(find.text('Resident ID: #1'), findsOneWidget);
      expect(find.text('Back to Search'), findsOneWidget);

      // Verify three distinct wellness cards are present
      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('Emotional Wellness'), findsOneWidget);
      expect(find.text('Metabolic Wellness'), findsOneWidget);
    });

    testWidgets('6. Missing metabolic data is displayed clearly without fabricated 0% scores', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Metabolic card must clearly display "No metabolic wellness data available" rather than a fake 0%
      expect(find.text('No metabolic wellness data available'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('7. Layout renders without overflow at narrow browser width (375px)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(375, 667)));
      await tester.pumpAndSettle();

      // Search on mobile width
      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Verify cards render without throwing RenderFlex overflow errors
      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('Emotional Wellness'), findsOneWidget);
      expect(find.text('Metabolic Wellness'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Back to Search clears selected resident and returns to search view', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      expect(find.text('Back to Search'), findsOneWidget);

      await tester.tap(find.text('Back to Search'));
      await tester.pumpAndSettle();

      // Returns to search state
      expect(find.text('Cognitive Wellness'), findsNothing);
      expect(find.text('Matching Residents (1)'), findsOneWidget);
    });
  });
}
