import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LockoutBanner extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback? onForgotPassword;

  const LockoutBanner({
    super.key,
    required this.secondsRemaining,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.riskHigh.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: secondsRemaining / 30.0,
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.riskHigh,
                      ),
                      backgroundColor:
                          AppColors.riskHigh.withValues(alpha: 0.15),
                    ),
                    Text(
                      '$secondsRemaining',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.riskHigh,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Temporarily Locked',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.riskHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Too many failed attempts. Try again in ${secondsRemaining}s.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.riskHigh.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onForgotPassword != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onForgotPassword,
              child: const Text(
                'Need immediate access? Reset password →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
