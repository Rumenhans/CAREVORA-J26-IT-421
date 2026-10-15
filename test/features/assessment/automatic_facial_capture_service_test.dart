import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:carevora/features/assessment/application/automatic_facial_capture_service.dart';
import 'package:carevora/features/assessment/application/facial_emotion_ai_service.dart';

/// Mock Camera Adapter for deterministic unit testing
class MockTestCameraAdapter implements FacialCameraAdapter {
  bool initialized = false;
  bool shouldFailInit = false;
  String? failInitReason;
  Uint8List? nextFrameBytes;
  int captureCallCount = 0;
  bool disposed = false;
  Duration captureDelay = Duration.zero;

  @override
  bool get isInitialized => initialized;

  @override
  String? get lastError => failInitReason;

  @override
  Future<bool> initialize() async {
    if (shouldFailInit) {
      initialized = false;
      return false;
    }
    initialized = true;
    return true;
  }

  @override
  Future<Uint8List?> captureFrame() async {
    captureCallCount++;
    if (captureDelay > Duration.zero) {
      await Future.delayed(captureDelay);
    }
    return nextFrameBytes;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    initialized = false;
  }
}

void main() {
  group('AutomaticFacialCaptureService - Lifecycle & Consent Guards', () {
    test('Does not capture if consent is not granted', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        captureInterval: const Duration(milliseconds: 100),
      );

      expect(service.hasInformedConsent, isFalse);
      expect(service.status, FacialCaptureStatus.idle);

      // Attempt start without consent
      await service.startCaptureForVoiceRecording();

      expect(service.status, FacialCaptureStatus.consentRequired);
      expect(camera.captureCallCount, 0);
      expect(service.isVoiceRecordingActive, isFalse);

      await service.dispose();
    });

    test('Starts capture only when consent is granted and recording starts', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'model_available': true,
            'analysis': {
              'status': 'success',
              'dominant_emotion': 'happy',
              'confidence': 0.88,
              'emotion_breakdown_percent': {'happy': 88.0, 'neutral': 12.0},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = FacialEmotionAiService(
        client: mockClient,
        baseUrl: 'http://test-ai',
      );

      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: aiService,
        captureInterval: const Duration(milliseconds: 100),
      );

      service.grantConsent(true);
      expect(service.hasInformedConsent, isTrue);

      await service.startCaptureForVoiceRecording();

      expect(service.isVoiceRecordingActive, isTrue);
      expect(camera.captureCallCount, 1);
      expect(camera.isInitialized, isTrue);

      service.stopCapture();
      expect(service.isVoiceRecordingActive, isFalse);

      await service.dispose();
    });

    test('Revoking consent immediately stops capture and resets status', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);
      final fastAiService = FacialEmotionAiService(
        client: MockClient((_) async => http.Response('{"status": "no_face"}', 200)),
        baseUrl: 'http://test-ai',
      );
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: fastAiService,
        captureInterval: const Duration(milliseconds: 100),
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();
      expect(service.isVoiceRecordingActive, isTrue);

      // Revoke consent
      service.grantConsent(false);
      expect(service.hasInformedConsent, isFalse);
      expect(service.isVoiceRecordingActive, isFalse);
      expect(service.status, FacialCaptureStatus.consentRequired);

      await service.dispose();
    });

    test('Handles camera permission denial safely without crashing', () async {
      final camera = MockTestCameraAdapter()
        ..shouldFailInit = true
        ..failInitReason = 'Camera permission denied by user';

      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        captureInterval: const Duration(milliseconds: 100),
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      expect(service.status, FacialCaptureStatus.permissionDenied);
      expect(camera.captureCallCount, 0);

      await service.dispose();
    });

    test('Handles camera hardware unavailable safely', () async {
      final camera = MockTestCameraAdapter()
        ..shouldFailInit = true
        ..failInitReason = 'No camera found on this device';

      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        captureInterval: const Duration(milliseconds: 100),
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      expect(service.status, FacialCaptureStatus.cameraUnavailable);
      expect(camera.captureCallCount, 0);

      await service.dispose();
    });
  });

  group('AutomaticFacialCaptureService - Single-Flight & Concurrency Protection', () {
    test('Prevents overlapping captures when previous frame is still inflight', () async {
      final camera = MockTestCameraAdapter()
        ..nextFrameBytes = Uint8List.fromList([1, 2, 3])
        ..captureDelay = const Duration(milliseconds: 50);

      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 60));
        return http.Response(
          jsonEncode({
            'success': true,
            'model_available': true,
            'analysis': {
              'status': 'success',
              'dominant_emotion': 'happy',
              'confidence': 0.85,
              'emotion_breakdown_percent': {'happy': 85.0},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = FacialEmotionAiService(
        client: mockClient,
        baseUrl: 'http://test-ai',
      );

      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: aiService,
        // Short timer interval that will fire while frame 1 is still processing
        captureInterval: const Duration(milliseconds: 20),
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      // Wait 120ms: timer triggers multiple times, but flight is in progress
      await Future.delayed(const Duration(milliseconds: 120));

      final aggregate = service.stopCapture();
      // Should have processed 1 frame cleanly without overlap
      expect(aggregate.totalCapturesAttempted, greaterThanOrEqualTo(1));
      expect(aggregate.successfulInferences, 1);

      await service.dispose();
    });

    test('Disposed service releases resources and ignores late frame responses', () async {
      final camera = MockTestCameraAdapter()
        ..nextFrameBytes = Uint8List.fromList([1, 2, 3])
        ..captureDelay = const Duration(milliseconds: 40);

      final fastAiService = FacialEmotionAiService(
        client: MockClient((_) async => http.Response('{"status": "no_face"}', 200)),
        baseUrl: 'http://test-ai',
      );
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: fastAiService,
        captureInterval: const Duration(milliseconds: 20),
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      await service.dispose();

      expect(service.isDisposed, isTrue);
      expect(camera.disposed, isTrue);
      expect(service.isVoiceRecordingActive, isFalse);
    });
  });

  group('AutomaticFacialCaptureService - Real Inference & Error Parsing', () {
    test('Detects no_face status and does not fabricate emotions or scores', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'status': 'no_face',
            'model_available': true,
            'analysis': {
              'status': 'no_face',
              'error': 'No face detected in photo.',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = FacialEmotionAiService(client: mockClient, baseUrl: 'http://test-ai');
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: aiService,
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      expect(service.status, FacialCaptureStatus.noFace);
      final agg = service.stopCapture();

      expect(agg.successfulInferences, 0);
      expect(agg.noFaceCount, 1);
      expect(agg.averageConfidence, 0.0);
      expect(agg.hasSufficientInferences, isFalse);

      await service.dispose();
    });

    test('Detects retired or unavailable model and marks modelUnavailable without mock score', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'model_available': false,
            'analysis': {
              'status': 'model_unavailable',
              'error': 'FER model weights not loaded.',
            },
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = FacialEmotionAiService(client: mockClient, baseUrl: 'http://test-ai');
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: aiService,
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      final agg = service.stopCapture();

      expect(agg.successfulInferences, 0);
      expect(agg.errorCount, 1);
      expect(agg.dominantSessionEmotion, isNull);

      await service.dispose();
    });

    test('Detects HTTP network error and does not produce fabricated inference', () async {
      final camera = MockTestCameraAdapter()..nextFrameBytes = Uint8List.fromList([1, 2, 3]);

      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused to AI microservice');
      });

      final aiService = FacialEmotionAiService(client: mockClient, baseUrl: 'http://test-ai');
      final service = AutomaticFacialCaptureService(
        cameraAdapter: camera,
        aiService: aiService,
      );

      service.grantConsent(true);
      await service.startCaptureForVoiceRecording();

      final agg = service.stopCapture();

      expect(agg.successfulInferences, 0);
      expect(agg.errorCount, 1);
      expect(agg.averageConfidence, 0.0);

      await service.dispose();
    });

    test('Calculates grounded session aggregate across multiple successful frames', () {
      final results = [
        FacialEmotionResult(
          status: FacialInferenceStatus.success,
          primaryEmotion: EmotionCategory.happy,
          confidence: 0.90,
          valenceScore: 0.90,
          arousalScore: 0.50,
          emotionProbabilities: const {EmotionCategory.happy: 0.90},
          clinicalObservation: 'Happy face',
          facialActionUnits: const ['AU6', 'AU12'],
          analyzedAt: DateTime.now(),
        ),
        FacialEmotionResult(
          status: FacialInferenceStatus.success,
          primaryEmotion: EmotionCategory.happy,
          confidence: 0.80,
          valenceScore: 0.80,
          arousalScore: 0.50,
          emotionProbabilities: const {EmotionCategory.happy: 0.80},
          clinicalObservation: 'Happy face',
          facialActionUnits: const ['AU6', 'AU12'],
          analyzedAt: DateTime.now(),
        ),
        FacialEmotionResult.noFace(message: 'No face in frame 3'),
      ];

      final agg = FacialSessionAggregate.fromResults(
        totalAttempts: 3,
        results: results,
      );

      expect(agg.totalCapturesAttempted, 3);
      expect(agg.successfulInferences, 2);
      expect(agg.noFaceCount, 1);
      expect(agg.errorCount, 0);
      expect(agg.averageConfidence, closeTo(0.85, 0.001));
      expect(agg.dominantSessionEmotion, EmotionCategory.happy);
      expect(agg.happyProb, 1.0);
      expect(agg.sadProb, 0.0);
      expect(agg.hasSufficientInferences, isTrue);
    });
  });
}
