import 'package:flutter_test/flutter_test.dart';
import 'package:carevora/features/assessment/application/emotional_assessment_service.dart';

void main() {
  group('EmotionalAssessmentService - Question Polarity & Index Mapping', () {
    test('Identifies Q4 and Q5 as negative polarity questions', () {
      expect(EmotionalAssessmentService.negativeQuestionIds, contains(4));
      expect(EmotionalAssessmentService.negativeQuestionIds, contains(5));
      expect(EmotionalAssessmentService.negativeQuestionIds.length, 2);
    });

    test('Identifies Q1, Q2, Q3, Q6, Q7, Q8, Q9, Q10 as positive polarity questions', () {
      for (final id in [1, 2, 3, 6, 7, 8, 9, 10]) {
        expect(EmotionalAssessmentService.positiveQuestionIds, contains(id));
      }
      expect(EmotionalAssessmentService.positiveQuestionIds.length, 8);
    });

    test('Maps positive question answers correctly: Yes = 0 (favorable), No = 1 (adverse)', () {
      // Q1: "Are you feeling peaceful and content today?"
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(1, true), 0);
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(1, false), 1);

      // Q7: "Do you have hobbies or activities you still look forward to doing?"
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(7, true), 0);
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(7, false), 1);
    });

    test('Maps negative question answers correctly: No = 0 (favorable), Yes = 1 (adverse)', () {
      // Q4: "Do you often feel left out or lonely when people gather around?"
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(4, false), 0);
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(4, true), 1);

      // Q5: "Do you find yourself spending most of your day alone in your room?"
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(5, false), 0);
      expect(EmotionalAssessmentService.mapAnswerToBackendIndex(5, true), 1);
    });
  });

  group('EmotionalAssessmentService - Scoring & Risk Disambiguation', () {
    test('Calculates 100.0% wellness and 0.0% loneliness risk when all 10 answers are favorable', () {
      final answers = {
        1: true,  // Yes (favorable)
        2: true,  // Yes (favorable)
        3: true,  // Yes (favorable)
        4: false, // No (favorable, reverse-scored)
        5: false, // No (favorable, reverse-scored)
        6: true,  // Yes (favorable)
        7: true,  // Yes (favorable)
        8: true,  // Yes (favorable)
        9: true,  // Yes (favorable)
        10: true, // Yes (favorable)
      };

      final wellness = EmotionalAssessmentService.calculateWellnessScore(answers);
      final risk = EmotionalAssessmentService.calculateLonelinessRiskScore(wellness);

      expect(wellness, 100.0);
      expect(risk, 0.0);
    });

    test('Calculates 0.0% wellness and 100.0% loneliness risk when all 10 answers are adverse', () {
      final answers = {
        1: false, // No (adverse)
        2: false, // No (adverse)
        3: false, // No (adverse)
        4: true,  // Yes (adverse, reverse-scored)
        5: true,  // Yes (adverse, reverse-scored)
        6: false, // No (adverse)
        7: false, // No (adverse)
        8: false, // No (adverse)
        9: false, // No (adverse)
        10: false, // No (adverse)
      };

      final wellness = EmotionalAssessmentService.calculateWellnessScore(answers);
      final risk = EmotionalAssessmentService.calculateLonelinessRiskScore(wellness);

      expect(wellness, 0.0);
      expect(risk, 100.0);
    });

    test('Calculates 80.0% wellness and 20.0% loneliness risk for 8 favorable / 2 adverse', () {
      // 8 favorable answers, 2 adverse (e.g. Q1 adverse No, Q4 adverse Yes)
      final answers = {
        1: false, // adverse (0 pts)
        2: true,  // favorable
        3: true,  // favorable
        4: true,  // adverse (0 pts)
        5: false, // favorable
        6: true,  // favorable
        7: true,  // favorable
        8: true,  // favorable
        9: true,  // favorable
        10: true, // favorable
      };

      final wellness = EmotionalAssessmentService.calculateWellnessScore(answers);
      final risk = EmotionalAssessmentService.calculateLonelinessRiskScore(wellness);

      expect(wellness, 80.0);
      expect(risk, 20.0);
      // Disambiguation verification: wellness + risk = 100
      expect(wellness + risk, 100.0);
    });

    test('Loneliness risk is not confused with wellness score', () {
      // High loneliness risk (70.0%) means low wellness score (30.0%)
      const double wellnessScore = 30.0;
      final riskScore = EmotionalAssessmentService.calculateLonelinessRiskScore(wellnessScore);

      expect(riskScore, 70.0);
      expect(riskScore, isNot(equals(wellnessScore)));
      expect(riskScore, greaterThan(wellnessScore));
    });
  });

  group('EmotionalAssessmentService - Validation & Payload Construction', () {
    test('Validates completion correctly', () {
      final incompleteAnswers = <int, bool?>{
        1: true,
        2: false,
        3: true,
      };

      expect(EmotionalAssessmentService.areAllQuestionsAnswered(incompleteAnswers), isFalse);
      final missing = EmotionalAssessmentService.getUnansweredQuestions(incompleteAnswers);
      expect(missing, [4, 5, 6, 7, 8, 9, 10]);

      final completeAnswers = <int, bool?>{
        for (int i = 1; i <= 10; i++) i: true,
      };
      expect(EmotionalAssessmentService.areAllQuestionsAnswered(completeAnswers), isTrue);
      expect(EmotionalAssessmentService.getUnansweredQuestions(completeAnswers), isEmpty);
    });

    test('Builds 10-item integer payload matching Spring Boot AssessmentSubmissionRequest', () {
      final answers = {
        1: true,  // pos -> 0
        2: false, // pos -> 1
        3: true,  // pos -> 0
        4: false, // neg -> 0
        5: true,  // neg -> 1
        6: true,  // pos -> 0
        7: true,  // pos -> 0
        8: false, // pos -> 1
        9: true,  // pos -> 0
        10: true, // pos -> 0
      };

      final payload = EmotionalAssessmentService.buildAnswersPayload(answers);

      expect(payload.length, 10);
      expect(payload, equals([0, 1, 0, 0, 1, 0, 0, 1, 0, 0]));
      expect(payload.every((v) => v == 0 || v == 1), isTrue);
    });

    test('Correctly identifies exact missing question indices when partially answered', () {
      // User answered 1, 4, 6, 7, 8, 9 (6 answered, missing 2, 3, 5, 10)
      final partialAnswers = <int, bool?>{
        1: true,
        2: null,
        3: null,
        4: false,
        5: null,
        6: true,
        7: true,
        8: true,
        9: true,
        10: null,
      };

      expect(EmotionalAssessmentService.areAllQuestionsAnswered(partialAnswers), isFalse);
      final missing = EmotionalAssessmentService.getUnansweredQuestions(partialAnswers);
      expect(missing, equals([2, 3, 5, 10]));
    });

    test('Submission result parses complete multimodal payload including facial and voice', () {
      final json = {
        'id': 42,
        'residentId': 1,
        'overallScore': 80.0,
        'emotionalScore': 80.0,
        'socialScore': 75.0,
        'status': 'STABLE',
        'riskLevel': 'LOW',
        'trajectory': 'STABLE',
        'encouragingMessage': 'Mood and affect are stable.',
        'facialCheckIncluded': true,
        'voiceCheckIncluded': true,
      };

      final result = EmotionalAssessmentSubmissionResult.fromJson(json);
      expect(result.id, 42);
      expect(result.residentId, 1);
      expect(result.overallScore, 80.0);
      expect(result.facialCheckIncluded, isTrue);
      expect(result.voiceCheckIncluded, isTrue);
    });
  });
}

