import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import '../../data/landing_content.dart';

class LandingFooter extends StatelessWidget {
  final VoidCallback onScrollHome;
  final VoidCallback onScrollAbout;
  final VoidCallback onScrollSolution;
  final VoidCallback onScrollHow;
  final VoidCallback onScrollCaregivers;
  final VoidCallback onScrollContact;

  const LandingFooter({
    super.key,
    required this.onScrollHome,
    required this.onScrollAbout,
    required this.onScrollSolution,
    required this.onScrollHow,
    required this.onScrollCaregivers,
    required this.onScrollContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              ResponsiveBuilder(
                mobile: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandColumn(),
                    const SizedBox(height: 36),
                    _buildLinksColumn('Product & Solutions', [
                      _LinkItem('Overview', onScrollHome),
                      _LinkItem('Multimodal Intelligence', onScrollSolution),
                      _LinkItem('Clinical Workflow', onScrollHow),
                    ]),
                    const SizedBox(height: 28),
                    _buildLinksColumn('For Facilities', [
                      _LinkItem('Caregiver Support', onScrollCaregivers),
                      _LinkItem('About Our Mission', onScrollAbout),
                      _LinkItem('Clinical Demonstration', onScrollContact),
                    ]),
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildBrandColumn()),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 3,
                      child: _buildLinksColumn('Product & Solutions', [
                        _LinkItem('Overview', onScrollHome),
                        _LinkItem('Multimodal Intelligence', onScrollSolution),
                        _LinkItem('Clinical Workflow', onScrollHow),
                      ]),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildLinksColumn('For Facilities', [
                        _LinkItem('Caregiver Support', onScrollCaregivers),
                        _LinkItem('About Our Mission', onScrollAbout),
                        _LinkItem('Clinical Demonstration', onScrollContact),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Regulatory & Non-Diagnostic Disclaimer Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  LandingContent.clinicalDisclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),
              // Copyright & Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2025 Carevora. Compassionate Care, Smarter Tomorrow. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Terms of Service',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CarevoraLogo(variant: LogoVariant.full, size: 36, isDark: true),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'Carevora empowers care home teams with continuous multimodal wellness monitoring and early risk detection.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksColumn(String title, List<_LinkItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: item.onTap,
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkItem {
  final String label;
  final VoidCallback onTap;
  _LinkItem(this.label, this.onTap);
}
