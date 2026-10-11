import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';

class FeatureStrip extends StatelessWidget {
  const FeatureStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Transform.translate(
      offset: Offset(0, isMobile ? -30 : -50),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
            child: isMobile
                ? _buildMobileCarousel()
                : _buildDesktopGrid(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return Row(
      children: LandingContent.features.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCarousel() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LandingContent.features.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = LandingContent.features[index];
          return SizedBox(
            width: 260,
            child: _buildCard(item),
          );
        },
      ),
    );
  }

  Widget _buildCard(FeatureItemData item) {
    return HoverCard(
      padding: const EdgeInsets.all(22),
      hasTopPurpleAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: AppTextStyles.h4.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              height: 1.5,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}
