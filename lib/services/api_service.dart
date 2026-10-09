import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/carevora_models.dart';
import '../models/enums.dart';
import 'service_interfaces.dart';

class ApiService implements IAuthService, IResidentService, IAssessmentService, IAlertService, IAiMlService {
  final String baseUrl;
  String? _authToken;
  UserModel? _currentUser;

  ApiService({this.baseUrl = 'http://localhost:8080/api'});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel?> login(String email, String password, UserRole role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        _authToken = data['token'];

        _currentUser = UserModel(
          id: data['id'].toString(),
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: role,
          avatarUrl: data['avatarUrl'] ?? '',
        );
        return _currentUser;
      }
    } catch (_) {
      // Fallback for offline development
    }

    _currentUser = UserModel(
      id: role == UserRole.resident ? 'res_01' : 'cg_01',
      name: role == UserRole.resident ? 'Sarah Jenkins' : 'Dr. Eleanor Vance',
      email: email,
      role: role,
    );
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
  }

  @override
  Future<List<ResidentModel>> getResidents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/residents'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List list = json['data'] ?? [];
        return list.map((item) {
          return ResidentModel(
            id: item['id'].toString(),
            name: item['name'] ?? '',
            age: item['age'] ?? 75,
            roomNumber: item['roomNumber'] ?? '',
            avatarUrl: item['avatarUrl'] ?? '',
            currentStatus: _parseStatus(item['currentStatus']),
            riskLevel: _parseRisk(item['riskLevel']),
            trajectory: _parseTrajectory(item['trajectory']),
            lastAssessmentDate: DateTime.tryParse(item['lastAssessmentDate'] ?? '') ?? DateTime.now(),
            emotionalScore: (item['emotionalScore'] as num?)?.toDouble() ?? 80.0,
            socialScore: (item['socialScore'] as num?)?.toDouble() ?? 75.0,
            unreadAlertsCount: item['unreadAlertsCount'] ?? 0,
          );
        }).toList();
      }
    } catch (_) {}

    return _fallbackResidents();
  }

  @override
  Future<ResidentModel?> getResidentById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/residents/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final item = json['data'];
        return ResidentModel(
          id: item['id'].toString(),
          name: item['name'] ?? '',
          age: item['age'] ?? 75,
          roomNumber: item['roomNumber'] ?? '',
          avatarUrl: item['avatarUrl'] ?? '',
          currentStatus: _parseStatus(item['currentStatus']),
          riskLevel: _parseRisk(item['riskLevel']),
          trajectory: _parseTrajectory(item['trajectory']),
          lastAssessmentDate: DateTime.tryParse(item['lastAssessmentDate'] ?? '') ?? DateTime.now(),
          emotionalScore: (item['emotionalScore'] as num?)?.toDouble() ?? 80.0,
          socialScore: (item['socialScore'] as num?)?.toDouble() ?? 75.0,
        );
      }
    } catch (_) {}

    return _fallbackResidents().first;
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
    try {
      final parsedResidentId = int.tryParse(residentId) ?? 1;
      final response = await http.post(
        Uri.parse('$baseUrl/assessments/submit'),
        headers: _headers,
        body: jsonEncode({
          'residentId': parsedResidentId,
          'answers': answers,
          'includeFacialCheck': includeFacialCheck,
          'includeVoiceCheck': includeVoiceCheck,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final item = json['data'];
        return WellnessResultModel(
          id: item['id'].toString(),
          timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
          overallScore: (item['overallScore'] as num).toDouble(),
          emotionalScore: (item['emotionalScore'] as num).toDouble(),
          socialScore: (item['socialScore'] as num).toDouble(),
          status: _parseStatus(item['status']),
          riskLevel: _parseRisk(item['riskLevel']),
          trajectory: _parseTrajectory(item['trajectory']),
          encouragingMessage: item['encouragingMessage'] ?? '',
          contributingFactors: ((item['contributingFactors'] as List?) ?? []).map((f) => ContributingFactor(
            title: f['title'] ?? '',
            score: (f['score'] as num).toDouble(),
            description: f['description'] ?? '',
            category: f['category'] ?? '',
          )).toList(),
          recommendations: ((item['recommendations'] as List?) ?? []).map((r) => RecommendationModel(
            id: r['id'].toString(),
            title: r['title'] ?? '',
            reason: r['reason'] ?? '',
            priority: r['priority'] ?? 'Low',
            suggestedAction: r['suggestedAction'] ?? '',
            iconKey: r['iconKey'] ?? 'walk',
          )).toList(),
        );
      }
    } catch (_) {}

    // Fallback computation
    double score = 84.0;
    if (answers.isNotEmpty) {
      double sum = answers.fold(0, (prev, elem) => prev + elem);
      score = (100 - ((sum / answers.length) * 20)).clamp(40.0, 96.0);
    }

    return WellnessResultModel(
      id: 'res_sub_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      overallScore: score,
      emotionalScore: (score + 2).clamp(0.0, 100.0),
      socialScore: (score - 2).clamp(0.0, 100.0),
      status: score >= 75 ? WellnessStatus.lookingGood : (score >= 60 ? WellnessStatus.stable : WellnessStatus.needsAttention),
      riskLevel: score >= 75 ? RiskLevel.low : (score >= 60 ? RiskLevel.moderate : RiskLevel.high),
      trajectory: TrajectoryDirection.improving,
      encouragingMessage: "You're doing wonderfully today! Your emotional wellness is shining.",
      contributingFactors: const [
        ContributingFactor(title: 'Daily Questionnaire', score: 85, description: 'Reflects answers to daily check-in', category: 'Questionnaire'),
      ],
      recommendations: const [
        RecommendationModel(id: 'rec_1', title: 'Afternoon Courtyard Walk', reason: 'Fresh air sustains positive mood', priority: 'Low', suggestedAction: 'Enjoy 15 minutes of calm sunlight'),
      ],
    );
  }

  @override
  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List list = json['data'] ?? [];
        return list.map((a) {
          return AlertModel(
            id: a['id'].toString(),
            residentId: a['resident']?['id']?.toString() ?? '1',
            residentName: a['resident']?['user']?['fullName'] ?? 'Resident',
            title: a['title'] ?? '',
            message: a['message'] ?? '',
            type: AlertType.wellnessAlert,
            priority: a['priority'] == 'HIGH' ? AlertPriority.high : (a['priority'] == 'MEDIUM' ? AlertPriority.medium : AlertPriority.low),
            timestamp: DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now(),
            isRead: a['isRead'] ?? false,
          );
        }).toList();
      }
    } catch (_) {}

    return [
      AlertModel(
        id: 'alt_01',
        residentId: 'res_04',
        residentName: 'Robert Hastings',
        title: 'Sudden Dip in Social Wellness',
        message: 'Robert has missed group activities for 2 consecutive days.',
        type: AlertType.wellnessAlert,
        priority: AlertPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  @override
  Future<void> markAsRead(String alertId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/alerts/$alertId/read'),
        headers: _headers,
      );
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> predictTrajectory(String residentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/trajectory/$residentId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      }
    } catch (_) {}

    return {
      'residentId': residentId,
      'trajectory': 'Stable',
      'confidenceScore': 0.89,
    };
  }

  @override
  Future<List<ContributingFactor>> getExplainableFactors(String residentId) async {
    return const [
      ContributingFactor(title: 'Social Group Attendance', score: 85, description: 'Frequent attendance noted', category: 'Social'),
      ContributingFactor(title: 'Vocal Acoustic Modulation', score: 78, description: 'Consistent intonation detected', category: 'Voice'),
      ContributingFactor(title: 'Self-Report Consistency', score: 88, description: 'Positive emotional response entries', category: 'Questionnaire'),
    ];
  }

  @override
  Future<List<RecommendationModel>> generateAiRecommendations(String residentId) async {
    return const [
      RecommendationModel(id: 'rec_ai_1', title: 'Gentle Music Therapy Session', reason: 'Soothing classical selections reinforce positive emotional states', priority: 'Medium', suggestedAction: 'Offer 20 minutes in the afternoon', iconKey: 'music'),
    ];
  }

  WellnessStatus _parseStatus(dynamic val) {
    if (val == 'LOOKING_GOOD' || val == 'lookingGood') return WellnessStatus.lookingGood;
    if (val == 'STABLE' || val == 'stable') return WellnessStatus.stable;
    if (val == 'CHECK_IN_NEEDED' || val == 'letCheckIn') return WellnessStatus.letCheckIn;
    return WellnessStatus.needsAttention;
  }

  RiskLevel _parseRisk(dynamic val) {
    if (val == 'LOW' || val == 'low') return RiskLevel.low;
    if (val == 'HIGH' || val == 'high') return RiskLevel.high;
    return RiskLevel.moderate;
  }

  TrajectoryDirection _parseTrajectory(dynamic val) {
    if (val == 'IMPROVING' || val == 'improving') return TrajectoryDirection.improving;
    if (val == 'INCREASING_RISK' || val == 'increasingRisk') return TrajectoryDirection.increasingRisk;
    return TrajectoryDirection.stable;
  }

  List<ResidentModel> _fallbackResidents() {
    return [
      ResidentModel(
        id: '1',
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
      ),
      ResidentModel(
        id: '2',
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
      ),
    ];
  }
}
