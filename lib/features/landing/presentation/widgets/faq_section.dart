import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: Colors.white,
      maxWidth: 900,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Frequently Asked Questions',
            title: 'Everything You Need to Know',
            subtitle:
                'Clear answers on how Carevora supports caregivers, protects resident data, and ensures medical safety.',
            isCentered: true,
          ),
          const SizedBox(height: 48),
          ...LandingContent.faqs.map((faq) => _buildFaqItem(faq)),
          const SizedBox(height: 32),
          // Clinical Non-Diagnostic Disclaimer Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lilac),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    LandingContent.clinicalDisclaimer,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(FaqItemData faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.muted,
        title: Text(
          faq.question,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Text(
            faq.answer,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
