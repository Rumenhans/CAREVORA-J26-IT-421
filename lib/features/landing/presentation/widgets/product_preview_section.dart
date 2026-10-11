import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/score_card.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class ProductPreviewSection extends StatelessWidget {
  const ProductPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Interactive Dashboard Preview',
            title: 'See Risk Clearly, Act Early',
            subtitle:
                'Caregivers receive immediate longitudinal indicators synthesized from cognitive, affective, and metabolic streams.',
            isCentered: true,
          ),
          const SizedBox(height: 56),
          _buildTabletMockup(context),
        ],
      ),
    );
  }

  Widget _buildTabletMockup(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Browser mockup top bar
          Row(
            children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_rounded, size: 12, color: AppColors.riskLow),
                      SizedBox(width: 6),
                      Text('carevora.app/dashboard/overview', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Embedded Live Score Cards
          isMobile
              ? Column(
                  children: const [
                    ScoreCard(title: 'Cognitive Health', score: 0.64, delta: 0.08),
                    SizedBox(height: 12),
                    ScoreCard(title: 'Emotional Wellness', score: 0.78, delta: 0.12),
                    SizedBox(height: 12),
                    ScoreCard(title: 'Metabolic Health', score: 0.56, delta: 0.04),
                    SizedBox(height: 12),
                    ScoreCard(title: 'Overall Wellness Index', score: 0.62, delta: 0.06, isGauge: true),
                  ],
                )
              : Row(
                  children: const [
                    Expanded(child: ScoreCard(title: 'Cognitive Health', score: 0.64, delta: 0.08)),
                    SizedBox(width: 12),
                    Expanded(child: ScoreCard(title: 'Emotional Wellness', score: 0.78, delta: 0.12)),
                    SizedBox(width: 12),
                    Expanded(child: ScoreCard(title: 'Metabolic Health', score: 0.56, delta: 0.04)),
                    SizedBox(width: 12),
                    Expanded(child: ScoreCard(title: 'Overall Wellness Index', score: 0.62, delta: 0.06, isGauge: true)),
                  ],
                ),
          const SizedBox(height: 24),
          // 3 Feature Callout Chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildCalloutChip('Explainable Risk Factors', Icons.insights_rounded),
              _buildCalloutChip('Longitudinal Trend Telemetry', Icons.timeline_rounded),
              _buildCalloutChip('Smart Clinical Alerts', Icons.notifications_active_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.navy)),
        ],
      ),
    );
  }
}
