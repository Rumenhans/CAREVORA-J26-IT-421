import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/risk_utils.dart';
import '../../data/models/carevora_models.dart';
import 'risk_badge.dart';

class RecentAssessmentsTable extends StatelessWidget {
  final List<AssessmentRecord> records;
  final Function(AssessmentRecord record)? onSelectRecord;
  final VoidCallback? onViewAll;

  const RecentAssessmentsTable({
    super.key,
    required this.records,
    this.onSelectRecord,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Assessments', style: AppTextStyles.h4),
                    const SizedBox(height: 2),
                    Text('Historical multimodal wellness & risk scores',
                        style: AppTextStyles.caption),
                  ],
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text('View All Assessments →',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppColors.surfaceSecondary),
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(
                          label: Text('Date & Time',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Cognitive',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Emotional',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Metabolic',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Overall Risk',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Assessed By',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Action',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: records.map((record) {
                      return DataRow(
                        cells: [
                          DataCell(Text(record.dateTime,
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13))),
                          DataCell(RiskBadge(
                            score: record.cognitiveScore,
                            customLabel:
                                '${RiskUtils.getTier(record.cognitiveScore).label} (${record.cognitiveScore.toStringAsFixed(2)})',
                          )),
                          DataCell(RiskBadge(
                            score: record.emotionalScore,
                            customLabel:
                                '${RiskUtils.getTier(record.emotionalScore).label} (${record.emotionalScore.toStringAsFixed(2)})',
                          )),
                          DataCell(RiskBadge(
                            score: record.metabolicScore,
                            customLabel:
                                '${RiskUtils.getTier(record.metabolicScore).label} (${record.metabolicScore.toStringAsFixed(2)})',
                          )),
                          DataCell(RiskBadge(
                            score: record.overallRiskScore,
                            customLabel:
                                '${RiskUtils.getTier(record.overallRiskScore).label} (${record.overallRiskScore.toStringAsFixed(2)})',
                          )),
                          DataCell(Text(record.assessedBy,
                              style: AppTextStyles.bodySmall)),
                          DataCell(
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.lilac),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => onSelectRecord?.call(record),
                              child: const Text('Details',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Showing last ${records.length} assessments',
                    style: AppTextStyles.caption),
                TextButton(
                  onPressed: onViewAll,
                  child: Text('View All Assessments →',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
