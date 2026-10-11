import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';
import '../../../shared/widgets/city_skyline_illustration.dart';
import '../../../shared/widgets/voice_waveform.dart';
import 'widgets/live_facial_emotion_scanner_widget.dart';

class AssessmentSessionPage extends ConsumerStatefulWidget {
  const AssessmentSessionPage({super.key});

  @override
  ConsumerState<AssessmentSessionPage> createState() =>
      _AssessmentSessionPageState();
}

class _AssessmentSessionPageState extends ConsumerState<AssessmentSessionPage> {
  int _currentIndex = 0;
  final List<AssessmentQuestion> _questions = MockCarevoraData.cognitiveQuestions;

  // Speech and Voice
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initVoiceEngines();
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
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init fallback: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _readQuestionAloud() async {
    final currentQ = _questions[_currentIndex];
    await _flutterTts.speak(currentQ.audioPrompt);
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechEnabled) {
        setState(() {
          _isListening = true;
          _spokenText = '';
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
        });
      } else {
        // Fallback simulation
        setState(() {
          _isListening = true;
          _spokenText = 'Listening to response...';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isListening = false;
              _spokenText = 'Resident answered: "The year is 2025 and it is spring."';
            });
          }
        });
      }
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _spokenText = '';
        _isListening = false;
      });
    } else {
      _showEndAssessmentDialog();
    }
  }

  void _showEndAssessmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Assessment?'),
        content: const Text(
          'All 20 multimodal items have been completed. The system will calculate the updated cognitive risk score and archive the assessment session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: const Text('Confirm & Save Score'),
          ),
        ],
      ),
    );
  }

  void _showTipsDialog(String tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(LucideIcons.bot, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Assistant Protocol Tip'),
          ],
        ),
        content: Text(tip),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Back & Session Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.go('/dashboard'),
                child: Row(
                  children: const [
                    Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Back to overview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Live Session: Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.riskLow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Resident Session Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
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
                      child: const Text('JP',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mr. James Perera (ID: R001)', style: AppTextStyles.h4),
                        Text('Age 78 / Male / Room 105', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assessment Type', style: AppTextStyles.caption),
                        Text('Standard Cognitive Assessment',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session Started', style: AppTextStyles.caption),
                        Text('12 May 2025, 10:30 AM',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Assessment Body
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildQuestionCard(currentQ, progress),
                const SizedBox(height: 20),
                _buildSidebarOverview(currentQ),
              ],
            ),
            desktop: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildQuestionCard(currentQ, progress)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildSidebarOverview(currentQ)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion currentQ, double progress) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cognitive Assessment in Progress',
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${currentQ.id} of ${_questions.length} • Category: ${currentQ.category}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Large Lavender Question Panel
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lilac),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'QUESTION ${currentQ.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.volume2, color: AppColors.primary),
                      onPressed: _readQuestionAloud,
                      tooltip: 'Read question aloud',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentQ.prompt,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                const CitySkylineIllustration(height: 90),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Assistant Prompt Bubble
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySoft,
                  child: const Icon(LucideIcons.bot, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please take your time and answer clearly.',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real-time Facial Emotion Recognition AI Component
          const LiveFacialEmotionScannerWidget(),
          const SizedBox(height: 20),

          // Response & Waveform Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _isListening
                      ? 'Listening to response...'
                      : _spokenText.isNotEmpty
                          ? _spokenText
                          : 'Tap microphone to speak or capture verbal answer',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isListening ? AppColors.leafGreen : AppColors.muted,
                    fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16),
                VoiceWaveformWidget(isListening: _isListening),
                const SizedBox(height: 16),
                // Round Purple Mic Button
                FloatingActionButton(
                  onPressed: _toggleMic,
                  backgroundColor: _isListening ? AppColors.riskHigh : AppColors.primary,
                  elevation: 2,
                  child: Icon(
                    _isListening ? LucideIcons.micOff : LucideIcons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Action Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _readQuestionAloud,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.lilac),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Repeat Question'),
              ),
              ElevatedButton.icon(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: Text(
                  _currentIndex == _questions.length - 1
                      ? 'Complete Assessment'
                      : 'Next Question',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOverview(AssessmentQuestion currentQ) {
    return Column(
      children: [
        // Questions Overview Checklist
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Questions Overview', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final isDone = index < _currentIndex;
                    final isCurrent = index == _currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primarySoft
                            : isDone
                                ? AppColors.surfaceSecondary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : isCurrent
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isDone
                                ? AppColors.riskLow
                                : isCurrent
                                    ? AppColors.primary
                                    : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Q${q.id}. ${q.category}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? AppColors.primary : AppColors.body,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Assistant Tips Card
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
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primarySoft,
                    child: const Icon(LucideIcons.bot, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('AI Protocol Guide', style: AppTextStyles.h4.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                currentQ.tip,
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showTipsDialog(currentQ.tip),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: const Text('Show Tips', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // End Assessment Button
        OutlinedButton.icon(
          onPressed: _showEndAssessmentDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.riskHigh,
            side: const BorderSide(color: AppColors.riskHigh),
            minimumSize: const Size(double.infinity, 44),
          ),
          icon: const Icon(LucideIcons.xCircle, size: 16),
          label: const Text('End Assessment'),
        ),
      ],
    );
  }
}
