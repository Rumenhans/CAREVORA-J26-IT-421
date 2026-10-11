import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'carevora_logo.dart';

class DesktopSidebar extends StatelessWidget {
  final String currentRoute;
  final bool isCollapsed;

  const DesktopSidebar({
    super.key,
    required this.currentRoute,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 80.0 : 260.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: isCollapsed
                ? const CarevoraLogo(variant: LogoVariant.iconOnly, size: 36)
                : const CarevoraLogo(variant: LogoVariant.full, size: 36),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildNavItem(
                  context,
                  icon: LucideIcons.layoutDashboard,
                  label: 'Overview',
                  route: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.users,
                  label: 'Residents',
                  route: '/dashboard/residents',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.brain,
                  label: 'Cognitive Assessment',
                  route: '/dashboard/cognitive/session',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.heartPulse,
                  label: 'Emotional Wellness',
                  route: '/dashboard/emotional',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.activity,
                  label: 'Metabolic Health',
                  route: '/dashboard/metabolic',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.bell,
                  label: 'Alerts & Notifications',
                  route: '/dashboard/alerts',
                  badge: '3',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.barChart3,
                  label: 'Reports & Analytics',
                  route: '/dashboard/reports',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.clipboardList,
                  label: 'Care Plans',
                  route: '/dashboard/care-plans',
                  badge: '3',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.stethoscope,
                  label: 'Doctor Prescribing',
                  route: '/dashboard/doctor',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.pill,
                  label: 'Live Medicine Board',
                  route: '/dashboard/medicine',
                  badge: '2',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  route: '/dashboard/settings',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Caregiver Profile Card & Log Out
          Padding(
            padding: const EdgeInsets.all(16),
            child: isCollapsed
                ? IconButton(
                    icon: const Icon(LucideIcons.logOut, color: AppColors.riskHigh),
                    onPressed: () => context.go('/login'),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                'SN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Seetha N.', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                                  Text('Caregiver', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => context.go('/login'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(LucideIcons.logOut, size: 16, color: AppColors.riskHigh),
                              SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.riskHigh,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    String? badge,
  }) {
    final isActive = currentRoute == route ||
        (route != '/dashboard' && currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.muted,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppColors.primary : AppColors.body,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
