import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/responsive/responsive_builder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';
import '../application/facial_emotion_ai_service.dart';

class EmotionalWellnessPage extends ConsumerStatefulWidget {
  const EmotionalWellnessPage({super.key});

  @override
  ConsumerState<EmotionalWellnessPage> createState() => _EmotionalWellnessPageState();
}

class _EmotionalWellnessPageState extends ConsumerState<EmotionalWellnessPage>
    with TickerProviderStateMixin {
  // Default to question 5 (index 4) to strictly mirror Proposal Figure 11-4 on load!
  int _currentIndex = 4;
  final List<AssessmentQuestion> _questions = MockCarevoraData.emotionalQuestions;

  // Real-time analysis metrics
  String _selectedEmotion = 'Happy';
  double _facialConfidence = 0.85;
  String _voiceEmotion = 'Neutral';
  double _voiceConfidence = 0.72;

  // Scores
  int _lonelinessScore = 67;
  int _isolationScore = 58;

  // Social behavior indicators
  String _commLevel = 'Moderate';
  String _engagementLevel = 'High';
  String _responseTime = 'Normal';

  // Voice recording & timers
  bool _isRecording = true;
  int _recordSeconds = 12;
  Timer? _recordTimer;
  String _spokenText =
      'Sometimes in the evenings, even when people are around, I feel alone in my thoughts.';

  // Speech and Voice engines
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;

  // Camera & Image state
  String _currentFaceAsset = 'assets/images/landing/senior_happy_face.jpg';
  Uint8List? _capturedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Animations
  late AnimationController _waveController;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVoiceEngines();
    _startRecordingTimer();
  }

  void _initAnimations() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initVoiceEngines() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);

    _speech = stt.SpeechToText();
    try {
      _speechEnabled = await _speech.initialize(
        onError: (err) => debugPrint('STT Error: $err'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isRecording) {
              // keep state synced
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init fallback: $e');
    }
  }

  void _startRecordingTimer() {
    _recordTimer?.cancel();
    if (_isRecording) {
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveController.dispose();
    _scannerController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _readQuestionAloud() async {
    final currentQ = _questions[_currentIndex];
    await _flutterTts.speak(currentQ.audioPrompt);
  }

  void _toggleRecording() async {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startRecordingTimer();
      if (_speechEnabled) {
        _speech.listen(onResult: (result) {
          if (mounted) {
            setState(() {
              _spokenText = result.recognizedWords;
            });
          }
        });
      }
    } else {
      _recordTimer?.cancel();
      if (_speechEnabled) {
        await _speech.stop();
      }
    }
  }

  Future<void> _takeLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
        });

        final result = await FacialEmotionAiService.analyzeImage(imageBytes: bytes);
        if (mounted) {
          _updateEmotionFromResult(result);
        }
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
    }
  }

  void _selectSampleEmotion(String emotion, String assetPath, double conf, int lScore, int iScore) {
    setState(() {
      _selectedEmotion = emotion;
      _currentFaceAsset = assetPath;
      _capturedImageBytes = null;
      _facialConfidence = conf;
      _lonelinessScore = lScore;
      _isolationScore = iScore;

      if (emotion == 'Happy') {
        _voiceEmotion = 'Neutral / Calm';
        _voiceConfidence = 0.72;
        _commLevel = 'Moderate';
        _engagementLevel = 'High';
        _responseTime = 'Normal';
      } else if (emotion == 'Sad') {
        _voiceEmotion = 'Melancholic / Low Pitch';
        _voiceConfidence = 0.82;
        _commLevel = 'Low';
        _engagementLevel = 'Low';
        _responseTime = 'Delayed';
        _lonelinessScore = 78;
        _isolationScore = 72;
      } else if (emotion == 'Angry') {
        _voiceEmotion = 'Agitated / Elevated Pitch';
        _voiceConfidence = 0.76;
        _commLevel = 'Defensive';
        _engagementLevel = 'Medium';
        _responseTime = 'Fast';
        _lonelinessScore = 62;
        _isolationScore = 65;
      } else {
        _voiceEmotion = 'Anxious / Tremor';
        _voiceConfidence = 0.79;
        _commLevel = 'Hesitant';
        _engagementLevel = 'Low';
        _responseTime = 'Variable';
        _lonelinessScore = 74;
        _isolationScore = 69;
      }
    });
  }

  void _updateEmotionFromResult(FacialEmotionResult result) {
    setState(() {
      _facialConfidence = result.confidence;
      if (result.primaryEmotion == EmotionCategory.happy) {
        _selectedEmotion = 'Happy';
        _lonelinessScore = 52;
        _isolationScore = 48;
      } else if (result.primaryEmotion == EmotionCategory.sadDepressed) {
        _selectedEmotion = 'Sad';
        _lonelinessScore = 79;
        _isolationScore = 75;
      } else if (result.primaryEmotion == EmotionCategory.confusedAgitated) {
        _selectedEmotion = 'Angry';
        _lonelinessScore = 65;
        _isolationScore = 62;
      } else {
        _selectedEmotion = 'Fear';
        _lonelinessScore = 70;
        _isolationScore = 68;
      }
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _updateQuestionContext();
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _updateQuestionContext();
      });
    } else {
      _showEndAssessmentDialog();
    }
  }

  void _skipQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _updateQuestionContext();
      });
    }
  }

  void _updateQuestionContext() {
    final q = _questions[_currentIndex];
    // Dynamic simulated sample response per question
    if (q.id == 5) {
      _spokenText =
          'Sometimes in the evenings, even when people are around, I feel alone in my thoughts.';
    } else if (q.id == 6) {
      _spokenText =
          'I do feel left out occasionally when groups are laughing together in the lounge.';
    } else if (q.id == 7) {
      _spokenText =
          'I attend morning tea, but I prefer sitting at the side quiet corner.';
    } else {
      _spokenText = 'Resident verbal response captured and transcribed via RALPA audio feature pipeline.';
    }
  }

  void _showTipsDialog() {
    final currentQ = _questions[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('AI Protocol Guide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavenderBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lilac),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.heartHandshake, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Question ${_currentIndex + 1} Focus: ${currentQ.category}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(currentQ.tip, style: AppTextStyles.body),
            const SizedBox(height: 12),
            const Text(
              '• Allow the senior at least 10–15 seconds to finish their thoughts without interruption.\n• The AI speech model analyzes vocal latency, fundamental frequency (F0), and emotional prosody.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showEndAssessmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: AppColors.riskModerate, size: 22),
            SizedBox(width: 10),
            Text('End Loneliness & Social Assessment?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The current session data will be processed through the RALPA (Resident-Adaptive Longitudinal Prediction Algorithm) pipeline to update Mr. James Perera\'s baseline and risk trajectory.',
              style: TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Loneliness Index:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$_lonelinessScore (Moderate Risk)',
                          style: const TextStyle(
                              color: AppColors.riskModerate, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Social Isolation Index:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$_isolationScore (High Risk)',
                          style: const TextStyle(
                              color: AppColors.riskHigh, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Predicted Trajectory:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Slow Deterioration (Action Req.)',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save & Finish Assessment'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final completedCount = _currentIndex;
    final remainingCount = _questions.length - (_currentIndex + 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Back to Residents & Date Badge
          _buildTopHeaderBar(),
          const SizedBox(height: 16),

          // 2. Resident Profile Card (Mr. James Perera)
          _buildResidentHeaderCard(),
          const SizedBox(height: 20),

          // 3. Two-Column Main Body (Assessment Left 70%, Real-time Indicators Right 30%)
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildMainAssessmentCard(currentQ),
                const SizedBox(height: 24),
                _buildRightSidePanel(completedCount, remainingCount),
              ],
            ),
            desktop: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 68, child: _buildMainAssessmentCard(currentQ)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 32,
                  child: _buildRightSidePanel(completedCount, remainingCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP HEADER BAR ---
  Widget _buildTopHeaderBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.go('/dashboard/residents'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: const [
                Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Back to Residents',
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
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(LucideIcons.bell, size: 16, color: AppColors.navy),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.riskHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.calendar, size: 14, color: AppColors.muted),
                  SizedBox(width: 8),
                  Text(
                    '12 May 2025',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Monday, 10:30 AM',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- RESIDENT HEADER CARD ---
  Widget _buildResidentHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'JP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mr. James Perera (ID: R001)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Age 78 / Male / Room No: 105',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASSESSMENT TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.heartPulse, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Loneliness & Social-Isolation Assessment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SESSION STARTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '10:30:15 AM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MAIN ASSESSMENT CARD ---
  Widget _buildMainAssessmentCard(AssessmentQuestion currentQ) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Session Title and Question Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'AI-Assisted Loneliness & Social-Isolation Assessment Session',
                  style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Question Prompt Lavender Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lilac),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQ.prompt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _readQuestionAloud,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.volume2, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Tap to replay',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Side-by-side: Camera & Voice Recording
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    _buildCameraCard(),
                    const SizedBox(height: 16),
                    _buildVoiceRecordingCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCameraCard()),
                  const SizedBox(width: 18),
                  Expanded(child: _buildVoiceRecordingCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 4. Voice Prompt Guidance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please respond using your voice. Take your time. There are no right or wrong answers.',
                    style: TextStyle(fontSize: 13, color: AppColors.body, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Button Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentIndex > 0 ? _previousQuestion : null,
                icon: const Icon(LucideIcons.arrowLeft, size: 15),
                label: const Text('Previous Question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(LucideIcons.arrowRight, size: 15),
                    label: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'Complete Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _skipQuestion,
                    icon: const Icon(LucideIcons.chevronsRight, size: 15, color: AppColors.muted),
                    label: const Text('Skip Question', style: TextStyle(color: AppColors.muted)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 20),

          // 6. Assessment Focus Panel
          _buildAssessmentFocusPanel(),
        ],
      ),
    );
  }

  // --- CAMERA BOX (FACIAL EXPRESSION) ---
  Widget _buildCameraCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Camera (Facial Expression)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.riskLowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fiber_manual_record, size: 8, color: AppColors.riskLow),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.riskLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Face Stream Video Container with Bounding Box Reticle
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _capturedImageBytes != null
                      ? Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
                      : Image.asset(_currentFaceAsset, fit: BoxFit.cover),

                  // Overlay Face Tracking Box with green/purple corners
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedEmotion == 'Happy'
                              ? AppColors.riskLow.withValues(alpha: 0.85)
                              : AppColors.primary.withValues(alpha: 0.85),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Face Target: ${(_facialConfidence * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subtle animated scanning laser line
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_scannerController.value * 120),
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Live Camera Switch button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: _takeLiveCameraPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Detected Emotion Label and Selection Pills
          const Text(
            'Detected Emotion:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildEmotionTag(
                'Happy',
                'assets/images/landing/senior_happy_face.jpg',
                '😊 Happy',
                0.85,
                67,
                58,
                isActive: _selectedEmotion == 'Happy',
                activeColor: AppColors.riskLow,
                activeBg: AppColors.riskLowBg,
              ),
              _buildEmotionTag(
                'Sad',
                'assets/images/landing/senior_sad_face.jpg',
                '😢 Sad',
                0.82,
                78,
                72,
                isActive: _selectedEmotion == 'Sad',
                activeColor: AppColors.riskHigh,
                activeBg: AppColors.riskHighBg,
              ),
              _buildEmotionTag(
                'Angry',
                'assets/images/landing/senior_sad_face.jpg',
                '😠 Angry',
                0.74,
                64,
                65,
                isActive: _selectedEmotion == 'Angry',
                activeColor: AppColors.riskModerate,
                activeBg: AppColors.riskModerateBg,
              ),
              _buildEmotionTag(
                'Fear',
                'assets/images/landing/senior_sad_face.jpg',
                '😨 Fear',
                0.78,
                74,
                69,
                isActive: _selectedEmotion == 'Fear',
                activeColor: AppColors.primary,
                activeBg: AppColors.primarySoft,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTag(
    String key,
    String asset,
    String label,
    double conf,
    int lScore,
    int iScore, {
    required bool isActive,
    required Color activeColor,
    required Color activeBg,
  }) {
    return InkWell(
      onTap: () => _selectSampleEmotion(key, asset, conf, lScore, iScore),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : AppColors.navy,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                '${(conf * 100).toInt()}%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- VOICE RECORDING BOX ---
  Widget _buildVoiceRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with recording blinker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voice Recording',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.riskHighBg : AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: _isRecording ? AppColors.riskHigh : AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isRecording ? 'Recording...' : 'Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? AppColors.riskHigh : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimer(_recordSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Animated Audio Waveform Box
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(24, (i) {
                    final factor = (1 + 0.8 * ((i % 4 == 0) ? 1.0 : 0.4));
                    final waveValue = (_waveController.value * 6.28 + (i * 0.3)).abs();
                    final dynamicHeight = _isRecording
                        ? (12.0 + (35.0 * (0.3 + 0.7 * (1.0 - (waveValue % 1.0)))) * factor)
                            .clamp(8.0, 75.0)
                        : 6.0;

                    return Container(
                      width: 4,
                      height: dynamicHeight,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                        gradient: _isRecording
                            ? LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Central Microphone Action Button
          Center(
            child: Column(
              children: [
                InkWell(
                  onTap: _toggleRecording,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.riskHigh : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? AppColors.riskHigh : AppColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? LucideIcons.square : LucideIcons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRecording ? 'Tap microphone to stop' : 'Tap microphone to record',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Spoken Transcript Preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.messageSquare, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _spokenText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ASSESSMENT FOCUS PANEL ---
  Widget _buildAssessmentFocusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assessment Focus',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        const Text(
          'This assessment helps us understand your emotional well-being and social connection',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildFocusBadge(LucideIcons.heart, 'Emotional Well-being', isCurrent: _questions[_currentIndex].category == 'Emotional Well-being'),
            _buildFocusBadge(LucideIcons.users, 'Social Interaction', isCurrent: _questions[_currentIndex].category == 'Social Interaction'),
            _buildFocusBadge(LucideIcons.messageSquare, 'Communication Patterns', isCurrent: _questions[_currentIndex].category == 'Communication Patterns'),
            _buildFocusBadge(LucideIcons.shieldAlert, 'Loneliness Indicators', isCurrent: _questions[_currentIndex].category == 'Loneliness Indicators'),
            _buildFocusBadge(LucideIcons.share2, 'Social-isolation Indicators', isCurrent: _questions[_currentIndex].category == 'Social-isolation Indicators'),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusBadge(IconData icon, String title, {required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isCurrent ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? AppColors.primary : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  // --- RIGHT SIDEBAR PANEL ---
  Widget _buildRightSidePanel(int completed, int remaining) {
    return Column(
      children: [
        // 1. Real-time Analysis Card
        _buildRealtimeAnalysisCard(),
        const SizedBox(height: 18),

        // 2. Loneliness & Social-Isolation Indicators Card
        _buildLonelinessIsolationCard(),
        const SizedBox(height: 18),

        // 3. Session Progress Card
        _buildSessionProgressCard(completed, remaining),
        const SizedBox(height: 18),

        // 4. AI Assistant Tips Card
        _buildAiAssistantCard(),
        const SizedBox(height: 18),

        // 5. End Assessment Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showEndAssessmentDialog,
            icon: const Icon(LucideIcons.xCircle, size: 16, color: AppColors.riskHigh),
            label: const Text(
              'End Assessment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.riskHigh,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.riskHigh, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Real-time Analysis Card
  Widget _buildRealtimeAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-time Analysis',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),

          // Facial Emotion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Facial Emotion', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(
                '$_selectedEmotion  ${(_facialConfidence * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.riskLow),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _facialConfidence,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.riskLow,
            ),
          ),
          const SizedBox(height: 14),

          // Voice Emotion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Voice Emotion', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(
                '$_voiceEmotion  ${(_voiceConfidence * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _voiceConfidence,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Social Behavior Indicators
          const Text(
            'Social Behavior Indicators',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 10),
          _buildBehaviorRow('• Communication Level', _commLevel, AppColors.riskModerateBg, AppColors.riskModerate),
          const SizedBox(height: 8),
          _buildBehaviorRow('• Engagement Level', _engagementLevel, AppColors.riskLowBg, AppColors.riskLow),
          const SizedBox(height: 8),
          _buildBehaviorRow('• Response Time', _responseTime, const Color(0xFFE0F2FE), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBehaviorRow(String label, String value, Color bg, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.body)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ],
    );
  }

  // 2. Loneliness & Social-Isolation Indicators Card
  Widget _buildLonelinessIsolationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loneliness & Social-Isolation Indicators',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),

          // Section A: Loneliness Indicators
          const Text(
            'Loneliness Indicators',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _IndicatorSubRow(label: 'Emotional Disconnection', level: 'Medium'),
                    SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Perceived Loneliness', level: 'High'),
                    SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Social Support', level: 'Low'),
                  ],
                ),
              ),
              _buildCircularScoreGauge(
                score: _lonelinessScore,
                riskLabel: 'Moderate Risk',
                riskColor: AppColors.riskModerate,
                bgRingColor: AppColors.riskModerateBg,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Section B: Social-Isolation Indicators
          const Text(
            'Social-Isolation Indicators',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.riskHigh),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _IndicatorSubRow(label: 'Social Interaction Frequency', level: 'Medium'),
                    SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Participation in Activities', level: 'Low'),
                    SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Network Size', level: 'Low'),
                  ],
                ),
              ),
              _buildCircularScoreGauge(
                score: _isolationScore,
                riskLabel: 'High Risk',
                riskColor: AppColors.riskHigh,
                bgRingColor: AppColors.riskHighBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScoreGauge({
    required int score,
    required String riskLabel,
    required Color riskColor,
    required Color bgRingColor,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 5,
                backgroundColor: bgRingColor,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          riskLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: riskColor,
          ),
        ),
      ],
    );
  }

  // 3. Session Progress Card
  Widget _buildSessionProgressCard(int completed, int remaining) {
    final currentNum = _currentIndex + 1;
    final total = _questions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Progress',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: currentNum / total.toDouble(),
                      strokeWidth: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '$currentNum',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressLegendDot(Colors.blue, 'Completed', '$completed'),
                  const SizedBox(height: 6),
                  _buildProgressLegendDot(AppColors.primary, 'Current', '1'),
                  const SizedBox(height: 6),
                  _buildProgressLegendDot(AppColors.muted, 'Remaining', '$remaining'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLegendDot(Color color, String label, String count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '• $label',
          style: const TextStyle(fontSize: 12, color: AppColors.body),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
      ],
    );
  }

  // 4. AI Assistant Tips Card
  Widget _buildAiAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lilac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.bot, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI ASSISTANT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '"I am here to listen and understand how you feel."',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showTipsDialog,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(LucideIcons.lightbulb, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Show Tips',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorSubRow extends StatelessWidget {
  final String label;
  final String level;

  const _IndicatorSubRow({required this.label, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        Text(
          level,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}
