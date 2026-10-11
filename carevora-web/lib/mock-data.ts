export interface Resident {
  id: string;
  name: string;
  age: number;
  gender: string;
  roomNumber: string;
  avatarUrl?: string;
  lastAssessmentDate: string;
  overallWellnessIndex: number; // 0.00 to 1.00
  cognitiveHealthScore: number;
  emotionalWellnessScore: number;
  metabolicHealthScore: number;
  cognitiveTrendDelta: number; // e.g. +0.08
  emotionalTrendDelta: number;
  metabolicTrendDelta: number;
  overallTrendDelta: number;
}

export interface AssessmentRecord {
  id: string;
  dateTime: string;
  cognitiveScore: number;
  emotionalScore: number;
  metabolicScore: number;
  overallRiskScore: number;
  assessedBy: string;
  status: "Completed" | "Pending Review";
  notes?: string;
}

export interface AlertNotification {
  id: string;
  type: "High Risk" | "Moderate Risk" | "Reminder";
  title: string;
  description: string;
  timestamp: string;
  residentName: string;
  unread: boolean;
}

export interface CognitiveQuestion {
  id: number;
  category: "Orientation" | "Memory" | "Attention" | "Language" | "Recall";
  questionText: string;
  aiTip: string;
  recommendedAnswerGuide: string;
}

export const mockResident: Resident = {
  id: "9001",
  name: "Mr. James Perera",
  age: 78,
  gender: "Male",
  roomNumber: "105",
  lastAssessmentDate: "12 May 2025, 10:30 AM",
  overallWellnessIndex: 0.62,
  cognitiveHealthScore: 0.64,
  emotionalWellnessScore: 0.78,
  metabolicHealthScore: 0.56,
  cognitiveTrendDelta: 0.08,
  emotionalTrendDelta: 0.12,
  metabolicTrendDelta: 0.04,
  overallTrendDelta: 0.06,
};

export const mockRiskTrendData = [
  { date: "10-Apr", risk: 0.45, label: "0.45" },
  { date: "18-Apr", risk: 0.50, label: "0.50" },
  { date: "26-Apr", risk: 0.47, label: "0.47" },
  { date: "02-May", risk: 0.55, label: "0.55" },
];

export const mockRiskContribution = [
  { name: "Cognitive", value: 40, color: "#6C3FC5" },
  { name: "Emotional", value: 35, color: "#EF4444" },
  { name: "Metabolic", value: 25, color: "#F59E0B" },
];

export const mockAlerts: AlertNotification[] = [
  {
    id: "alt-1",
    type: "High Risk",
    title: "Elevated Emotional Distress Detected",
    description: "Affect scoring indicates acute withdrawal during morning session.",
    timestamp: "10 mins ago",
    residentName: "Mr. James Perera",
    unread: true,
  },
  {
    id: "alt-2",
    type: "Moderate Risk",
    title: "Cognitive Memory Recall Inconsistency",
    description: "Delayed verbal recall for 3-item delayed retrieval task.",
    timestamp: "2 hours ago",
    residentName: "Mr. James Perera",
    unread: true,
  },
  {
    id: "alt-3",
    type: "Reminder",
    title: "Metabolic Vitals Due for Entry",
    description: "Evening BP and blood glucose logging requested.",
    timestamp: "Yesterday",
    residentName: "Mr. James Perera",
    unread: false,
  },
];

export const mockRecentAssessments: AssessmentRecord[] = [
  {
    id: "asm-1",
    dateTime: "12 May 2025, 10:30 AM",
    cognitiveScore: 0.64,
    emotionalScore: 0.78,
    metabolicScore: 0.56,
    overallRiskScore: 0.66,
    assessedBy: "Seetha N.",
    status: "Completed",
    notes: "Patient cooperative. Speech clarity intact, mild latency in delayed spatial orientation.",
  },
  {
    id: "asm-2",
    dateTime: "02 May 2025, 02:15 PM",
    cognitiveScore: 0.52,
    emotionalScore: 0.61,
    metabolicScore: 0.53,
    overallRiskScore: 0.55,
    assessedBy: "Seetha N.",
    status: "Completed",
    notes: "Baseline monitoring following physical therapy routine.",
  },
  {
    id: "asm-3",
    dateTime: "26 Apr 2025, 09:45 AM",
    cognitiveScore: 0.45,
    emotionalScore: 0.50,
    metabolicScore: 0.46,
    overallRiskScore: 0.47,
    assessedBy: "Kamal P.",
    status: "Completed",
    notes: "Routine quarterly evaluation. Steady posture and verbal engagement.",
  },
];

export const cognitiveQuestionsList: CognitiveQuestion[] = [
  {
    id: 1,
    category: "Orientation",
    questionText: "What is today's date, including the day of the week, month, and year?",
    aiTip: "Listen for complete day, month, date, and year details without prompting.",
    recommendedAnswerGuide: "Full accuracy required for month and year; +/- 1 day permitted.",
  },
  {
    id: 2,
    category: "Orientation",
    questionText: "Can you tell me where we are right now, including the building and the city?",
    aiTip: "Assess awareness of current facility name and municipal jurisdiction.",
    recommendedAnswerGuide: "Identification of elderly care facility and current town.",
  },
  {
    id: 3,
    category: "Memory",
    questionText: "I am going to name three objects: Apple, Table, and Penny. Please repeat them back to me.",
    aiTip: "Patient must immediately register all three words clearly.",
    recommendedAnswerGuide: "Instant registration score 1 point per correct item.",
  },
  {
    id: 4,
    category: "Attention",
    questionText: "Could you spell the word 'WORLD' backwards for me?",
    aiTip: "Expected answer sequence is D - L - R - O - W.",
    recommendedAnswerGuide: "Award 1 point for each correctly sequenced letter.",
  },
  {
    id: 5,
    category: "Recall",
    questionText: "What were the three objects I asked you to remember a few moments ago?",
    aiTip: "Evaluate delayed recall for: Apple, Table, Penny.",
    recommendedAnswerGuide: "No cues permitted for first attempt.",
  },
  {
    id: 6,
    category: "Language",
    questionText: "What do you call this object: a wristwatch? And what is this: a pencil?",
    aiTip: "Verify naming clarity for common everyday objects.",
    recommendedAnswerGuide: "Precise naming without circumlocution.",
  },
  {
    id: 7,
    category: "Language",
    questionText: "Please repeat this exact phrase: 'No ifs, ands, or buts.'",
    aiTip: "Examine articulation and phonemic integrity.",
    recommendedAnswerGuide: "Single repetition strictly required.",
  },
  {
    id: 8,
    category: "Attention",
    questionText: "Count backwards from 100 by subtracting 7 each time, starting with 93.",
    aiTip: "Check up to 5 serial subtractions: 93, 86, 79, 72, 65.",
    recommendedAnswerGuide: "Give 1 point per accurate mathematical step.",
  },
  {
    id: 9,
    category: "Orientation",
    questionText: "What season of the year are we currently in?",
    aiTip: "Observe climate and calendar seasonal recognition.",
    recommendedAnswerGuide: "Permit flexibility during seasonal transition weeks.",
  },
  {
    id: 10,
    category: "Memory",
    questionText: "Can you remember your home address from before moving to our care home?",
    aiTip: "Cross-reference with medical admission record.",
    recommendedAnswerGuide: "Validate street and locality.",
  },
  {
    id: 11,
    category: "Language",
    questionText: "Take this piece of paper in your right hand, fold it in half, and put it on your lap.",
    aiTip: "Three-stage motor command comprehension test.",
    recommendedAnswerGuide: "Score 1 point per executed clause in correct sequence.",
  },
  {
    id: 12,
    category: "Language",
    questionText: "Please read the sentence shown on the screen and close your eyes.",
    aiTip: "Assesses reading comprehension and executive motor response.",
    recommendedAnswerGuide: "Immediate motor closing of eyes upon reading.",
  },
  {
    id: 13,
    category: "Language",
    questionText: "Write a complete sentence about today's weather or your thoughts.",
    aiTip: "Must contain subject, predicate, and form a coherent thought.",
    recommendedAnswerGuide: "Semantic validity irrespective of minor spelling errors.",
  },
  {
    id: 14,
    category: "Attention",
    questionText: "Name as many animals as you can think of in sixty seconds.",
    aiTip: "Standard verbal categorical fluency test (Target: >= 14 animals).",
    recommendedAnswerGuide: "Unique animal count recorded within 1 minute timer.",
  },
  {
    id: 15,
    category: "Recall",
    questionText: "Do you recall who visited you yesterday afternoon?",
    aiTip: "Episodic recent memory query corroborated with nursing log.",
    recommendedAnswerGuide: "Accurate name or familial relationship.",
  },
  {
    id: 16,
    category: "Orientation",
    questionText: "What floor of the residence building are we currently on?",
    aiTip: "Immediate spatial floor and wing awareness.",
    recommendedAnswerGuide: "First floor / Residential Wing A.",
  },
  {
    id: 17,
    category: "Language",
    questionText: "How are an orange and a banana alike? What category do they share?",
    aiTip: "Abstract reasoning and categorization test.",
    recommendedAnswerGuide: "Abstract answer 'Fruit' scores higher than concrete 'You eat them'.",
  },
  {
    id: 18,
    category: "Attention",
    questionText: "Please tap the table each time you hear the letter 'A' as I read a list of letters.",
    aiTip: "Continuous sustained auditory vigilance test.",
    recommendedAnswerGuide: "Record omissions and commission errors.",
  },
  {
    id: 19,
    category: "Memory",
    questionText: "Can you describe what you had for breakfast this morning?",
    aiTip: "Short-term episodic retrieval matching dietary logs.",
    recommendedAnswerGuide: "Consistency with morning dietary tray record.",
  },
  {
    id: 20,
    category: "Orientation",
    questionText: "Do you know who the current President or Prime Minister of the country is?",
    aiTip: "Long-term public knowledge recall.",
    recommendedAnswerGuide: "Correct identification of the head of state.",
  },
];
