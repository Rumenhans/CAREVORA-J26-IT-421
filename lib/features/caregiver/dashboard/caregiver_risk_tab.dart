import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/responsive/responsive.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../core/providers/app_providers.dart';
import '../residents/caregiver_resident_detail_view.dart';
import '../../../models/enums.dart';

class CaregiverRiskTab extends ConsumerWidget {
  const CaregiverRiskTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentsAsync = ref.watch(residentsProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Concept Note
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk Prediction & Trajectory (RALPA)', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text(
                      'AI-based risk progression modeling for timely preventative care',
                      style: AppTypography.body,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('RALPA Engine Active', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Methodology explainer card
            CarevoraCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About RALPA (Risk-Aware Latent Progression Architecture)', style: AppTypography.h3.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'RALPA observes multi-modal cues (voice intonation, facial affect, and daily activity logs) over rolling windows to forecast emotional trajectory before clinical symptoms become acute.',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Priority Action List
            Text('Residents Requiring Wellness Attention', style: AppTypography.h2.copyWith(fontSize: 19)),
            const SizedBox(height: 12),

            residentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (residents) {
                final attentionResidents = residents.where(
                  (r) => r.riskLevel != RiskLevel.low,
                ).toList();

                return Column(
                  children: attentionResidents.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CarevoraCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: r.riskLevel == RiskLevel.high ? AppColors.criticalSoft : AppColors.warningSoft,
                              child: Text(
                                r.name.substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: r.riskLevel == RiskLevel.high ? AppColors.critical : AppColors.warning,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(r.name, style: AppTypography.h3),
                                      const SizedBox(width: 10),
                                      RiskBadge(riskLevel: r.riskLevel),
                                      const SizedBox(width: 8),
                                      TrajectoryBadge(trajectory: r.trajectory),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.roomNumber} • Observed decrease in social dining participation over past 48 hours.',
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop) ...[
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(selectedResidentIdProvider.notifier).select(r.id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CaregiverResidentDetailView(resident: r)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(140, 40),
                                ),
                                child: const Text('Examine Factors'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
