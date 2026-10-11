import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class WhyCarevoraSection extends StatelessWidget {
  const WhyCarevoraSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SectionContainer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Clinical Governance & Trust',
            title: 'Why Care Homes Trust Carevora',
            subtitle:
                'Built in collaboration with geriatric clinicians to uphold patient confidentiality, scientific rigor, and senior dignity.',
            isCentered: true,
          ),
          const SizedBox(height: 56),
          isMobile ? _buildMobileList() : _buildDesktopRow(),
        ],
      ),
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: LandingContent.whyCarevora.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: LandingContent.whyCarevora.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return HoverCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            item['title'] as String,
            style: AppTextStyles.h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            item['desc'] as String,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
