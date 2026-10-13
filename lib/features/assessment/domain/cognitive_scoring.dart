/// Carevora Cognitive Assessment Scoring & Domain Mapping (Flutter/Dart)
///
/// Maps the 20-question cognitive battery to the 5 ACRF cognitive categories:
/// - memory: Immediate registration and episodic recall (Q3, Q10, Q19)
/// - attention: Calculation, backwards sequencing, and vigilance (Q4, Q8, Q14, Q18)
/// - orientation: Temporal, spatial, and geopolitical awareness (Q1, Q2, Q9, Q16, Q20)
/// - recall: Delayed verbal and episodic retrieval (Q5, Q15)
/// - reasoning: Categorization, motor command execution, reading, and language (Q6, Q7, Q11, Q12, Q13, Q17)
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
    1: 'orientation', // Date, day of week, month, year
    2: 'orientation', // Current location, building, city
    3: 'memory', // 3 objects immediate registration (Apple, Table, Penny)
    4: 'attention', // Spell WORLD backwards
    5: 'recall', // Delayed recall of 3 objects
    6: 'reasoning', // Object naming (wristwatch, pencil)
    7: 'reasoning', // Exact phrase repetition ("No ifs, ands, or buts")
    8: 'attention', // Serial 7s subtraction from 100
    9: 'orientation', // Current season
    10: 'memory', // Past residential address
    11: 'reasoning', // 3-stage command comprehension & execution
    12: 'reasoning', // Reading comprehension and executive response
    13: 'reasoning', // Coherent sentence composition
    14: 'attention', // Categorical verbal animal fluency in 60s
    15: 'recall', // Delayed episodic recall of visitors
    16: 'orientation', // Floor awareness
    17: 'reasoning', // Abstract similarities / categorization (Orange & Banana)
    18: 'attention', // Sustained auditory vigilance tapping (letter 'A')
    19: 'memory', // Short-term episodic breakfast recall
    20: 'orientation', // Head of state identification (President / Prime Minister)
  };

  static const Map<String, List<int>> questionIdsByDomain = {
    'memory': [3, 10, 19],
    'attention': [4, 8, 14, 18],
    'orientation': [1, 2, 9, 16, 20],
    'recall': [5, 15],
    'reasoning': [6, 7, 11, 12, 13, 17],
  };

  static const List<CognitiveQuestionItem> questions = [
    CognitiveQuestionItem(
      id: 1,
      category: 'Orientation',
      domain: 'orientation',
      prompt: "What is today's date, including the day of the week, month, and year?",
      aiTip: 'Listen for complete day, month, date, and year details without prompting.',
      recommendedAnswerGuide:
          'Full accuracy required for month and year; +/- 1 day permitted.',
    ),
    CognitiveQuestionItem(
      id: 2,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'Can you tell me where we are right now, including the building and the city?',
      aiTip: 'Assess awareness of current facility name and municipal jurisdiction.',
      recommendedAnswerGuide:
          'Identification of elderly care facility and current town.',
    ),
    CognitiveQuestionItem(
      id: 3,
      category: 'Memory',
      domain: 'memory',
      prompt: 'I am going to name three objects: Apple, Table, and Penny. Please repeat them back to me.',
      aiTip: 'Patient must immediately register all three words clearly.',
      recommendedAnswerGuide:
          'Instant registration score 1 point per correct item.',
    ),
    CognitiveQuestionItem(
      id: 4,
      category: 'Attention',
      domain: 'attention',
      prompt: "Could you spell the word 'WORLD' backwards for me?",
      aiTip: 'Expected answer sequence is D - L - R - O - W.',
      recommendedAnswerGuide:
          'Award 1 point for each correctly sequenced letter.',
    ),
    CognitiveQuestionItem(
      id: 5,
      category: 'Recall',
      domain: 'recall',
      prompt: 'What were the three objects I asked you to remember a few moments ago?',
      aiTip: 'Evaluate delayed recall for: Apple, Table, Penny.',
      recommendedAnswerGuide: 'No cues permitted for first attempt.',
    ),
    CognitiveQuestionItem(
      id: 6,
      category: 'Language & Reasoning',
      domain: 'reasoning',
      prompt: 'What do you call this object: a wristwatch? And what is this: a pencil?',
      aiTip: 'Verify naming clarity for common everyday objects.',
      recommendedAnswerGuide: 'Precise naming without circumlocution.',
    ),
    CognitiveQuestionItem(
      id: 7,
      category: 'Language & Reasoning',
      domain: 'reasoning',
      prompt: "Please repeat this exact phrase: 'No ifs, ands, or buts.'",
      aiTip: 'Examine articulation and phonemic integrity.',
      recommendedAnswerGuide: 'Single repetition strictly required.',
    ),
    CognitiveQuestionItem(
      id: 8,
      category: 'Attention',
      domain: 'attention',
      prompt: 'Count backwards from 100 by subtracting 7 each time, starting with 93.',
      aiTip: 'Check up to 5 serial subtractions: 93, 86, 79, 72, 65.',
      recommendedAnswerGuide: 'Give 1 point per accurate mathematical step.',
    ),
    CognitiveQuestionItem(
      id: 9,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'What season of the year are we currently in?',
      aiTip: 'Observe climate and calendar seasonal recognition.',
      recommendedAnswerGuide:
          'Permit flexibility during seasonal transition weeks.',
    ),
    CognitiveQuestionItem(
      id: 10,
      category: 'Memory',
      domain: 'memory',
      prompt: 'Can you remember your home address from before moving to our care home?',
      aiTip: 'Cross-reference with medical admission record.',
      recommendedAnswerGuide: 'Validate street and locality.',
    ),
    CognitiveQuestionItem(
      id: 11,
      category: 'Executive & Reasoning',
      domain: 'reasoning',
      prompt: 'Take this piece of paper in your right hand, fold it in half, and put it on your lap.',
      aiTip: 'Three-stage motor command comprehension test.',
      recommendedAnswerGuide:
          'Score 1 point per executed clause in correct sequence.',
    ),
    CognitiveQuestionItem(
      id: 12,
      category: 'Language & Reasoning',
      domain: 'reasoning',
      prompt:
          'Please read the sentence shown on the screen and close your eyes.',
      aiTip: 'Assesses reading comprehension and executive motor response.',
      recommendedAnswerGuide: 'Immediate motor closing of eyes upon reading.',
    ),
    CognitiveQuestionItem(
      id: 13,
      category: 'Language & Reasoning',
      domain: 'reasoning',
      prompt:
          "Write a complete sentence about today's weather or your thoughts.",
      aiTip: 'Must contain subject, predicate, and form a coherent thought.',
      recommendedAnswerGuide:
          'Semantic validity irrespective of minor spelling errors.',
    ),
    CognitiveQuestionItem(
      id: 14,
      category: 'Attention',
      domain: 'attention',
      prompt: 'Name as many animals as you can think of in sixty seconds.',
      aiTip:
          'Standard verbal categorical fluency test (Target: >= 14 animals).',
      recommendedAnswerGuide:
          'Unique animal count recorded within 1 minute timer.',
    ),
    CognitiveQuestionItem(
      id: 15,
      category: 'Recall',
      domain: 'recall',
      prompt: 'Do you recall who visited you yesterday afternoon?',
      aiTip: 'Episodic recent memory query corroborated with nursing log.',
      recommendedAnswerGuide: 'Accurate name or familial relationship.',
    ),
    CognitiveQuestionItem(
      id: 16,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'What floor of the residence building are we currently on?',
      aiTip: 'Immediate spatial floor and wing awareness.',
      recommendedAnswerGuide: 'First floor / Residential Wing A.',
    ),
    CognitiveQuestionItem(
      id: 17,
      category: 'Abstract Reasoning',
      domain: 'reasoning',
      prompt:
          'How are an orange and a banana alike? What category do they share?',
      aiTip: 'Abstract reasoning and categorization test.',
      recommendedAnswerGuide:
          "Abstract answer 'Fruit' scores higher than concrete 'You eat them'.",
    ),
    CognitiveQuestionItem(
      id: 18,
      category: 'Attention',
      domain: 'attention',
      prompt: "Please tap the table each time you hear the letter 'A' as I read a list of letters.",
      aiTip: 'Continuous sustained auditory vigilance test.',
      recommendedAnswerGuide: 'Record omissions and commission errors.',
    ),
    CognitiveQuestionItem(
      id: 19,
      category: 'Memory',
      domain: 'memory',
      prompt: 'Can you describe what you had for breakfast this morning?',
      aiTip: 'Short-term episodic retrieval matching dietary logs.',
      recommendedAnswerGuide: 'Consistency with morning dietary tray record.',
    ),
    CognitiveQuestionItem(
      id: 20,
      category: 'Orientation',
      domain: 'orientation',
      prompt: 'Do you know who the current President or Prime Minister of the country is?',
      aiTip: 'Long-term public knowledge recall.',
      recommendedAnswerGuide: 'Correct identification of the head of state.',
    ),
  ];

  /// Calculates per-domain accuracies in [0.0, 1.0] range based on caregiver grades (1.0, 0.5, 0.0).
  /// Unanswered questions (null or absent) are treated as 0.0 (not automatically marked correct).
  static Map<String, double> calculateDomainAccuracies(
    Map<int, double?> grades,
  ) {
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
        if (score != null && !score.isNaN) {
          sum += score;
        } else {
          // Unanswered or null scores count as 0.0
          sum += 0.0;
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
