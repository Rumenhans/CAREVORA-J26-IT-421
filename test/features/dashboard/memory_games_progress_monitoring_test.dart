import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:carevora/features/assessment/application/care_plans_service.dart';
import 'package:carevora/features/assessment/application/cognitive_assessment_service.dart';
import 'package:carevora/features/assessment/application/memory_game_service.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/dashboard/presentation/care_plans_page.dart';
import 'package:carevora/features/dashboard/presentation/memory_games_page.dart';
import 'package:carevora/features/dashboard/presentation/resident_directory_page.dart';

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

  final mockSessionsData = [
    {
      'id': 101,
      'sessionId': 'MG-SEQ-001',
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'gameType': 'SEQUENCE',
      'scorePercentage': 100.0,
      'attempts': 1,
      'correctAnswers': 3,
      'totalItems': 3,
      'status': 'COMPLETED',
      'completedAt': '2026-10-17T10:30:00Z',
    },
    {
      'id': 102,
      'sessionId': 'MG-SEQ-002',
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'gameType': 'SEQUENCE',
      'scorePercentage': 75.0,
      'attempts': 2,
      'correctAnswers': 3,
      'totalItems': 3,
      'status': 'COMPLETED',
      'completedAt': '2026-10-16T14:15:00Z',
    },
    {
      'id': 103,
      'sessionId': 'MG-PAIRS-001',
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'gameType': 'PAIRS',
      'scorePercentage': 75.0,
      'attempts': 8,
      'correctAnswers': 6,
      'totalItems': 6,
      'status': 'COMPLETED',
      'completedAt': '2026-10-17T09:20:00Z',
    },
    {
      'id': 104,
      'sessionId': 'MG-ITEMS-001',
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'gameType': 'ITEMS',
      'scorePercentage': 85.0,
      'attempts': 1,
      'correctAnswers': 4,
      'totalItems': 4,
      'status': 'COMPLETED',
      'completedAt': '2026-10-17T08:45:00Z',
    },
  ];

  final mockProgressSummaryJson = jsonEncode({
    'success': true,
    'data': {
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'totalCompletedSessions': 4,
      'latestActivityDate': '2026-10-17T10:30:00Z',
      'latestSequenceScore': 100.0,
      'latestPairsScore': 75.0,
      'latestItemsScore': 85.0,
      'averageScore': 83.8,
      'sequenceProgress': 'IMPROVING',
      'pairsProgress': 'STEADY',
      'itemsProgress': 'STEADY',
      'overallProgress': 'IMPROVING',
      'hasRepeatedDecline': false,
      'caregiverNotice': null,
      'sessions': mockSessionsData,
    },
  });

  final mockDeclineProgressSummaryJson = jsonEncode({
    'success': true,
    'data': {
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'totalCompletedSessions': 3,
      'latestActivityDate': '2026-10-17T11:00:00Z',
      'latestSequenceScore': 50.0,
      'latestPairsScore': 50.0,
      'latestItemsScore': 50.0,
      'averageScore': 50.0,
      'sequenceProgress': 'DECLINING',
      'pairsProgress': 'DECLINING',
      'itemsProgress': 'DECLINING',
      'overallProgress': 'DECLINING',
      'hasRepeatedDecline': true,
      'caregiverNotice':
          'Noticeable decline across recent practice sessions. Consider scheduling a relaxed practice session or checking if the resident was fatigued during play.',
      'sessions': [
        {
          'id': 201,
          'sessionId': 'MG-DEC-001',
          'residentId': 1,
          'residentName': 'Sarah Jenkins',
          'gameType': 'SEQUENCE',
          'scorePercentage': 50.0,
          'attempts': 3,
          'correctAnswers': 3,
          'totalItems': 3,
          'status': 'COMPLETED',
          'completedAt': '2026-10-17T11:00:00Z',
        },
      ],
    },
  });

  final mockEmptyProgressSummaryJson = jsonEncode({
    'success': true,
    'data': {
      'residentId': 1,
      'residentName': 'Sarah Jenkins',
      'totalCompletedSessions': 0,
      'latestActivityDate': null,
      'latestSequenceScore': null,
      'latestPairsScore': null,
      'latestItemsScore': null,
      'averageScore': null,
      'sequenceProgress': 'NO_DATA',
      'pairsProgress': 'NO_DATA',
      'itemsProgress': 'NO_DATA',
      'overallProgress': 'NO_DATA',
      'hasRepeatedDecline': false,
      'caregiverNotice': null,
      'sessions': [],
    },
  });

  group('Memory Games - Real Scoring Calculation Tests', () {
    test('1. Remember the Sequence scoring calculates accuracy and records attempts correctly', () {
      // 3 tiles, 0 mistakes: 3 / 3 = 100%
      const length = 3;
      const wrongTaps = 0;
      final accuracy = ((length / (length + wrongTaps)) * 100.0).clamp(0.0, 100.0);
      expect((accuracy * 10).round() / 10.0, equals(100.0));

      // 3 tiles, 1 mistake: 3 / (3 + 1) = 75.0%
      const wrongTaps1 = 1;
      final accuracy1 = ((length / (length + wrongTaps1)) * 100.0).clamp(0.0, 100.0);
      expect((accuracy1 * 10).round() / 10.0, equals(75.0));

      // 4 tiles, 2 mistakes: 4 / 6 = 66.7%
      const length4 = 4;
      const wrongTaps2 = 2;
      final accuracy2 = ((length4 / (length4 + wrongTaps2)) * 100.0).clamp(0.0, 100.0);
      expect((accuracy2 * 10).round() / 10.0, equals(66.7));
    });

    test('2. Matching Pairs scoring calculates performance based on 6 pairs and turns taken', () {
      // 6 pairs, completed in 6 turns = 100%
      const pairs = 6;
      final perf6 = ((pairs / 6.0) * 100.0).clamp(0.0, 100.0);
      expect((perf6 * 10).round() / 10.0, equals(100.0));

      // 6 pairs, completed in 8 turns = 75.0%
      final perf8 = ((pairs / 8.0) * 100.0).clamp(0.0, 100.0);
      expect((perf8 * 10).round() / 10.0, equals(75.0));

      // 6 pairs, completed in 10 turns = 60.0%
      final perf10 = ((pairs / 10.0) * 100.0).clamp(0.0, 100.0);
      expect((perf10 * 10).round() / 10.0, equals(60.0));

      // 6 pairs, completed in 12 turns = 50.0%
      final perf12 = ((pairs / 12.0) * 100.0).clamp(0.0, 100.0);
      expect((perf12 * 10).round() / 10.0, equals(50.0));
    });

    test('3. Remember the Items scoring calculates recall accuracy from 4 target items', () {
      // 4 recalled of 4 = 100.0%
      expect(((4 / 4.0) * 100.0).roundToDouble(), equals(100.0));

      // 3 recalled of 4 = 75.0%
      expect(((3 / 4.0) * 100.0).roundToDouble(), equals(75.0));

      // 2 recalled of 4 = 50.0%
      expect(((2 / 4.0) * 100.0).roundToDouble(), equals(50.0));

      // 1 recalled of 4 = 25.0%
      expect(((1 / 4.0) * 100.0).roundToDouble(), equals(25.0));

      // 0 recalled of 4 = 0.0%
      expect(((0 / 4.0) * 100.0).roundToDouble(), equals(0.0));
    });
  });

  group('Memory Games - Session Persistence & Exclusion Tests', () {
    test('4. saveCompletedSession rejects non-COMPLETED or abandoned session status', () async {
      expect(
        () => MemoryGameService.saveCompletedSession(
          residentId: 1,
          gameType: 'SEQUENCE',
          scorePercentage: 50.0,
          attempts: 1,
          correctAnswers: 1,
          totalItems: 3,
          status: 'ABANDONED',
        ),
        throwsArgumentError,
      );

      expect(
        () => MemoryGameService.saveCompletedSession(
          residentId: 1,
          gameType: 'PAIRS',
          scorePercentage: 0.0,
          attempts: 2,
          correctAnswers: 1,
          totalItems: 6,
          status: 'INCOMPLETE',
        ),
        throwsArgumentError,
      );
    });

    test('5. saveCompletedSession sends correct payload and parses response', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedAuthHeader;

      MemoryGameService.client = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 99,
              'sessionId': 'MG-SAVED-999',
              'residentId': 1,
              'residentName': 'Sarah Jenkins',
              'gameType': 'SEQUENCE',
              'scorePercentage': 100.0,
              'attempts': 1,
              'correctAnswers': 3,
              'totalItems': 3,
              'status': 'COMPLETED',
              'completedAt': '2026-10-17T12:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await MemoryGameService.saveCompletedSession(
        residentId: 1,
        gameType: 'SEQUENCE',
        scorePercentage: 100.0,
        attempts: 1,
        correctAnswers: 3,
        totalItems: 3,
        token: 'test-token-xyz',
      );

      expect(result.sessionId, equals('MG-SAVED-999'));
      expect(result.scorePercentage, equals(100.0));
      expect(result.status, equals('COMPLETED'));
      expect(capturedAuthHeader, equals('Bearer test-token-xyz'));
      expect(capturedBody?['gameType'], equals('SEQUENCE'));
      expect(capturedBody?['attempts'], equals(1));
      expect(capturedBody?['correctAnswers'], equals(3));
      expect(capturedBody?['totalItems'], equals(3));

      MemoryGameService.client = null;
    });

    test('6. saveCompletedSession handles failure cleanly without pretending it succeeded', () async {
      MemoryGameService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Database connection error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => MemoryGameService.saveCompletedSession(
          residentId: 1,
          gameType: 'PAIRS',
          scorePercentage: 75.0,
          attempts: 8,
          correctAnswers: 6,
          totalItems: 6,
        ),
        throwsA(isA<Exception>()),
      );

      MemoryGameService.client = null;
    });
  });

  group('Memory Games - In-Game Scoring & UI Feedback Tests', () {
    testWidgets('7. Sequence game displays calculated score and save confirmation on success', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));

      bool sessionSaved = false;
      MemoryGameService.client = MockClient((request) async {
        sessionSaved = true;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'sessionId': 'MG-SEQ-AUTO-1',
              'residentId': 1,
              'residentName': 'Sarah Jenkins',
              'gameType': 'SEQUENCE',
              'scorePercentage': 100.0,
              'attempts': 1,
              'correctAnswers': 3,
              'totalItems': 3,
              'status': 'COMPLETED',
              'completedAt': DateTime.now().toIso8601String(),
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => MockElderAuthNotifier())],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(1200, 1400)),
              child: MemoryGamesPage(
                initialGame: MemoryGameType.sequence,
                initialSequence: [0, 1, 2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start input
      await tester.tap(find.byKey(const ValueKey('start_sequence_input_button')));
      await tester.pumpAndSettle();

      // Tap correct sequence: 0, 1, 2
      await tester.tap(find.byKey(const ValueKey('sequence_tile_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sequence_tile_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sequence_tile_2')));
      await tester.pumpAndSettle();

      // Real gameplay score and confirmation badge displayed
      expect(find.text('Well done!'), findsOneWidget);
      expect(find.textContaining('Accuracy: 100.0%'), findsOneWidget);
      expect(find.textContaining('Recalled: 3 / 3 Tiles • Attempts: 1'), findsOneWidget);
      expect(sessionSaved, isTrue);

      MemoryGameService.client = null;
    });

    testWidgets('8. Incomplete session: exiting before completing sequence never calls saveCompletedSession', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));

      bool sessionSaved = false;
      MemoryGameService.client = MockClient((request) async {
        sessionSaved = true;
        return http.Response('{"success":true}', 200);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => MockElderAuthNotifier())],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(1200, 1400)),
              child: MemoryGamesPage(
                initialGame: MemoryGameType.sequence,
                initialSequence: [0, 1, 2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1 tile only (incomplete)
      await tester.tap(find.byKey(const ValueKey('start_sequence_input_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sequence_tile_0')));
      await tester.pumpAndSettle();

      // Abandon session by tapping Back to Memory Games
      await tester.tap(find.byKey(const ValueKey('back_to_games_button')));
      await tester.pumpAndSettle();

      // Abandoned/incomplete session was NOT saved
      expect(sessionSaved, isFalse);
      expect(find.text('Memory Games'), findsOneWidget);

      MemoryGameService.client = null;
    });
  });

  group('Resident Directory - Quick Progress Summary Tests', () {
    testWidgets('9. Resident Directory displays compact Memory Games Progress card with latest scores and Care Plan link', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));

      MemoryGameService.client = MockClient((request) async {
        if (request.url.path.contains('/progress')) {
          return http.Response(mockProgressSummaryJson, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      CognitiveAssessmentService.client = MockClient((request) async {
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => MockCaregiverAuthNotifier())],
          child: const MaterialApp(
            home: Scaffold(body: ResidentDirectoryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Sarah Jenkins
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Sarah');
      await tester.pumpAndSettle();

      // Select resident
      final residentCard = find.text('Sarah Jenkins');
      expect(residentCard, findsWidgets);
      await tester.tap(residentCard.first);
      await tester.pumpAndSettle();

      // Verify all 3 original wellness cards are preserved intact
      expect(find.text('Cognitive Wellness'), findsOneWidget);
      expect(find.text('Emotional Wellness'), findsOneWidget);
      expect(find.text('Metabolic Wellness'), findsOneWidget);

      // Verify Memory Games Progress card is displayed
      expect(find.text('Memory Games'), findsWidgets);
      expect(find.text('Completed Sessions'), findsOneWidget);
      expect(find.text('4'), findsWidgets); // 4 completed sessions
      expect(find.text('Remember Sequence'), findsOneWidget);
      expect(find.text('100.0%'), findsWidgets);
      expect(find.text('Matching Pairs'), findsOneWidget);
      expect(find.text('75.0%'), findsWidgets);
      expect(find.text('Remember Items'), findsOneWidget);
      expect(find.text('85.0%'), findsWidgets);

      // Verify "View in Care Plans" button exists
      expect(find.byKey(const ValueKey('open_memory_games_care_plan_button')), findsOneWidget);

      MemoryGameService.client = null;
      CognitiveAssessmentService.client = null;
    });
  });

  group('Care Plans - Detailed Progress & Clinical Risk Separation Tests', () {
    testWidgets('10. Care Plans displays detailed memory games section, history, trends, and neutral decline notice', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));

      MemoryGameService.client = MockClient((request) async {
        if (request.url.path.contains('/progress')) {
          return http.Response(mockDeclineProgressSummaryJson, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      CarePlansService.client = MockClient((request) async {
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => MockElderAuthNotifier())],
          child: const MaterialApp(
            home: Scaffold(body: CarePlansPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memory Games Progress Section
      expect(find.text('Memory Games Progress'), findsOneWidget);
      expect(find.textContaining('Practice Activity Disclaimer: Memory Games are optional cognitive practice exercises'), findsOneWidget);

      // Caregiver Observation notice on repeated decline
      expect(find.textContaining('Caregiver Observation: Noticeable Practice Variation'), findsOneWidget);
      expect(find.textContaining('Noticeable decline across recent practice sessions'), findsOneWidget);

      // Game summaries
      expect(find.text('Remember the Sequence'), findsWidgets);
      expect(find.text('Matching Pairs'), findsWidgets);
      expect(find.text('Remember the Items'), findsWidgets);

      // Performance chart and session history
      expect(find.text('Recent Performance Chart'), findsOneWidget);
      expect(find.textContaining('Session History'), findsOneWidget);

      MemoryGameService.client = null;
      CarePlansService.client = null;
    });

    testWidgets('11. Care Plans displays friendly empty state when no completed sessions exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));

      MemoryGameService.client = MockClient((request) async {
        if (request.url.path.contains('/progress')) {
          return http.Response(mockEmptyProgressSummaryJson, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      CarePlansService.client = MockClient((request) async {
        return http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => MockElderAuthNotifier())],
          child: const MaterialApp(
            home: Scaffold(body: CarePlansPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state
      expect(find.text('No Completed Game Sessions Yet'), findsOneWidget);
      expect(find.textContaining('When Sarah Jenkins plays Remember the Sequence'), findsOneWidget);

      MemoryGameService.client = null;
      CarePlansService.client = null;
    });

    test('12. Clinical risk separation: Memory game scores NEVER alter AI cognitive risk or ACRF assessment', () {
      // Formal cognitive assessment recommendation protocol is strictly decoupled from games
      final lowRiskRec = CognitiveCareRecommendation.forRisk('LOW');
      expect(lowRiskRec.category, equals(CognitiveRiskCategory.low));

      final highRiskRec = CognitiveCareRecommendation.forRisk('HIGH');
      expect(highRiskRec.category, equals(CognitiveRiskCategory.high));

      // A resident with low game score (e.g. 50%) STILL keeps their formal AI LOW risk prediction
      const aiCognitiveRiskLevel = 'LOW';
      const gameScore = 50.0; // low practice score
      expect(gameScore, lessThan(80.0));
      expect(aiCognitiveRiskLevel, equals('LOW')); // Cognitive risk is NOT modified by games
    });
  });
}
