import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class HowItWorksSection extends StatelessWidget {
  final GlobalKey howKey;

  const HowItWorksSection({super.key, required this.howKey});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SectionContainer(
      sectionKey: howKey,
      backgroundColor: AppColors.page,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Operational Workflow',
            title: 'How Carevora Works',
            subtitle:
                'A streamlined 4-step clinical flow connecting resident conversation directly to proactive care plans.',
            isCentered: true,
          ),
          const SizedBox(height: 56),
          isMobile ? _buildMobileTimeline() : _buildDesktopTimeline(),
        ],
      ),
    );
  }

  Widget _buildDesktopTimeline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(LandingContent.steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Container(
              width: 32,
              height: 2,
              color: AppColors.lilac,
            ),
          );
        }
        final step = LandingContent.steps[index ~/ 2];
        return Expanded(
          child: _buildStepCard(step),
        );
      }),
    );
  }

  Widget _buildMobileTimeline() {
    return Column(
      children: LandingContent.steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildStepCard(step),
        );
      }).toList(),
    );
  }

  Widget _buildStepCard(HowItWorksStepData step) {
    return HoverCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(step.icon, color: AppColors.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            step.title,
            style: AppTextStyles.h4.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.5, color: AppColors.body),
          ),
        ],
      ),
    );
  }
}
