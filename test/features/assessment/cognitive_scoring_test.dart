import 'package:flutter_test/flutter_test.dart';
import 'package:carevora/features/assessment/domain/cognitive_scoring.dart';
import 'package:carevora/features/assessment/application/cognitive_assessment_service.dart';

void main() {
  group('CognitiveScoring Domain & Question Battery Tests', () {
    test('battery contains exactly 20 questions', () {
      expect(CognitiveScoring.questions.length, equals(20));
      expect(CognitiveScoring.questionDomainMap.length, equals(20));
    });

    test('verifies domain mapping counts across all five domains', () {
      final orientationIds =
          CognitiveScoring.questionIdsByDomain['orientation']!;
      final memoryIds = CognitiveScoring.questionIdsByDomain['memory']!;
      final attentionIds = CognitiveScoring.questionIdsByDomain['attention']!;
      final recallIds = CognitiveScoring.questionIdsByDomain['recall']!;
      final reasoningIds = CognitiveScoring.questionIdsByDomain['reasoning']!;

      expect(orientationIds.length, equals(5)); // Q1, Q2, Q9, Q16, Q20
      expect(memoryIds.length, equals(3)); // Q3, Q10, Q19
      expect(attentionIds.length, equals(4)); // Q4, Q8, Q14, Q18
      expect(recallIds.length, equals(2)); // Q5, Q15
      expect(reasoningIds.length, equals(6)); // Q6, Q7, Q11, Q12, Q13, Q17

      expect(orientationIds, containsAll([1, 2, 9, 16, 20]));
      expect(memoryIds, containsAll([3, 10, 19]));
      expect(attentionIds, containsAll([4, 8, 14, 18]));
      expect(recallIds, containsAll([5, 15]));
      expect(reasoningIds, containsAll([6, 7, 11, 12, 13, 17]));

      // Verify reciprocal mapping in questionDomainMap
      for (final q in CognitiveScoring.questions) {
        expect(CognitiveScoring.questionDomainMap[q.id], equals(q.domain));
        expect(CognitiveScoring.questionIdsByDomain[q.domain], contains(q.id));
      }
    });

    test('domain weights match fixed ACRF clinical specification', () {
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

    test('calculates perfect 100.0 score when all 20 questions are graded Correct (1.0)', () {
      final Map<int, double?> perfectGrades = {
        for (int i = 1; i <= 20; i++) i: 1.0,
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

    test('does NOT mark unanswered questions as correct; treats missing/null as 0.0', () {
      // Suppose caregiver grades only Q1 as Correct (1.0) and leaves remaining 19 unanswered (null)
      final Map<int, double?> partialSession = {1: 1.0};

      final accuracies = CognitiveScoring.calculateDomainAccuracies(
        partialSession,
      );
      // Orientation has 5 questions (1, 2, 9, 16, 20). Q1 is 1.0, others are 0.0 -> 1/5 = 0.20
      expect(accuracies['orientation'], equals(0.2));
      // All other domains are completely unanswered -> 0.0
      expect(accuracies['memory'], equals(0.0));
      expect(accuracies['attention'], equals(0.0));
      expect(accuracies['recall'], equals(0.0));
      expect(accuracies['reasoning'], equals(0.0));

      final scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['orientation'], equals(20.0));
      expect(scores['memory'], equals(0.0));

      final acrf = CognitiveScoring.calculateAcrfWeightedScore(scores);
      // orientation weight is 0.20 * 20.0 = 4.0
      expect(acrf, equals(4.0));
    });

    test('supports Partial (0.5) caregiver scoring', () {
      // Memory has 3 questions (3, 10, 19)
      // Q3 = 1.0, Q10 = 0.5, Q19 = 0.0 -> Sum = 1.5 -> Mean = 0.5
      final Map<int, double?> grades = {3: 1.0, 10: 0.5, 19: 0.0};

      final accuracies = CognitiveScoring.calculateDomainAccuracies(grades);
      expect(accuracies['memory'], equals(0.5));

      final scores = CognitiveScoring.calculateDomainScores(accuracies);
      expect(scores['memory'], equals(50.0));
    });

    test(
      'aggregates question response times per domain and enforces >= 0.5s',
      () {
        final Map<int, double> questionTimes = {
          // memory: Q3=5.0s, Q10=3.0s, Q19=4.0s -> avg = 4.0s
          3: 5.0,
          10: 3.0,
          19: 4.0,
          // attention: Q4=10.0s, Q8=12.0s, Q14=8.0s, Q18=6.0s -> avg = 9.0s
          4: 10.0,
          8: 12.0,
          14: 8.0,
          18: 6.0,
        };

        final domainTimes = CognitiveScoring.aggregateDomainResponseTimes(
          questionTimes,
        );
        expect(domainTimes['memory'], equals(4.0));
        expect(domainTimes['attention'], equals(9.0));
        // For unrecorded domains, default fallback is valid positive (>= 0.5s)
        expect(domainTimes['orientation']!, greaterThanOrEqualTo(0.5));
        expect(domainTimes['recall']!, greaterThanOrEqualTo(0.5));
        expect(domainTimes['reasoning']!, greaterThanOrEqualTo(0.5));
      },
    );
  });

  group('Cognitive Assessment DTO & Serialization Tests', () {
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
}
