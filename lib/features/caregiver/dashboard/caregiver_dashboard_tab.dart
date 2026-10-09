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

class CaregiverDashboardTab extends ConsumerWidget {
  const CaregiverDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentsAsync = ref.watch(residentsProvider);
    final alertsAsync = ref.watch(alertsListProvider);
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning, Dr. Vance', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text(
                    'Emotional & Social Wellness Summary for Meadowbrook Senior Living',
                    style: AppTypography.body,
                  ),
                ],
              ),
              if (isDesktop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Today • Live Monitoring', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metricCard('Total Monitored', '42 Residents', '100% Active coverage', Icons.people_outline_rounded, AppColors.primary, cardWidth),
                  _metricCard('Needs Attention', '6 Residents', 'Increased risk / check required', Icons.warning_amber_rounded, AppColors.warning, cardWidth),
                  _metricCard('Stable Wellness', '29 Residents', 'Consistent mood scores', Icons.sentiment_satisfied_rounded, AppColors.secondary, cardWidth),
                  _metricCard('Positive Trajectory', '7 Residents', 'Improving social index', Icons.trending_up_rounded, AppColors.positive, cardWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Main Visualizations & Highlights
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildWellnessTrendChartCard()),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: _buildRiskDistributionCard()),
              ],
            )
          else ...[
            _buildWellnessTrendChartCard(),
            const SizedBox(height: 20),
            _buildRiskDistributionCard(),
          ],

          const SizedBox(height: 28),

          // Recent Alerts & Recent Assessments
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildRecentAssessmentsCard(residentsAsync, context, ref)),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: _buildActiveAlertsCard(alertsAsync)),
              ],
            )
          else ...[
            _buildRecentAssessmentsCard(residentsAsync, context, ref),
            const SizedBox(height: 20),
            _buildActiveAlertsCard(alertsAsync),
          ],
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, String subtitle, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: CarevoraCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.h2.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessTrendChartCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facility Emotional Wellness Trajectory', style: AppTypography.h3),
                  const SizedBox(height: 2),
                  Text('Average aggregate wellness index over past 7 days', style: AppTypography.caption),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.positiveSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+4.2% this week', style: AppTypography.caption.copyWith(color: AppColors.positive, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Interactive-styled chart representation
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _barColumn('Mon', 74, 68),
                _barColumn('Tue', 76, 70),
                _barColumn('Wed', 72, 73),
                _barColumn('Thu', 79, 75),
                _barColumn('Fri', 81, 78),
                _barColumn('Sat', 84, 82),
                _barColumn('Sun (Today)', 86, 84, isToday: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.primary, 'Emotional Wellness'),
              const SizedBox(width: 24),
              _legendItem(AppColors.secondary, 'Social Engagement'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barColumn(String day, double emotional, double social, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 14,
              height: (emotional / 100) * 140,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 14,
              height: (social / 100) * 140,
              decoration: BoxDecoration(
                color: isToday ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: AppTypography.caption.copyWith(
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildRiskDistributionCard() {
    return CarevoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Level Distribution', style: AppTypography.h3),
          const SizedBox(height: 2),
          Text('RALPA trajectory status grouping', style: AppTypography.caption),
          const SizedBox(height: 24),

          // Donut visual representation
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.69, // 29 out of 42
                    strokeWidth: 16,
                    backgroundColor: AppColors.surfaceSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.positive),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('69%', style: AppTypography.h1.copyWith(fontSize: 26)),
                    Text('Low Risk', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _distributionRow('Low Risk (Stable/Improving)', '29 residents', AppColors.positive),
          const SizedBox(height: 8),
          _distributionRow('Moderate Risk (Under observation)', '7 residents', AppColors.warning),
          const SizedBox(height: 8),
          _distributionRow('High Priority / Intervention', '6 residents', AppColors.critical),
        ],
      ),
    );
  }

  Widget _distributionRow(String label, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTypography.caption)),
        Text(count, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildRecentAssessmentsCard(AsyncValue residentsAsync, BuildContext context, WidgetRef ref) {
    return CarevoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Resident Assessments', style: AppTypography.h3),
              Text('View all', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          residentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading residents: $e'),
            data: (residents) {
              return Column(
                children: (residents as List).take(3).map((res) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(res.name.substring(0, 2).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(res.name, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${res.roomNumber} • Score: ${res.emotionalScore.toInt()}%', style: AppTypography.caption),
                    trailing: StatusBadge(status: res.currentStatus),
                    onTap: () {
                      ref.read(selectedResidentIdProvider.notifier).select(res.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CaregiverResidentDetailView(resident: res)),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsCard(AsyncValue alertsAsync) {
    return CarevoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Urgent Attention Alerts', style: AppTypography.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.criticalSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('2 Critical', style: AppTypography.caption.copyWith(color: AppColors.critical, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          alertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading alerts: $e'),
            data: (alerts) {
              return Column(
                children: (alerts as List).map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          alert.priority == AlertPriority.high ? Icons.warning_rounded : Icons.info_outline_rounded,
                          color: alert.priority == AlertPriority.high ? AppColors.critical : AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert.title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(alert.message, style: AppTypography.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
