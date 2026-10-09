import 'enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'avatarUrl': avatarUrl,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        avatarUrl: json['avatarUrl'] as String? ?? '',
      );
}

class ContributingFactor {
  final String title;
  final double score; // 0.0 - 100.0 or impact weight
  final String description;
  final String category; // Facial, Voice, Social, Questionnaire

  const ContributingFactor({
    required this.title,
    required this.score,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'score': score,
        'description': description,
        'category': category,
      };

  factory ContributingFactor.fromJson(Map<String, dynamic> json) =>
      ContributingFactor(
        title: json['title'] as String,
        score: (json['score'] as num).toDouble(),
        description: json['description'] as String,
        category: json['category'] as String,
      );
}

class RecommendationModel {
  final String id;
  final String title;
  final String reason;
  final String priority; // High, Medium, Low
  final String suggestedAction;
  final String iconKey; // e.g., 'walk', 'social', 'music', 'group'

  const RecommendationModel({
    required this.id,
    required this.title,
    required this.reason,
    required this.priority,
    required this.suggestedAction,
    this.iconKey = 'walk',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reason': reason,
        'priority': priority,
        'suggestedAction': suggestedAction,
        'iconKey': iconKey,
      };

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      RecommendationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        reason: json['reason'] as String,
        priority: json['priority'] as String,
        suggestedAction: json['suggestedAction'] as String,
        iconKey: json['iconKey'] as String? ?? 'walk',
      );
}

class WellnessResultModel {
  final String id;
  final DateTime timestamp;
  final double overallScore; // 0 - 100
  final double emotionalScore;
  final double socialScore;
  final WellnessStatus status;
  final RiskLevel riskLevel;
  final TrajectoryDirection trajectory;
  final String encouragingMessage;
  final List<ContributingFactor> contributingFactors;
  final List<RecommendationModel> recommendations;

  const WellnessResultModel({
    required this.id,
    required this.timestamp,
    required this.overallScore,
    required this.emotionalScore,
    required this.socialScore,
    required this.status,
    required this.riskLevel,
    required this.trajectory,
    required this.encouragingMessage,
    this.contributingFactors = const [],
    this.recommendations = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'overallScore': overallScore,
        'emotionalScore': emotionalScore,
        'socialScore': socialScore,
        'status': status.name,
        'riskLevel': riskLevel.name,
        'trajectory': trajectory.name,
        'encouragingMessage': encouragingMessage,
        'contributingFactors':
            contributingFactors.map((e) => e.toJson()).toList(),
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
      };
}

class ResidentModel {
  final String id;
  final String name;
  final int age;
  final String roomNumber;
  final String avatarUrl;
  final WellnessStatus currentStatus;
  final RiskLevel riskLevel;
  final TrajectoryDirection trajectory;
  final DateTime lastAssessmentDate;
  final double emotionalScore;
  final double socialScore;
  final int unreadAlertsCount;
  final List<WellnessResultModel> assessmentHistory;
  final List<RecommendationModel> activeRecommendations;

  const ResidentModel({
    required this.id,
    required this.name,
    required this.age,
    required this.roomNumber,
    required this.avatarUrl,
    required this.currentStatus,
    required this.riskLevel,
    required this.trajectory,
    required this.lastAssessmentDate,
    required this.emotionalScore,
    required this.socialScore,
    this.unreadAlertsCount = 0,
    this.assessmentHistory = const [],
    this.activeRecommendations = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'roomNumber': roomNumber,
        'avatarUrl': avatarUrl,
        'currentStatus': currentStatus.name,
        'riskLevel': riskLevel.name,
        'trajectory': trajectory.name,
        'lastAssessmentDate': lastAssessmentDate.toIso8601String(),
        'emotionalScore': emotionalScore,
        'socialScore': socialScore,
        'unreadAlertsCount': unreadAlertsCount,
      };
}

class AlertModel {
  final String id;
  final String residentId;
  final String residentName;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final DateTime timestamp;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'residentId': residentId,
        'residentName': residentName,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  AlertModel copyWith({bool? isRead}) {
    return AlertModel(
      id: id,
      residentId: residentId,
      residentName: residentName,
      title: title,
      message: message,
      type: type,
      priority: priority,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AssessmentQuestion {
  final String id;
  final String question;
  final String category; // 'emotional', 'social'
  final List<String> options;
  final int selectedIndex;

  const AssessmentQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.options,
    this.selectedIndex = -1,
  });
}
