import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/buttons/carevora_button.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../models/carevora_models.dart';
import '../resident_main_view.dart';

class AssessmentResultView extends StatelessWidget {
  final WellnessResultModel result;

  const AssessmentResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Wellness Check'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration / Status Card
              CarevoraCard(
                padding: const EdgeInsets.all(28),
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.positive.withValues(alpha: 0.2), width: 3),
                      ),
                      child: const Icon(
                        Icons.sentiment_very_satisfied_rounded,
                        color: AppColors.positive,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StatusBadge(status: result.status),
                    const SizedBox(height: 16),
                    Text(
                      '${result.overallScore.toInt()}%',
                      style: AppTypography.display.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Overall Wellness Index',
                      style: AppTypography.caption.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        result.encouragingMessage,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown Cards
              Text('Wellness Focus Areas', style: AppTypography.h2.copyWith(fontSize: 19)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _pillarCard(
                      'Emotional Harmony',
                      '${result.emotionalScore.toInt()}%',
                      Icons.spa_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _pillarCard(
                      'Social Wellness',
                      '${result.socialScore.toInt()}%',
                      Icons.diversity_3_rounded,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recommendations Section
              if (result.recommendations.isNotEmpty) ...[
                Text('Personalized Suggestions for You', style: AppTypography.h2.copyWith(fontSize: 19)),
                const SizedBox(height: 12),
                ...result.recommendations.map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CarevoraCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec.title, style: AppTypography.h3.copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(rec.suggestedAction, style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              CarevoraButton(
                text: 'Return to Home',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentMainView()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillarCard(String title, String score, IconData icon, Color color) {
    return CarevoraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(score, style: AppTypography.h1.copyWith(fontSize: 24, color: color)),
          const SizedBox(height: 2),
          Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
