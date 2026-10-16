import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/assessment/application/cognitive_assessment_service.dart';
import 'package:carevora/features/dashboard/presentation/resident_directory_page.dart';

class MockCaregiverAuthNotifier extends AuthNotifier {
  @override
  AuthState get state => const AuthState(
    isAuthenticated: true,
    userName: 'Eleanor Vance',
    role: UserRole.caregiver,
    elderHomeId: 1,
    elderHomeName: 'Serene Valley Senior Living',
    token: 'test-jwt-token',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    CognitiveAssessmentService.client = null;
  });

  group('Cognitive Wellness DTO & Data Consistency Unit Tests', () {
    test('1. CognitiveSubmissionResult preserves null scores without converting to misleading 0.0', () {
      final json = <String, dynamic>{
        'id': 101,
        'residentId': 1,
        'residentName': 'James Perera',
        'status': 'PENDING_CAREGIVER_REVIEW',
        'memory': null,
        'attention': null,
        'orientation': null,
        'recall': null,
        'reasoning': null,
        'acrfScore': null,
        'mlPrediction': null,
        'riskLevel': 'Not Available',
      };

      final result = CognitiveSubmissionResult.fromJson(json);

      expect(result.id, equals(101));
      expect(result.residentName, equals('James Perera'));
      expect(result.status, equals('PENDING_CAREGIVER_REVIEW'));
      expect(result.acrfScore, isNull);
      expect(result.memory, isNull);
      expect(result.attention, isNull);
      expect(result.orientation, isNull);
      expect(result.recall, isNull);
      expect(result.reasoning, isNull);
      expect(result.riskLevel, equals('Not Available'));
    });

    test('2. CognitiveSubmissionResult resolves risk level from prediction or defaults to Not Available', () {
      final jsonWithLow = <String, dynamic>{
        'id': 1,
        'residentId': 1,
        'residentName': 'James Perera',
        'acrfScore': 85.0,
        'mlPrediction': 'Low Risk',
      };
      final resLow = CognitiveSubmissionResult.fromJson(jsonWithLow);
      expect(resLow.riskLevel, equals('Low Risk'));

      final jsonWithMissing = <String, dynamic>{
        'id': 2,
        'residentId': 1,
        'residentName': 'James Perera',
        'acrfScore': 70.0,
        'mlPrediction': null,
      };
      final resMissing = CognitiveSubmissionResult.fromJson(jsonWithMissing);
      expect(resMissing.riskLevel, equals('Not Available'));
    });

    test('3. CognitiveSubmissionResult parses responses and clinical grades if persisted', () {
      final json = <String, dynamic>{
        'id': 10,
        'residentId': 1,
        'residentName': 'James Perera',
        'acrfScore': 88.0,
        'responses': {
          '1': 'Monday',
          '2': '2026',
        },
        'grades': {
          '1': 1.0,
          '2': 0.5,
        },
      };

      final res = CognitiveSubmissionResult.fromJson(json);
      expect(res.responses?[1], equals('Monday'));
      expect(res.responses?[2], equals('2026'));
      expect(res.grades?[1], equals(1.0));
      expect(res.grades?[2], equals(0.5));
    });
  });

  group('Resident Directory Cognitive Wellness UI Tests', () {
    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockCaregiverAuthNotifier()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 1000)),
            child: ResidentDirectoryPage(),
          ),
        ),
      );
    }

    testWidgets('4. A resident with no completed assessments does not show fabricated 75.0% score', (tester) async {
      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('75.0%'), findsNothing);
      expect(find.text('0 assessment(s) completed'), findsOneWidget);
      expect(find.text('AI Risk Prediction:'), findsOneWidget);
      expect(find.text('Not Available'), findsAtLeastNWidgets(1));
      expect(find.text('No cognitive assessments yet'), findsOneWidget);
    });

    testWidgets('5. History button opens real data, and empty state shows exact required message', (tester) async {
      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      final historyBtn = find.widgetWithText(OutlinedButton, 'History');
      expect(historyBtn, findsOneWidget);
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Cognitive Assessment History — Sarah Jenkins'), findsOneWidget);
      expect(find.text('No cognitive assessments recorded yet.'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Hide'));
      await tester.pumpAndSettle();
      expect(find.text('Cognitive Assessment History — Sarah Jenkins'), findsNothing);
    });

    testWidgets('6. Failed history request displays error state and retry action instead of empty success', (tester) async {
      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': false, 'message': 'Internal Server Error'}), 500);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      final historyBtn = find.widgetWithText(OutlinedButton, 'History');
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Cognitive Assessment History — Sarah Jenkins'), findsOneWidget);
      expect(find.textContaining('Error loading cognitive history'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No cognitive assessments recorded yet.'), findsNothing);
    });

    testWidgets('7. Pending sessions do not increase completed count; completed assessment increments count exactly once', (tester) async {
      final mockData = [
        {
          'id': 102,
          'sessionId': 'cog-sess-pending-1',
          'residentId': 1,
          'residentName': 'Sarah Jenkins',
          'status': 'PENDING_CAREGIVER_REVIEW',
          'createdAt': '2026-10-15T18:00:00Z',
          'memory': null,
          'attention': null,
          'orientation': null,
          'recall': null,
          'reasoning': null,
          'acrfScore': null,
          'riskLevel': 'Not Available',
        },
        {
          'id': 101,
          'sessionId': 'cog-sess-completed-1',
          'residentId': 1,
          'residentName': 'Sarah Jenkins',
          'status': 'COMPLETED',
          'createdAt': '2026-10-14T10:00:00Z',
          'memory': 85.0,
          'attention': 80.0,
          'orientation': 90.0,
          'recall': 75.0,
          'reasoning': 85.0,
          'acrfScore': 83.0,
          'mlPrediction': 'Low Risk',
          'riskLevel': 'Low Risk',
          'responses': {'1': 'Monday'},
          'grades': {'1': 1.0},
        },
      ];

      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': mockData}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Only 1 completed assessment (pending session did NOT increase the completed count!)
      expect(find.text('1 assessment(s) completed'), findsOneWidget);

      // Latest completed score and risk level are displayed
      expect(find.text('83.0%'), findsOneWidget);
      expect(find.text('Low Risk'), findsAtLeastNWidgets(1));

      // Open history section
      final historyBtn = find.widgetWithText(OutlinedButton, 'History');
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      // Both records appear in history newest first
      expect(find.text('Pending Caregiver Review'), findsAtLeastNWidgets(1));
      expect(find.text('Completed'), findsAtLeastNWidgets(1));
      expect(find.text('cog-sess-pending-1'), findsOneWidget);
      expect(find.text('cog-sess-completed-1'), findsOneWidget);
    });

    testWidgets('8. Clinical and research disclaimer is displayed on Cognitive card', (tester) async {
      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      expect(
        find.text('ACRF is a weighted wellness metric. Model trained on synthetic data. Non-diagnostic.'),
        findsOneWidget,
      );
    });

    testWidgets('9. Different residents never share scores or history', (tester) async {
      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. Select Sarah Jenkins (ID 1)
      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      expect(find.text('Resident ID: #1'), findsOneWidget);

      // 2. Clear and select Arthur Pendelton (ID 2)
      await tester.tap(find.text('Back to Search'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Arthur');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arthur Pendelton'));
      await tester.pumpAndSettle();

      expect(find.text('Resident ID: #2'), findsOneWidget);
      expect(find.text('Resident ID: #1'), findsNothing);
    });

    testWidgets('10. High task accuracy score (100.0%) with Moderate AI risk prediction displays explanatory note and distinct metrics', (tester) async {
      final mockData = [
        {
          'id': 96,
          'sessionId': 'cog-sess-100-mod',
          'residentId': 1,
          'residentName': 'Sarah Jenkins',
          'status': 'COMPLETED',
          'createdAt': '2026-10-16T15:00:00Z',
          'memory': 100.0,
          'attention': 100.0,
          'orientation': 100.0,
          'recall': 100.0,
          'reasoning': 100.0,
          'acrfScore': 100.0,
          'mlPrediction': 'Moderate',
          'riskLevel': 'Moderate Risk',
          'responses': {'1': 'Friday'},
          'grades': {'1': 1.0},
        },
      ];

      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': mockData}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Card displays separate metrics
      expect(find.text('Task Accuracy Score'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('AI Risk Prediction:'), findsOneWidget);
      expect(find.text('Moderate Risk'), findsOneWidget);

      // Explanatory note is displayed
      expect(
        find.textContaining('AI prediction also considers response latency, longitudinal features'),
        findsOneWidget,
      );

      // Open history section
      final historyBtn = find.widgetWithText(OutlinedButton, 'History');
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      // History item also displays Task Accuracy Score and AI Risk Prediction with explanatory note
      expect(find.text('Task Accuracy Score'), findsNWidgets(2));
      expect(find.text('AI Risk Prediction'), findsOneWidget);
      expect(
        find.textContaining('AI prediction also considers response latency, longitudinal features'),
        findsNWidgets(2), // 1 in summary card, 1 in history item
      );
    });

    testWidgets('11. High task accuracy score with Low AI risk prediction does NOT display explanatory note', (tester) async {
      final mockData = [
        {
          'id': 92,
          'sessionId': 'cog-sess-92-low',
          'residentId': 1,
          'residentName': 'Sarah Jenkins',
          'status': 'COMPLETED',
          'createdAt': '2026-10-16T13:00:00Z',
          'memory': 100.0,
          'attention': 100.0,
          'orientation': 100.0,
          'recall': 100.0,
          'reasoning': 50.0,
          'acrfScore': 92.5,
          'mlPrediction': 'Low',
          'riskLevel': 'Low Risk',
          'responses': {'1': 'Friday'},
          'grades': {'1': 1.0},
        },
      ];

      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': mockData}), 200);
      });

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      // Card displays separate metrics
      expect(find.text('Task Accuracy Score'), findsOneWidget);
      expect(find.text('92.5%'), findsOneWidget);
      expect(find.text('AI Risk Prediction:'), findsOneWidget);
      expect(find.text('Low Risk'), findsOneWidget);

      // Explanatory note is NOT displayed when risk is Low
      expect(
        find.textContaining('AI prediction also considers response latency, longitudinal features'),
        findsNothing,
      );
    });
  });
}
