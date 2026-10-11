import 'package:flutter/material.dart';
import '../../../../../core/responsive/responsive_builder.dart';
import '../../../../../core/theme/app_colors.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final GlobalKey? sectionKey;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  const SectionContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.backgroundGradient,
    this.sectionKey,
    this.padding,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final verticalPadding = isMobile ? 56.0 : 96.0;
    final horizontalPadding = isMobile ? 20.0 : 40.0;

    return Container(
      key: sectionKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundGradient == null ? (backgroundColor ?? AppColors.page) : null,
        gradient: backgroundGradient,
      ),
      padding: padding ??
          EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
