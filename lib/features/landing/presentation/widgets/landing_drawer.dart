import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';

class LandingDrawer extends StatelessWidget {
  final String activeSection;
  final VoidCallback onScrollHome;
  final VoidCallback onScrollAbout;
  final VoidCallback onScrollSolution;
  final VoidCallback onScrollHow;
  final VoidCallback onScrollCaregivers;
  final VoidCallback onScrollContact;

  const LandingDrawer({
    super.key,
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
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CarevoraLogo(variant: LogoVariant.full, size: 32),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.navy),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  _buildDrawerItem('Home', onScrollHome, activeSection == 'home'),
                  _buildDrawerItem('About', onScrollAbout, activeSection == 'about'),
                  _buildDrawerItem('Our Solution', onScrollSolution, activeSection == 'solution'),
                  _buildDrawerItem('How It Works', onScrollHow, activeSection == 'how'),
                  _buildDrawerItem('For Caregivers', onScrollCaregivers, activeSection == 'caregivers'),
                  _buildDrawerItem('Contact', onScrollContact, activeSection == 'contact'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(LucideIcons.user, size: 18),
                    label: const Text('Log In'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text('Get Started →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, VoidCallback onTap, bool isActive) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.navy,
        ),
      ),
      tileColor: isActive ? AppColors.primarySoft : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
