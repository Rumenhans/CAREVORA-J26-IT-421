import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/enums.dart';

class CaregiverAlertsTab extends ConsumerWidget {
  const CaregiverAlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsListProvider);

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
                    Text('Alert Center & Recommended Actions', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Automated alerts from multimodal sensors and daily check-ins', style: AppTypography.body),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All alerts marked as read.')),
                    );
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all as read'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading alerts: $e'),
              data: (alerts) {
                return Column(
                  children: alerts.map((alert) {
                    final isHigh = alert.priority == AlertPriority.high;
                    final isMed = alert.priority == AlertPriority.medium;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CarevoraCard(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: alert.isRead ? Colors.white : (isHigh ? AppColors.criticalSoft.withOpacity(0.25) : AppColors.surfaceSecondary),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isHigh
                                    ? AppColors.criticalSoft
                                    : (isMed ? AppColors.warningSoft : AppColors.primarySoft),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isHigh ? Icons.warning_rounded : (isMed ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded),
                                color: isHigh ? AppColors.critical : (isMed ? AppColors.warning : AppColors.primary),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(alert.residentName, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      Text(
                                        '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(alert.title, style: AppTypography.h3.copyWith(fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text(alert.message, style: AppTypography.bodySmall),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Action initiated for ${alert.residentName}')),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isHigh ? AppColors.critical : AppColors.primary,
                                          minimumSize: const Size(120, 34),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Take Action', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(100, 34),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
