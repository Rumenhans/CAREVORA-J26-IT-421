import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String? pillText;
  final String title;
  final String? subtitle;
  final bool isCentered;
  final Color? titleColor;

  const SectionHeader({
    super.key,
    this.pillText,
    required this.title,
    this.subtitle,
    this.isCentered = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (pillText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              pillText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          style: AppTextStyles.h2.copyWith(
            color: titleColor ?? AppColors.navy,
            fontSize: 32,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              subtitle!,
              textAlign: isCentered ? TextAlign.center : TextAlign.start,
              style: AppTextStyles.body.copyWith(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
