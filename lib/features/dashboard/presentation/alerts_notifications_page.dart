import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';

class AlertsNotificationsPage extends StatefulWidget {
  const AlertsNotificationsPage({super.key});

  @override
  State<AlertsNotificationsPage> createState() => _AlertsNotificationsPageState();
}

class _AlertsNotificationsPageState extends State<AlertsNotificationsPage> {
  String _selectedFilter = 'All';
  final Set<String> _acknowledgedAlertIds = {};

  @override
  Widget build(BuildContext context) {
    final alerts = MockCarevoraData.alerts;
    final filteredAlerts = alerts.where((a) {
      if (_selectedFilter == 'Urgent & High') {
        return a.severity.toLowerCase() == 'high' || a.title.contains('Urgent') || a.title.contains('Doctor');
      } else if (_selectedFilter == 'Caregiver Dispatches') {
        return a.title.contains('Caregiver') || a.title.contains('Doctor');
      }
      return true;
    }).toList();

    final urgentCount = alerts.where((a) => a.severity.toLowerCase() == 'high' || a.title.contains('Urgent')).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.bellRing, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerts & Clinical Notifications', style: AppTextStyles.h2),
                      const SizedBox(height: 3),
                      const Text(
                        'Real-time resident alerts, emergency doctor calls, and caregiver dispatch logs',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: urgentCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: urgentCount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      urgentCount > 0 ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
                      size: 16,
                      color: urgentCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      urgentCount > 0 ? '$urgentCount Urgent Care Attention Required' : 'All Residents Stable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: urgentCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Metrics Row
          Row(
            children: [
              _buildMetricCard(
                title: 'Total Active Alerts',
                value: '${alerts.length}',
                subtitle: 'Logged across care facility',
                icon: LucideIcons.bell,
                color: AppColors.primary,
                bgColor: AppColors.primarySoft,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                title: 'Urgent Dispatch Requests',
                value: '$urgentCount',
                subtitle: 'Immediate doctor or caregiver calls',
                icon: LucideIcons.heartPulse,
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEE2E2),
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                title: 'Assigned Staff',
                value: 'Nurse Seetha N. (RN)',
                subtitle: 'Room 101 On-duty Attendant',
                icon: LucideIcons.userCheck,
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              _buildFilterChip('All', alerts.length),
              const SizedBox(width: 8),
              _buildFilterChip('Urgent & High', urgentCount),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Caregiver Dispatches',
                alerts.where((a) => a.title.contains('Caregiver') || a.title.contains('Doctor')).length,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Alerts List
          if (filteredAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('No alerts found for this filter.', style: TextStyle(color: AppColors.muted)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAlerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = filteredAlerts[index];
                final isUrgent = alert.severity.toLowerCase() == 'high' || alert.title.contains('Urgent');
                final isAcknowledged = _acknowledgedAlertIds.contains(alert.id);

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isUrgent ? const Color(0xFFFFF7F7) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUrgent ? const Color(0xFFFECACA) : AppColors.border,
                      width: isUrgent ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUrgent ? const Color(0xFFFEE2E2) : AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUrgent ? LucideIcons.bellRing : LucideIcons.info,
                          color: isUrgent ? const Color(0xFFDC2626) : AppColors.primary,
                          size: 20,
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
                                Row(
                                  children: [
                                    Text(
                                      alert.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isUrgent ? const Color(0xFF991B1B) : AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isUrgent ? const Color(0xFFDC2626) : AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        alert.severity.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  alert.timestamp,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              alert.description,
                              style: const TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
                            ),
                            if (isUrgent) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(LucideIcons.userCheck, size: 14, color: Color(0xFFDC2626)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Assigned Caregiver: Nurse Seetha N. (RN) Dispatched',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (isAcknowledged) {
                              _acknowledgedAlertIds.remove(alert.id);
                            } else {
                              _acknowledgedAlertIds.add(alert.id);
                            }
                          });
                        },
                        icon: Icon(
                          isAcknowledged ? LucideIcons.checkCheck : LucideIcons.check,
                          size: 14,
                        ),
                        label: Text(
                          isAcknowledged ? 'Attended (සලකා බැලුණි)' : 'Acknowledge (තහවුරු කරන්න)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAcknowledged ? const Color(0xFF16A34A) : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.body), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.body,
      ),
    );
  }
}
