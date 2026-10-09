import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../models/enums.dart';
import '../assessment/assessment_flow_view.dart';
import '../../splash/splash_view.dart';

class ResidentHomeTab extends StatelessWidget {
  const ResidentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('CAREVORA', style: AppTypography.h3.copyWith(letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Portal',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SplashView()),
              );
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No urgent alerts. Your morning check-in is ready!')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      'SJ',
                      style: AppTypography.h2.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Morning,', style: AppTypography.body.copyWith(fontSize: 16)),
                        Text('Sarah Jenkins', style: AppTypography.h1.copyWith(fontSize: 24)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Callout Banner: Today's Wellness Check-in
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Daily Wellness Moment',
                        style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'How are you feeling today?',
                      style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a gentle 2-minute check-in to help your caregivers support your happiness and peace.',
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AssessmentFlowView()),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                      label: Text(
                        'Start Morning Check-in',
                        style: AppTypography.button.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Last Recorded Status Card
              Text('Your Recent Wellness', style: AppTypography.h2.copyWith(fontSize: 19)),
              const SizedBox(height: 12),
              CarevoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const StatusBadge(status: WellnessStatus.lookingGood),
                        Text('Updated today, 9:00 AM', style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"You felt peaceful and enjoyed greeting your friends this morning."',
                      style: AppTypography.bodyLarge.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _scorePill('Emotional', '88%', Icons.sentiment_very_satisfied_rounded, AppColors.positive),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _scorePill('Social Connection', '82%', Icons.people_outline_rounded, AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Helpful Care Suggestions for Today
              Text('Today’s Care Suggestions', style: AppTypography.h2.copyWith(fontSize: 19)),
              const SizedBox(height: 12),
              CarevoraCard(
                backgroundColor: AppColors.positiveSoft.withValues(alpha: 0.4),
                border: Border.all(color: AppColors.positive.withValues(alpha: 0.2)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.nature_people_rounded, color: AppColors.positive, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Afternoon Courtyard Walk', style: AppTypography.h3.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Enjoy 15 minutes of calm sunlight and fresh garden air.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CarevoraCard(
                backgroundColor: AppColors.secondarySoft.withValues(alpha: 0.4),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.coffee_rounded, color: AppColors.secondary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tea & Music Hour', style: AppTypography.h3.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Fellow residents are gathering in the east parlor at 3:30 PM.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scorePill(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                Text(val, style: AppTypography.h3.copyWith(color: color, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
