import 'package:flutter_test/flutter_test.dart';
import 'package:carevora/features/assessment/domain/cognitive_scoring.dart';
import 'package:carevora/features/assessment/application/cognitive_assessment_service.dart';

void main() {
  group('CognitiveScoring 10-Question Battery Tests', () {
    test('battery contains exactly 10 questions with IDs 1 to 10', () {
      expect(CognitiveScoring.questions.length, equals(10));
      expect(CognitiveScoring.questionDomainMap.length, equals(10));

      final ids = CognitiveScoring.questions.map((q) => q.id).toList();
      expect(ids, equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    });

    test('verifies exactly two questions per cognitive domain across all 5 domains', () {
      final orientationIds =
          CognitiveScoring.questionIdsByDomain['orientation']!;
      final memoryIds = CognitiveScoring.questionIdsByDomain['memory']!;
      final attentionIds = CognitiveScoring.questionIdsByDomain['attention']!;
      final recallIds = CognitiveScoring.questionIdsByDomain['recall']!;
      final reasoningIds = CognitiveScoring.questionIdsByDomain['reasoning']!;

      expect(orientationIds.length, equals(2)); // Q1, Q2
      expect(memoryIds.length, equals(2)); // Q3, Q4
      expect(attentionIds.length, equals(2)); // Q5, Q6
      expect(recallIds.length, equals(2)); // Q7, Q8
      expect(reasoningIds.length, equals(2)); // Q9, Q10

      expect(orientationIds, equals([1, 2]));
      expect(memoryIds, equals([3, 4]));
      expect(attentionIds, equals([5, 6]));
      expect(recallIds, equals([7, 8]));
      expect(reasoningIds, equals([9, 10]));

      // Verify reciprocal bidirectional mapping
      for (final q in CognitiveScoring.questions) {
        expect(CognitiveScoring.questionDomainMap[q.id], equals(q.domain));
        expect(CognitiveScoring.questionIdsByDomain[q.domain], contains(q.id));
      }
    });

    test('verifies all 10 prompt texts match exact specified wording', () {
      final expectedPrompts = {
        1: 'What day is it today?',
        2: 'What year is this?',
        3: 'Repeat these words: Sun, Book, Tree.',
        4: 'Say those three words once more.',
        5: 'What is 2 plus 3?',
        6: 'Which is bigger: 3 or 8?',
        7: 'What were the three words from earlier?',
        8: 'Did you hear the word Sun earlier?',
        9: 'What do you use to tell the time?',
        10: 'Are an apple and an orange both fruits?',
      };

      for (final q in CognitiveScoring.questions) {
        expect(q.prompt, equals(expectedPrompts[q.id]));
        expect(q.category.isNotEmpty, isTrue);
        expect(q.domain.isNotEmpty, isTrue);
        expect(q.aiTip.isNotEmpty, isTrue);
        expect(q.recommendedAnswerGuide.isNotEmpty, isTrue);
      }
    });

    test('domain weights match fixed ACRF clinical specification summing to 1.00', () {
      expect(CognitiveScoring.domainWeights['memory'], equals(0.25));
      expect(CognitiveScoring.domainWeights['attention'], equals(0.20));
      expect(CognitiveScoring.domainWeights['orientation'], equals(0.20));
      expect(CognitiveScoring.domainWeights['recall'], equals(0.20));
      expect(CognitiveScoring.domainWeights['reasoning'], equals(0.15));

      final totalWeight = CognitiveScoring.domainWeights.values.fold(
        0.0,
        (a, b) => a + b,
      );
      expect((totalWeight - 1.0).abs(), lessThan(0.0001));
    });

    test('calculates perfect 100.0 score when all 10 questions are graded Correct (1.0)', () {
      final Map<int, double?> perfectGrades = {
        for (int i = 1; i <= 10; i++) i: 1.0,
      };

      final accuracies = CognitiveScoring.calculateDomainAccuracies(
        perfectGrades,
      );
      for (final domain in CognitiveScoring.domains) {
        expect(accuracies[domain], equals(1.0));
      }

      final scores = CognitiveScoring.calculateDomainScores(accuracies);
      for (final domain in CognitiveScoring.domains) {
        expect(scores[domain], equals(100.0));
      }

      final acrf = CognitiveScoring.calculateAcrfWeightedScore(scores);
      expect(acrf, equals(100.0));
    });

    test('strictly distinguishes legitimate 0.0 (Incorrect) from missing grade (null)', () {
      // 1. Legitimate Incorrect score (0.0): All 10 questions are assessed, Q1 is graded 0.0 (Incorrect)
      final Map<int, double?> legitimateGrades = {
        1: 0.0, // Assessed as Incorrect
        for (int i = 2; i <= 10; i++) i: 1.0,
      };

      final accuracies = CognitiveScoring.calculateDomainAccuracies(legitimateGrades);
      // Orientation domain has Q1 (0.0) and Q2 (1.0) -> mean = 0.50
      expect(accuracies['orientation'], equals(0.5));

      // 2. Missing grade (null): Throws ArgumentError when allowIncomplete is false (default)
      final Map<int, double?> incompleteGrades = {
        for (int i = 2; i <= 10; i++) i: 1.0, // Q1 is omitted (null)
      };

      expect(
        () => CognitiveScoring.calculateDomainAccuracies(incompleteGrades),
        throwsArgumentError,
      );

      // When allowIncomplete is explicitly enabled for fallback calculations:
      final fallbackAccuracies = CognitiveScoring.calculateDomainAccuracies(
        incompleteGrades,
        allowIncomplete: true,
      );
      expect(fallbackAccuracies['orientation'], equals(0.5));
    });

    test('supports Partial (0.5) caregiver scoring without double-counting', () {
      // Memory has 2 questions (3, 4)
      final Map<int, double?> grades = {
        for (int i = 1; i <= 10; i++) i: 1.0,
      };
      grades[3] = 1.0;
      grades[4] = 0.5;

      final accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      expect(accuracies['memory'], equals(0.75));

      final scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['memory'], equals(75.0));

      // Overwriting Q4 with 0.0 replaces score cleanly without double-counting
      grades[4] = 0.0;
      final updatedAcc = CognitiveScoring.calculateDomainAccuracies(grades);
      expect(updatedAcc['memory'], equals(0.50));

      // Re-grading Q4 back to 1.0 updates memory accuracy to 1.0
      grades[4] = 1.0;
      final reAcc = CognitiveScoring.calculateDomainAccuracies(grades);
      expect(reAcc['memory'], equals(1.0));
    });

    test('re-grading without double-counting updates total ACRF score accurately', () {
      final Map<int, double?> grades = {
        for (int i = 1; i <= 10; i++) i: 1.0,
      };

      // Perfect score initially = 100.0
      var accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      var scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(CognitiveScoring.calculateAcrfWeightedScore(scores), equals(100.0));

      // Change Reasoning Q10 from 1.0 to 0.0 (Reasoning weight = 0.15, domain has Q9 & Q10)
      // Reasoning accuracy drops from 1.0 to 0.5 (50.0). Loss = 50.0 * 0.15 = 7.5
      grades[10] = 0.0;
      accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['reasoning'], equals(50.0));
      expect(CognitiveScoring.calculateAcrfWeightedScore(scores), equals(92.5));

      // Re-grade Reasoning Q10 to Partial (0.5):
      // Reasoning accuracy becomes (1.0 + 0.5) / 2 = 0.75 (75.0). Loss = 25.0 * 0.15 = 3.75
      grades[10] = 0.5;
      accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['reasoning'], equals(75.0));
      expect(CognitiveScoring.calculateAcrfWeightedScore(scores), equals(96.25));

      // Re-grade Reasoning Q10 back to Correct (1.0) returns exactly to 100.0
      grades[10] = 1.0;
      accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['reasoning'], equals(100.0));
      expect(CognitiveScoring.calculateAcrfWeightedScore(scores), equals(100.0));
    });

    test('aggregates question response times per domain and enforces >= 0.5s', () {
      final Map<int, double> questionTimes = {
        // memory: Q3=5.0s, Q4=3.0s -> avg = 4.0s
        3: 5.0,
        4: 3.0,
        // attention: Q5=8.0s, Q6=6.0s -> avg = 7.0s
        5: 8.0,
        6: 6.0,
        // orientation: Q1=0.2s, Q2=0.2s -> avg 0.2s, clamped to 0.5s
        1: 0.2,
        2: 0.2,
      };

      final domainTimes = CognitiveScoring.aggregateDomainResponseTimes(
        questionTimes,
      );
      expect(domainTimes['memory'], equals(4.0));
      expect(domainTimes['attention'], equals(7.0));
      expect(domainTimes['orientation'], equals(0.5)); // Clamped to minimum 0.5s
      // Unrecorded domains default to positive 4.0s >= 0.5s
      expect(domainTimes['recall']!, greaterThanOrEqualTo(0.5));
      expect(domainTimes['reasoning']!, greaterThanOrEqualTo(0.5));
    });
  });

  group('Session Progress & Incomplete Submission Blocking Tests', () {
    test('simulates answer persistence during question navigation', () {
      final Map<int, String> responses = {};

      // User enters answer for Q1
      responses[1] = "Monday";
      // User navigates to Q2 and enters answer
      responses[2] = "2026";
      // User navigates back to Q1; previous answer persists
      expect(responses[1], equals("Monday"));

      // User edits answer for Q1
      responses[1] = "Tuesday";
      expect(responses[1], equals("Tuesday"));
      expect(responses[2], equals("2026"));
    });

    test('calculates transparent progress matching actual session state (0%, 10%, 100%)', () {
      final questions = CognitiveScoring.questions;
      expect(questions.length, equals(10));

      bool isAnswered(int id, Map<int, String> resp) =>
          resp[id]?.trim().isNotEmpty == true;
      bool isGraded(int id, Map<int, double?> grd) => grd[id] != null;
      bool isFullyCompleted(int id, Map<int, String> resp, Map<int, double?> grd) =>
          isAnswered(id, resp) && isGraded(id, grd);

      int computeProgress(Map<int, String> resp, Map<int, double?> grd) {
        final completed = questions.where((q) => isFullyCompleted(q.id, resp, grd)).length;
        return ((completed / questions.length) * 100.0).round();
      }

      final Map<int, String> resp = {};
      final Map<int, double?> grd = {};

      // 1. Initial State: 0 completed -> 0%
      expect(computeProgress(resp, grd), equals(0));
      expect(CognitiveScoring.isBatteryComplete(responses: resp, grades: grd), isFalse);

      // 2. Question graded 0.0 without answer: Graded = 1, Answered = 0, Completed = 0 -> 0%
      grd[1] = 0.0;
      expect(isGraded(1, grd), isTrue);
      expect(isAnswered(1, resp), isFalse);
      expect(isFullyCompleted(1, resp, grd), isFalse);
      expect(computeProgress(resp, grd), equals(0)); // Does NOT automatically count as answered or completed

      // 3. Question answered with text, but not yet graded: Answered = 1, Graded = 0, Completed = 0 -> 0%
      resp[2] = "2026";
      expect(isAnswered(2, resp), isTrue);
      expect(isGraded(2, grd), isFalse);
      expect(isFullyCompleted(2, resp, grd), isFalse);

      // 4. Question has both valid answer and grade: Completed = 1 -> 10%
      resp[1] = "Monday"; // Now Q1 has both answer and grade (0.0)
      expect(isFullyCompleted(1, resp, grd), isTrue);
      expect(computeProgress(resp, grd), equals(10));

      // 5. Half session complete: 5 questions with both valid answers and grades -> 50%
      for (int i = 2; i <= 5; i++) {
        resp[i] = "answer $i";
        grd[i] = 1.0;
      }
      expect(computeProgress(resp, grd), equals(50));
      expect(CognitiveScoring.isBatteryComplete(responses: resp, grades: grd), isFalse);

      // 6. Complete session: Exactly 10 questions with both valid answers and grades -> 100%
      for (int i = 6; i <= 10; i++) {
        resp[i] = "answer $i";
        grd[i] = 1.0;
      }
      expect(computeProgress(resp, grd), equals(100));
      expect(CognitiveScoring.isBatteryComplete(responses: resp, grades: grd), isTrue);
    });

    test('blocks incomplete submission when any question lacks an answer or grade', () {
      final Map<int, String> responses = {
        for (int i = 1; i <= 10; i++) i: "Answer $i",
      };
      final Map<int, double?> grades = {
        for (int i = 1; i <= 10; i++) i: 1.0,
      };

      // Fully complete initially
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isTrue);

      // If Q10 has an empty string as answer -> blocked
      responses[10] = "";
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isFalse);

      // If Q10 has whitespace-only as answer -> blocked
      responses[10] = "   ";
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isFalse);

      // Restore answer, but remove grade for Q10 -> blocked
      responses[10] = "Both fruits";
      grades.remove(10);
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isFalse);

      // Grade Q10 with 0.0 (Incorrect) -> valid, complete!
      grades[10] = 0.0;
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isTrue);
    });
  });

  group('Cognitive Model Compatibility & DTO Serialization Tests', () {
    test('verifies 10 questions aggregate to 5 domain features matching ML model schema', () {
      final Map<int, double?> grades = {
        1: 1.0, 2: 1.0, // orientation: 1.0 (100%)
        3: 1.0, 4: 0.5, // memory: 0.75 (75%)
        5: 1.0, 6: 1.0, // attention: 1.0 (100%)
        7: 0.5, 8: 1.0, // recall: 0.75 (75%)
        9: 1.0, 10: 1.0, // reasoning: 1.0 (100%)
      };

      final accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      final scores = CognitiveScoring.calculateDomainScores(accuracies);

      // Ensure output schema has the exact 5 domains required by carevora_acrf.py and cognitive_engine
      const expectedDomains = ['memory', 'attention', 'orientation', 'recall', 'reasoning'];
      expect(accuracies.keys.toSet(), equals(expectedDomains.toSet()));
      expect(scores.keys.toSet(), equals(expectedDomains.toSet()));

      // Verify domain aggregations
      expect(accuracies['orientation'], equals(1.0));
      expect(accuracies['memory'], equals(0.75));
      expect(scores['orientation'], equals(100.0));
      expect(scores['memory'], equals(75.0));

      final Map<int, double> questionTimes = {for (int i = 1; i <= 10; i++) i: 3.5};
      final domainTimes = CognitiveScoring.aggregateDomainResponseTimes(questionTimes);
      expect(domainTimes.keys.toSet(), equals(expectedDomains.toSet()));
      for (final d in expectedDomains) {
        expect(domainTimes[d], equals(3.5));
      }
    });

    test('CognitiveSubmissionPayload serializes optional demographic & ML fields accurately', () {
      final payload = CognitiveSubmissionPayload(
        residentId: 42,
        memory: 85.0,
        attention: 75.0,
        orientation: 90.0,
        recall: 70.0,
        reasoning: 80.0,
        age: 78,
        educationYears: 14,
        accuracies: {
          'memory': 0.85,
          'attention': 0.75,
          'orientation': 0.90,
          'recall': 0.70,
          'reasoning': 0.80,
        },
        responseTimes: {
          'memory': 4.2,
          'attention': 6.5,
          'orientation': 3.1,
          'recall': 5.0,
          'reasoning': 7.8,
        },
      );

      final json = payload.toJson();
      expect(json['residentId'], equals(42));
      expect(json['age'], equals(78));
      expect(json['educationYears'], equals(14));
      expect(json['memory'], equals(85.0));
      expect(json['accuracies']['memory'], equals(0.85));
      expect(json['responseTimes']['reasoning'], equals(7.8));
    });

    test('CognitiveSubmissionResult parses ML evaluation when available', () {
      final rawBackendResponse = {
        'id': 101,
        'residentId': 42,
        'residentName': 'Arthur Morgan',
        'memory': 85.0,
        'attention': 75.0,
        'orientation': 90.0,
        'recall': 70.0,
        'reasoning': 80.0,
        'acrfScore': 80.75,
        'mlPrediction': 'Normal',
        'alertTriggered': false,
        'assessedBy': 'Nurse Jackie',
        'mlModelEvaluation': {
          'available': true,
          'prediction': 'Normal',
          'modelType': 'RandomForestClassifier',
          'alertTriggered': false,
          'statusMessage': 'Random Forest inference complete',
          'probabilities': {'Normal': 0.92, 'Mild Cognitive Impairment': 0.08},
          'disclaimer':
              'Experimental synthetic model; not clinically validated.',
        },
      };

      final result = CognitiveSubmissionResult.fromJson(rawBackendResponse);
      expect(result.id, equals(101));
      expect(result.residentId, equals(42));
      expect(result.acrfScore, equals(80.75));
      expect(result.mlAvailable, isTrue);
      expect(result.mlPrediction, equals('Normal'));
      expect(result.alertTriggered, isFalse);
      expect(result.probabilities!['Normal'], equals(0.92));
      expect(result.disclaimer, contains('Experimental synthetic model'));
    });

    test('CognitiveSubmissionResult gracefully handles missing or unavailable ML prediction', () {
      final rawBackendResponse = {
        'id': 102,
        'residentId': 43,
        'residentName': 'Sadie Adler',
        'memory': 60.0,
        'attention': 65.0,
        'orientation': 70.0,
        'recall': 55.0,
        'reasoning': 60.0,
        'acrfScore': 62.5,
        'mlPrediction': null,
        'alertTriggered': false,
        'mlModelEvaluation': {
          'available': false,
          'prediction': null,
          'statusMessage': 'Demographics missing',
        },
      };

      final result = CognitiveSubmissionResult.fromJson(rawBackendResponse);
      expect(result.id, equals(102));
      expect(result.mlAvailable, isFalse);
      expect(result.mlPrediction, isNull);
      expect(result.acrfScore, equals(62.5));
    });
  });

  group('Caregiver Access & Empty State Regression Tests', () {
    String getInitials(String name) {
      final clean = name.trim();
      if (clean.isEmpty) return 'R';
      final parts = clean
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'R';
      if (parts.length == 1) {
        return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    test('getInitials safely parses malformed, single-word, or trailing-space names without RangeError', () {
      // Names registered in the database like "- ", "Senarath ", "Pasidi  " previously crashed with RangeError(index) 0
      expect(getInitials('- '), equals('-'));
      expect(getInitials('Senarath '), equals('SE'));
      expect(getInitials('Pasidi  '), equals('PA'));
      expect(getInitials(''), equals('R'));
      expect(getInitials('   '), equals('R'));
      expect(getInitials('Pasidi  Sarangi'), equals('PS'));
      expect(getInitials('Sarah Jenkins'), equals('SJ'));
      expect(getInitials('Arthur Pendelton'), equals('AP'));
      expect(getInitials('A'), equals('A'));
    });

    test('empty resident list does not perform unsafe list.first or list[0] access', () {
      final List<CognitiveResidentProfile> emptyList = [];
      CognitiveResidentProfile? selectedResident;

      if (emptyList.isNotEmpty) {
        selectedResident = emptyList.first;
      } else {
        selectedResident = null;
      }

      expect(selectedResident, isNull);
    });

    test('caregiver session with no pending responses loads safely without crashing', () {
      final resident = CognitiveResidentProfile(
        id: 5,
        name: '- ',
        roomNumber: 'Room 101',
      );
      expect(resident.id, equals(5));

      final Map<int, String> responses = {};
      final Map<int, double?> grades = {};

      // Calculate answer count & progress
      final answeredCount = responses.values.where((r) => r.trim().isNotEmpty).length;
      expect(answeredCount, equals(0));

      final completedCount = CognitiveScoring.questions.where((q) {
        final hasAnswer = responses[q.id]?.trim().isNotEmpty == true;
        final hasGrade = grades[q.id] != null;
        return hasAnswer && hasGrade;
      }).length;
      expect(completedCount, equals(0));

      // Caregiver progress with 0 answers is safely 0%
      final progressPct = ((completedCount / 10) * 100).round();
      expect(progressPct, equals(0));

      // Submitting empty battery is correctly blocked
      expect(CognitiveScoring.isBatteryComplete(responses: responses, grades: grades), isFalse);
    });

    test('switching resident preserves isolation and clears previous responses and grades', () {
      final resA = CognitiveResidentProfile(id: 1, name: 'Sarah Jenkins', roomNumber: '204');
      final resB = CognitiveResidentProfile(id: 2, name: 'Arthur Pendelton', roomNumber: '205');

      final available = [resA, resB];
      CognitiveResidentProfile? currentResident = resA;

      final Map<int, String> responses = {1: 'Wednesday', 2: '2026'};
      final Map<int, double?> grades = {1: 1.0, 2: 1.0};

      expect(responses.length, equals(2));
      expect(grades.length, equals(2));

      // Caregiver switches to Resident B
      final targetId = 2;
      final found = available.firstWhere((r) => r.id == targetId, orElse: () => available.first);

      // Resident switch resets session state for isolation
      currentResident = found;
      responses.clear();
      grades.clear();

      expect(currentResident.id, equals(2));
      expect(currentResident.name, equals('Arthur Pendelton'));
      expect(responses.isEmpty, isTrue);
      expect(grades.isEmpty, isTrue);
    });

    test('safe dropdown value resolves cleanly when selected resident is missing from list', () {
      final List<CognitiveResidentProfile> available = [
        CognitiveResidentProfile(id: 10, name: 'Resident 10', roomNumber: '101'),
        CognitiveResidentProfile(id: 20, name: 'Resident 20', roomNumber: '102'),
      ];

      const int missingResidentId = 999;

      // Dropdown value resolution logic
      final safeValue = available.any((r) => r.id == missingResidentId)
          ? missingResidentId
          : (available.isNotEmpty ? available.first.id : null);

      expect(safeValue, equals(10));
    });
  });

  group('Automatic Scoring Engine Tests (Deterministic Rubrics)', () {
    final refDate = DateTime(2026, 10, 16); // Friday, 2026

    test('Q1: What day is it today?', () {
      expect(CognitiveScoring.scoreQuestion(1, 'Friday', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(1, 'Today is Friday!', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(1, 'it is friday morning', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(1, 'Monday', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(1, null, referenceDate: refDate), isNull);
      expect(CognitiveScoring.scoreQuestion(1, '   ', referenceDate: refDate), isNull);
    });

    test('Q2: What year is this?', () {
      expect(CognitiveScoring.scoreQuestion(2, '2026', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(2, 'The year is 2026.', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(2, 'twenty twenty-six', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(2, '2025', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(2, null, referenceDate: refDate), isNull);
    });

    test('Q3, Q4, Q7: Memory questions with partial credit and duplicate-word protection', () {
      // 3 distinct words -> 1.0
      expect(CognitiveScoring.scoreQuestion(3, 'Sun, Book, Tree', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(4, 'Tree, book and sun', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(7, 'I remember Sun, Book, Tree.', referenceDate: refDate), equals(1.0));

      // 1-2 distinct words -> 0.5 (partial credit)
      expect(CognitiveScoring.scoreQuestion(3, 'Sun and Book', referenceDate: refDate), equals(0.5));
      expect(CognitiveScoring.scoreQuestion(4, 'Just tree', referenceDate: refDate), equals(0.5));

      // Duplicate word does not inflate score: "Sun sun sun" has only 1 distinct word -> 0.5, NOT 1.0!
      expect(CognitiveScoring.scoreQuestion(3, 'Sun sun sun', referenceDate: refDate), equals(0.5));
      expect(CognitiveScoring.scoreQuestion(7, 'Book book book', referenceDate: refDate), equals(0.5));

      // 0 matching words -> 0.0
      expect(CognitiveScoring.scoreQuestion(3, 'Dog cat bird', referenceDate: refDate), equals(0.0));

      // Missing response -> null (never 0.0)
      expect(CognitiveScoring.scoreQuestion(3, null, referenceDate: refDate), isNull);
      expect(CognitiveScoring.scoreQuestion(7, '', referenceDate: refDate), isNull);
    });

    test('Q5: What is 2 plus 3?', () {
      expect(CognitiveScoring.scoreQuestion(5, '5', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(5, 'five', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(5, 'It is 5.', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(5, 'That makes five', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(5, '6', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(5, null, referenceDate: refDate), isNull);
    });

    test('Q6: Which is bigger: 3 or 8?', () {
      expect(CognitiveScoring.scoreQuestion(6, '8', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(6, 'eight', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(6, '8 is bigger', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(6, '3 is bigger', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(6, null, referenceDate: refDate), isNull);
    });

    test('Q8: Did you hear the word Sun earlier?', () {
      expect(CognitiveScoring.scoreQuestion(8, 'Yes', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(8, 'yeah I did', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(8, 'I heard sun', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(8, 'No', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(8, 'I did not', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(8, null, referenceDate: refDate), isNull);
    });

    test('Q9: What do you use to tell the time?', () {
      // Direct correct answers
      expect(CognitiveScoring.scoreQuestion(9, 'clock', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'watch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'A clock', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'The watch', referenceDate: refDate), equals(1.0));

      // Semantically equivalent timekeeping instruments
      expect(CognitiveScoring.scoreQuestion(9, 'wall clock', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'wristwatch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'wrist watch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'smart watch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'smartwatch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'alarm clock', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'timepiece', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'sundial', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'hourglass', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'I use a clock to tell the time', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'I check my watch', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, 'A clock or a watch', referenceDate: refDate), equals(1.0));

      // Capitalization and surrounding whitespace ignored
      expect(CognitiveScoring.scoreQuestion(9, 'CLOCK', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, '   watch   ', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(9, '  A Wristwatch  ', referenceDate: refDate), equals(1.0));

      // Incorrect objects
      expect(CognitiveScoring.scoreQuestion(9, 'Pen', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'Shoe', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'calendar', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'telephone', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'mirror', referenceDate: refDate), equals(0.0));

      // Disallowed idioms / non-instrument uses of "clock"
      expect(CognitiveScoring.scoreQuestion(9, 'biological clock', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'body clock', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'working around the clock', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'clock in', referenceDate: refDate), equals(0.0));

      // Negation and denial expressions
      expect(CognitiveScoring.scoreQuestion(9, 'not a clock', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'no clock', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'without a watch', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'I don\'t know', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(9, 'I do not use a clock', referenceDate: refDate), equals(0.0));

      // Missing or empty responses
      expect(CognitiveScoring.scoreQuestion(9, null, referenceDate: refDate), isNull);
      expect(CognitiveScoring.scoreQuestion(9, '', referenceDate: refDate), isNull);
      expect(CognitiveScoring.scoreQuestion(9, '   ', referenceDate: refDate), isNull);
    });

    test('Q10: Are an apple and an orange both fruits?', () {
      expect(CognitiveScoring.scoreQuestion(10, 'Yes', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(10, 'both fruits', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(10, 'Yes they are fruits', referenceDate: refDate), equals(1.0));
      expect(CognitiveScoring.scoreQuestion(10, 'No, vegetables', referenceDate: refDate), equals(0.0));
      expect(CognitiveScoring.scoreQuestion(10, null, referenceDate: refDate), isNull);
    });

    test('autoScoreBattery handles complete battery and missing answers properly', () {
      final Map<int, String> fullResponses = {
        1: 'Friday',
        2: '2026',
        3: 'Sun, Book, Tree',
        4: 'Sun, Book, Tree',
        5: '5',
        6: '8',
        7: 'Sun, Book, Tree',
        8: 'Yes',
        9: 'A clock',
        10: 'both fruits',
      };

      expect(CognitiveScoring.isAllQuestionsAnswered(fullResponses), isTrue);
      expect(CognitiveScoring.getUnansweredQuestionIds(fullResponses), isEmpty);

      final fullGrades = CognitiveScoring.autoScoreBattery(fullResponses, referenceDate: refDate);
      expect(fullGrades.length, equals(10));
      for (int i = 1; i <= 10; i++) {
        expect(fullGrades[i], equals(1.0));
      }

      final accuracies = CognitiveScoring.calculateDomainAccuracies(fullGrades);
      final domainScores = CognitiveScoring.calculateDomainScores(accuracies);
      final acrf = CognitiveScoring.calculateAcrfWeightedScore(domainScores);
      expect(acrf, equals(100.0));

      // With missing answer
      final Map<int, String> incompleteResponses = {
        1: 'Friday',
        3: 'Sun, Book', // partial
        // 2, 4..10 missing
      };

      expect(CognitiveScoring.isAllQuestionsAnswered(incompleteResponses), isFalse);
      final unanswered = CognitiveScoring.getUnansweredQuestionIds(incompleteResponses);
      expect(unanswered, contains(2));
      expect(unanswered, contains(4));

      final incompleteGrades = CognitiveScoring.autoScoreBattery(incompleteResponses, referenceDate: refDate);
      expect(incompleteGrades[1], equals(1.0));
      expect(incompleteGrades[2], isNull); // MUST remain null, NOT 0.0
      expect(incompleteGrades[3], equals(0.5));
      expect(incompleteGrades[4], isNull); // MUST remain null, NOT 0.0
    });
  });

  group('Cognitive Assessment Submission Flow & Error Handling Tests', () {
    test('1. CognitiveSubmissionPayload serializes all 10 responses, grades, and domain metrics', () {
      final payload = CognitiveSubmissionPayload(
        residentId: 1,
        memory: 80.0,
        attention: 85.0,
        orientation: 90.0,
        recall: 75.0,
        reasoning: 80.0,
        age: 78,
        educationYears: 12,
        sessionId: 'test-session-123',
        responses: {
          1: 'Friday',
          2: '2026',
          3: 'Sun, Book, Tree',
          4: 'Sun, Book, Tree',
          5: '5',
          6: '8',
          7: 'Sun, Book, Tree',
          8: 'Yes',
          9: 'A clock',
          10: 'both fruits',
        },
        grades: {
          1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.0,
          6: 1.0, 7: 1.0, 8: 1.0, 9: 1.0, 10: 1.0,
        },
        accuracies: {'memory': 1.0, 'attention': 1.0, 'orientation': 1.0, 'recall': 1.0, 'reasoning': 1.0},
        responseTimes: {'memory': 2.5, 'attention': 1.8, 'orientation': 3.0, 'recall': 2.0, 'reasoning': 2.2},
      );

      final jsonMap = payload.toJson();
      expect(jsonMap['residentId'], equals(1));
      expect(jsonMap['memory'], equals(80.0));
      expect(jsonMap['sessionId'], equals('test-session-123'));
      expect(jsonMap['responses']['1'], equals('Friday'));
      expect(jsonMap['responses']['10'], equals('both fruits'));
      expect(jsonMap['grades']['1'], equals(1.0));
      expect(jsonMap['accuracies']['memory'], equals(1.0));
      expect(jsonMap['responseTimes']['attention'], equals(1.8));
    });

    test('2. Unanswered questions block submission with specific missing question IDs', () {
      final partialResponses = <int, String>{
        1: 'Friday',
        2: '2026',
        // 3 to 10 missing
      };

      final unanswered = CognitiveScoring.getUnansweredQuestionIds(partialResponses);
      expect(unanswered.length, equals(8));
      expect(unanswered, containsAll([3, 4, 5, 6, 7, 8, 9, 10]));
      expect(CognitiveScoring.isAllQuestionsAnswered(partialResponses), isFalse);
    });

    test('3. CognitiveSubmissionResult correctly parses completed result with ML prediction', () {
      final jsonResponse = {
        'id': 101,
        'residentId': 1,
        'residentName': 'Sarah Jenkins',
        'memory': 90.0,
        'attention': 85.0,
        'orientation': 100.0,
        'recall': 80.0,
        'reasoning': 85.0,
        'acrfScore': 88.5,
        'mlPrediction': 'Low Risk',
        'riskLevel': 'Low Risk',
        'alertTriggered': false,
        'status': 'COMPLETED',
        'mlModelEvaluation': {
          'available': true,
          'prediction': 'Low Risk',
          'statusMessage': 'Prediction available',
          'probabilities': {'Low': 0.85, 'Moderate': 0.12, 'High': 0.03},
        },
        'assessedBy': 'Eleanor Vance',
      };

      final result = CognitiveSubmissionResult.fromJson(jsonResponse);
      expect(result.id, equals(101));
      expect(result.residentName, equals('Sarah Jenkins'));
      expect(result.acrfScore, equals(88.5));
      expect(result.status, equals('COMPLETED'));
      expect(result.mlAvailable, isTrue);
      expect(result.riskLevel, equals('Low Risk'));
      expect(result.probabilities?['Low'], equals(0.85));
    });

    test('4. CognitiveSubmissionResult correctly parses COMPLETED_PREDICTION_UNAVAILABLE without fabricating risk', () {
      final jsonResponse = {
        'id': 102,
        'residentId': 1,
        'residentName': 'Sarah Jenkins',
        'memory': 70.0,
        'attention': 65.0,
        'orientation': 80.0,
        'recall': 60.0,
        'reasoning': 70.0,
        'acrfScore': 69.0,
        'status': 'COMPLETED_PREDICTION_UNAVAILABLE',
        'mlModelEvaluation': {
          'available': false,
          'prediction': null,
          'statusMessage': 'ML inference unavailable: missing demographic features',
        },
      };

      final result = CognitiveSubmissionResult.fromJson(jsonResponse);
      expect(result.id, equals(102));
      expect(result.acrfScore, equals(69.0));
      expect(result.status, equals('COMPLETED_PREDICTION_UNAVAILABLE'));
      expect(result.mlAvailable, isFalse);
      expect(result.riskLevel, equals('Not Available'));
    });

    test('5. CognitiveApiException preserves HTTP status and readable error message', () {
      const exception = CognitiveApiException(
        'Duplicate submission detected: Assessment session sess-123 has already been completed.',
        statusCode: 400,
        errorCode: 'DUPLICATE_SUBMISSION',
      );

      expect(exception.message, contains('Duplicate submission detected'));
      expect(exception.statusCode, equals(400));
      expect(exception.toString(), equals('Duplicate submission detected: Assessment session sess-123 has already been completed.'));
    });
  });
}
