import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';
import '../../assessment/application/cognitive_assessment_service.dart';
import '../../auth/application/auth_controller.dart';

class AlertsNotificationsPage extends ConsumerStatefulWidget {
  const AlertsNotificationsPage({super.key});

  @override
  ConsumerState<AlertsNotificationsPage> createState() => _AlertsNotificationsPageState();
}

class _AlertsNotificationsPageState extends ConsumerState<AlertsNotificationsPage> {
  String _selectedFilter = 'All';
  final Set<String> _acknowledgedAlertIds = {};
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCognitiveAlerts();
    });
  }

  Future<void> _syncCognitiveAlerts() async {
    if (_hasSynced) return;
    _hasSynced = true;
    try {
      final authState = ref.read(authProvider).state;
      if (authState.isElder) return;

      final residents = await CognitiveAssessmentService.fetchResidents(token: authState.token);
      if (residents.isEmpty) return;

      for (final res in residents) {
        final history = await CognitiveAssessmentService.fetchHistory(
          residentId: res.id,
          token: authState.token,
        );
        if (history.isEmpty) continue;

        final latest = history.first;
        final bool isHighRisk =
            (latest.riskLevel?.toLowerCase().contains('high') ?? false) ||
            (latest.mlPrediction?.toLowerCase().contains('high') ?? false) ||
            (latest.alertTriggered == true) ||
            (latest.acrfScore != null && latest.acrfScore! < 50.0);

        MockCarevoraData.alerts.removeWhere((a) =>
            a.id.startsWith('ALT-COG') &&
            (a.residentName == res.name || a.residentName == latest.residentName));

        if (isHighRisk) {
          final scoreVal = latest.acrfScore ?? 0.0;
          final scoreText = '${scoreVal.toStringAsFixed(1)}/100';
          final roomNo = res.roomNumber.isNotEmpty ? res.roomNumber : '105';
          final resName = res.name.isNotEmpty ? res.name : latest.residentName;

          String formattedTime = 'Recent Assessment';
          if (latest.createdAt != null && latest.createdAt!.isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(latest.createdAt!);
              formattedTime = 'Today, ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
            } catch (_) {
              formattedTime = latest.createdAt!;
            }
          }

          MockCarevoraData.alerts.insert(
            0,
            AlertItem(
              id: 'ALT-COG-REAL-${res.id}-${latest.id}',
              title: 'High Cognitive Impairment Risk: $resName',
              description:
                  'Cognitive assessment score ($scoreText) indicates acute cognitive decline risk for $resName in room $roomNo. Urgent caregiver review and clinical attention required.',
              severity: 'High',
              timestamp: formattedTime,
              residentName: resName,
              roomNo: roomNo,
              residentAge: res.age,
              residentGender: res.gender,
              currentStatus: 'High Cognitive Risk',
              cognitiveScore: scoreVal,
            ),
          );
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).state;

    // Clinical alerts and facility notifications are restricted to caregivers and staff
    if (authState.isElder) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Clinical Alerts are Staff-Only',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alerts and clinical notifications are managed by caregivers and medical attendants.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Return to Overview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final caregiverName = (authState.userName != null && authState.userName!.isNotEmpty)
        ? authState.userName!
        : 'Pasidi Sarangi';
    final careHomeName = (authState.elderHomeName != null && authState.elderHomeName!.isNotEmpty)
        ? authState.elderHomeName!
        : 'Serenity Elder Home';

    final alerts = MockCarevoraData.alerts;
    final filteredAlerts = alerts.where((a) {
      if (_selectedFilter == 'Urgent & High') {
        return a.severity.toLowerCase() == 'high' || a.title.contains('Urgent') || a.title.contains('Doctor');
      } else if (_selectedFilter == 'Caregiver Dispatches') {
        return a.title.contains('Caregiver') || a.title.contains('Doctor') || a.severity.toLowerCase() == 'high';
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
                value: caregiverName,
                subtitle: '$careHomeName On-duty Caregiver',
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
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                            if (alert.residentName != null || alert.roomNo != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (alert.residentName != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.user, size: 13, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            alert.residentName!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                                          ),
                                        ],
                                      ),
                                    if (alert.roomNo != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.doorClosed, size: 13, color: AppColors.muted),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Room ${alert.roomNo}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.body),
                                          ),
                                        ],
                                      ),
                                    if (alert.residentAge != null)
                                      Text(
                                        'Age: ${alert.residentAge}${alert.residentGender != null ? ' (${alert.residentGender})' : ''}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    if (alert.currentStatus != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: alert.currentStatus!.toLowerCase().contains('high')
                                              ? const Color(0xFFFEE2E2)
                                              : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          alert.currentStatus!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: alert.currentStatus!.toLowerCase().contains('high')
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    if (alert.cognitiveScore != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.lavenderBg,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.lilac),
                                        ),
                                        child: Text(
                                          'Cognitive Score: ${alert.cognitiveScore!.toStringAsFixed(1)} / 100',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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
                                  children: [
                                    const Icon(LucideIcons.userCheck, size: 14, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Assigned Caregiver: $caregiverName Dispatched',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
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
