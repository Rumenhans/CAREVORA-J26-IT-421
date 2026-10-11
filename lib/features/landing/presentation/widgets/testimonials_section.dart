import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/landing_content.dart';
import 'common/hover_card.dart';
import 'common/section_container.dart';
import 'common/section_header.dart';

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  int _activePage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SectionContainer(
      backgroundColor: AppColors.page,
      child: Column(
        children: [
          const SectionHeader(
            pillText: 'Sample Field Feedback',
            title: 'Trusted by Eldercare Teams',
            subtitle:
                'Voices from geriatric nurse managers and care specialists who rely on Carevora daily.',
            isCentered: true,
          ),
          const SizedBox(height: 12),
          // Clear Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Sample demonstration feedback • Not formal endorsements',
              style: TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 48),
          isMobile ? _buildMobileCarousel() : _buildDesktopGrid(),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: LandingContent.testimonials.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildTestimonialCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _activePage = idx),
            itemCount: LandingContent.testimonials.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildTestimonialCard(LandingContent.testimonials[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            LandingContent.testimonials.length,
            (idx) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _activePage == idx ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _activePage == idx ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(TestimonialItemData item) {
    return HoverCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
              Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
              Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
              Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
              Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${item.quote}"',
            style: AppTextStyles.body.copyWith(
              fontSize: 13.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  item.name.substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text('${item.role} • ${item.facility}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
