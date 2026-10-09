import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/responsive/responsive.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../models/carevora_models.dart';

class CaregiverResidentDetailView extends StatelessWidget {
  final ResidentModel resident;

  const CaregiverResidentDetailView({super.key, required this.resident});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${resident.name} • Wellness Profile', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resident Header Profile Banner
            CarevoraCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      resident.name.substring(0, 2).toUpperCase(),
                      style: AppTypography.h1.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(resident.name, style: AppTypography.h1.copyWith(fontSize: 24)),
                            const SizedBox(width: 14),
                            StatusBadge(status: resident.currentStatus),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${resident.roomNumber} • ${resident.age} years old • Daily Monitored Resident',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          children: [
                            RiskBadge(riskLevel: resident.riskLevel),
                            TrajectoryBadge(trajectory: resident.trajectory),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // RALPA Trajectory Prediction Section (Front-end ready for AI/ML)
            _buildRalpaTrajectorySection(),
            const SizedBox(height: 24),

            // Explainable Contributing Factors (Decision-Support)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildContributingFactorsCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildCaregiverRecommendationsCard()),
                ],
              )
            else ...[
              _buildContributingFactorsCard(),
              const SizedBox(height: 20),
              _buildCaregiverRecommendationsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRalpaTrajectorySection() {
    return CarevoraCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RALPA Trajectory Prediction Model', style: AppTypography.h3),
                      Text('Risk-Aware Latent Progression Architecture (AI Model Interface)', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Confidence: 89%', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Trajectory Visualizer Timeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _timelineNode('Past 14 Days', 'Stable Baseline', Icons.check_circle_outline_rounded, AppColors.secondary),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.textTertiary, size: 20),
                    _timelineNode('Current Status', 'Slight Social Dip', Icons.info_outline_rounded, AppColors.warning),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.textTertiary, size: 20),
                    _timelineNode('Predicted (RALPA)', 'Positive Recovery', Icons.trending_up_rounded, AppColors.positive),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: Non-diagnostic caregiver decision support. Anticipates emotional trends based on multimodal behavioral inputs.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineNode(String title, String status, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
        Text(status, style: AppTypography.caption.copyWith(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _buildContributingFactorsCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explainable Risk Contributing Factors', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('Behavioral and acoustic inputs analyzed by multimodal pipeline', style: AppTypography.caption),
          const SizedBox(height: 20),

          _factorItem('Social Engagement Level', 0.82, 'Active participation noted during afternoon gardening.', AppColors.positive),
          const SizedBox(height: 14),
          _factorItem('Self-Reported Questionnaire', 0.85, 'Direct responses reflect tranquil baseline feelings.', AppColors.primary),
          const SizedBox(height: 14),
          _factorItem('Vocal Acoustic Modulation', 0.76, 'Steady speech rhythm and warm cadence detected.', AppColors.secondary),
          const SizedBox(height: 14),
          _factorItem('Facial Affect Alignment', 0.88, 'Gentle resting facial composure with positive expressions.', AppColors.positive),
        ],
      ),
    );
  }

  Widget _factorItem(String title, double score, String desc, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            Text('${(score * 100).toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(desc, style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCaregiverRecommendationsCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proactive Caregiver Interventions', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('AI-assisted decision-support suggestions', style: AppTypography.caption),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Afternoon Courtyard Walk', style: AppTypography.label.copyWith(fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Suggested', style: AppTypography.caption.copyWith(color: AppColors.positive, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Encourage a 15-minute garden stroll to sustain positive emotional trajectory and daylight exposure.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Assign to Staff Schedule', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
