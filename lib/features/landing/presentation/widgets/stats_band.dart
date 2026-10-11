import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/landing_content.dart';
import 'common/count_up_text.dart';

class StatsBand extends StatelessWidget {
  const StatsBand({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 64,
        horizontal: isMobile ? 20 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 4 Trust Pillars with Translucent Circle Icons & Dividers
              isMobile ? _buildMobileTrustList() : _buildDesktopTrustRow(),
              const SizedBox(height: 48),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 48),
              // Animated Product Fact Numbers
              _buildStatsRow(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTrustRow() {
    return Row(
      children: List.generate(LandingContent.trustMetrics.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Container(
            height: 48,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
          );
        }
        final item = LandingContent.trustMetrics[index ~/ 2];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTrustItem(item),
          ),
        );
      }),
    );
  }

  Widget _buildMobileTrustList() {
    return Column(
      children: LandingContent.trustMetrics.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _buildTrustItem(item),
        );
      }).toList(),
    );
  }

  Widget _buildTrustItem(TrustMetricData item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtext,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    if (isMobile) {
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.spaceAround,
        children: LandingContent.statsCountUp.map((stat) {
          return SizedBox(
            width: 140,
            child: _buildStatItem(stat),
          );
        }).toList(),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: LandingContent.statsCountUp.map((stat) {
        return _buildStatItem(stat);
      }).toList(),
    );
  }

  Widget _buildStatItem(Map<String, String> stat) {
    final value = int.tryParse(stat['value'] ?? '0') ?? 0;
    final suffix = stat['suffix'] ?? '';
    final label = stat['label'] ?? '';

    return Column(
      children: [
        CountUpText(
          targetValue: value,
          suffix: suffix,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
