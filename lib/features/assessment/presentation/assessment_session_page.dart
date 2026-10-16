import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/responsive/responsive_builder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/application/auth_controller.dart';
import '../application/cognitive_assessment_service.dart';
import '../domain/cognitive_scoring.dart';

class AssessmentSessionPage extends ConsumerStatefulWidget {
  const AssessmentSessionPage({super.key});

  @override
  ConsumerState<AssessmentSessionPage> createState() =>
      _AssessmentSessionPageState();
}

class _AssessmentSessionPageState extends ConsumerState<AssessmentSessionPage>
    with SingleTickerProviderStateMixin {
  // Navigation & session index (10 questions battery)
  int _currentIndex = 0;
  final List<CognitiveQuestionItem> _questions = CognitiveScoring.questions;

  // Single Source of Truth: Question grades (id -> 1.0, 0.5, 0.0, or null if ungraded)
  final Map<int, double?> _grades = {};

  // Single Source of Truth: Per-question response text (manual keyboard or voice transcribed)
  final Map<int, String> _responses = {};
  late TextEditingController _responseController;

  // Timing: active question viewing duration
  final Map<int, double> _questionTimes = {};
  late DateTime _questionStartTime;
  int _sessionElapsedSeconds = 0;
  Timer? _sessionTimer;

  // Speech & TTS
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _speechAvailable = false;
  String? _speechStatusMessage;
  int _activeListeningSessionId = 0;

  // Resident Context
  CognitiveResidentProfile? _resident;
  List<CognitiveResidentProfile> _availableResidents = [];
  bool _isLoadingResidents = false;
  String? _residentLoadError;

  // Demographic inputs if missing in resident profile
  int? _customEducationYears;
  int? _customAge;

  // Submission state
  bool _isSubmitting = false;
  String? _submitError;

  // Session lifecycle & persistence
  String? _sessionId;
  String _sessionStatus = 'IN_PROGRESS'; // 'IN_PROGRESS', 'PENDING_CAREGIVER_REVIEW', 'COMPLETED'

  // Animated waveform controller
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
    _responseController = TextEditingController();
    _initTts();
    _initSpeech();
    _initWaveformAnimation();
    _startSessionTimer();
    _loadResidentContext();
  }

  @override
  void dispose() {
    _activeListeningSessionId++;
    _sessionTimer?.cancel();
    _waveformController.dispose();
    _flutterTts.stop();
    _speech.statusListener = null;
    _speech.errorListener = null;
    _speech.cancel();
    _responseController.dispose();
    super.dispose();
  }

  void _initWaveformAnimation() {
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();

    void statusHandler(String status) {
      debugPrint(
        '[CARE-STT] [5. Status Change] [6. Stop/Cancel Reason] status="$status", '
        'speechListening=${_speech.isListening}, isListeningState=$_isListening, '
        'buffer="${_responseController.text}"',
      );
      if (mounted) {
        setState(() {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            final text = _responseController.text.trim();
            debugPrint(
              '[CARE-STT] [7. Final Save Tracking] End status "$status". '
              'Buffer to save: "$text", targetQ=${_currentIndex < _questions.length ? _questions[_currentIndex].id : -1}',
            );
            if (_currentIndex < _questions.length) {
              final qId = _questions[_currentIndex].id;
              if (text.isNotEmpty) {
                _responses[qId] = text;
                _grades[qId] = CognitiveScoring.scoreQuestion(qId, text);
                _speechStatusMessage = 'Voice response captured.';
                _persistResponses();
              } else {
                if (_speechStatusMessage == 'Listening... Speak now.') {
                  _speechStatusMessage =
                      'Speech not recognized. Please tap the microphone to retry or type your answer.';
                }
              }
            }
          }
        });
      }
    }

    void errorHandler(dynamic val) {
      String errorMsg = 'Unknown error';
      bool permanent = false;
      try {
        errorMsg = val?.errorMsg?.toString() ?? val?.toString() ?? 'Unknown error';
        permanent = val?.permanent == true;
      } catch (_) {
        errorMsg = val.toString();
      }
      debugPrint(
        '[CARE-STT] [5. Recognition Error] [6. Stop/Cancel Reason] '
        'errorMsg="$errorMsg", permanent=$permanent',
      );
      if (mounted) {
        setState(() {
          _isListening = false;
          final existing = _responseController.text.trim();
          if (existing.isNotEmpty && _currentIndex < _questions.length) {
            final qId = _questions[_currentIndex].id;
            _responses[qId] = existing;
            if (_grades[qId] == null) {
              _grades[qId] = CognitiveScoring.scoreQuestion(qId, existing);
            }
            _speechStatusMessage = 'Voice response captured.';
            _persistResponses();
          } else {
            if (errorMsg.contains('no-speech') || errorMsg.contains('error_no_match')) {
              _speechStatusMessage =
                  'Speech not recognized. Please tap the microphone to retry or type your answer.';
            } else if (errorMsg.contains('not-allowed') || errorMsg.contains('permission')) {
              _speechStatusMessage =
                  'Microphone permission denied. Please allow microphone access in Chrome or type your answer.';
            } else if (errorMsg.contains('network')) {
              _speechStatusMessage =
                  'Speech service network issue. Please check connection or type your answer.';
            } else {
              _speechStatusMessage =
                  'Audio note: $errorMsg. Please retry or type your answer.';
            }
          }
        });
      }
    }

    _speech.statusListener = statusHandler;
    _speech.errorListener = errorHandler;

    try {
      debugPrint('[CARE-STT] [2. Init] Initializing SpeechToText engine...');
      final available = await _speech.initialize(
        onStatus: statusHandler,
        onError: errorHandler,
      );
      bool hasPerm = false;
      try {
        hasPerm = await _speech.hasPermission;
      } catch (_) {}
      debugPrint(
        '[CARE-STT] [2. Init Status] available=$available, hasPermission=$hasPerm, '
        'isAvailable=${_speech.isAvailable}, hasError=${_speech.hasError}',
      );
      if (mounted) {
        setState(() {
          _speechInitialized = true;
          _speechAvailable = available;
          if (!available) {
            _speechStatusMessage =
                'Microphone/speech recognition unavailable. Please use manual entry or scoring.';
          }
        });
      }
    } catch (e) {
      debugPrint('[CARE-STT] [2. Init Status] Exception during initialize: $e');
      if (mounted) {
        setState(() {
          _speechInitialized = true;
          _speechAvailable = false;
          _speechStatusMessage =
              'Audio capture unavailable. Manual entry is supported.';
        });
      }
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _sessionElapsedSeconds++);
      }
    });
  }

  Future<void> _loadResidentContext() async {
    final authState = ref.read(authProvider).state;
    final token = authState.token;

    // 1. ELDER Role: The elder user is strictly taking the assessment for themselves
    if (authState.isElder) {
      CognitiveResidentProfile profile;
      try {
        final residentId = authState.residentId ?? 1;
        final fetched = await CognitiveAssessmentService.fetchResident(
          residentId: residentId,
          token: token,
        );
        profile = fetched ??
            CognitiveResidentProfile(
              id: residentId,
              name: authState.userName ?? 'Sarah Jenkins',
              roomNumber: 'Room 204',
            );
      } catch (_) {
        profile = CognitiveResidentProfile(
          id: authState.residentId ?? 1,
          name: authState.userName ?? 'Sarah Jenkins',
          roomNumber: 'Room 204',
        );
      }
      if (mounted) {
        setState(() {
          _isLoadingResidents = false;
          _residentLoadError = null;
          _resident = profile;
          _availableResidents = [profile];
        });
        await _loadSavedResidentResponses(profile.id);
      }
      return;
    }

    // 2. CAREGIVER / DOCTOR Role: Load residents from assigned elder home
    if (mounted) {
      setState(() {
        _isLoadingResidents = true;
        _residentLoadError = null;
      });
    }

    try {
      final list = await CognitiveAssessmentService.fetchResidents(
        token: token,
      );
      if (mounted) {
        setState(() {
          _isLoadingResidents = false;
          _availableResidents = list;
          if (list.isNotEmpty) {
            // Keep selected resident if still in the list, else select first item safely
            final currentId = _resident?.id;
            if (currentId != null && list.any((r) => r.id == currentId)) {
              _resident = list.firstWhere((r) => r.id == currentId);
            } else {
              _resident = list.first;
            }
          } else {
            _resident = null;
          }
        });
        if (_resident != null) {
          await _loadSavedResidentResponses(_resident!.id);
        }
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isLoadingResidents = false;
          _residentLoadError = 'Unable to connect to resident directory: $err';
          _availableResidents = [];
          _resident = null;
        });
      }
    }
  }

  void _selectResident(int residentId) {
    if (_resident?.id == residentId) return;
    _saveCurrentQuestionState();
    final found = _availableResidents.firstWhere(
      (r) => r.id == residentId,
      orElse: () => _availableResidents.first,
    );
    setState(() {
      _resident = found;
      _customEducationYears = null;
      _customAge = null;
      _responses.clear();
      _grades.clear();
      _questionTimes.clear();
      _currentIndex = 0;
      _responseController.clear();
      _isListening = false;
      _isSpeaking = false;
      _speechStatusMessage = null;
      _sessionId = null;
      _sessionStatus = 'IN_PROGRESS';
    });
    _loadSavedResidentResponses(residentId);
  }

  Future<void> _startNewAssessmentSession() async {
    final residentId = _resident?.id ?? ref.read(authProvider).state.residentId;
    if (residentId == null) return;
    final token = ref.read(authProvider).state.token;

    _saveCurrentQuestionState();
    setState(() {
      _grades.clear();
      _responses.clear();
      _questionTimes.clear();
      _currentIndex = 0;
      _responseController.clear();
      _sessionElapsedSeconds = 0;
      _sessionId = null;
      _sessionStatus = 'IN_PROGRESS';
    });

    try {
      final session = await CognitiveAssessmentService.startSession(
        residentId: residentId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _sessionId = session.sessionId;
          _sessionStatus = 'IN_PROGRESS';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedResidentResponses(int residentId) async {
    final token = ref.read(authProvider).state.token;

    // 1. First retrieve active/pending session from the existing backend
    try {
      final pendingSession = await CognitiveAssessmentService.getPendingSession(
        residentId: residentId,
        token: token,
      );
      if (pendingSession != null && mounted) {
        setState(() {
          _sessionId = pendingSession.sessionId;
          _sessionStatus = pendingSession.status;
          if (pendingSession.responses.isNotEmpty) {
            _responses.addAll(pendingSession.responses);
          }
          if (pendingSession.grades.isNotEmpty) {
            _grades.addAll(pendingSession.grades);
          }
          if (pendingSession.questionTimes.isNotEmpty) {
            _questionTimes.addAll(pendingSession.questionTimes);
          }
          _responseController.text =
              _responses[_questions[_currentIndex].id] ?? '';
        });
        return;
      }
    } catch (_) {}

    // 2. If no pending session, start a new session on backend
    if (_sessionId == null) {
      try {
        final newSession = await CognitiveAssessmentService.startSession(
          residentId: residentId,
          token: token,
        );
        if (mounted) {
          setState(() {
            _sessionId = newSession.sessionId;
            _sessionStatus = 'IN_PROGRESS';
          });
        }
      } catch (_) {}
    }

    // 3. SharedPreferences offline fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('cognitive_responses_$residentId');
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = json.decode(savedJson) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            decoded.forEach((key, val) {
              final qId = int.tryParse(key);
              if (qId != null && val is String && val.trim().isNotEmpty) {
                _responses[qId] ??= val;
              }
            });
            _responseController.text =
                _responses[_questions[_currentIndex].id] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _persistResponses() async {
    final rId = _resident?.id ?? ref.read(authProvider).state.residentId;
    if (rId == null) return;

    final token = ref.read(authProvider).state.token;

    // Save to existing backend H2 database
    if (_sessionId != null) {
      try {
        await CognitiveAssessmentService.saveResponses(
          sessionId: _sessionId!,
          responses: _responses,
          questionTimes: _questionTimes,
          token: token,
        );
      } catch (_) {}
    }

    // Local SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        for (final e in _responses.entries) e.key.toString(): e.value,
      };
      await prefs.setString('cognitive_responses_$rId', json.encode(map));
    } catch (_) {}
  }

  void _recordCurrentQuestionDuration() {
    final now = DateTime.now();
    final elapsedSec =
        (now.difference(_questionStartTime).inMilliseconds / 1000.0);
    final qId = _questions[_currentIndex].id;
    _questionTimes[qId] =
        (_questionTimes[qId] ?? 0.0) + (elapsedSec < 0.2 ? 0.2 : elapsedSec);
    _questionStartTime = DateTime.now();
  }

  void _saveCurrentQuestionState() {
    _activeListeningSessionId++;
    _recordCurrentQuestionDuration();
    if (_isSpeaking) _flutterTts.stop();
    if (_isListening || _speech.isListening) _speech.stop();
    final qId = _questions[_currentIndex].id;
    final text = _responseController.text;
    _responses[qId] = text;
    if (_grades[qId] == null && text.trim().isNotEmpty) {
      _grades[qId] = CognitiveScoring.scoreQuestion(qId, text);
    }
    _persistResponses();
  }

  Future<void> _toggleTts(String text) async {
    if (_isListening || _speech.isListening) {
      _activeListeningSessionId++;
      debugPrint('[CARE-STT] [6. Stop/Cancel Reason] Stopped microphone because TTS audio playback started.');
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          final text = _responseController.text.trim();
          if (text.isNotEmpty && _currentIndex < _questions.length) {
            final qId = _questions[_currentIndex].id;
            _responses[qId] = text;
            _grades[qId] = CognitiveScoring.scoreQuestion(qId, text);
            _speechStatusMessage = 'Voice response captured.';
            _persistResponses();
          }
        });
      }
    }
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      if (mounted) setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _toggleListening() async {
    final qId = _currentIndex < _questions.length ? _questions[_currentIndex].id : -1;
    debugPrint(
      '[CARE-STT] [1. Mic Pressed] qId=$qId, isListening=$_isListening, '
      'speechListening=${_speech.isListening}, isSpeaking=$_isSpeaking, '
      'speechAvailable=$_speechAvailable, speechInitialized=$_speechInitialized, '
      'currentBuffer="${_responseController.text}"',
    );

    // 1. Promptly stop any active TTS output so audio playback does not conflict with microphone capture
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    }

    if (_isListening || _speech.isListening) {
      _activeListeningSessionId++;
      debugPrint(
        '[CARE-STT] [6. Stop/Cancel Reason] User tapped to stop listening. '
        'qId=$qId, finalBuffer="${_responseController.text}"',
      );
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          final text = _responseController.text.trim();
          if (text.isNotEmpty) {
            _responses[qId] = text;
            _grades[qId] = CognitiveScoring.scoreQuestion(qId, text);
            _speechStatusMessage = 'Voice response captured.';
            _persistResponses();
          } else {
            _speechStatusMessage =
                'Speech not recognized. Please tap the microphone to retry or type your answer.';
          }
        });
      }
      return;
    }

    if (!_speechInitialized) {
      await _initSpeech();
    }
    if (!_speechAvailable) {
      debugPrint('[CARE-STT] [3. Listen Failed] Speech not available. Cannot start listening.');
      setState(() {
        _speechStatusMessage =
            'Microphone not available. Please enter the answer manually below or apply caregiver clinical scoring.';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _speechStatusMessage = 'Listening... Speak now.';
    });

    final currentSessionId = ++_activeListeningSessionId;
    final targetQId = qId;

    try {
      debugPrint(
        '[CARE-STT] [3. Listen Start Attempt] Calling _speech.listen for qId=$targetQId (session $currentSessionId), '
        'currentText="${_responseController.text}"',
      );
      await _speech.listen(
        onResult: (result) {
          if (currentSessionId != _activeListeningSessionId ||
              _currentIndex >= _questions.length ||
              _questions[_currentIndex].id != targetQId) {
            debugPrint(
              '[CARE-STT] Discarding late callback: session $currentSessionId vs active $_activeListeningSessionId, '
              'targetQ=$targetQId vs current=${_currentIndex < _questions.length ? _questions[_currentIndex].id : -1}',
            );
            return;
          }

          final incoming = result.recognizedWords;
          final incomingTrimmed = incoming.trim();
          final prevText = _responseController.text.trim();

          debugPrint(
            '[CARE-STT] [4. onResult] qId=$targetQId, recognizedWords="$incoming", '
            'finalResult=${result.finalResult}, confidence=${result.confidence.toStringAsFixed(2)}',
          );

          // Never wipe valid recognized text with an empty callback
          if (incomingTrimmed.isEmpty && prevText.isNotEmpty) {
            debugPrint('[CARE-STT] Preserving existing non-empty text, ignoring empty callback.');
            return;
          }

          if (mounted) {
            setState(() {
              if (incomingTrimmed.isNotEmpty) {
                _responseController.text = incoming;
                _responseController.selection = TextSelection.collapsed(
                  offset: incoming.length,
                );
                _responses[targetQId] = incoming;
              }
            });
            // NOTE: We do not invoke _persistResponses() on partial callbacks.
            // Persistence is handled when the session ends naturally or is stopped.
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          pauseFor: kIsWeb ? null : const Duration(seconds: 5),
          cancelOnError: false,
          partialResults: true,
          localeId: 'en_US',
        ),
      );
      debugPrint('[CARE-STT] [3. Listen Started] Session active: speechListening=${_speech.isListening}');
    } catch (err) {
      debugPrint('[CARE-STT] [3. Listen Failed] Exception while starting listen: $err');
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechStatusMessage = 'Recording note: $err';
        });
      }
    }
  }

  // Caregiver Clinical Scoring: Updates immediately without double-counting
  void _setGrade(double score) {
    final qId = _questions[_currentIndex].id;
    setState(() {
      _grades[qId] = score;
    });
  }

  void _goToQuestion(int index) {
    if (index == _currentIndex) return;
    _saveCurrentQuestionState();
    setState(() {
      _currentIndex = index;
      _responseController.text = _responses[_questions[index].id] ?? '';
      _isListening = false;
      _isSpeaking = false;
      _speechStatusMessage = null;
    });
  }

  void _nextQuestion(bool isElder) {
    _saveCurrentQuestionState();

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _responseController.text =
            _responses[_questions[_currentIndex].id] ?? '';
        _isListening = false;
        _isSpeaking = false;
        _speechStatusMessage = null;
      });
    } else {
      _showFinishConfirmationDialog(isElder);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _saveCurrentQuestionState();
      setState(() {
        _currentIndex--;
        _responseController.text =
            _responses[_questions[_currentIndex].id] ?? '';
        _isListening = false;
        _isSpeaking = false;
        _speechStatusMessage = null;
      });
    }
  }

  String _formatElapsed(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m}m ${s < 10 ? '0' : ''}${s}s';
  }

  // --- Strict Session Metrics & Role-Specific Calculations ---
  bool _isAnswered(int qId) => _responses[qId]?.trim().isNotEmpty == true;
  bool _isGraded(int qId) =>
      _grades[qId] != null ||
      (_isAnswered(qId) && CognitiveScoring.scoreQuestion(qId, _responses[qId]) != null);
  bool _isFullyCompleted(int qId) => _isAnswered(qId);

  int get _totalCount => _questions.length; // 10
  int get _answeredCount => _questions.where((q) => _isAnswered(q.id)).length;
  int get _gradedCount => _questions.where((q) => _isGraded(q.id)).length;
  int get _fullyCompletedCount =>
      _questions.where((q) => _isFullyCompleted(q.id)).length;
  int get _remainingToCompleteCount => _totalCount - _fullyCompletedCount;
  int get _remainingToAnswerCount => _totalCount - _answeredCount;

  /// Role-appropriate progress percentage:
  /// - ELDER: progress measures questions answered by resident: (answered / 10) * 100
  /// - CAREGIVER: progress measures questions fully assessed: (fully completed / 10) * 100
  int _getProgressPct(bool isElder) {
    if (_totalCount == 0) return 0;
    final count = isElder ? _answeredCount : _fullyCompletedCount;
    final pct = (count / _totalCount) * 100.0;
    return pct.clamp(0.0, 100.0).round();
  }

  Future<void> _submitCaregiverAssessment() async {
    _saveCurrentQuestionState();

    // Auto-grade all answered questions using question-specific deterministic rubric
    final autoGrades = CognitiveScoring.autoScoreBattery(_responses);
    for (final e in autoGrades.entries) {
      if (_grades[e.key] == null && e.value != null) {
        _grades[e.key] = e.value;
      }
    }

    final unanswered = CognitiveScoring.getUnansweredQuestionIds(_responses);
    if (unanswered.isNotEmpty) {
      setState(() {
        _isSubmitting = false;
        _submitError =
            'Cannot submit: Question(s) ${unanswered.join(', ')} are unanswered. All 10 questions must have responses before automatic evaluation.';
      });
      return;
    }

    final authState = ref.read(authProvider).state;
    final token = authState.token;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final accuracies = CognitiveScoring.calculateDomainAccuracies(_grades);
      final taskScores = CognitiveScoring.calculateDomainScores(accuracies);
      final responseTimes = CognitiveScoring.aggregateDomainResponseTimes(
        _questionTimes,
      );

      final residentId = _resident?.id ??
          authState.residentId ??
          (_availableResidents.isNotEmpty ? _availableResidents.first.id : null);
      if (residentId == null) {
        setState(() {
          _isSubmitting = false;
          _submitError = 'No eligible resident selected for assessment.';
        });
        return;
      }

      if (_sessionId == null) {
        final session = await CognitiveAssessmentService.startSession(
          residentId: residentId,
          token: token,
        );
        _sessionId = session.sessionId;
      }

      if (_sessionId != null) {
        try {
          await CognitiveAssessmentService.saveResponses(
            sessionId: _sessionId!,
            responses: _responses,
            questionTimes: _questionTimes,
            status: 'IN_PROGRESS',
            token: token,
          );
        } catch (_) {}
      }

      final effectiveAge = _customAge ?? _resident?.age;
      final effectiveEducationYears =
          _customEducationYears ?? _resident?.educationYears;

      final payload = CognitiveSubmissionPayload(
        residentId: residentId,
        memory: taskScores['memory'] ?? 0.0,
        attention: taskScores['attention'] ?? 0.0,
        orientation: taskScores['orientation'] ?? 0.0,
        recall: taskScores['recall'] ?? 0.0,
        reasoning: taskScores['reasoning'] ?? 0.0,
        age: effectiveAge,
        educationYears: effectiveEducationYears,
        accuracies: accuracies,
        responseTimes: responseTimes,
        sessionId: _sessionId,
        responses: _responses,
        grades: {
          for (final e in _grades.entries)
            if (e.value != null) e.key: e.value!,
        },
      );

      final result = await CognitiveAssessmentService.submitAssessment(
        payload: payload,
        token: token,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cognitive_responses_$residentId');
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _sessionStatus = result.status;
          _sessionId = null;
          if (_resident != null &&
              (effectiveEducationYears != _resident!.educationYears ||
                  effectiveAge != _resident!.age)) {
            _resident = CognitiveResidentProfile(
              id: _resident!.id,
              name: _resident!.name,
              age: effectiveAge,
              educationYears: effectiveEducationYears,
              roomNumber: _resident!.roomNumber,
              gender: _resident!.gender,
              currentStatus: _resident!.currentStatus,
              riskLevel: _resident!.riskLevel,
            );
          }
        });
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss confirm
        _showResultDialog(result);
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = err.toString();
        });
      }
    }
  }

  Future<void> _submitElderResponses() => _submitCaregiverAssessment();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).state;
    final bool isElder = authState.isElder;

    final currentQ = _questions[_currentIndex];
    final currentGrade = _grades[currentQ.id];
    final progressPct = _getProgressPct(isElder);

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar & Timer (Responsive Wrap)
            _buildTopNavBar(),
            const SizedBox(height: 16),

            if (!isElder && _isLoadingResidents) ...[
              _buildLoadingResidentsState(),
            ] else if (!isElder && _residentLoadError != null) ...[
              _buildResidentErrorState(_residentLoadError!),
            ] else if (!isElder && _availableResidents.isEmpty) ...[
              _buildEmptyResidentsState(),
            ] else ...[
              // Resident Context Banner
              _buildResidentBanner(isElder),
              const SizedBox(height: 20),

              // Main 2-Column Responsive Assessment Workspace
              ResponsiveBuilder(
                mobile: (context) => Column(
                  children: [
                    _buildMainQuestionWorkspace(
                      currentQ,
                      progressPct,
                      currentGrade,
                      isElder,
                    ),
                    const SizedBox(height: 20),
                    _buildRightPanel(progressPct, isElder),
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildMainQuestionWorkspace(
                        currentQ,
                        progressPct,
                        currentGrade,
                        isElder,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildRightPanel(progressPct, isElder),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (_sessionStatus == 'COMPLETED') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusLabel = 'Completed';
      statusIcon = LucideIcons.circleCheckBig;
    } else if (_sessionStatus == 'PENDING_CAREGIVER_REVIEW') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
      statusLabel = 'Pending Caregiver Review';
      statusIcon = LucideIcons.alertCircle;
    } else {
      statusBg = const Color(0xFFEFF6FF);
      statusColor = const Color(0xFF1D4ED8);
      statusLabel = 'In Progress';
      statusIcon = LucideIcons.clock;
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.go('/dashboard/residents'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Resident Directory',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 13, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_sessionId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '#${_sessionId!.length > 18 ? _sessionId!.substring(0, 18) : _sessionId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _startNewAssessmentSession,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.plus, size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'New Assessment',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Session Elapsed: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.body,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatElapsed(_sessionElapsedSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'R';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildLoadingResidentsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading resident profiles...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Retrieving residents assigned to your care community.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentErrorState(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riskHighBg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.riskHighBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle, color: AppColors.riskHigh, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to Load Residents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadResidentContext,
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('Retry Loading Directory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResidentsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.lavenderBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Eligible Residents Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are currently no residents registered or assigned to your care facility for cognitive assessment.\nCaregivers can only assess residents enrolled in their assigned Elder Home.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard/residents'),
                icon: const Icon(LucideIcons.userPlus, size: 15),
                label: const Text('Go to Resident Directory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadResidentContext,
                icon: const Icon(LucideIcons.refreshCw, size: 15),
                label: const Text('Refresh Directory'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResidentBanner(bool isElder) {
    final res = _resident;
    final initials = res != null ? _getInitials(res.name) : 'R';
    final displayName = (res != null && res.name.trim().isNotEmpty)
        ? res.name.trim()
        : (isElder ? 'Sarah Jenkins' : 'Resident #${res?.id ?? 1}');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lilac),
                        ),
                        child: Text(
                          isElder ? 'ELDER / RESIDENT' : 'ID: ${res?.id ?? 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Age: ${res?.age ?? 'N/A'} • Room ${res?.roomNumber ?? '204'} • Education: ${res?.educationYears != null ? '${res!.educationYears} yrs' : 'Not recorded'}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Caregivers can select from assigned residents; Elders are locked to themselves
              if (!isElder && _availableResidents.length > 1)
                DropdownButton<int>(
                  value: (_resident != null &&
                          _availableResidents.any((r) => r.id == _resident!.id))
                      ? _resident!.id
                      : (_availableResidents.isNotEmpty
                          ? _availableResidents.first.id
                          : null),
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _availableResidents.map((r) {
                    final clean = r.name.trim().isNotEmpty
                        ? r.name.trim()
                        : 'Resident #${r.id}';
                    return DropdownMenuItem<int>(
                      value: r.id,
                      child: Text('$clean (ID: ${r.id})'),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      _selectResident(id);
                    }
                  },
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lilac),
                ),
                child: Text(
                  isElder
                      ? 'Self-Response Session ($_totalCount Items)'
                      : 'Standard Cognitive Battery ($_totalCount Items)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainQuestionWorkspace(
    CognitiveQuestionItem currentQ,
    int progressPct,
    double? currentGrade,
    bool isElder,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $_totalCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isElder
                    ? 'Questions Answered: $_answeredCount/$_totalCount ($progressPct%) • Status: Self-Response'
                    : 'Completed: $_fullyCompletedCount/$_totalCount ($progressPct%) • Answered: $_answeredCount • Graded: $_gradedCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _totalCount == 0 ? 0.0 : (progressPct / 100.0),
              minHeight: 6,
              backgroundColor: AppColors.lavenderBg,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lavender Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lilac, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lilac),
                          ),
                          child: Text(
                            currentQ.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Domain: ${currentQ.domain}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isSpeaking ? LucideIcons.volume2 : LucideIcons.volumeX,
                        size: 20,
                        color: _isSpeaking
                            ? AppColors.primaryDeep
                            : AppColors.primary,
                      ),
                      tooltip:
                          _isSpeaking ? 'Stop audio' : 'Read question aloud',
                      onPressed: () => _toggleTts(currentQ.prompt),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentQ.prompt,
                  style: AppTextStyles.h2.copyWith(fontSize: 19, height: 1.35),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isElder
                              ? 'Tip: Take your time. Speak clearly into the microphone or type your answer.'
                              : 'AI Guidance: ${currentQ.aiTip}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.body,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Response Panel: Animated Waveform, Voice Transcript & Manual Entry
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isListening
                          ? 'Listening to speech...'
                          : (isElder
                              ? 'Your Response'
                              : 'Response Capture'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    Row(
                      children: [
                        if (_isAnswered(currentQ.id))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.riskLowBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Answer Saved',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.riskLow,
                              ),
                            ),
                          ),
                        Text(
                          isElder
                              ? 'Voice or Keyboard'
                              : 'Voice & Clinical Grading',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Animated Green Waveform Simulator
                _buildAnimatedWaveform(),
                const SizedBox(height: 12),

                // Editable Response Text Field (Real-time sync to single source of truth)
                TextField(
                  controller: _responseController,
                  onChanged: (val) {
                    final qId = currentQ.id;
                    setState(() {
                      _responses[qId] = val;
                      _grades[qId] = CognitiveScoring.scoreQuestion(qId, val);
                    });
                    _persistResponses();
                  },
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: isElder
                        ? 'Type your answer here, or tap the microphone to speak...'
                        : 'Type resident answer here, or tap the microphone to dictate...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 12, color: AppColors.navy),
                ),
                if (_speechStatusMessage != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.info, size: 12, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _speechStatusMessage!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Role-Specific Section:
                // - CAREGIVER sees automatic scoring indicator and optional override buttons
                // - ELDER sees confirmation that answers are auto-evaluated upon submission
                if (!isElder) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: const [
                          Text(
                            'Automatic Scoring (Deterministic Rubric):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            'System auto-grades answers • Optional override',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGradeButton(
                              label: 'Correct (1.0)',
                              icon: LucideIcons.checkCircle,
                              scoreValue: 1.0,
                              selectedColor: AppColors.riskLow,
                              selectedBg: AppColors.riskLowBg,
                              isSelected: currentGrade == 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGradeButton(
                              label: 'Partial (0.5)',
                              icon: LucideIcons.minusCircle,
                              scoreValue: 0.5,
                              selectedColor: AppColors.riskModerate,
                              selectedBg: AppColors.riskModerateBg,
                              isSelected: currentGrade == 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGradeButton(
                              label: 'Incorrect (0.0)',
                              icon: LucideIcons.xCircle,
                              scoreValue: 0.0,
                              selectedColor: AppColors.riskHigh,
                              selectedBg: AppColors.riskHighBg,
                              isSelected: currentGrade == 0.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lilac),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnswered(currentQ.id)
                              ? LucideIcons.checkCircle2
                              : LucideIcons.userCheck,
                          size: 16,
                          color: _isAnswered(currentQ.id)
                              ? AppColors.riskLow
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isAnswered(currentQ.id)
                                ? 'Answer saved. The system will automatically evaluate and score your response upon submission.'
                                : 'Type or speak your answer above. The system will evaluate your response.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Buttons: Repeat, Mic Toggle, Next/Finish (Responsive Wrap)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _toggleTts(currentQ.prompt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.lilac),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                    label: const Text(
                      'Repeat Question',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    'Time: ${(_questionTimes[currentQ.id] ?? 0.0).toStringAsFixed(0)}s',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton(
                      onPressed: _prevQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '← Prev',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  // Round Mic Button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? AppColors.riskHigh
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? AppColors.riskHigh
                                    : AppColors.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? LucideIcons.micOff : LucideIcons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _nextQuestion(isElder),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Next Question →'
                          : (isElder
                              ? 'Finish & Submit'
                              : 'Finish Assessment'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeButton({
    required String label,
    required IconData icon,
    required double scoreValue,
    required Color selectedColor,
    required Color selectedBg,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _setGrade(scoreValue),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? selectedColor : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? selectedColor : AppColors.body,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(24, (i) {
              final waveHeight = _isListening
                  ? (10 + 16 * ((i + _waveformController.value * 24) % 6) / 6)
                  : 4.0;
              return Container(
                width: 3.5,
                height: waveHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.riskLow : AppColors.lilac,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRightPanel(int progressPct, bool isElder) {
    return Column(
      children: [
        // 1. Circular Progress Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                isElder ? 'Your Answer Progress' : 'Assessment Progress',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 14),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: _totalCount == 0 ? 0.0 : (progressPct / 100.0),
                      strokeWidth: 8,
                      backgroundColor: AppColors.lavenderBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPct%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        isElder ? 'Answered' : 'Completed',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Responsive Stat Row
              if (isElder) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Answered',
                        '$_answeredCount/$_totalCount',
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Remaining',
                        '$_remainingToAnswerCount',
                        AppColors.muted,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Status',
                        _answeredCount == _totalCount
                            ? 'Ready'
                            : 'In Progress',
                        _answeredCount == _totalCount
                            ? AppColors.riskLow
                            : const Color(0xFFB45309),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Reviewer',
                        'Care Specialist',
                        AppColors.navy,
                      ),
                    ),
                  ],
                ),
                if (_remainingToAnswerCount > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.riskModerateBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.riskModerate),
                    ),
                    child: Text(
                      '$_remainingToAnswerCount question(s) pending your answer',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.riskLowBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.riskLow),
                    ),
                    child: const Text(
                      'All 10 questions answered — Ready for review!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.riskLow,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Completed',
                        '$_fullyCompletedCount/$_totalCount',
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Answered',
                        '$_answeredCount/$_totalCount',
                        const Color(0xFFB45309),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Graded',
                        '$_gradedCount/$_totalCount',
                        AppColors.riskLow,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Remaining',
                        '$_remainingToCompleteCount',
                        AppColors.muted,
                      ),
                    ),
                  ],
                ),
                if (_remainingToCompleteCount > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.riskModerateBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.riskModerate),
                    ),
                    child: Text(
                      '$_remainingToCompleteCount item(s) pending response or score',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Questions Overview Checklist
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Questions Overview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    isElder
                        ? '$_answeredCount / $_totalCount Answered'
                        : '$_fullyCompletedCount / $_totalCount Completed',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _questions.length,
                  itemBuilder: (context, idx) {
                    final q = _questions[idx];
                    final isCurrent = idx == _currentIndex;
                    final isGraded = _isGraded(q.id);
                    final isAnswered = _isAnswered(q.id);
                    final isComplete = _isFullyCompleted(q.id);
                    final gradeValue = _grades[q.id];

                    return InkWell(
                      onTap: () => _goToQuestion(idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primarySoft
                              : (isElder ? isAnswered : isComplete)
                              ? AppColors.lavenderBg
                              : (isAnswered || isGraded)
                              ? const Color(0xFFFEF3C7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${q.id}. ${q.category}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : (isElder ? isAnswered : isComplete)
                                      ? AppColors.navy
                                      : (isAnswered || isGraded)
                                      ? const Color(0xFF92400E)
                                      : AppColors.muted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isElder) ...[
                              if (isAnswered) ...[
                                const Text(
                                  'Answer Saved',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.riskLow,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.checkCircle2,
                                  size: 14,
                                  color: AppColors.riskLow,
                                ),
                              ] else ...[
                                Icon(
                                  isCurrent
                                      ? LucideIcons.circleDot
                                      : LucideIcons.circle,
                                  size: 13,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.lilac,
                                ),
                              ],
                            ] else ...[
                              if (isComplete) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.lilac),
                                  ),
                                  child: Text(
                                    gradeValue!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.riskLow,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.checkCircle2,
                                  size: 14,
                                  color: AppColors.riskLow,
                                ),
                              ] else if (isGraded && !isAnswered) ...[
                                const Text(
                                  'Missing answer',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.alertCircle,
                                  size: 13,
                                  color: Color(0xFFB45309),
                                ),
                              ] else if (isAnswered && !isGraded) ...[
                                const Text(
                                  'Awaiting score',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.clock,
                                  size: 13,
                                  color: Color(0xFFB45309),
                                ),
                              ] else ...[
                                Icon(
                                  isCurrent
                                      ? LucideIcons.circleDot
                                      : LucideIcons.circle,
                                  size: 13,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.lilac,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Clinical Scoring Rubric Guidance (or Elder Session Tips)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isElder ? LucideIcons.info : LucideIcons.helpCircle,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isElder
                        ? 'Elder Assessment Guidance'
                        : 'Clinical Evaluation Tips',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isElder
                    ? 'Take as much time as you need for each question. You can answer using the microphone or keyboard. Your care team will review your responses.'
                    : 'Guidance: ${_questions[_currentIndex].recommendedAnswerGuide}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.body,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Methodology & Synthetic Model Metrics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    LucideIcons.cpu,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AI Methodology & Model Metrics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ACRF Base Weights: Mem 25% • Attn 20% • Orient 20% • Recall 20% • Reas 15%',
                style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.3),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Trained Random Forest (Synthetic Benchmark):',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Synthetic Accuracy: 96.80% (95% CI: [95.85%, 97.70%])\n'
                      '• Macro F1: 96.76% | Macro Recall: 96.87%\n'
                      '• High-Risk Recall: 96.88% (Alert Threshold: P ≥ 0.48)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.navy,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Notice: Verified on synthetic test residents. Non-clinical research metric; not a medical diagnosis.',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. End / Finish Assessment Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showFinishConfirmationDialog(isElder),
            style: OutlinedButton.styleFrom(
              foregroundColor: isElder ? AppColors.primary : AppColors.riskHigh,
              side: BorderSide(
                color: isElder ? AppColors.lilac : AppColors.riskHighBg,
              ),
              backgroundColor: isElder
                  ? AppColors.primarySoft
                  : AppColors.riskHighBg.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isElder ? LucideIcons.send : LucideIcons.alertOctagon,
              size: 16,
            ),
            label: Text(
              isElder
                  ? (_answeredCount == _totalCount
                      ? 'Submit for Caregiver Review'
                      : 'End & Save Session')
                  : 'End Assessment',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.muted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showFinishConfirmationDialog(bool isElder) {
    _saveCurrentQuestionState();
    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final unansweredIds = _questions
                .where((q) => !_isAnswered(q.id))
                .map((q) => q.id)
                .toList();

            if (isElder) {
              final bool isAllAnswered = unansweredIds.isEmpty;
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(
                      isAllAnswered
                          ? LucideIcons.checkCircle2
                          : LucideIcons.alertTriangle,
                      color: isAllAnswered
                          ? AppColors.riskLow
                          : const Color(0xFFB45309),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAllAnswered
                          ? 'Submit & Auto-Score Assessment'
                          : 'Questions Pending Answer',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Summary: $_answeredCount of $_totalCount questions answered for ${_resident?.name ?? 'Resident'}.',
                        style: const TextStyle(fontSize: 12, color: AppColors.body),
                      ),
                      if (!isAllAnswered) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.riskModerateBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.riskModerate),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.alertCircle,
                                    size: 16,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${unansweredIds.length} Question(s) Require Your Response',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Unanswered: Question(s) ${unansweredIds.join(', ')}.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please answer all 10 questions before submitting. Missing answers remain incomplete.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF92400E),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: unansweredIds.map((id) {
                                  return ActionChip(
                                    label: Text(
                                      'Go to Q$id',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _goToQuestion(id - 1);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.riskLowBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.riskLow),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.checkCircle2,
                                    size: 16,
                                    color: AppColors.riskLow,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All 10 questions have saved responses.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.riskLow,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Your responses will be evaluated deterministically using question-specific scoring rules, ACRF cognitive domain scores calculated, and AI risk prediction generated.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((_customEducationYears ?? _resident?.educationYears) == null ||
                            (_customAge ?? _resident?.age) == null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 16,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Demographic Details for AI Prediction',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'The 31-feature Random Forest model requires Education Years (and Age) for risk classification. If left blank, ACRF domain scores will still be calculated and saved without ML prediction.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if ((_customAge ?? _resident?.age) == null) ...[
                                  TextFormField(
                                    initialValue: _customAge?.toString() ?? '',
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Resident Age (1-130)',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final n = int.tryParse(val.trim());
                                      if (n != null && n > 0 && n <= 130) {
                                        _customAge = n;
                                      } else if (val.trim().isEmpty) {
                                        _customAge = null;
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if ((_customEducationYears ?? _resident?.educationYears) == null) ...[
                                  TextFormField(
                                    initialValue: _customEducationYears?.toString() ?? '',
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Education Years (0-40)',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final n = int.tryParse(val.trim());
                                      if (n != null && n >= 0 && n <= 40) {
                                        _customEducationYears = n;
                                      } else if (val.trim().isEmpty) {
                                        _customEducationYears = null;
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (_submitError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.riskHighBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.riskHigh),
                          ),
                          child: Text(
                            _submitError!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.riskHigh,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      isAllAnswered ? 'Review Answers' : 'Return to Assessment',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (isAllAnswered && !_isSubmitting)
                        ? () async {
                            setDialogState(() => _isSubmitting = true);
                            await _submitElderResponses();
                            if (mounted) setDialogState(() {});
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isAllAnswered
                                ? 'Submit & Calculate Score'
                                : 'Answer All 10 Questions to Submit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              );
            }

            // CAREGIVER Flow: Requires all 10 responses, then automatically evaluates and finalizes
            final uncompletedIds = unansweredIds;
            final bool isAllCompleted = uncompletedIds.isEmpty;
            final bool canSubmit = !_isSubmitting && isAllCompleted;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isAllCompleted
                        ? LucideIcons.checkCircle2
                        : LucideIcons.alertTriangle,
                    color: isAllCompleted
                        ? AppColors.riskLow
                        : const Color(0xFFB45309),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAllCompleted
                        ? 'Submit & Auto-Score Assessment'
                        : 'Assessment Incomplete',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Summary: $_answeredCount of $_totalCount questions answered for ${_resident?.name ?? 'Resident'}.',
                      style: const TextStyle(fontSize: 12, color: AppColors.body),
                    ),
                    if (!isAllCompleted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.riskModerateBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.riskModerate),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  size: 16,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${uncompletedIds.length} Question(s) Require Resident Response',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (unansweredIds.isNotEmpty) ...[
                              Text(
                                '• Unanswered: Question(s) ${unansweredIds.join(', ')}.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'Every question must have a recorded response before finalizing. Missing responses remain incomplete and cannot be graded as incorrect.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF92400E),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: uncompletedIds.map((id) {
                                return ActionChip(
                                  label: Text(
                                    'Go to Q$id',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _goToQuestion(id - 1);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.riskLowBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.riskLow),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 16,
                              color: AppColors.riskLow,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'All 10 questions have valid saved responses. Ready for automatic scoring and AI evaluation.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.riskLow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((_customEducationYears ?? _resident?.educationYears) == null ||
                          (_customAge ?? _resident?.age) == null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    LucideIcons.sparkles,
                                    size: 16,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Demographic Details for AI Prediction',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'The 31-feature Random Forest model requires Education Years (and Age) for risk classification. If left blank, ACRF domain scores will still be calculated and saved without ML prediction.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if ((_customAge ?? _resident?.age) == null) ...[
                                TextFormField(
                                  initialValue: _customAge?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Resident Age (1-130)',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final n = int.tryParse(val.trim());
                                    if (n != null && n > 0 && n <= 130) {
                                      _customAge = n;
                                    } else if (val.trim().isEmpty) {
                                      _customAge = null;
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                              if ((_customEducationYears ?? _resident?.educationYears) == null) ...[
                                TextFormField(
                                  initialValue: _customEducationYears?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Education Years (0-40)',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final n = int.tryParse(val.trim());
                                    if (n != null && n >= 0 && n <= 40) {
                                      _customEducationYears = n;
                                    } else if (val.trim().isEmpty) {
                                      _customEducationYears = null;
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.riskHighBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.riskHigh),
                        ),
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.riskHigh,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    isAllCompleted ? 'Review Answers' : 'Return to Assessment',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          setDialogState(() => _isSubmitting = true);
                          await _submitCaregiverAssessment();
                          if (mounted) setDialogState(() {});
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isAllCompleted
                              ? 'Submit & Calculate Score'
                              : 'Complete All 10 Items to Submit',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResultDialog(CognitiveSubmissionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.riskLowBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: AppColors.riskLow,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cognitive Assessment Saved',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.residentName} • Assessed by ${result.assessedBy ?? 'Care Specialist'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ACRF Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lilac),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ACRF COGNITIVE WELLNESS SCORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${result.acrfScore != null ? result.acrfScore!.toStringAsFixed(1) : 'N/A'} / 100',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.methodology ??
                            'ACRF Fixed Base Weights (Non-Diagnostic Wellness Metric)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Category Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCategoryBadge('Memory', result.memory ?? 0.0, '25%'),
                    _buildCategoryBadge('Attention', result.attention ?? 0.0, '20%'),
                    _buildCategoryBadge(
                      'Orientation',
                      result.orientation ?? 0.0,
                      '20%',
                    ),
                    _buildCategoryBadge('Recall', result.recall ?? 0.0, '20%'),
                    _buildCategoryBadge('Reasoning', result.reasoning ?? 0.0, '15%'),
                  ],
                ),
                const SizedBox(height: 16),

                // Random Forest ML Model Evaluation
                if (result.mlAvailable) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.riskModerateBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.riskModerate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  LucideIcons.alertTriangle,
                                  size: 15,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Experimental ML Prediction',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                result.mlPrediction ?? 'Low Risk',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ Non-Clinical Demonstration Notice: This Random Forest model was experimentally trained on synthetic data for research demonstration purposes. It is NOT clinically validated and must not be used for medical diagnosis, clinical triage, or care interventions.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                        if (result.probabilities != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: result.probabilities!.entries.map((
                              entry,
                            ) {
                              return Column(
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                  Text(
                                    '${(entry.value * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 15,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.mlStatusMessage.isNotEmpty
                                ? result.mlStatusMessage
                                : 'Random Forest inference unavailable (demographics or metrics incomplete). Fixed-weight ACRF score saved successfully.',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Clinical Disclaimer
                Text(
                  result.clinicalDisclaimer ??
                      'The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.go('/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryBadge(String title, double score, String weight) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          score.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        Text(
          'w=$weight',
          style: const TextStyle(fontSize: 9, color: AppColors.primary),
        ),
      ],
    );
  }
}
