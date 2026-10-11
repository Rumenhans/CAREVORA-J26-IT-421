import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class MobileBottomNav extends StatelessWidget {
  final String currentRoute;

  const MobileBottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    if (currentRoute == '/dashboard') {
      currentIndex = 0;
    } else if (currentRoute.startsWith('/dashboard/residents')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/dashboard/cognitive')) {
      currentIndex = 2;
    } else if (currentRoute.startsWith('/dashboard/alerts')) {
      currentIndex = 3;
    } else {
      currentIndex = 4;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/dashboard/residents');
              break;
            case 2:
              context.go('/dashboard/cognitive/session');
              break;
            case 3:
              context.go('/dashboard/alerts');
              break;
            case 4:
              context.go('/dashboard/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard, size: 20),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users, size: 20),
            label: 'Residents',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.brain, size: 20),
            label: 'Assess',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bell, size: 20),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings, size: 20),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
