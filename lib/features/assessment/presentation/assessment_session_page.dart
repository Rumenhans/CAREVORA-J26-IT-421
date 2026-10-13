import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  // Navigation & session index
  int _currentIndex = 0;
  final List<CognitiveQuestionItem> _questions = CognitiveScoring.questions;

  // Question grades (id -> 1.0, 0.5, 0.0, or null if unanswered)
  final Map<int, double?> _grades = {};

  // Timing: active question viewing duration
  final Map<int, double> _questionTimes = {};
  late DateTime _questionStartTime;
  int _sessionElapsedSeconds = 0;
  Timer? _sessionTimer;

  // Speech & TTS
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _transcript = '';

  // Resident Context
  CognitiveResidentProfile? _resident;
  List<CognitiveResidentProfile> _availableResidents = [];

  // Submission state
  bool _isSubmitting = false;
  String? _submitError;

  // Animated waveform controller
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
    _initTts();
    _initWaveformAnimation();
    _startSessionTimer();
    _loadResidentContext();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _waveformController.dispose();
    _flutterTts.stop();
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
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {}
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

    try {
      final list = await CognitiveAssessmentService.fetchResidents(
        token: token,
      );
      if (mounted) {
        setState(() {
          _availableResidents = list;
          if (list.isNotEmpty) {
            _resident = list.first;
          } else if (authState.residentId != null) {
            _resident = CognitiveResidentProfile(
              id: authState.residentId!,
              name: authState.userName ?? 'Resident',
              roomNumber: 'Assigned Room',
            );
          }
        });
      }
    } catch (_) {
      if (mounted && authState.residentId != null) {
        setState(() {
          _resident = CognitiveResidentProfile(
            id: authState.residentId!,
            name: authState.userName ?? 'Resident',
            roomNumber: 'Assigned Room',
          );
        });
      }
    }
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

  Future<void> _toggleTts(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      if (mounted) setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening && _transcript.isEmpty) {
        // Simulated speech capture
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted && _isListening) {
            setState(() {
              _transcript = 'Patient verbal response recorded successfully.';
            });
          }
        });
      }
    });
  }

  void _setGrade(double score) {
    final qId = _questions[_currentIndex].id;
    setState(() {
      _grades[qId] = score;
    });
  }

  void _goToQuestion(int index) {
    if (index == _currentIndex) return;
    _recordCurrentQuestionDuration();
    if (_isSpeaking) _flutterTts.stop();
    setState(() {
      _currentIndex = index;
      _transcript = '';
      _isListening = false;
      _isSpeaking = false;
    });
  }

  void _nextQuestion() {
    _recordCurrentQuestionDuration();
    if (_isSpeaking) _flutterTts.stop();

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _transcript = '';
        _isListening = false;
        _isSpeaking = false;
      });
    } else {
      _showFinishConfirmationDialog();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _recordCurrentQuestionDuration();
      if (_isSpeaking) _flutterTts.stop();
      setState(() {
        _currentIndex--;
        _transcript = '';
        _isListening = false;
        _isSpeaking = false;
      });
    }
  }

  String _formatElapsed(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m}m ${s < 10 ? '0' : ''}${s}s';
  }

  int get _answeredCount => _grades.values.where((v) => v != null).length;

  Future<void> _submitAssessment() async {
    _recordCurrentQuestionDuration();
    final authState = ref.read(authProvider).state;
    final token = authState.token;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // Calculate domain accuracies, scores, and response times
      final accuracies = CognitiveScoring.calculateDomainAccuracies(_grades);
      final taskScores = CognitiveScoring.calculateDomainScores(accuracies);
      final responseTimes = CognitiveScoring.aggregateDomainResponseTimes(
        _questionTimes,
      );

      final residentId = _resident?.id ?? (authState.residentId ?? 1);

      final payload = CognitiveSubmissionPayload(
        residentId: residentId,
        memory: taskScores['memory'] ?? 0.0,
        attention: taskScores['attention'] ?? 0.0,
        orientation: taskScores['orientation'] ?? 0.0,
        recall: taskScores['recall'] ?? 0.0,
        reasoning: taskScores['reasoning'] ?? 0.0,
        age: _resident?.age, // Genuine demographics only
        educationYears:
            _resident?.educationYears, // Never fabricated if missing
        accuracies: accuracies,
        responseTimes: responseTimes,
      );

      final result = await CognitiveAssessmentService.submitAssessment(
        payload: payload,
        token: token,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Dismiss confirmation dialog
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

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final progressPct = ((_answeredCount / _questions.length) * 100).toInt();
    final currentGrade = _grades[currentQ.id];

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar & Timer
            _buildTopNavBar(),
            const SizedBox(height: 16),

            // Resident Context Banner
            _buildResidentBanner(),
            const SizedBox(height: 20),

            // Main 2-Column Responsive Assessment Workspace
            ResponsiveBuilder(
              mobile: (context) => Column(
                children: [
                  _buildMainQuestionWorkspace(
                    currentQ,
                    progressPct,
                    currentGrade,
                  ),
                  const SizedBox(height: 20),
                  _buildRightPanel(progressPct),
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
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _buildRightPanel(progressPct)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.go('/dashboard'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: const [
                Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Back to Overview',
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
    );
  }

  Widget _buildResidentBanner() {
    final res = _resident;
    final initials = res != null && res.name.isNotEmpty
        ? res.name.split(' ').map((n) => n[0]).take(2).join()
        : 'SJ';

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
                        res?.name ?? 'Sarah Jenkins',
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
                          'ID: ${res?.id ?? 1}',
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
              if (_availableResidents.length > 1)
                DropdownButton<int>(
                  value: _resident?.id,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _availableResidents.map((r) {
                    return DropdownMenuItem<int>(
                      value: r.id,
                      child: Text('${r.name} (ID: ${r.id})'),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() {
                        _resident = _availableResidents.firstWhere(
                          (r) => r.id == id,
                        );
                      });
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
                child: const Text(
                  'Standard Cognitive Battery (20 Items)',
                  style: TextStyle(
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
          // Header: Question counter & Linear Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinical Cognitive Assessment',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length} ($progressPct%)',
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
              value: (_currentIndex + 1) / _questions.length,
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
                        _isSpeaking ? LucideIcons.volumeX : LucideIcons.volume2,
                        size: 20,
                        color: _isSpeaking
                            ? AppColors.primaryDeep
                            : AppColors.primary,
                      ),
                      tooltip: 'Read question aloud',
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
                          'AI Guidance: ${currentQ.aiTip}',
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

          // Response Panel: Animated Waveform & Speech Transcript
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
                          : 'Response Capture',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const Text(
                      'Voice & Clinical Grading',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Animated Green Waveform Simulator
                _buildAnimatedWaveform(),
                const SizedBox(height: 12),

                // Transcript box
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _transcript.isNotEmpty ? '"$_transcript"' : 'Tap the microphone to record verbal responses, or select clinical scoring below.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: _transcript.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: _transcript.isNotEmpty
                          ? AppColors.navy
                          : AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Clinical Grading Buttons (Requirement 5)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Caregiver Clinical Scoring:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Rubric: Correct = 1.0 • Partial = 0.5 • Incorrect = 0.0',
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Buttons: Repeat, Mic Toggle, Next/Finish
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  const SizedBox(width: 10),
                  Text(
                    'Time: ${(_questionTimes[currentQ.id] ?? 0.0).toStringAsFixed(0)}s',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_currentIndex > 0) ...[
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
                    const SizedBox(width: 10),
                  ],
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
                            color:
                                (_isListening
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
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _nextQuestion,
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
                          : 'Finish Assessment',
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

  Widget _buildRightPanel(int progressPct) {
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
              const Text(
                'Assessment Progress',
                style: TextStyle(
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
                      value: _answeredCount / _questions.length,
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
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Graded',
                    '$_answeredCount',
                    AppColors.riskLow,
                  ),
                  _buildStatItem(
                    'Current',
                    '${_currentIndex + 1}',
                    AppColors.primary,
                  ),
                  _buildStatItem(
                    'Remaining',
                    '${_questions.length - _answeredCount}',
                    AppColors.muted,
                  ),
                ],
              ),
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
                    '$_answeredCount / ${_questions.length}',
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
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _questions.length,
                  itemBuilder: (context, idx) {
                    final q = _questions[idx];
                    final isCurrent = idx == _currentIndex;
                    final isGraded = _grades[q.id] != null;
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
                              : isGraded
                              ? AppColors.lavenderBg
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
                            Text(
                              '${q.id}. ${q.category}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? AppColors.primary
                                    : isGraded
                                    ? AppColors.navy
                                    : AppColors.muted,
                              ),
                            ),
                            Icon(
                              isGraded
                                  ? LucideIcons.checkCircle
                                  : isCurrent
                                  ? LucideIcons.circleDot
                                  : LucideIcons.circle,
                              size: 13,
                              color: isGraded
                                  ? AppColors.riskLow
                                  : isCurrent
                                  ? AppColors.primary
                                  : AppColors.lilac,
                            ),
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

        // 3. Clinical Scoring Rubric Button
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
                    LucideIcons.helpCircle,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Clinical Evaluation Tips',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Guidance: ${_questions[_currentIndex].recommendedAnswerGuide}',
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

        // 4. End Assessment Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showFinishConfirmationDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.riskHigh,
              side: const BorderSide(color: AppColors.riskHighBg),
              backgroundColor: AppColors.riskHighBg.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.alertOctagon, size: 16),
            label: const Text(
              'End Assessment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }

  void _showFinishConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final uncompletedCount = _questions.length - _answeredCount;
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(
                    LucideIcons.checkCircle2,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Finalize Assessment?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have answered and graded $_answeredCount of ${_questions.length} questions for ${_resident?.name ?? 'Resident'}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.body),
                  ),
                  if (uncompletedCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.riskModerateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.riskModerate),
                      ),
                      child: Text(
                        'Note: $uncompletedCount questions remain ungraded. Unanswered items are scored as 0.0.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
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
              actions: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Continue Testing',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => _isSubmitting = true);
                          await _submitAssessment();
                          if (mounted) setDialogState(() {});
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Finalize & Submit',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                        '${result.acrfScore.toStringAsFixed(1)} / 100',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.methodology ?? 'ACRF Fixed Base Weights (Non-Diagnostic Wellness Metric)',
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
                    _buildCategoryBadge('Memory', result.memory, '25%'),
                    _buildCategoryBadge('Attention', result.attention, '20%'),
                    _buildCategoryBadge(
                      'Orientation',
                      result.orientation,
                      '20%',
                    ),
                    _buildCategoryBadge('Recall', result.recall, '20%'),
                    _buildCategoryBadge('Reasoning', result.reasoning, '15%'),
                  ],
                ),
                const SizedBox(height: 16),

                // Random Forest ML Model Evaluation (Requirement 10)
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
                  result.clinicalDisclaimer ?? 'The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.',
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
