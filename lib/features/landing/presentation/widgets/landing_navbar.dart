import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';

class LandingNavbar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String activeSection;
  final VoidCallback onScrollHome;
  final VoidCallback onScrollAbout;
  final VoidCallback onScrollSolution;
  final VoidCallback onScrollHow;
  final VoidCallback onScrollCaregivers;
  final VoidCallback onScrollContact;

  const LandingNavbar({
    super.key,
    required this.scaffoldKey,
    required this.activeSection,
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
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CarevoraLogo(variant: LogoVariant.full, size: 36),
          ResponsiveBuilder(
            mobile: (context) => IconButton(
              icon: const Icon(LucideIcons.menu, color: AppColors.navy),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
            desktop: (context) => Row(
              children: [
                _buildNavItem('Home', onScrollHome, activeSection == 'home'),
                _buildNavItem('About', onScrollAbout, activeSection == 'about'),
                _buildNavItem('Our Solution', onScrollSolution, activeSection == 'solution'),
                _buildNavItem('How It Works', onScrollHow, activeSection == 'how'),
                _buildNavItem('For Caregivers', onScrollCaregivers, activeSection == 'caregivers'),
                _buildNavItem('Contact', onScrollContact, activeSection == 'contact'),
                const SizedBox(width: 24),
                OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.user, size: 16),
                  label: const Text('Log In'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  label: const Text('Get Started →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, VoidCallback onTap, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.body,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 22 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
