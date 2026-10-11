import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/caregiver_hands_illustration.dart';
import '../../data/landing_content.dart';
import 'common/photo_frame.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class AboutSection extends StatelessWidget {
  final GlobalKey aboutKey;

  const AboutSection({super.key, required this.aboutKey});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      sectionKey: aboutKey,
      backgroundColor: Colors.white,
      child: ResponsiveBuilder(
        mobile: (context) => Column(
          children: [
            _buildTextColumn(),
            const SizedBox(height: 48),
            _buildPhotoWithIllustration(),
          ],
        ),
        desktop: (context) => Row(
          children: [
            Expanded(flex: 5, child: _buildPhotoWithIllustration()),
            const SizedBox(width: 64),
            Expanded(flex: 6, child: _buildTextColumn()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          pillText: 'About Carevora',
          title: LandingContent.aboutHeading,
          isCentered: false,
        ),
        const SizedBox(height: 20),
        Text(
          LandingContent.aboutParagraph,
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        ...LandingContent.aboutMissionBullets.map((bullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.riskLowBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.riskLow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bullet,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoWithIllustration() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          const PhotoFrame(
            assetPath: 'assets/images/landing/about_holding_hands.jpg',
            width: 380,
            height: 420,
            borderRadius: 24,
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CaregiverHandsIllustration(size: 150),
            ),
          ),
        ],
      ),
    );
  }
}
