import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/responsive/responsive.dart';
import '../../../components/cards/carevora_card.dart';

class CaregiverAnalyticsTab extends StatelessWidget {
  const CaregiverAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wellness Analytics & Longitudinal Trends', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Comparative cohort analysis and seasonal social engagement patterns', style: AppTypography.body),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating Care Quality Report PDF...')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Summary Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(180, 42),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildCohortPerformanceCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildMultimodalCoverageCard()),
                ],
              )
            else ...[
              _buildCohortPerformanceCard(),
              const SizedBox(height: 20),
              _buildMultimodalCoverageCard(),
            ],

            const SizedBox(height: 24),
            _buildInterventionOutcomeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortPerformanceCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Emotional Trajectory by Wing', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('Average baseline progression across residential suites', style: AppTypography.caption),
          const SizedBox(height: 28),

          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _barWing('North Wing (Suite 100s)', 0.82, AppColors.primary),
                _barWing('East Garden (Suite 200s)', 0.88, AppColors.positive),
                _barWing('South Parlor (Suite 300s)', 0.74, AppColors.secondary),
                _barWing('West Haven (Suite 400s)', 0.65, AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'East Garden shows the highest social cohesion this month (+6%).',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.positive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barWing(String label, double ratio, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 44,
          height: 140 * ratio,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(ratio * 100).toInt()}%',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMultimodalCoverageCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Multimodal Input Compliance', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('Percentage of data captured for AI inference', style: AppTypography.caption),
          const SizedBox(height: 20),

          _coverageRow('Questionnaire Completion', '96%', AppColors.positive),
          const SizedBox(height: 12),
          _coverageRow('Facial Affect Samples', '84%', AppColors.primary),
          const SizedBox(height: 12),
          _coverageRow('Voice Modulation Check-ins', '78%', AppColors.secondary),
          const SizedBox(height: 12),
          _coverageRow('Group Activity Interaction Logs', '91%', AppColors.positive),
        ],
      ),
    );
  }

  Widget _coverageRow(String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.bodySmall),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(val, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  Widget _buildInterventionOutcomeCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caregiver Intervention Response Rate', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('Observed resolution time following early trajectory warnings', style: AppTypography.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('Average Resolution', '1.8 Days', Icons.speed_rounded, AppColors.primary),
              const SizedBox(width: 16),
              _statBox('Early Preventative Interventions', '24 This Month', Icons.verified_user_rounded, AppColors.positive),
              const SizedBox(width: 16),
              _statBox('Resident Satisfaction', '94% Positive', Icons.sentiment_very_satisfied_rounded, AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.h3.copyWith(fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(title, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
