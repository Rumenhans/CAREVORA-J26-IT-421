import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/buttons/carevora_button.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../core/providers/app_providers.dart';
import 'assessment_result_view.dart';

class AssessmentFlowView extends ConsumerStatefulWidget {
  const AssessmentFlowView({super.key});

  @override
  ConsumerState<AssessmentFlowView> createState() => _AssessmentFlowViewState();
}

class _AssessmentFlowViewState extends ConsumerState<AssessmentFlowView> {
  int _currentStep = 0; // 0: questionnaire, 1: facial check preview, 2: voice check preview
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _facialCheckEnabled = true;
  final bool _voiceCheckEnabled = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(assessmentQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'Daily Wellness Check'
              : (_currentStep == 1 ? 'Facial Expression Check' : 'Voice Tone Check'),
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else if (_currentQuestionIndex > 0) {
              setState(() => _currentQuestionIndex--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading assessment: $err')),
          data: (questions) {
            final totalSteps = questions.length + 2; // Questions + Facial + Voice
            final currentProgress = (_currentStep == 0 ? _currentQuestionIndex + 1 : questions.length + _currentStep) / totalSteps;

            return Column(
              children: [
                // Clean Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentStep == 0
                                ? 'Question ${_currentQuestionIndex + 1} of ${questions.length}'
                                : (_currentStep == 1 ? 'Step 2: Facial Check' : 'Step 3: Vocal Check'),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${(currentProgress * 100).toInt()}% completed',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: currentProgress,
                          backgroundColor: AppColors.surfaceSecondary,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _currentStep == 0
                        ? _buildQuestionnaireStep(questions)
                        : (_currentStep == 1 ? _buildFacialCheckStep() : _buildVoiceCheckStep(questions)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionnaireStep(List dynamicQuestions) {
    final currentQ = dynamicQuestions[_currentQuestionIndex];
    final selectedOption = _selectedAnswers[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarevoraCard(
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentQ.category.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentQ.question,
                style: AppTypography.h1.copyWith(fontSize: 22, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Accessible Large Answer Choices
        ...List.generate(currentQ.options.length, (index) {
          final isSelected = selectedOption == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAnswers[_currentQuestionIndex] = index;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentQ.options[index],
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        CarevoraButton(
          text: _currentQuestionIndex < dynamicQuestions.length - 1 ? 'Next Question' : 'Continue to Expression Check',
          onPressed: selectedOption != null
              ? () {
                  if (_currentQuestionIndex < dynamicQuestions.length - 1) {
                    setState(() => _currentQuestionIndex++);
                  } else {
                    setState(() => _currentStep = 1);
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildFacialCheckStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarevoraCard(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.face_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Gentle Expression Check',
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s take a brief resting moment. Look calmly at the camera for a couple seconds.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: 24),

              // Camera UI Placeholder (Clean representation prepared for AI)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_rounded, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 10),
                        Text(
                          'Front Camera Preview Ready',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(Ready for Multimodal Emotion AI Integration)',
                          style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.positiveSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.positive),
                            const SizedBox(width: 6),
                            Text(
                              'Lighting is gentle & clear',
                              style: AppTypography.caption.copyWith(color: AppColors.positive, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CarevoraButton(
          text: 'Continue to Voice Check',
          onPressed: () {
            setState(() => _currentStep = 2);
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _facialCheckEnabled = false;
              _currentStep = 2;
            });
          },
          child: Text('Skip facial check', style: AppTypography.bodySmall),
        ),
      ],
    );
  }

  Widget _buildVoiceCheckStep(List dynamicQuestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarevoraCard(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mic_rounded, size: 40, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Voice & Tone Moment',
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Say a quick greeting or share one thing you are looking forward to today.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: 24),

              // Audio Recording Preview Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(12, (index) {
                        final heights = [14.0, 26.0, 42.0, 30.0, 50.0, 22.0, 44.0, 36.0, 24.0, 48.0, 28.0, 16.0];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 4,
                          height: heights[index],
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"I\'m looking forward to reading in the sunshine today."',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '(Audio sample captured • Ready for Vocal Affect Analysis)',
                      style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CarevoraButton(
          text: 'Complete My Wellness Check',
          isLoading: _isSubmitting,
          onPressed: () async {
            setState(() => _isSubmitting = true);
            final service = ref.read(apiServiceProvider);
            final answersList = List.generate(dynamicQuestions.length, (i) => _selectedAnswers[i] ?? 0);
            
            final result = await service.submitAssessment(
              residentId: 'res_01',
              answers: answersList,
              includeFacialCheck: _facialCheckEnabled,
              includeVoiceCheck: _voiceCheckEnabled,
            );

            ref.read(latestWellnessResultProvider.notifier).setResult(result);
            if (!mounted) return;
            setState(() => _isSubmitting = false);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AssessmentResultView(result: result)),
            );
          },
        ),
      ],
    );
  }
}
