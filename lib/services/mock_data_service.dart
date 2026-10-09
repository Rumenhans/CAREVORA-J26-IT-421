import '../models/carevora_models.dart';
import '../models/enums.dart';
import 'service_interfaces.dart';

class MockDataService implements IAuthService, IResidentService, IAssessmentService, IAlertService, IAiMlService {
  UserModel? _currentUser = const UserModel(
    id: 'res_01',
    name: 'Sarah Jenkins',
    email: 'sarah.jenkins@carevora.com',
    role: UserRole.resident,
  );

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel?> login(String email, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (role == UserRole.resident) {
      _currentUser = const UserModel(
        id: 'res_01',
        name: 'Sarah Jenkins',
        email: 'sarah.jenkins@carevora.com',
        role: UserRole.resident,
      );
    } else {
      _currentUser = const UserModel(
        id: 'cg_01',
        name: 'Dr. Eleanor Vance',
        email: 'eleanor.vance@carevora.com',
        role: UserRole.caregiver,
      );
    }
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  static final List<ResidentModel> _mockResidents = [
    ResidentModel(
      id: 'res_01',
      name: 'Sarah Jenkins',
      age: 78,
      roomNumber: 'Suite 204',
      avatarUrl: '',
      currentStatus: WellnessStatus.lookingGood,
      riskLevel: RiskLevel.low,
      trajectory: TrajectoryDirection.improving,
      lastAssessmentDate: DateTime.now().subtract(const Duration(hours: 2)),
      emotionalScore: 88,
      socialScore: 82,
      unreadAlertsCount: 0,
      assessmentHistory: [
        WellnessResultModel(
          id: 'w_01',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          overallScore: 86,
          emotionalScore: 88,
          socialScore: 84,
          status: WellnessStatus.lookingGood,
          riskLevel: RiskLevel.low,
          trajectory: TrajectoryDirection.improving,
          encouragingMessage: "You're feeling uplifted and well connected today!",
          contributingFactors: const [
            ContributingFactor(
              title: 'Morning Garden Walk',
              score: 92,
              description: 'Active outdoor engagement noted early morning',
              category: 'Social',
            ),
            ContributingFactor(
              title: 'Calm Vocal Tone',
              score: 85,
              description: 'Speech rhythm exhibited relaxed cadence',
              category: 'Voice',
            ),
            ContributingFactor(
              title: 'Positive Expression',
              score: 88,
              description: 'Frequent smiles during community greeting',
              category: 'Facial',
            ),
          ],
          recommendations: const [
            RecommendationModel(
              id: 'rec_01',
              title: 'Afternoon Tea Social',
              reason: 'Keep up the warm social connection with fellow residents.',
              priority: 'Low',
              suggestedAction: 'Join community lounge at 3:30 PM',
              iconKey: 'social',
            ),
            RecommendationModel(
              id: 'rec_02',
              title: 'Gentle Stroll in Courtyard',
              reason: 'Mild physical activity continues to brighten your afternoon.',
              priority: 'Low',
              suggestedAction: 'Take a 15-minute garden walk',
              iconKey: 'walk',
            ),
          ],
        ),
      ],
      activeRecommendations: const [
        RecommendationModel(
          id: 'rec_01',
          title: 'Afternoon Tea Social',
          reason: 'Keep up the warm social connection with fellow residents.',
          priority: 'Low',
          suggestedAction: 'Join community lounge at 3:30 PM',
          iconKey: 'social',
        ),
      ],
    ),
    ResidentModel(
      id: 'res_02',
      name: 'Arthur Pendelton',
      age: 82,
      roomNumber: 'Suite 112',
      avatarUrl: '',
      currentStatus: WellnessStatus.needsAttention,
      riskLevel: RiskLevel.moderate,
      trajectory: TrajectoryDirection.increasingRisk,
      lastAssessmentDate: DateTime.now().subtract(const Duration(hours: 5)),
      emotionalScore: 54,
      socialScore: 48,
      unreadAlertsCount: 2,
      assessmentHistory: [
        WellnessResultModel(
          id: 'w_02',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          overallScore: 51,
          emotionalScore: 54,
          socialScore: 48,
          status: WellnessStatus.needsAttention,
          riskLevel: RiskLevel.moderate,
          trajectory: TrajectoryDirection.increasingRisk,
          encouragingMessage: "We're here with you. Let's take it easy and connect.",
          contributingFactors: const [
            ContributingFactor(
              title: 'Reduced Social Interaction',
              score: 42,
              description: 'Fewer interactions observed during communal meals',
              category: 'Social',
            ),
            ContributingFactor(
              title: 'Flat Vocal Pitch Range',
              score: 52,
              description: 'Acoustic cues showed subtle decrease in dynamic modulation',
              category: 'Voice',
            ),
          ],
          recommendations: const [
            RecommendationModel(
              id: 'rec_03',
              title: 'Companion Check-in',
              reason: 'Arthur expressed feeling slightly solitary this morning.',
              priority: 'High',
              suggestedAction: 'Schedule a 10-minute one-on-one caregiver chat',
              iconKey: 'social',
            ),
          ],
        ),
      ],
    ),
    ResidentModel(
      id: 'res_03',
      name: 'Margaret Chen',
      age: 75,
      roomNumber: 'Suite 305',
      avatarUrl: '',
      currentStatus: WellnessStatus.stable,
      riskLevel: RiskLevel.low,
      trajectory: TrajectoryDirection.stable,
      lastAssessmentDate: DateTime.now().subtract(const Duration(hours: 8)),
      emotionalScore: 76,
      socialScore: 78,
      unreadAlertsCount: 0,
    ),
    ResidentModel(
      id: 'res_04',
      name: 'Robert Hastings',
      age: 84,
      roomNumber: 'Suite 108',
      avatarUrl: '',
      currentStatus: WellnessStatus.letCheckIn,
      riskLevel: RiskLevel.high,
      trajectory: TrajectoryDirection.increasingRisk,
      lastAssessmentDate: DateTime.now().subtract(const Duration(hours: 1)),
      emotionalScore: 38,
      socialScore: 35,
      unreadAlertsCount: 3,
    ),
    ResidentModel(
      id: 'res_05',
      name: 'Dorothy Miller',
      age: 80,
      roomNumber: 'Suite 219',
      avatarUrl: '',
      currentStatus: WellnessStatus.lookingGood,
      riskLevel: RiskLevel.low,
      trajectory: TrajectoryDirection.improving,
      lastAssessmentDate: DateTime.now().subtract(const Duration(hours: 12)),
      emotionalScore: 91,
      socialScore: 89,
      unreadAlertsCount: 0,
    ),
  ];

  static final List<AlertModel> _mockAlerts = [
    AlertModel(
      id: 'alt_01',
      residentId: 'res_04',
      residentName: 'Robert Hastings',
      title: 'Sudden Dip in Social Wellness',
      message: 'Robert has missed group activities for 2 consecutive days and expressed mild distress.',
      type: AlertType.wellnessAlert,
      priority: AlertPriority.high,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    AlertModel(
      id: 'alt_02',
      residentId: 'res_02',
      residentName: 'Arthur Pendelton',
      title: 'Risk Trajectory Shift',
      message: 'RALPA trajectory indicators shifted from Stable towards Increasing Risk.',
      type: AlertType.riskAlert,
      priority: AlertPriority.medium,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AlertModel(
      id: 'alt_03',
      residentId: 'res_01',
      residentName: 'Sarah Jenkins',
      title: 'Daily Assessment Completed',
      message: 'Sarah completed her morning emotional wellness questionnaire with positive scores.',
      type: AlertType.assessmentAlert,
      priority: AlertPriority.low,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];

  @override
  Future<List<ResidentModel>> getResidents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockResidents;
  }

  @override
  Future<ResidentModel?> getResidentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockResidents.firstWhere((r) => r.id == id);
    } catch (_) {
      return _mockResidents.first;
    }
  }

  @override
  Future<List<AssessmentQuestion>> getQuestions() async {
    return const [
      AssessmentQuestion(
        id: 'q1',
        question: 'How are you feeling overall today?',
        category: 'emotional',
        options: [
          'Feeling Great & Peaceful',
          'Doing Okay and Calm',
          'A Little Down or Tired',
          'Feeling Quite Sad or Uneasy',
        ],
      ),
      AssessmentQuestion(
        id: 'q2',
        question: 'How connected do you feel with friends and staff today?',
        category: 'social',
        options: [
          'Very Connected & Supported',
          'Comfortably Connected',
          'A Bit Solitary',
          'Feeling Quite Isolated',
        ],
      ),
      AssessmentQuestion(
        id: 'q3',
        question: 'How has your interest in daily activities been recently?',
        category: 'emotional',
        options: [
          'Engaged & Enjoying Activities',
          'Participating Normally',
          'Less Interested Than Usual',
          'Not Feeling Like Participating',
        ],
      ),
      AssessmentQuestion(
        id: 'q4',
        question: 'Have you enjoyed sharing conversations or meals with others?',
        category: 'social',
        options: [
          'Yes, Had Wonderful Chats',
          'Enjoyed Normal Companionship',
          'Kept mostly to myself',
          'Preferred Not to Talk',
        ],
      ),
    ];
  }

  @override
  Future<WellnessResultModel> submitAssessment({
    required String residentId,
    required List<int> answers,
    bool includeFacialCheck = false,
    bool includeVoiceCheck = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Calculate simple friendly score based on responses
    double score = 84.0;
    if (answers.isNotEmpty) {
      double sum = answers.fold(0, (prev, elem) => prev + elem);
      double avgIndex = sum / answers.length;
      score = (100 - (avgIndex * 20)).clamp(40.0, 96.0);
    }

    WellnessStatus status = score >= 75
        ? WellnessStatus.lookingGood
        : (score >= 60 ? WellnessStatus.stable : WellnessStatus.needsAttention);

    RiskLevel risk = score >= 75
        ? RiskLevel.low
        : (score >= 60 ? RiskLevel.moderate : RiskLevel.high);

    return WellnessResultModel(
      id: 'res_sub_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      overallScore: score,
      emotionalScore: (score + 2).clamp(0.0, 100.0),
      socialScore: (score - 2).clamp(0.0, 100.0),
      status: status,
      riskLevel: risk,
      trajectory: TrajectoryDirection.improving,
      encouragingMessage: score >= 75
          ? "You're doing wonderfully today! Your emotional wellness is shining."
          : "Thank you for sharing. We're here to support you at every step.",
      contributingFactors: [
        ContributingFactor(
          title: 'Daily Questionnaire',
          score: score,
          description: 'Reflects your direct answers to emotional and social prompts',
          category: 'Questionnaire',
        ),
        if (includeFacialCheck)
          const ContributingFactor(
            title: 'Facial Affect Check',
            score: 86.0,
            description: 'Gentle facial cues indicate calm resting composure',
            category: 'Facial',
          ),
        if (includeVoiceCheck)
          const ContributingFactor(
            title: 'Acoustic Tone Check',
            score: 82.0,
            description: 'Vocal modulation reflects clear and steady warmth',
            category: 'Voice',
          ),
      ],
      recommendations: const [
        RecommendationModel(
          id: 'rec_new_1',
          title: 'Enjoy a Peaceful Garden Walk',
          reason: 'Fresh air and light walking help sustain your calm mood.',
          priority: 'Low',
          suggestedAction: 'Take a gentle stroll after lunch',
          iconKey: 'walk',
        ),
        RecommendationModel(
          id: 'rec_new_2',
          title: 'Share a Warm Chat',
          reason: 'Staying in touch with familiar faces brings joy.',
          priority: 'Low',
          suggestedAction: 'Call a loved one or sit in the lounge',
          iconKey: 'social',
        ),
      ],
    );
  }

  @override
  Future<List<AlertModel>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _mockAlerts;
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final index = _mockAlerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _mockAlerts[index] = _mockAlerts[index].copyWith(isRead: true);
    }
  }

  @override
  Future<Map<String, dynamic>> predictTrajectory(String residentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'residentId': residentId,
      'trajectory': 'Stable',
      'confidenceScore': 0.89,
      'predictedHorizonDays': 7,
      'forecastTrend': [72, 74, 76, 75, 78, 80, 82],
    };
  }

  @override
  Future<List<ContributingFactor>> getExplainableFactors(String residentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ContributingFactor(
        title: 'Social Group Attendance',
        score: 85,
        description: 'Frequent attendance at community social gatherings',
        category: 'Social',
      ),
      ContributingFactor(
        title: 'Vocal Acoustic Modulation',
        score: 78,
        description: 'Consistent vocal intonation in wellness check-ins',
        category: 'Voice',
      ),
      ContributingFactor(
        title: 'Self-Report Consistency',
        score: 88,
        description: 'Steady positive emotional response entries',
        category: 'Questionnaire',
      ),
    ];
  }

  @override
  Future<List<RecommendationModel>> generateAiRecommendations(String residentId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      RecommendationModel(
        id: 'ai_rec_1',
        title: 'Gentle Music Therapy Session',
        reason: 'Soothing classical selections reinforce positive emotional states.',
        priority: 'Medium',
        suggestedAction: 'Offer 20 minutes of calming music in the afternoon',
        iconKey: 'music',
      ),
    ];
  }
}
