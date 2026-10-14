import 'dart:convert';

import 'package:http/http.dart' as http;

class CognitiveResidentProfile {
  final int id;
  final String name;
  final int? age;
  final int? educationYears;
  final String roomNumber;
  final String? gender;
  final String? currentStatus;
  final String? riskLevel;

  const CognitiveResidentProfile({
    required this.id,
    required this.name,
    this.age,
    this.educationYears,
    required this.roomNumber,
    this.gender,
    this.currentStatus,
    this.riskLevel,
  });

  factory CognitiveResidentProfile.fromJson(Map<String, dynamic> json) {
    return CognitiveResidentProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Resident',
      age: (json['age'] as num?)?.toInt(),
      educationYears: (json['educationYears'] as num?)?.toInt(),
      roomNumber: json['roomNumber'] as String? ?? 'Room 101',
      gender: json['gender'] as String?,
      currentStatus: json['currentStatus'] as String?,
      riskLevel: json['riskLevel'] as String?,
    );
  }
}

class CognitiveSubmissionPayload {
  final int residentId;
  final double memory;
  final double attention;
  final double orientation;
  final double recall;
  final double reasoning;
  final int? age;
  final int? educationYears;
  final Map<String, double>? accuracies;
  final Map<String, double>? responseTimes;

  const CognitiveSubmissionPayload({
    required this.residentId,
    required this.memory,
    required this.attention,
    required this.orientation,
    required this.recall,
    required this.reasoning,
    this.age,
    this.educationYears,
    this.accuracies,
    this.responseTimes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'residentId': residentId,
      'memory': memory,
      'attention': attention,
      'orientation': orientation,
      'recall': recall,
      'reasoning': reasoning,
    };
    if (age != null) map['age'] = age;
    if (educationYears != null) map['educationYears'] = educationYears;
    if (accuracies != null && accuracies!.isNotEmpty) {
      map['accuracies'] = accuracies;
    }
    if (responseTimes != null && responseTimes!.isNotEmpty) {
      map['responseTimes'] = responseTimes;
    }
    return map;
  }
}

class CognitiveSubmissionResult {
  final int id;
  final int residentId;
  final String residentName;
  final double memory;
  final double attention;
  final double orientation;
  final double recall;
  final double reasoning;
  final double acrfScore;
  final String? mlPrediction;
  final bool? alertTriggered;
  final bool mlAvailable;
  final String mlModelType;
  final String mlStatusMessage;
  final Map<String, double>? probabilities;
  final String? disclaimer;
  final String? methodology;
  final String? clinicalDisclaimer;
  final String? assessedBy;
  final String? createdAt;

  const CognitiveSubmissionResult({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.memory,
    required this.attention,
    required this.orientation,
    required this.recall,
    required this.reasoning,
    required this.acrfScore,
    this.mlPrediction,
    this.alertTriggered,
    required this.mlAvailable,
    required this.mlModelType,
    required this.mlStatusMessage,
    this.probabilities,
    this.disclaimer,
    this.methodology,
    this.clinicalDisclaimer,
    this.assessedBy,
    this.createdAt,
  });

  factory CognitiveSubmissionResult.fromJson(Map<String, dynamic> json) {
    final mlEval = json['mlModelEvaluation'] as Map<String, dynamic>?;
    final bool isAvailable = mlEval != null && (mlEval['available'] == true);

    Map<String, double>? probs;
    if (mlEval != null && mlEval['probabilities'] is Map) {
      final rawProbs = mlEval['probabilities'] as Map<String, dynamic>;
      probs = rawProbs.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    String? prediction = json['mlPrediction'] as String?;
    if (prediction == null && isAvailable) {
      prediction = mlEval['prediction']?.toString();
    }

    bool? alert = json['alertTriggered'] as bool?;
    if (alert == null && mlEval != null) {
      alert = mlEval['alertTriggered'] as bool?;
    }

    final String modelType = (mlEval != null && mlEval['modelType'] != null)
        ? mlEval['modelType'].toString()
        : 'RandomForestClassifier';

    final String statusMsg = (mlEval != null && mlEval['statusMessage'] != null)
        ? mlEval['statusMessage'].toString()
        : (isAvailable ? 'Prediction available' : 'ML inference unavailable');

    final String disclaimerText =
        (mlEval != null && mlEval['disclaimer'] != null)
        ? mlEval['disclaimer'].toString()
        : 'This model was experimentally trained on synthetic data for research and demonstration purposes only. It is not clinically validated.';

    return CognitiveSubmissionResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      residentId: (json['residentId'] as num?)?.toInt() ?? 0,
      residentName: json['residentName'] as String? ?? 'Resident',
      memory: (json['memory'] as num?)?.toDouble() ?? 0.0,
      attention: (json['attention'] as num?)?.toDouble() ?? 0.0,
      orientation: (json['orientation'] as num?)?.toDouble() ?? 0.0,
      recall: (json['recall'] as num?)?.toDouble() ?? 0.0,
      reasoning: (json['reasoning'] as num?)?.toDouble() ?? 0.0,
      acrfScore: (json['acrfScore'] as num?)?.toDouble() ?? 0.0,
      mlPrediction: prediction,
      alertTriggered: alert,
      mlAvailable: isAvailable,
      mlModelType: modelType,
      mlStatusMessage: statusMsg,
      probabilities: probs,
      disclaimer: disclaimerText,
      methodology: json['methodology'] as String? ?? 'ACRF Fixed Base Weights',
      clinicalDisclaimer: json['clinicalDisclaimer'] as String? ?? 'The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.',
      assessedBy: json['assessedBy'] as String? ?? 'Care Specialist',
      createdAt: json['createdAt'] as String?,
    );
  }
}

class CognitiveApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const CognitiveApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

class CognitiveAssessmentService {
  static const String baseUrl = 'http://localhost:8081';

  /// Fetches residents accessible to the authenticated caregiver/doctor.
  static Future<List<CognitiveResidentProfile>> fetchResidents({
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/residents');
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List?;
        if (list != null) {
          return list
              .map(
                (e) => CognitiveResidentProfile.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches a specific resident profile.
  static Future<CognitiveResidentProfile?> fetchResident({
    required int residentId,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/residents/$residentId');
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data != null) {
          return CognitiveResidentProfile.fromJson(data);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submits the cognitive assessment to POST /api/cognitive/assessments/submit.
  static Future<CognitiveSubmissionResult> submitAssessment({
    required CognitiveSubmissionPayload payload,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/cognitive/assessments/submit');
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final bodyJson = jsonEncode(payload.toJson());

    final res = await http
        .post(uri, headers: headers, body: bodyJson)
        .timeout(const Duration(seconds: 8));

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {}

    if (res.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'] as Map<String, dynamic>;
      return CognitiveSubmissionResult.fromJson(data);
    }

    final String message =
        decoded?['message'] as String? ??
        (res.statusCode == 401
            ? 'Authentication required. Please log in to submit assessments.'
            : res.statusCode == 403
            ? 'Authorization error: You do not have permission to assess this resident.'
            : 'Failed to submit cognitive assessment (HTTP ${res.statusCode})');

    final String? errorCode = decoded?['errorCode'] as String?;

    throw CognitiveApiException(
      message,
      statusCode: res.statusCode,
      errorCode: errorCode,
    );
  }
}
