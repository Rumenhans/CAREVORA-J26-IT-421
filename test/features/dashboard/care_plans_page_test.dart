import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:carevora/features/assessment/application/care_plans_service.dart';
import 'package:carevora/features/assessment/application/cognitive_assessment_service.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/dashboard/presentation/care_plans_page.dart';
import 'package:carevora/shared/widgets/desktop_sidebar.dart';

class MockCaregiverAuthNotifier extends AuthNotifier {
  @override
  AuthState get state => const AuthState(
        isAuthenticated: true,
        userName: 'Eleanor Vance',
        role: UserRole.caregiver,
        elderHomeId: 1,
        elderHomeName: 'Serene Valley Senior Living',
        token: 'test-caregiver-token',
      );
}

class MockElderAuthNotifier extends AuthNotifier {
  @override
  AuthState get state => const AuthState(
        isAuthenticated: true,
        userName: 'Sarah Jenkins',
        role: UserRole.elder,
        residentId: 1,
        elderHomeId: 1,
        elderHomeName: 'Serene Valley Senior Living',
        token: 'test-elder-token',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockResidentsJson = jsonEncode({
    'success': true,
    'data': [
      {
        'id': 1,
        'name': 'Sarah Jenkins',
        'age': 78,
        'gender': 'Female',
        'roomNumber': '101',
        'elderHomeName': 'Serene Valley Senior Living',
        'elderHomeId': 1,
        'cognitiveScore': 85.0,
        'emotionalScore': 88.0,
        'riskLevel': 'LOW',
      },
      {
        'id': 2,
        'name': 'Arthur Pendelton',
        'age': 82,
        'gender': 'Male',
        'roomNumber': '102',
        'elderHomeName': 'Serene Valley Senior Living',
        'elderHomeId': 1,
        'cognitiveScore': 62.0,
        'emotionalScore': 54.0,
        'riskLevel': 'MODERATE',
      },
      {
        'id': 3,
        'name': 'Robert Hastings',
        'age': 84,
        'gender': 'Male',
        'roomNumber': '202',
        'elderHomeName': 'Serene Valley Senior Living',
        'elderHomeId': 1,
        'cognitiveScore': 48.0,
        'emotionalScore': 38.0,
        'riskLevel': 'HIGH',
      },
      {
        'id': 37,
        'name': 'James Perera',
        'age': 79,
        'gender': 'Male',
        'roomNumber': '204',
        'elderHomeName': 'Serene Valley Senior Living',
        'elderHomeId': 1,
        'cognitiveScore': 72.5,
        'emotionalScore': 70.0,
        'riskLevel': 'LOW',
      },
      {
        'id': 5,
        'name': 'Resident Five',
        'age': 75,
        'gender': 'Female',
        'roomNumber': '301',
        'elderHomeName': 'Serene Valley Senior Living',
        'elderHomeId': 1,
        'cognitiveScore': 80.0,
        'emotionalScore': 75.0,
        'riskLevel': 'LOW',
      },
    ],
  });

  group('CarePlansService & CognitiveCareRecommendation Logic Tests', () {
    test('1. LOW risk prediction produces exact low risk recommendation protocol', () {
      final rec = CognitiveCareRecommendation.forRisk('LOW');
      expect(rec.category, equals(CognitiveRiskCategory.low));
      expect(rec.categoryLabel, equals('LOW RISK'));
      expect(rec.actionItems, contains('Continue routine care.'));
      expect(rec.actionItems, contains('Encourage regular memory/attention/orientation activities.'));
      expect(rec.actionItems, contains('Support hobbies and social interaction.'));
      expect(rec.actionItems, contains('Continue periodic monitoring.'));
    });

    test('2. MODERATE risk prediction produces exact moderate risk recommendation protocol', () {
      final rec = CognitiveCareRecommendation.forRisk('MODERATE');
      expect(rec.category, equals(CognitiveRiskCategory.moderate));
      expect(rec.categoryLabel, equals('MODERATE RISK'));
      expect(rec.actionItems, contains('Provide short supervised cognitive sessions.'));
      expect(rec.actionItems, contains('Practise relevant cognitive tasks.'));
      expect(rec.actionItems, contains('Compare results with previous assessments.'));
      expect(rec.actionItems, contains('Consider clinical review if concerns persist or worsen.'));
    });

    test('3. HIGH risk prediction produces exact high risk recommendation protocol', () {
      final rec = CognitiveCareRecommendation.forRisk('HIGH');
      expect(rec.category, equals(CognitiveRiskCategory.high));
      expect(rec.categoryLabel, equals('HIGH RISK'));
      expect(rec.actionItems, contains('Promptly notify the responsible caregiver.'));
      expect(rec.actionItems, contains('Arrange clinical review according to care-home protocol.'));
      expect(rec.actionItems, contains('Provide supportive supervised activities.'));
      expect(rec.actionItems, contains('Review the assessment history.'));
    });

    test('4. Missing or unavailable prediction displays honest status without inventing risk', () {
      final recNull = CognitiveCareRecommendation.forRisk(null);
      expect(recNull.category, equals(CognitiveRiskCategory.unavailable));
      expect(recNull.categoryLabel, equals('PREDICTION UNAVAILABLE'));

      final recUnavailable = CognitiveCareRecommendation.forRisk('MODERATE', mlAvailable: false);
      expect(recUnavailable.category, equals(CognitiveRiskCategory.unavailable));
      expect(recUnavailable.categoryLabel, equals('PREDICTION UNAVAILABLE'));
    });

    test('5. Task accuracy is kept strictly separate from AI risk prediction', () {
      // High task accuracy (e.g. 100% or 92.5%) paired with MODERATE AI prediction
      // must yield MODERATE care recommendations, not LOW.
      final rec = CognitiveCareRecommendation.forRisk('MODERATE', mlAvailable: true);
      expect(rec.category, equals(CognitiveRiskCategory.moderate));
      expect(rec.categoryLabel, equals('MODERATE RISK'));
    });

    test('6. Metabolic wellness data strictly reports pending integration without fabricated data', () async {
      final meta = await CarePlansService.loadMetabolicData(1);
      expect(meta.isAvailable, isFalse);
      expect(meta.statusMessage, equals('Pending Integration'));
      expect(meta.integrationNote, contains('Continuous metabolic telemetry'));
    });

    test('7. formatDomainScore formats percentage-scaled values accurately (100, 75, 50, 0)', () {
      expect(CarePlansService.formatDomainScore(100.0), equals('100%'));
      expect(CarePlansService.formatDomainScore(75.0), equals('75%'));
      expect(CarePlansService.formatDomainScore(50.0), equals('50%'));
      expect(CarePlansService.formatDomainScore(0.0), equals('0%'));
    });

    test('8. formatDomainScore formats fractional representation accurately (1.0, 0.75, 0.5, 0.85)', () {
      expect(CarePlansService.formatDomainScore(1.0), equals('100%'));
      expect(CarePlansService.formatDomainScore(0.75), equals('75%'));
      expect(CarePlansService.formatDomainScore(0.50), equals('50%'));
      expect(CarePlansService.formatDomainScore(0.85), equals('85%'));
    });

    test('9. formatDomainScore does not double-multiply already percentage-scaled values', () {
      // Must produce 100% and 75%, NEVER 10000% or 7500%
      final hundred = CarePlansService.formatDomainScore(100.0);
      final seventyFive = CarePlansService.formatDomainScore(75.0);
      expect(hundred, isNot(contains('10000')));
      expect(hundred, equals('100%'));
      expect(seventyFive, isNot(contains('7500')));
      expect(seventyFive, equals('75%'));
    });

    test('10. formatDomainScore handles null, NaN, and Infinite inputs safely', () {
      expect(CarePlansService.formatDomainScore(null), equals('--'));
      expect(CarePlansService.formatDomainScore(double.nan), equals('--'));
      expect(CarePlansService.formatDomainScore(double.infinity), equals('--'));
      expect(CarePlansService.formatDomainScore(-10.0), equals('--'));
    });

    test('11. formatTaskAccuracyScore formats percentage-scaled values without multiplying twice', () {
      final score72_5 = CarePlansService.formatTaskAccuracyScore(72.5);
      final score100 = CarePlansService.formatTaskAccuracyScore(100.0);
      final score0 = CarePlansService.formatTaskAccuracyScore(0.0);

      expect(score72_5, equals('72.5%'));
      expect(score72_5, isNot(contains('7250')));
      expect(score100, equals('100.0%'));
      expect(score100, isNot(contains('10000')));
      expect(score0, equals('0.0%'));
    });

    test('12. formatTaskAccuracyScore formats fractional values (0.0–1.0) into percentages', () {
      expect(CarePlansService.formatTaskAccuracyScore(0.725), equals('72.5%'));
      expect(CarePlansService.formatTaskAccuracyScore(1.0), equals('100.0%'));
      expect(CarePlansService.formatTaskAccuracyScore(0.85), equals('85.0%'));
    });

    test('13. formatTaskAccuracyScore handles null, negative, NaN, and Infinite inputs safely with N/A', () {
      expect(CarePlansService.formatTaskAccuracyScore(null), equals('N/A'));
      expect(CarePlansService.formatTaskAccuracyScore(double.nan), equals('N/A'));
      expect(CarePlansService.formatTaskAccuracyScore(double.infinity), equals('N/A'));
      expect(CarePlansService.formatTaskAccuracyScore(-5.0), equals('N/A'));
    });

    test('14. Percentage formatting contains exactly one percent symbol without duplication', () {
      final formattedAcc = CarePlansService.formatTaskAccuracyScore(72.5);
      final formattedDomain = CarePlansService.formatDomainScore(50.0);

      expect('%'.allMatches(formattedAcc).length, equals(1));
      expect('%'.allMatches(formattedDomain).length, equals(1));
      expect(formattedAcc.endsWith('%%'), isFalse);
      expect(formattedDomain.endsWith('%%'), isFalse);
    });
  });

  group('CarePlansPage Widget & Integration Tests', () {
    late http.Client mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/api/residents')) {
          return http.Response(mockResidentsJson, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/1')) {
          // Resident 1: LOW Risk Cognitive Assessment
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 101,
                'residentId': 1,
                'residentName': 'Sarah Jenkins',
                'acrfScore': 90.0,
                'riskLevel': 'LOW',
                'mlPrediction': 'LOW',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'prediction': 'LOW',
                },
                'createdAt': '2026-10-16T14:30:00Z',
                'orientation': 1.0,
                'memory': 0.85,
                'attention': 0.90,
                'recall': 0.85,
                'reasoning': 0.90,
                'assessedBy': 'Eleanor Vance',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/2')) {
          // Resident 2: MODERATE Risk with 92.5% task accuracy (verifies separation)
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 102,
                'residentId': 2,
                'residentName': 'Arthur Pendelton',
                'acrfScore': 92.5,
                'riskLevel': 'MODERATE',
                'mlPrediction': 'MODERATE',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'prediction': 'MODERATE',
                },
                'createdAt': '2026-10-15T11:00:00Z',
                'orientation': 100.0,
                'memory': 75.0,
                'attention': 90.0,
                'recall': 75.0,
                'reasoning': 90.0,
                'assessedBy': 'Eleanor Vance',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/3')) {
          // Resident 3: HIGH Risk Cognitive Assessment with history
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 103,
                'residentId': 3,
                'residentName': 'Robert Hastings',
                'acrfScore': 50.0,
                'riskLevel': 'HIGH',
                'mlPrediction': 'HIGH',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'prediction': 'HIGH',
                },
                'createdAt': '2026-10-16T09:15:00Z',
                'orientation': 0.50,
                'memory': 0.50,
                'attention': 0.50,
                'recall': 0.50,
                'reasoning': 0.50,
                'assessedBy': 'David Silva',
              },
              {
                'id': 99,
                'residentId': 3,
                'residentName': 'Robert Hastings',
                'acrfScore': 55.0,
                'riskLevel': 'HIGH',
                'mlPrediction': 'HIGH',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'prediction': 'HIGH',
                },
                'createdAt': '2026-10-01T09:15:00Z',
                'assessedBy': 'David Silva',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/4')) {
          // Resident 4: Missing / Unavailable ML prediction
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 104,
                'residentId': 4,
                'residentName': 'Test Resident',
                'acrfScore': 75.0,
                'riskLevel': null,
                'mlPrediction': null,
                'mlAvailable': false,
                'mlModelEvaluation': {
                  'available': false,
                  'prediction': null,
                },
                'createdAt': '2026-10-16T12:00:00Z',
                'assessedBy': 'Staff',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/37')) {
          // Resident 37 (James Perera): Active session first, followed by completed assessment (No ML)
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': null,
                'residentId': 37,
                'residentName': 'James Perera',
                'memory': null,
                'attention': null,
                'orientation': null,
                'recall': null,
                'reasoning': null,
                'acrfScore': null,
                'mlPrediction': null,
                'riskLevel': 'Not Available',
                'alertTriggered': false,
                'mlAvailable': false,
                'mlModelEvaluation': {
                  'available': false,
                  'modelType': 'RandomForestClassifier',
                  'statusMessage': 'Pending clinical review: AI inference will be evaluated upon caregiver completion.',
                  'prediction': null,
                  'alertTriggered': false,
                },
                'methodology': 'Pending Caregiver Clinical Review',
                'clinicalDisclaimer': 'Awaiting caregiver review and clinical grading.',
                'assessedBy': 'Caregiver Session',
                'createdAt': '2026-10-16T23:02:37.25452',
                'sessionId': 'cog-sess-b2b124fe-4561-46f8-8467-47394a4366f2',
                'status': 'IN_PROGRESS',
              },
              {
                'id': 120,
                'residentId': 37,
                'residentName': 'James Perera',
                'memory': 50.0,
                'attention': 100.0,
                'orientation': 50.0,
                'recall': 75.0,
                'reasoning': 50.0,
                'acrfScore': 72.5,
                'mlPrediction': null,
                'riskLevel': 'Not Available',
                'alertTriggered': false,
                'mlAvailable': false,
                'mlModelEvaluation': {
                  'available': false,
                  'modelType': 'RandomForestClassifier',
                  'statusMessage': 'Random Forest model inference was unavailable (missing required task metrics at assessment time)',
                  'prediction': null,
                  'probabilities': null,
                  'alertTriggered': false,
                  'alertThreshold': 0.48,
                  'experimentalLabel': 'Synthetic Data Experiment (Non-Clinical)',
                },
                'methodology': 'ACRF Fixed Base Weights',
                'clinicalDisclaimer': 'The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.',
                'assessedBy': 'James Perera',
                'createdAt': '2026-10-16T23:02:29.311996',
                'sessionId': 'cog-sess-d96248e8-574c-4659-a22a-0eaec6e7d750',
                'status': 'COMPLETED_PREDICTION_UNAVAILABLE',
              },
              {
                'id': 113,
                'residentId': 37,
                'residentName': 'James Perera',
                'memory': 100.0,
                'attention': 100.0,
                'orientation': 100.0,
                'recall': 100.0,
                'reasoning': 75.0,
                'acrfScore': 95.0,
                'mlPrediction': 'Low',
                'riskLevel': 'Low Risk',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'modelType': 'RandomForestClassifier',
                  'statusMessage': 'Experimental prediction generated using artifact trained on synthetic data.',
                  'prediction': 'Low',
                  'probabilities': {'Low Risk': 0.85, 'Moderate Risk': 0.10, 'High Risk': 0.05},
                  'alertTriggered': false,
                },
                'createdAt': '2026-10-16T22:18:26.890352',
                'sessionId': 'cog-sess-a22a5143-2633-4ebc-96cb-cdef0bbfde15',
                'status': 'COMPLETED',
                'assessedBy': 'David Silva',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/resident/5')) {
          // Resident 5: Valid score with missing/null domain scores
          final cogHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 105,
                'residentId': 5,
                'residentName': 'Resident Five',
                'acrfScore': 80.0,
                'memory': null,
                'attention': null,
                'orientation': null,
                'recall': null,
                'reasoning': null,
                'riskLevel': 'Low Risk',
                'mlPrediction': 'Low',
                'mlAvailable': true,
                'mlModelEvaluation': {
                  'available': true,
                  'prediction': 'Low',
                },
                'createdAt': '2026-10-16T15:00:00Z',
                'assessedBy': 'Staff',
                'status': 'COMPLETED',
              },
            ],
          });
          return http.Response(cogHistory, 200, headers: {'content-type': 'application/json'});
        }

        if (path.contains('/api/assessments/resident')) {
          // Emotional assessment endpoint
          final emoHistory = jsonEncode({
            'success': true,
            'data': [
              {
                'id': 201,
                'residentId': 1,
                'overallScore': 85.0,
                'emotionalScore': 88.0,
                'socialScore': 82.0,
                'status': 'LOOKING_GOOD',
                'riskLevel': 'LOW',
                'trajectory': 'Stable',
                'encouragingMessage': 'Good social engagement observed.',
                'timestamp': '2026-10-15T10:00:00Z',
                'recommendations': [
                  {
                    'id': 1,
                    'title': 'Symphonic Chamber Music',
                    'reason': 'Promotes morning relaxation',
                    'priority': 'Music Therapy',
                    'suggestedAction': 'Play classical playlist during reading hour',
                  },
                ],
              },
            ],
          });
          return http.Response(emoHistory, 200, headers: {'content-type': 'application/json'});
        }

        return http.Response('{"success": false}', 404);
      });

      CarePlansService.client = mockClient;
      CognitiveAssessmentService.client = mockClient;
    });

    tearDown(() {
      CarePlansService.client = null;
      CognitiveAssessmentService.client = null;
    });

    Widget createCaregiverWidget({int? initialResidentId}) {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockCaregiverAuthNotifier()),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 1600)),
            child: CarePlansPage(initialResidentId: initialResidentId),
          ),
        ),
      );
    }

    Widget createElderWidget() {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockElderAuthNotifier()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1600)),
            child: CarePlansPage(),
          ),
        ),
      );
    }

    testWidgets('1. Caregiver view loads header, search bar, and empty search prompt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Care Plans Management'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search to Select a Resident'), findsOneWidget);
      expect(find.textContaining('Serene Valley Senior Living'), findsOneWidget);
    });

    testWidgets('2. Searching resident by name displays matching list and filters non-matching', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Arthur');
      await tester.pump();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
    });

    testWidgets('3. Searching resident by ID displays matching resident', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '1');
      await tester.pump();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
    });

    testWidgets('4. Searching for non-existent resident displays clean empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentResident999');
      await tester.pump();

      expect(find.text('No residents found'), findsOneWidget);
    });

    testWidgets('5. Selecting resident with LOW risk displays accurate cognitive recommendations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 1));
      await tester.pumpAndSettle();

      // Header and Disclaimer
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.textContaining('Caregiver Guidance Notice'), findsOneWidget);

      // Cognitive Wellness Card
      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget); // Task Accuracy
      expect(find.text('LOW RISK'), findsAtLeastNWidgets(1));

      // Action items for LOW risk
      expect(find.text('Continue routine care.', skipOffstage: false), findsOneWidget);
      expect(find.text('Encourage regular memory/attention/orientation activities.', skipOffstage: false), findsOneWidget);
      expect(find.text('Support hobbies and social interaction.', skipOffstage: false), findsOneWidget);
      expect(find.text('Continue periodic monitoring.', skipOffstage: false), findsOneWidget);

      // Metabolic Wellness Card shows honest Pending Integration
      expect(find.text('Metabolic Wellness', skipOffstage: false), findsOneWidget);
      expect(find.text('Pending Integration', skipOffstage: false), findsOneWidget);
      expect(find.text('No Metabolic Assessment Available', skipOffstage: false), findsOneWidget);
    });

    testWidgets('6. Selecting resident with MODERATE risk displays accurate moderate recommendations even with 92.5% task accuracy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 2));
      await tester.pumpAndSettle();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('92.5%'), findsOneWidget); // Task Accuracy
      expect(find.text('MODERATE RISK'), findsAtLeastNWidgets(1));

      // Action items for MODERATE risk
      expect(find.text('Provide short supervised cognitive sessions.', skipOffstage: false), findsOneWidget);
      expect(find.text('Practise relevant cognitive tasks.', skipOffstage: false), findsOneWidget);
      expect(find.text('Compare results with previous assessments.', skipOffstage: false), findsOneWidget);
      expect(find.text('Consider clinical review if concerns persist or worsen.', skipOffstage: false), findsOneWidget);
    });

    testWidgets('7. Selecting resident with HIGH risk displays priority protocol recommendations and expandable history', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 3));
      await tester.pumpAndSettle();

      expect(find.text('Robert Hastings'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsAtLeastNWidgets(1));

      // Action items for HIGH risk
      expect(find.text('Promptly notify the responsible caregiver.', skipOffstage: false), findsOneWidget);
      expect(find.text('Arrange clinical review according to care-home protocol.', skipOffstage: false), findsOneWidget);
      expect(find.text('Provide supportive supervised activities.', skipOffstage: false), findsOneWidget);
      expect(find.text('Review the assessment history.', skipOffstage: false), findsOneWidget);

      // History Toggle
      expect(find.textContaining('Previous Assessment History', skipOffstage: false), findsOneWidget);
      await tester.tap(find.textContaining('Previous Assessment History', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('Assessed by David Silva', skipOffstage: false), findsAtLeastNWidgets(1));
    });

    testWidgets('8. Resident with missing AI prediction displays honest unavailable status without inventing risk', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PREDICTION UNAVAILABLE'), findsAtLeastNWidgets(1));
      expect(find.text('Prediction Unavailable Protocol'), findsOneWidget);
      expect(find.textContaining('AI risk prediction could not be computed'), findsOneWidget);
    });

    testWidgets('9. Elder role directly displays their own care plan without search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createElderWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Care Plans Management'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      // Elders do not see search bar
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('Emotional Wellness'), findsOneWidget);
      expect(find.text('Metabolic Wellness'), findsOneWidget);
    });

    testWidgets('10. Cognitive Domain Scores row displays accurate percentages (100%, 75%) without double-multiplying to 10000% or 7500%', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 2));
      await tester.pumpAndSettle();

      // Check Domain Header and labels
      expect(find.text('Cognitive Domain Scores', skipOffstage: false), findsOneWidget);
      expect(find.text('Orientation', skipOffstage: false), findsOneWidget);
      expect(find.text('Memory', skipOffstage: false), findsOneWidget);
      expect(find.text('Recall', skipOffstage: false), findsOneWidget);

      // Orientation (100.0) must display 100%, NEVER 10000%
      expect(find.text('100%', skipOffstage: false), findsAtLeastNWidgets(1));
      expect(find.text('10000%', skipOffstage: false), findsNothing);

      // Memory (75.0) and Recall (75.0) must display 75%, NEVER 7500%
      expect(find.text('75%', skipOffstage: false), findsAtLeastNWidgets(1));
      expect(find.text('7500%', skipOffstage: false), findsNothing);
    });

    testWidgets('11. DesktopSidebar navigation renders labels and icons without hardcoded dummy badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockCaregiverAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DesktopSidebar(currentRoute: '/dashboard/care-plans'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check navigation labels are properly rendered
      expect(find.text('Alerts & Notifications'), findsOneWidget);
      expect(find.text('Care Plans'), findsOneWidget);
      expect(find.text('Live Medicine Board'), findsOneWidget);

      // Confirm hardcoded dummy badges ('3' and '2') are not present in sidebar items
      expect(find.text('3'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('12. James Perera (Resident ID #37) displays valid 72.5% task accuracy and domain scores even with active session and unavailable ML prediction', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 37));
      await tester.pumpAndSettle();

      // Confirms correct resident is selected
      expect(find.text('James Perera'), findsOneWidget);

      // Task accuracy score must display 72.5% (from completed assessment #120, not N/A from in-progress session)
      expect(find.text('72.5%'), findsOneWidget);
      expect(find.text('N/A'), findsNothing);

      // AI Risk Prediction must show Prediction Unavailable without inventing risk
      expect(find.text('PREDICTION UNAVAILABLE'), findsAtLeastNWidgets(1));
      expect(find.text('Prediction Unavailable Protocol'), findsOneWidget);

      // Domain scores from assessment #120 must be displayed accurately (50%, 100%, 75%)
      expect(find.text('50%', skipOffstage: false), findsAtLeastNWidgets(1));
      expect(find.text('100%', skipOffstage: false), findsAtLeastNWidgets(1));
      expect(find.text('75%', skipOffstage: false), findsAtLeastNWidgets(1));
      // Domain scores must not display '--'
      expect(find.text('--', skipOffstage: false), findsNothing);

      // History toggle must show prior records count excluding the latest completed assessment
      expect(find.textContaining('Previous Assessment History (2 prior records)', skipOffstage: false), findsOneWidget);
    });

    testWidgets('13. Resident with valid score and available AI prediction displays score and ML risk correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 1));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('LOW RISK'), findsAtLeastNWidgets(1));
    });

    testWidgets('14. Missing or null domain scores display cleanly as -- without crashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 5));
      await tester.pumpAndSettle();

      expect(find.text('Resident Five'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      // Domain scores that are null must display '--'
      expect(find.text('--', skipOffstage: false), findsAtLeastNWidgets(1));
      expect(find.text('LOW RISK'), findsAtLeastNWidgets(1));
    });

    testWidgets('15. Searching and selecting resident loads correct resident and latest completed assessment', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'James');
      await tester.pump();

      expect(find.text('James Perera'), findsOneWidget);
      await tester.tap(find.text('James Perera'));
      await tester.pumpAndSettle();

      expect(find.text('72.5%'), findsOneWidget);
      expect(find.text('PREDICTION UNAVAILABLE'), findsAtLeastNWidgets(1));
    });

    testWidgets('16. History list excludes currently displayed latest assessment and does not duplicate it', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createCaregiverWidget(initialResidentId: 37));
      await tester.pumpAndSettle();

      // Open previous assessment history
      expect(find.textContaining('Previous Assessment History', skipOffstage: false), findsOneWidget);
      await tester.tap(find.textContaining('Previous Assessment History', skipOffstage: false));
      await tester.pumpAndSettle();

      // Older assessment #113 (assessed by David Silva, score 95.0%) is in history
      expect(find.textContaining('Assessed by David Silva', skipOffstage: false), findsOneWidget);
      expect(find.text('Accuracy: 95.0%', skipOffstage: false), findsOneWidget);

      // Latest assessment #120 score (72.5%) is in main card only, not duplicated in history
      expect(find.text('Accuracy: 72.5%', skipOffstage: false), findsNothing);
    });
  });
}
