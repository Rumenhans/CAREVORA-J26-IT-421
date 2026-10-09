import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/cards/carevora_card.dart';
import '../../splash/splash_view.dart';

class ResidentProfileTab extends StatefulWidget {
  const ResidentProfileTab({super.key});

  @override
  State<ResidentProfileTab> createState() => _ResidentProfileTabState();
}

class _ResidentProfileTabState extends State<ResidentProfileTab> {
  bool _largeText = true;
  bool _highContrast = false;
  bool _soundCues = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile & Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            // Profile Card
            CarevoraCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primarySoft,
                    child: Text('SJ', style: AppTypography.h1.copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sarah Jenkins', style: AppTypography.h2),
                        const SizedBox(height: 4),
                        Text('Room: Suite 204 • Age: 78', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('Care Coordinator: Dr. Eleanor Vance', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Accessibility Settings (Crucial for elderly residents)
            Text('Comfort & Accessibility', style: AppTypography.h2.copyWith(fontSize: 19)),
            const SizedBox(height: 12),
            CarevoraCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Large Text Display', style: AppTypography.bodyLarge.copyWith(fontSize: 16)),
                    subtitle: Text('Enlarge letters across questionnaires', style: AppTypography.caption),
                    value: _largeText,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _largeText = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('High Contrast Colors', style: AppTypography.bodyLarge.copyWith(fontSize: 16)),
                    subtitle: Text('Enhance visibility of buttons & cards', style: AppTypography.caption),
                    value: _highContrast,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _highContrast = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Voice & Audio Prompts', style: AppTypography.bodyLarge.copyWith(fontSize: 16)),
                    subtitle: Text('Speak instructions softly out loud', style: AppTypography.caption),
                    value: _soundCues,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _soundCues = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Safety & Support
            Text('Assistance & Privacy', style: AppTypography.h2.copyWith(fontSize: 19)),
            const SizedBox(height: 12),
            CarevoraCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.call_rounded, color: AppColors.primary),
                    title: Text('Call Care Desk', style: AppTypography.bodyLarge.copyWith(fontSize: 16)),
                    subtitle: Text('Direct line to front nursing station', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Care Desk at Room 204...')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                    title: Text('Privacy Policy', style: AppTypography.bodyLarge.copyWith(fontSize: 16)),
                    subtitle: Text('Learn how your wellness data is kept safe', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout / Portal Switcher
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashView()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.critical),
              label: Text('Sign Out', style: AppTypography.button.copyWith(color: AppColors.critical)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.critical, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
