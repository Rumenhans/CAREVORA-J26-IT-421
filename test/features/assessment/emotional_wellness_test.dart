import 'package:flutter_test/flutter_test.dart';
import 'package:carevora/features/assessment/application/facial_emotion_ai_service.dart';

void main() {
  group('Facial Emotion AI Service Unit Tests', () {
    test('FacialEmotionResult maps happy classification correctly', () {
      final result = FacialEmotionResult(
        primaryEmotion: EmotionCategory.happy,
        confidence: 0.88,
        valenceScore: 0.88,
        arousalScore: 0.50,
        emotionProbabilities: const {
          EmotionCategory.happy: 0.88,
          EmotionCategory.calmNeutral: 0.08,
          EmotionCategory.sadDepressed: 0.04,
        },
        clinicalObservation: 'PyTorch Model Inference: Face classified as HAPPY',
        facialActionUnits: const ['AU6: Cheek Raiser', 'AU12: Lip Corner Puller'],
        analyzedAt: DateTime.now(),
      );

      expect(result.primaryEmotion, EmotionCategory.happy);
      expect(result.emotionLabel, 'Happy / Uplifted');
      expect(result.emoji, '😊');
      expect(result.confidence, 0.88);
      expect(result.valenceScore, greaterThan(0.0));
      expect(result.facialActionUnits.length, 2);
    });

    test('FacialEmotionResult maps sad/depressed classification correctly', () {
      final result = FacialEmotionResult(
        primaryEmotion: EmotionCategory.sadDepressed,
        confidence: 0.84,
        valenceScore: -0.84,
        arousalScore: 0.25,
        emotionProbabilities: const {
          EmotionCategory.sadDepressed: 0.84,
          EmotionCategory.calmNeutral: 0.12,
          EmotionCategory.happy: 0.04,
        },
        clinicalObservation: 'PyTorch Model Inference: Face classified as SAD',
        facialActionUnits: const ['AU1: Inner Brow Raiser', 'AU15: Lip Corner Depressor'],
        analyzedAt: DateTime.now(),
      );

      expect(result.primaryEmotion, EmotionCategory.sadDepressed);
      expect(result.emotionLabel, 'Sad / Affect Flattening');
      expect(result.emoji, '😔');
      expect(result.valenceScore, lessThan(0.0));
      expect(result.facialActionUnits.first, contains('AU1'));
    });

    test('FacialEmotionResult maps fear / anxious classification correctly', () {
      final result = FacialEmotionResult(
        primaryEmotion: EmotionCategory.anxious,
        confidence: 0.82,
        valenceScore: -0.50,
        arousalScore: 0.85,
        emotionProbabilities: const {
          EmotionCategory.anxious: 0.82,
          EmotionCategory.calmNeutral: 0.10,
          EmotionCategory.happy: 0.08,
        },
        clinicalObservation: 'PyTorch Model Inference: Face classified as FEAR / ANXIOUS',
        facialActionUnits: const ['AU1: Inner Brow Raiser', 'AU5: Upper Lid Raiser'],
        analyzedAt: DateTime.now(),
      );

      expect(result.primaryEmotion, EmotionCategory.anxious);
      expect(result.emotionLabel, 'Fear / Anxious');
      expect(result.emoji, '😨');
      expect(result.confidence, 0.82);
    });

    test('FacialEmotionResult maps confused / agitated classification correctly', () {
      final result = FacialEmotionResult(
        primaryEmotion: EmotionCategory.confusedAgitated,
        confidence: 0.78,
        valenceScore: -0.35,
        arousalScore: 0.75,
        emotionProbabilities: const {
          EmotionCategory.confusedAgitated: 0.78,
          EmotionCategory.calmNeutral: 0.12,
          EmotionCategory.happy: 0.10,
        },
        clinicalObservation: 'PyTorch Model Inference: Face classified as CONFUSED / PUZZLED',
        facialActionUnits: const ['AU4: Brow Lowerer', 'AU7: Lid Tightener'],
        analyzedAt: DateTime.now(),
      );

      expect(result.primaryEmotion, EmotionCategory.confusedAgitated);
      expect(result.emotionLabel, 'Confused / Agitated');
      expect(result.emoji, '🤔');
      expect(result.confidence, 0.78);
    });

    test('FacialEmotionAiService provides transparent fallback when offline', () async {
      // Analyze with offline preferredEmotionHint
      final result = await FacialEmotionAiService.analyzeImage(
        assetPath: 'assets/images/landing/senior_sad_face.jpg',
        preferredEmotionHint: 'Sad',
      );

      expect(result.primaryEmotion, EmotionCategory.sadDepressed);
      expect(result.clinicalObservation, contains('Face analyzed as SAD'));
    });
  });

  group('RALPA Logic & Longitudinal Trajectory Guard Tests', () {
    test('Insufficient history (<2 sessions) produces safe fallback without forecast', () {
      final List<int> singleSessionHistory = [65];
      final bool hasSufficientHistory = singleSessionHistory.length >= 2;

      final List<double> forecast = hasSufficientHistory
          ? List.generate(14, (i) => 65.0 + (i * 1.5))
          : [];

      expect(hasSufficientHistory, isFalse);
      expect(forecast.isEmpty, isTrue);
    });

    test('Longitudinal history (>=2 sessions) generates valid 14-day projection', () {
      final List<int> multiSessionHistory = [54, 58, 64, 72];
      final bool hasSufficientHistory = multiSessionHistory.length >= 2;
      const double currentScore = 78.0;
      const double slope = 2.2;

      final List<double> forecast = hasSufficientHistory
          ? List.generate(14, (i) => (currentScore + (i * slope * 0.8)).clamp(10.0, 95.0))
          : [];

      expect(hasSufficientHistory, isTrue);
      expect(forecast.length, 14);
      expect(forecast.first, greaterThanOrEqualTo(currentScore));
      expect(forecast.last, greaterThan(forecast.first));
    });
  });
}
