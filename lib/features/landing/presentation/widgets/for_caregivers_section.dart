import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';
import 'common/photo_frame.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class ForCaregiversSection extends StatelessWidget {
  final GlobalKey caregiversKey;

  const ForCaregiversSection({super.key, required this.caregiversKey});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      sectionKey: caregiversKey,
      backgroundColor: const Color(0xFFF7F4FD),
      child: ResponsiveBuilder(
        mobile: (context) => Column(
          children: [
            _buildHeaderAndBenefits(context),
            const SizedBox(height: 48),
            _buildCaregiverPhoto(),
          ],
        ),
        desktop: (context) => Row(
          children: [
            Expanded(flex: 6, child: _buildHeaderAndBenefits(context)),
            const SizedBox(width: 48),
            Expanded(flex: 5, child: _buildCaregiverPhoto()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndBenefits(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          pillText: 'Built For Care Teams',
          title: 'Empowering Caregivers Daily',
          subtitle:
              'Care home staff spend less time filling tedious clinical forms and more time delivering empathetic, attentive care.',
          isCentered: false,
        ),
        const SizedBox(height: 36),
        ...LandingContent.caregiverBenefits.map((benefit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HoverCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(benefit.icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(benefit.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(benefit.description, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text('Explore the Dashboard →'),
        ),
      ],
    );
  }

  Widget _buildCaregiverPhoto() {
    return const Center(
      child: PhotoFrame(
        assetPath: 'assets/images/landing/caregivers_team.jpg',
        width: 400,
        height: 460,
        borderRadius: 24,
      ),
    );
  }
}
