import 'package:flutter/foundation.dart';

class AppConfig {
  /// Base URL for the Spring Boot backend service (port 8081)
  static String get backendBaseUrl {
    const fromEnv = String.fromEnvironment('BACKEND_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8081';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  /// Base URL for the FastAPI AI / ML Microservice (port 8000)
  static String get aiServiceBaseUrl {
    const fromEnv = String.fromEnvironment('AI_SERVICE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
