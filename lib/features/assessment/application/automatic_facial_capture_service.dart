import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'facial_emotion_ai_service.dart';

/// Camera adapter interface for platform abstraction and unit test mocking.
abstract class FacialCameraAdapter {
  Future<bool> initialize();
  Future<Uint8List?> captureFrame();
  Future<void> dispose();
  bool get isInitialized;
  String? get lastError;
  CameraController? get controller;
}

/// Production implementation using Flutter's official `camera` and `camera_web` plugins.
class DefaultFacialCameraAdapter implements FacialCameraAdapter {
  CameraController? _controller;
  bool _initialized = false;
  String? _error;

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized => _initialized && _controller != null && _controller!.value.isInitialized;

  @override
  String? get lastError => _error;

  @override
  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = 'No camera found on this device.';
        _initialized = false;
        return false;
      }

      // Prefer front-facing camera for elderly face capture
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
      _initialized = true;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Camera initialization failed: $e';
      _initialized = false;
      return false;
    }
  }

  @override
  Future<Uint8List?> captureFrame() async {
    if (!isInitialized) return null;
    try {
      final XFile photo = await _controller!.takePicture();
      return await photo.readAsBytes();
    } catch (e) {
      _error = 'Frame capture error: $e';
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }
}

/// Observable status of the automatic facial capture pipeline.
enum FacialCaptureStatus {
  idle,
  standby,
  consentRequired,
  initializingCamera,
  capturing,
  analyzing,
  noFace,
  modelUnavailable,
  networkError,
  permissionDenied,
  cameraUnavailable,
  error;

  bool get isModelUnavailable => this == FacialCaptureStatus.modelUnavailable;
  bool get isNoFace => this == FacialCaptureStatus.noFace;
}

/// Aggregated facial analysis summary for an active voice-recording session.
class FacialSessionAggregate {
  final int totalCapturesAttempted;
  final int successfulInferences;
  final int noFaceCount;
  final int errorCount;
  final List<FacialEmotionResult> validResults;
  final double averageConfidence;
  final Map<EmotionCategory, int> emotionFrequencies;
  final EmotionCategory? dominantSessionEmotion;

  // Grounded RALPA feature probabilities (0.0 to 1.0)
  final double happyProb;
  final double sadProb;
  final double neutralProb;
  final bool hasSufficientInferences;

  int get validCount => successfulInferences;
  String get dominantEmotion => dominantSessionEmotion?.name.toUpperCase() ?? 'NONE';

  const FacialSessionAggregate({
    required this.totalCapturesAttempted,
    required this.successfulInferences,
    required this.noFaceCount,
    required this.errorCount,
    required this.validResults,
    required this.averageConfidence,
    required this.emotionFrequencies,
    required this.dominantSessionEmotion,
    required this.happyProb,
    required this.sadProb,
    required this.neutralProb,
    required this.hasSufficientInferences,
  });

  factory FacialSessionAggregate.empty() {
    return const FacialSessionAggregate(
      totalCapturesAttempted: 0,
      successfulInferences: 0,
      noFaceCount: 0,
      errorCount: 0,
      validResults: [],
      averageConfidence: 0.0,
      emotionFrequencies: {},
      dominantSessionEmotion: null,
      happyProb: 0.0,
      sadProb: 0.0,
      neutralProb: 0.0,
      hasSufficientInferences: false,
    );
  }

  factory FacialSessionAggregate.fromResults({
    required int totalAttempts,
    required List<FacialEmotionResult> results,
  }) {
    final valid = results.where((r) => r.isSuccess).toList();
    final int noFace = results.where((r) => r.isNoFace).length;
    final int errors = results.where((r) => r.hasError || r.isModelUnavailable).length;

    if (valid.isEmpty) {
      return FacialSessionAggregate(
        totalCapturesAttempted: totalAttempts,
        successfulInferences: 0,
        noFaceCount: noFace,
        errorCount: errors,
        validResults: const [],
        averageConfidence: 0.0,
        emotionFrequencies: const {},
        dominantSessionEmotion: null,
        happyProb: 0.0,
        sadProb: 0.0,
        neutralProb: 0.0,
        hasSufficientInferences: false,
      );
    }

    final double avgConf = valid.map((r) => r.confidence).reduce((a, b) => a + b) / valid.length;

    final Map<EmotionCategory, int> freqs = {};
    for (final r in valid) {
      freqs[r.primaryEmotion] = (freqs[r.primaryEmotion] ?? 0) + 1;
    }

    EmotionCategory? dominant;
    int maxCount = -1;
    freqs.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = cat;
      }
    });

    final int happyCount = (freqs[EmotionCategory.happy] ?? 0);
    final int sadCount = (freqs[EmotionCategory.sadDepressed] ?? 0) +
        (freqs[EmotionCategory.confusedAgitated] ?? 0) +
        (freqs[EmotionCategory.anxious] ?? 0);
    final int neutralCount = (freqs[EmotionCategory.calmNeutral] ?? 0);

    final double happyP = valid.isNotEmpty ? (happyCount / valid.length) : 0.0;
    final double sadP = valid.isNotEmpty ? (sadCount / valid.length) : 0.0;
    final double neutralP = valid.isNotEmpty ? (neutralCount / valid.length) : 0.0;

    return FacialSessionAggregate(
      totalCapturesAttempted: totalAttempts,
      successfulInferences: valid.length,
      noFaceCount: noFace,
      errorCount: errors,
      validResults: valid,
      averageConfidence: avgConf,
      emotionFrequencies: freqs,
      dominantSessionEmotion: dominant,
      happyProb: happyP,
      sadProb: sadP,
      neutralProb: neutralP,
      hasSufficientInferences: valid.length >= 2,
    );
  }
}

/// Cross-platform automatic facial frame capture service.
///
/// Integrates directly with the voice-recording lifecycle.
/// Enforces explicit informed consent, non-blocking single-flight capture,
/// safe periodic intervals, and clean resource release.
class AutomaticFacialCaptureService {
  final FacialCameraAdapter _cameraAdapter;
  final FacialEmotionAiService _aiService;
  final Duration captureInterval;

  bool _hasInformedConsent = false;
  bool _isVoiceRecordingActive = false;
  bool _isDisposed = false;
  bool _isFlightInProgress = false;

  Timer? _periodicTimer;
  FacialCaptureStatus _status = FacialCaptureStatus.idle;

  int _totalCapturesAttempted = 0;
  final List<FacialEmotionResult> _sessionResults = [];
  FacialSessionAggregate _lastAggregate = FacialSessionAggregate.empty();

  // Callbacks for UI sync
  void Function(FacialCaptureStatus status)? onStatusChanged;
  void Function(Uint8List frameBytes)? onFrameCaptured;
  void Function(FacialEmotionResult result)? onFrameAnalyzed;

  AutomaticFacialCaptureService({
    FacialCameraAdapter? cameraAdapter,
    FacialEmotionAiService? aiService,
    this.captureInterval = const Duration(seconds: 1),
  })  : _cameraAdapter = cameraAdapter ?? DefaultFacialCameraAdapter(),
        _aiService = aiService ?? FacialEmotionAiService.instance;

  bool get hasInformedConsent => _hasInformedConsent;
  bool get isVoiceRecordingActive => _isVoiceRecordingActive;
  bool get isDisposed => _isDisposed;
  bool get isFlightInProgress => _isFlightInProgress;
  FacialCaptureStatus get status => _status;
  CameraController? get cameraController => _cameraAdapter.controller;
  bool get isCameraReady => _cameraAdapter.isInitialized;
  List<FacialEmotionResult> get sessionResults => List.unmodifiable(_sessionResults);
  FacialSessionAggregate get lastAggregate => _lastAggregate;
  FacialSessionAggregate get aggregate {
    if (_sessionResults.isNotEmpty) {
      return FacialSessionAggregate.fromResults(
        totalAttempts: _totalCapturesAttempted,
        results: _sessionResults,
      );
    }
    return _lastAggregate;
  }
  bool get isAutoCapturing => _isVoiceRecordingActive && _hasInformedConsent;
  bool get isCameraInitialized => _cameraAdapter.isInitialized;

  /// Updates user / caregiver consent for automatic facial observation.
  void setInformedConsent(bool consent) {
    _hasInformedConsent = consent;
    if (!consent && _isVoiceRecordingActive) {
      stopCapture();
      _setStatus(FacialCaptureStatus.consentRequired);
    }
  }

  /// Alias for setInformedConsent
  void grantConsent(bool consent) => setInformedConsent(consent);

  /// Initializes camera hardware after consent confirmation.
  Future<bool> initializeCamera() async {
    if (_isDisposed) return false;
    if (!_hasInformedConsent) {
      _setStatus(FacialCaptureStatus.consentRequired);
      return false;
    }
    if (_cameraAdapter.isInitialized) return true;

    _setStatus(FacialCaptureStatus.initializingCamera);
    final ok = await _cameraAdapter.initialize();
    if (_isDisposed) return false;

    if (ok) {
      _setStatus(FacialCaptureStatus.idle);
      return true;
    } else {
      final err = (_cameraAdapter.lastError ?? '').toLowerCase();
      debugPrint('[FacialCapture] Camera init returned false. Error: $err');
      if (err.contains('permission') ||
          err.contains('denied') ||
          err.contains('notallowed') ||
          err.contains('not allowed')) {
        _setStatus(FacialCaptureStatus.permissionDenied);
      } else {
        _setStatus(FacialCaptureStatus.cameraUnavailable);
      }
      return false;
    }
  }

  /// Starts the automatic capture loop tied to voice recording.
  /// Strictly requires informed consent.
  Future<void> startCaptureForVoiceRecording() async {
    if (_isDisposed) return;

    if (!_hasInformedConsent) {
      _setStatus(FacialCaptureStatus.consentRequired);
      return;
    }

    _isVoiceRecordingActive = true;
    _totalCapturesAttempted = 0;
    _sessionResults.clear();
    _lastAggregate = FacialSessionAggregate.empty();

    // Ensure camera is ready
    if (!_cameraAdapter.isInitialized) {
      final ready = await initializeCamera();
      if (!ready || !_isVoiceRecordingActive || _isDisposed) {
        return;
      }
    }

    // Trigger initial snapshot immediately (single-flight)
    await _executeSingleFlightCapture();

    // Schedule subsequent captures at configured interval
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(captureInterval, (_) {
      _executeSingleFlightCapture();
    });
  }

  /// Stops capture immediately when voice recording stops or is cancelled.
  FacialSessionAggregate stopCapture() {
    _isVoiceRecordingActive = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isFlightInProgress = false;

    _lastAggregate = FacialSessionAggregate.fromResults(
      totalAttempts: _totalCapturesAttempted,
      results: _sessionResults,
    );

    _setStatus(FacialCaptureStatus.idle);
    return _lastAggregate;
  }

  /// Single-flight capture and inference execution.
  /// Drops new capture triggers if the previous capture/HTTP request is still inflight.
  Future<void> _executeSingleFlightCapture() async {
    if (_isDisposed || !_isVoiceRecordingActive || !_hasInformedConsent) {
      return;
    }

    if (_isFlightInProgress) {
      // Single-flight guard: never overlap camera captures or HTTP analysis
      debugPrint('[FacialCapture] Previous frame still processing. Dropping overlapping capture trigger.');
      return;
    }

    _isFlightInProgress = true;
    _totalCapturesAttempted++;
    _setStatus(FacialCaptureStatus.capturing);

    try {
      final Uint8List? frameBytes = await _cameraAdapter.captureFrame();

      // Guard check after asynchronous camera operation
      if (_isDisposed || !_isVoiceRecordingActive) {
        _isFlightInProgress = false;
        return;
      }

      if (frameBytes == null || frameBytes.isEmpty) {
        _setStatus(FacialCaptureStatus.error);
        _isFlightInProgress = false;
        return;
      }

      onFrameCaptured?.call(frameBytes);
      _setStatus(FacialCaptureStatus.analyzing);

      // Perform real facial affect inference via AI microservice
      final FacialEmotionResult result = await _aiService.analyze(imageBytes: frameBytes);

      // Guard check after asynchronous HTTP inference
      if (_isDisposed || !_isVoiceRecordingActive) {
        _isFlightInProgress = false;
        return;
      }

      _sessionResults.add(result);
      _lastAggregate = FacialSessionAggregate.fromResults(
        totalAttempts: _totalCapturesAttempted,
        results: _sessionResults,
      );
      onFrameAnalyzed?.call(result);
      if (result.isSuccess) {
        _setStatus(FacialCaptureStatus.standby);
      } else if (result.isNoFace) {
        _setStatus(FacialCaptureStatus.noFace);
      } else if (result.isModelUnavailable) {
        _setStatus(FacialCaptureStatus.modelUnavailable);
      } else if (result.hasError) {
        _setStatus(FacialCaptureStatus.networkError);
      } else {
        _setStatus(FacialCaptureStatus.standby);
      }
    } catch (e) {
      debugPrint('[FacialCapture] Capture/Analysis pipeline error: $e');
      _setStatus(FacialCaptureStatus.error);
    } finally {
      _isFlightInProgress = false;
    }
  }

  void _setStatus(FacialCaptureStatus newStatus) {
    if (_isDisposed) return;
    _status = newStatus;
    onStatusChanged?.call(_status);
  }

  /// Disposes camera resources and safely cancels timers.
  Future<void> dispose() async {
    _isDisposed = true;
    _isVoiceRecordingActive = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isFlightInProgress = false;
    await _cameraAdapter.dispose();
  }
}
