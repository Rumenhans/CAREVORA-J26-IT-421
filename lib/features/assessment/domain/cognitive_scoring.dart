/// Carevora Cognitive Assessment Scoring & Domain Mapping (Flutter/Dart)
///
/// Maps the 10-question cognitive battery to the 5 ACRF cognitive categories:
/// - orientation: Temporal orientation and calendar awareness (Q1, Q2)
/// - memory: Immediate registration and verbal encoding (Q3, Q4)
/// - attention: Calculation and magnitude discrimination (Q5, Q6)
/// - recall: Delayed verbal recall and cued recognition (Q7, Q8)
/// - reasoning: Visual confrontation naming and conceptual categorization (Q9, Q10)
///
/// Designed with short, elderly-friendly prompts answerable in 1-2 words.
/// Non-diagnostic screening instrument for clinical decision support.
library;

class CognitiveQuestionItem {
  final int id;
  final String category;
  final String domain; // memory, attention, orientation, recall, reasoning
  final String prompt;
  final String aiTip;
  final String recommendedAnswerGuide;

  const CognitiveQuestionItem({
    required this.id,
    required this.category,
    required this.domain,
    required this.prompt,
    required this.aiTip,
    required this.recommendedAnswerGuide,
  });
}

class CognitiveScoring {
  static const List<String> domains = [
    'memory',
    'attention',
    'orientation',
    'recall',
    'reasoning',
  ];

  static const Map<String, double> domainWeights = {
    'memory': 0.25,
    'attention': 0.20,
    'orientation': 0.20,
    'recall': 0.20,
    'reasoning': 0.15,
  };

  static const Map<int, String> questionDomainMap = {
    1: 'orientation', // Day of the week
    2: 'orientation', // Current year
    3: 'memory', // 3 objects immediate registration (Sun, Book, Tree)
    4: 'memory', // Immediate repetition confirmation
    5: 'attention', // Simple mental addition (2 + 3)
    6: 'attention', // Number comparison (which is bigger: 3 or 8)
    7: 'recall', // Delayed recall of 3 objects
    8: 'recall', // Cued recognition of registered object
    9: 'reasoning', // Visual confrontation naming (pen / watch)
    10: 'reasoning', // Conceptual categorization (apple & orange)
  };

  static const Map<String, List<int>> questionIdsByDomain = {
    'orientation': [1, 2],
    'memory': [3, 4],
    'attention': [5, 6],
    'recall': [7, 8],
    'reasoning': [9, 10],
  };

  static const List<CognitiveQuestionItem> questions = [
    CognitiveQuestionItem(
      id: 1,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'What day is it today?',
      aiTip: 'Temporal orientation. Accept day of the week (e.g. Monday).',
      recommendedAnswerGuide: 'Correct day of the week.',
    ),
    CognitiveQuestionItem(
      id: 2,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'What year is this?',
      aiTip: 'Calendar awareness. Accept current four-digit year.',
      recommendedAnswerGuide: 'Current year (e.g., 2026).',
    ),
    CognitiveQuestionItem(
      id: 3,
      category: 'Immediate Memory',
      domain: 'memory',
      prompt: 'Repeat these words: Sun, Book, Tree.',
      aiTip: 'Immediate verbal registration of three common targets.',
      recommendedAnswerGuide:
          'Score 1.0 if all 3 repeated, 0.5 for 1-2 words, 0.0 for none.',
    ),
    CognitiveQuestionItem(
      id: 4,
      category: 'Immediate Memory',
      domain: 'memory',
      prompt: 'Say those three words once more.',
      aiTip: 'Reinforces memory encoding prior to delayed recall.',
      recommendedAnswerGuide:
          'Score 1.0 if all 3 repeated, 0.5 for 1-2 words, 0.0 for none.',
    ),
    CognitiveQuestionItem(
      id: 5,
      category: 'Attention & Math',
      domain: 'attention',
      prompt: 'What is 2 plus 3?',
      aiTip: 'Simple mental addition. Evaluates focus and basic arithmetic.',
      recommendedAnswerGuide: '5 (Five).',
    ),
    CognitiveQuestionItem(
      id: 6,
      category: 'Attention & Number',
      domain: 'attention',
      prompt: 'Which is bigger: 3 or 8?',
      aiTip: 'Magnitude discrimination and focused attention.',
      recommendedAnswerGuide: '8 (Eight).',
    ),
    CognitiveQuestionItem(
      id: 7,
      category: 'Delayed Recall',
      domain: 'recall',
      prompt: 'What were the three words from earlier?',
      aiTip: 'Spontaneous delayed recall for: Sun, Book, Tree.',
      recommendedAnswerGuide:
          'Score 1.0 if all 3 recalled, 0.5 for 1-2 words, 0.0 for none.',
    ),
    CognitiveQuestionItem(
      id: 8,
      category: 'Delayed Recall',
      domain: 'recall',
      prompt: 'Did you hear the word Sun earlier?',
      aiTip: 'Cued recognition memory.',
      recommendedAnswerGuide: "'Yes'.",
    ),
    CognitiveQuestionItem(
      id: 9,
      category: 'Language & Reasoning',
      domain: 'reasoning',
      prompt: 'What do you call this? (Show pen or watch.)',
      aiTip: 'Visual confrontation naming of common everyday item.',
      recommendedAnswerGuide: "'Pen' or 'Watch'.",
    ),
    CognitiveQuestionItem(
      id: 10,
      category: 'Abstract Reasoning',
      domain: 'reasoning',
      prompt: 'Are an apple and an orange both fruits?',
      aiTip: 'Semantic categorization and conceptual reasoning.',
      recommendedAnswerGuide: "'Yes' (or 'Both fruits').",
    ),
  ];

  /// Validates whether the 10-question battery is fully assessed with both saved responses and grades.
  static bool isBatteryComplete({
    required Map<int, String> responses,
    required Map<int, double?> grades,
  }) {
    for (final q in questions) {
      final hasAns = responses[q.id]?.trim().isNotEmpty == true;
      final hasGrd = grades[q.id] != null;
      if (!hasAns || !hasGrd) return false;
    }
    return true;
  }

  /// Calculates per-domain accuracies in [0.0, 1.0] range based on caregiver grades (1.0, 0.5, 0.0).
  /// Strictly distinguishes between missing scores (null) and legitimate Incorrect scores (0.0).
  /// If [allowIncomplete] is false (default), missing grades are rejected to prevent converting
  /// unassessed items to zero.
  static Map<String, double> calculateDomainAccuracies(
    Map<int, double?> grades, {
    bool allowIncomplete = false,
  }) {
    final Map<String, double> accuracies = {};

    for (final domain in domains) {
      final qIds = questionIdsByDomain[domain] ?? [];
      if (qIds.isEmpty) {
        accuracies[domain] = 0.0;
        continue;
      }

      double sum = 0.0;
      for (final id in qIds) {
        final score = grades[id];
        if (score == null) {
          if (!allowIncomplete) {
            throw ArgumentError(
              'Cannot calculate domain accuracy: Question $id has no clinical grade. Missing grades must not be converted to 0.0.',
            );
          }
          sum += 0.0;
        } else if (!score.isNaN) {
          sum += score;
        }
      }

      final mean = sum / qIds.length;
      accuracies[domain] = double.parse(mean.toStringAsFixed(4));
    }

    return accuracies;
  }

  /// Calculates domain scores on [0.0, 100.0] scale from accuracies.
  static Map<String, double> calculateDomainScores(
    Map<String, double> accuracies,
  ) {
    final Map<String, double> scores = {};
    for (final domain in domains) {
      final acc = accuracies[domain] ?? 0.0;
      scores[domain] = double.parse((acc * 100.0).toStringAsFixed(2));
    }
    return scores;
  }

  /// Aggregates measured question viewing durations in seconds to mean domain response times.
  /// Enforces a minimum of 0.5s so response times are strictly positive.
  static Map<String, double> aggregateDomainResponseTimes(
    Map<int, double> questionTimesInSeconds,
  ) {
    final Map<String, double> responseTimes = {};

    for (final domain in domains) {
      final qIds = questionIdsByDomain[domain] ?? [];
      double totalTime = 0.0;
      int count = 0;

      for (final id in qIds) {
        final t = questionTimesInSeconds[id];
        if (t != null && !t.isNaN && t > 0.0) {
          totalTime += t;
          count++;
        }
      }

      final mean = count > 0 ? (totalTime / count) : 4.0;
      final clamped = mean < 0.5 ? 0.5 : mean;
      responseTimes[domain] = double.parse(clamped.toStringAsFixed(2));
    }

    return responseTimes;
  }

  /// Calculates arithmetic ACRF score:
  /// memory*0.25 + attention*0.20 + orientation*0.20 + recall*0.20 + reasoning*0.15
  static double calculateAcrfWeightedScore(Map<String, double> domainScores) {
    double total = 0.0;
    for (final domain in domains) {
      final score = domainScores[domain] ?? 0.0;
      final weight = domainWeights[domain] ?? 0.20;
      total += score * weight;
    }
    return double.parse(total.toStringAsFixed(2));
  }
}
