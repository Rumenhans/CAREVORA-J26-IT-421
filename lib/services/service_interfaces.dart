import '../models/carevora_models.dart';
import '../models/enums.dart';

abstract class IAuthService {
  Future<UserModel?> login(String email, String password, UserRole role);
  Future<void> logout();
  UserModel? get currentUser;
}

abstract class IResidentService {
  Future<List<ResidentModel>> getResidents();
  Future<ResidentModel?> getResidentById(String id);
}

abstract class IAssessmentService {
  Future<List<AssessmentQuestion>> getQuestions();
  Future<WellnessResultModel> submitAssessment({
    required String residentId,
    required List<int> answers,
    bool includeFacialCheck = false,
    bool includeVoiceCheck = false,
  });
}

abstract class IAlertService {
  Future<List<AlertModel>> getAlerts();
  Future<void> markAsRead(String alertId);
}

/// Abstract AI/ML Contract
/// In the next development phase, this will be connected directly to Python ML / RALPA models via REST API.
abstract class IAiMlService {
  Future<Map<String, dynamic>> predictTrajectory(String residentId);
  Future<List<ContributingFactor>> getExplainableFactors(String residentId);
  Future<List<RecommendationModel>> generateAiRecommendations(String residentId);
}
