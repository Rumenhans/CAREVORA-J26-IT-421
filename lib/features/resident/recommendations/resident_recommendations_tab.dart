import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/cards/carevora_card.dart';

class ResidentRecommendationsTab extends StatelessWidget {
  const ResidentRecommendationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suggested Activities'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Text('Tailored for Sarah', style: AppTypography.h1.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'Gentle ideas to support your emotional comfort and happiness today.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 20),

            _activityItem(
              title: 'Afternoon Courtyard Walk',
              category: 'Physical & Fresh Air',
              time: '2:30 PM • 15 mins',
              description: 'A quiet stroll near the flowering garden with nurse escort or walking companion.',
              icon: Icons.directions_walk_rounded,
              color: AppColors.positive,
            ),
            const SizedBox(height: 14),

            _activityItem(
              title: 'Lounge Social & Herbal Tea',
              category: 'Social Connection',
              time: '3:30 PM • East Parlor',
              description: 'Join Margaret and fellow residents for chamomile tea and soft piano music.',
              icon: Icons.coffee_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),

            _activityItem(
              title: 'Mindful Breathing & Classical Music',
              category: 'Emotional Peace',
              time: 'Anytime • In your room',
              description: 'Listen to gentle cello melodies through your bedside audio speaker.',
              icon: Icons.headphones_rounded,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem({
    required String title,
    required String category,
    required String time,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return CarevoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.toUpperCase(), style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(title, style: AppTypography.h3.copyWith(fontSize: 17)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: AppTypography.body),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(time, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('I’ll Try This'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
