import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models.dart';

class DosePatternStepper extends StatelessWidget {
  final DosePattern value;
  final ValueChanged<DosePattern> onChanged;

  const DosePatternStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Widget _buildStepItem(String label, num val, ValueChanged<num> onValChanged) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (val > 0) {
                    onValChanged(val > 1 ? val - 1 : (val == 1 ? 0.5 : 0));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  val.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy),
                ),
              ),
              InkWell(
                onTap: () {
                  onValChanged(val == 0 ? 0.5 : (val == 0.5 ? 1 : val + 1));
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dashboardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem('Morning', value.morning, (v) {
            onChanged(DosePattern(morning: v, afternoon: value.afternoon, evening: value.evening, night: value.night));
          }),
          _buildStepItem('Afternoon', value.afternoon, (v) {
            onChanged(DosePattern(morning: value.morning, afternoon: v, evening: value.evening, night: value.night));
          }),
          _buildStepItem('Evening', value.evening, (v) {
            onChanged(DosePattern(morning: value.morning, afternoon: value.afternoon, evening: v, night: value.night));
          }),
          _buildStepItem('Night', value.night, (v) {
            onChanged(DosePattern(morning: value.morning, afternoon: value.afternoon, evening: value.evening, night: v));
          }),
        ],
      ),
    );
  }
}

class MealTimingBadge extends StatelessWidget {
  final MealTiming mealTiming;

  const MealTimingBadge({super.key, required this.mealTiming});

  @override
  Widget build(BuildContext context) {
    String text = 'Any time';
    Color bg = AppColors.primarySoft;
    Color fg = AppColors.primary;

    switch (mealTiming) {
      case MealTiming.beforeMeal:
        text = 'Before meal';
        bg = AppColors.riskModerateBg;
        fg = AppColors.riskModerate;
        break;
      case MealTiming.afterMeal:
        text = 'After meal';
        bg = AppColors.riskLowBg;
        fg = AppColors.riskLow;
        break;
      case MealTiming.withMeal:
        text = 'With meal';
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        break;
      case MealTiming.emptyStomach:
        text = 'Empty stomach';
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        break;
      case MealTiming.anyTime:
        text = 'Any time';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
