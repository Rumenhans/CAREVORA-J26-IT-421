import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../models/enums.dart';

class ResidentHistoryTab extends StatelessWidget {
  const ResidentHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wellness History'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Text('Past 7 Days Overview', style: AppTypography.h1.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text('A steady look at your emotional feelings and social connection.', style: AppTypography.body),
            const SizedBox(height: 20),

            // Friendly 7-day bar chart
            CarevoraCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekly Wellness Trend', style: AppTypography.h3),
                      const StatusBadge(status: WellnessStatus.lookingGood),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _dayBar('Mon', 0.80),
                      _dayBar('Tue', 0.72),
                      _dayBar('Wed', 0.85),
                      _dayBar('Thu', 0.90),
                      _dayBar('Fri', 0.78),
                      _dayBar('Sat', 0.86),
                      _dayBar('Today', 0.88, isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Your trend is very consistent and healthy!',
                      style: AppTypography.caption.copyWith(color: AppColors.positive, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Previous Check-ins', style: AppTypography.h2.copyWith(fontSize: 19)),
            const SizedBox(height: 14),

            _historyItem('Today, 9:00 AM', 'Looking Good', '86% Index', 'Felt uplifted after walking in garden.'),
            const SizedBox(height: 12),
            _historyItem('Yesterday, 9:15 AM', 'Looking Good', '84% Index', 'Great conversations during breakfast.'),
            const SizedBox(height: 12),
            _historyItem('2 days ago, 10:00 AM', 'Stable', '78% Index', 'Rested quietly in room with book.'),
          ],
        ),
      ),
    );
  }

  Widget _dayBar(String label, double ratio, {bool isHighlight = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 120 * ratio,
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.primary : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight ? AppColors.primaryDark : AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _historyItem(String date, String status, String score, String note) {
    return CarevoraCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                    Text(score, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(note, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
