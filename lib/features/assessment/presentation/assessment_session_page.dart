import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';

class AssessmentSessionPage extends StatefulWidget {
  const AssessmentSessionPage({super.key});

  @override
  State<AssessmentSessionPage> createState() => _AssessmentSessionPageState();
}

class _AssessmentSessionPageState extends State<AssessmentSessionPage> {
  final Resident _resident = MockCarevoraData.defaultResident;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Navigation Back Button & Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.go('/dashboard'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Back to Overview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lilac),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.sparkles, size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Cognitive Workspace Ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Resident Context Header Banner
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
                      child: const Text(
                        'JP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_resident.name} (ID: ${_resident.id})',
                          style: AppTextStyles.h4,
                        ),
                        Text(
                          'Age ${_resident.age} / ${_resident.gender} / Room ${_resident.roomNo}',
                          style: AppTextStyles.caption,
                        ),
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
                        Text('Current Cognitive Score', style: AppTextStyles.caption),
                        Text(
                          '${_resident.cognitiveScore.toInt()} / 100',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facility Assigned', style: AppTextStyles.caption),
                        Text('Maple Wood Care Home', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Clean Placeholder Central Workspace
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lilac, width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.brain,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cognitive Assessment Dashboard',
                  style: AppTextStyles.h2.copyWith(color: AppColors.navy),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'All previous mock questions, voice recording pipelines, and facial recognition scanners have been cleared. This workspace is ready for your custom Cognitive Assessment models, tasks, and telemetry integrations.',
                    style: AppTextStyles.body.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.layoutDashboard, size: 16),
                      label: const Text(
                        'Return to Dashboard',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/dashboard/residents'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.lilac),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.users, size: 16),
                      label: const Text(
                        'View Resident Directory',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Clean Module Integration Slots (Skeletons for upcoming features)
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildModuleSlotCard(
                  icon: LucideIcons.puzzle,
                  title: 'Cognitive Task Engine',
                  description: 'Slot reserved for memory recall, executive function, and spatial tasks.',
                ),
                const SizedBox(height: 16),
                _buildModuleSlotCard(
                  icon: LucideIcons.activity,
                  title: 'Neuro-Telemetry Stream',
                  description: 'Slot reserved for reaction latency, decision times, and focus metrics.',
                ),
                const SizedBox(height: 16),
                _buildModuleSlotCard(
                  icon: LucideIcons.fileSpreadsheet,
                  title: 'MMSE / MoCA Clinical Logs',
                  description: 'Slot reserved for standardized clinical cognitive score summaries.',
                ),
              ],
            ),
            desktop: (context) => Row(
              children: [
                Expanded(
                  child: _buildModuleSlotCard(
                    icon: LucideIcons.puzzle,
                    title: 'Cognitive Task Engine',
                    description: 'Slot reserved for memory recall, executive function, and spatial tasks.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModuleSlotCard(
                    icon: LucideIcons.activity,
                    title: 'Neuro-Telemetry Stream',
                    description: 'Slot reserved for reaction latency, decision times, and focus metrics.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModuleSlotCard(
                    icon: LucideIcons.fileSpreadsheet,
                    title: 'MMSE / MoCA Clinical Logs',
                    description: 'Slot reserved for standardized clinical cognitive score summaries.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSlotCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Ready to connect',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
