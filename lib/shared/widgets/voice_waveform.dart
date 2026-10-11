import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VoiceWaveformWidget extends StatefulWidget {
  final bool isListening;

  const VoiceWaveformWidget({super.key, required this.isListening});

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      return SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            18,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(18, (index) {
              final phase = (index / 18.0) * 3.14159 * 2;
              final wave = (1 + (0.8 * (0.5 + 0.5 * (index % 3 == 0 ? 1 : 0.6))) *
                      (0.5 + 0.5 * (index % 2 == 0 ? 1 : -1))) *
                  (14 + 16 * ((1 + (_controller.value * 2 * 3.14159 + phase).abs() % 1.0) / 2));

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3.5,
                height: wave.clamp(8.0, 44.0),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
