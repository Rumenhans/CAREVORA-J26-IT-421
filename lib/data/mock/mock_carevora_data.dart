import '../models/carevora_models.dart';

class MockCarevoraData {
  MockCarevoraData._();

  static const Resident defaultResident = Resident(
    id: '9001',
    name: 'Mr. James Perera',
    age: 78,
    gender: 'Male',
    roomNo: '105',
    lastAssessmentDate: '12 May 2025, 10:30 AM',
    cognitiveScore: 0.64,
    cognitiveTrend: 0.08,
    emotionalScore: 0.78,
    emotionalTrend: 0.12,
    metabolicScore: 0.56,
    metabolicTrend: 0.04,
    overallIndex: 0.62,
    overallTrend: 0.06,
  );

  static final List<AssessmentRecord> recentAssessments = [
    const AssessmentRecord(
      id: 'REC-001',
      dateTime: '12 May 2025, 10:30 AM',
      cognitiveScore: 0.64,
      emotionalScore: 0.78,
      metabolicScore: 0.56,
      overallRiskScore: 0.62,
      assessedBy: 'Seetha N. (RN)',
    ),
    const AssessmentRecord(
      id: 'REC-002',
      dateTime: '02 May 2025, 02:15 PM',
      cognitiveScore: 0.58,
      emotionalScore: 0.65,
      metabolicScore: 0.52,
      overallRiskScore: 0.55,
      assessedBy: 'Seetha N. (RN)',
    ),
    const AssessmentRecord(
      id: 'REC-003',
      dateTime: '26 Apr 2025, 09:45 AM',
      cognitiveScore: 0.50,
      emotionalScore: 0.48,
      metabolicScore: 0.45,
      overallRiskScore: 0.47,
      assessedBy: 'K. Bandara (Caregiver)',
    ),
  ];

  static final List<AlertItem> alerts = [
    const AlertItem(
      id: 'ALT-1',
      title: 'High Emotional Withdrawal',
      description: 'Affect scoring indicates acute withdrawal during morning session.',
      severity: 'High',
      timestamp: 'Today, 08:30 AM',
    ),
    const AlertItem(
      id: 'ALT-2',
      title: 'Delayed Cognitive Recall',
      description: 'Delayed verbal recall observed for 3-item delayed retrieval task.',
      severity: 'Moderate',
      timestamp: 'Yesterday, 04:10 PM',
    ),
    const AlertItem(
      id: 'ALT-3',
      title: 'Vitals Logging Reminder',
      description: 'Evening BP and blood glucose logging requested for room 105.',
      severity: 'Reminder',
      timestamp: '11 May 2025',
    ),
  ];

  static final List<AssessmentQuestion> cognitiveQuestions = [
    const AssessmentQuestion(
      id: 1,
      category: 'Orientation',
      prompt: 'What is the current year and which season are we currently in?',
      audioPrompt: 'What is the current year and which season are we currently in?',
      tip: 'Allow up to 10 seconds for the resident to respond without interruption.',
    ),
    const AssessmentQuestion(
      id: 2,
      category: 'Orientation',
      prompt: 'Can you tell me what city or town we are in right now?',
      audioPrompt: 'Can you tell me what city or town we are in right now?',
      tip: 'Listen for exact town name or general municipal reference.',
    ),
    const AssessmentQuestion(
      id: 3,
      category: 'Immediate Memory',
      prompt: 'I will say three words: Apple, Table, Penny. Please repeat them back to me.',
      audioPrompt: 'I will say three words: Apple, Table, Penny. Please repeat them back to me.',
      tip: 'Note immediate repetition accuracy. These words will be tested later.',
    ),
    const AssessmentQuestion(
      id: 4,
      category: 'Attention & Calculation',
      prompt: 'Starting from 100, count backwards by subtracting 7 each time.',
      audioPrompt: 'Starting from 100, count backwards by subtracting 7 each time.',
      tip: '93, 86, 79, 72, 65. Record each serial decrement.',
    ),
    const AssessmentQuestion(
      id: 5,
      category: 'Language & Object Naming',
      prompt: 'What is this object called that I am pointing to right now? (Watch)',
      audioPrompt: 'What is this object called that I am pointing to right now?',
      tip: 'Tests nominal naming capacity and visual recognition.',
    ),
    const AssessmentQuestion(
      id: 6,
      category: 'Language & Repetition',
      prompt: 'Please repeat this phrase after me: "No ifs, ands, or buts."',
      audioPrompt: 'Please repeat this phrase after me: No ifs, ands, or buts.',
      tip: 'Only one repetition allowed. Listen for precise phonemic pronunciation.',
    ),
    const AssessmentQuestion(
      id: 7,
      category: 'Visuospatial',
      prompt: 'Can you recognize this shape and identify how many corners it has?',
      audioPrompt: 'Can you recognize this shape and identify how many corners it has?',
      tip: 'Testing 2D geometric recognition and cardinal counting.',
    ),
    const AssessmentQuestion(
      id: 8,
      category: 'Executive Function',
      prompt: 'In what way are an orange and a banana alike?',
      audioPrompt: 'In what way are an orange and a banana alike?',
      tip: 'Abstract conceptual category: both are fruits.',
    ),
    const AssessmentQuestion(
      id: 9,
      category: 'Delayed Recall',
      prompt: 'What were the three words I asked you to remember a few minutes ago?',
      audioPrompt: 'What were the three words I asked you to remember a few minutes ago?',
      tip: 'Apple, Table, Penny. Uncued verbal retrieval.',
    ),
    const AssessmentQuestion(
      id: 10,
      category: 'Orientation',
      prompt: 'Do you know which day of the week it is today?',
      audioPrompt: 'Do you know which day of the week it is today?',
      tip: 'Orientation to temporal day.',
    ),
    const AssessmentQuestion(
      id: 11,
      category: 'Language',
      prompt: 'Name as many animals as you can think of in one minute.',
      audioPrompt: 'Name as many animals as you can think of in one minute.',
      tip: 'Verbal category fluency task (target > 12 animals).',
    ),
    const AssessmentQuestion(
      id: 12,
      category: 'Working Memory',
      prompt: 'Spell the word "WORLD" backwards.',
      audioPrompt: 'Spell the word WORLD backwards.',
      tip: 'D - L - R - O - W.',
    ),
    const AssessmentQuestion(
      id: 13,
      category: 'Abstract Reasoning',
      prompt: 'What does the saying "Actions speak louder than words" mean to you?',
      audioPrompt: 'What does the saying Actions speak louder than words mean to you?',
      tip: 'Tests proverb comprehension and metaphorical interpretation.',
    ),
    const AssessmentQuestion(
      id: 14,
      category: 'Motor Planning',
      prompt: 'Take this piece of paper in your right hand, fold it in half, and place it on the table.',
      audioPrompt: 'Take this piece of paper in your right hand, fold it in half, and place it on the table.',
      tip: 'Three-stage motor command execution.',
    ),
    const AssessmentQuestion(
      id: 15,
      category: 'Reading Comprehension',
      prompt: 'Please read the sentence shown on screen and do what it says.',
      audioPrompt: 'Please read the sentence shown on screen and do what it says.',
      tip: '"Close your eyes".',
    ),
    const AssessmentQuestion(
      id: 16,
      category: 'Orientation',
      prompt: 'What floor or room of the facility are we currently located in?',
      audioPrompt: 'What floor or room of the facility are we currently located in?',
      tip: 'Spatial facility orientation.',
    ),
    const AssessmentQuestion(
      id: 17,
      category: 'Semantic Memory',
      prompt: 'Who is the current head of state or leader of our country?',
      audioPrompt: 'Who is the current head of state or leader of our country?',
      tip: 'General knowledge retrieval.',
    ),
    const AssessmentQuestion(
      id: 18,
      category: 'Calculations',
      prompt: 'If you have five dollars and buy an item costing three dollars, how much change is left?',
      audioPrompt: 'If you have five dollars and buy an item costing three dollars, how much change is left?',
      tip: 'Simple currency arithmetic.',
    ),
    const AssessmentQuestion(
      id: 19,
      category: 'Judgment & Safety',
      prompt: 'What would you do if you smelled smoke coming from the hallway right now?',
      audioPrompt: 'What would you do if you smelled smoke coming from the hallway right now?',
      tip: 'Practical safety reasoning and emergency response awareness.',
    ),
    const AssessmentQuestion(
      id: 20,
      category: 'Self-Reflection',
      prompt: 'How has your memory and focus felt over the past few days?',
      audioPrompt: 'How has your memory and focus felt over the past few days?',
      tip: 'Subjective cognitive complaint logging and affective state.',
    ),
  ];
}
