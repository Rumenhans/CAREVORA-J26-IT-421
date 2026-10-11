import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class SolutionSection extends StatelessWidget {
  final GlobalKey solutionKey;

  const SolutionSection({super.key, required this.solutionKey});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SectionContainer(
      sectionKey: solutionKey,
      backgroundColor: AppColors.page,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Clinical Intelligence',
            title: 'Our Multimodal Solution',
            subtitle:
                'Comprehensive clinical intelligence combining cognitive, emotional, and metabolic data.',
            isCentered: true,
          ),
          const SizedBox(height: 56),
          isMobile ? _buildMobileList() : _buildDesktopGrid(),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 2;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: LandingContent.solutions.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _buildSolutionCard(item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: LandingContent.solutions.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSolutionCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildSolutionCard(SolutionCardData item) {
    return HoverCard(
      padding: const EdgeInsets.all(28),
      hasTopPurpleAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  item.domainTag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Text(
                'Learn more',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
