import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;
  final bool hasTopPurpleAccent;

  const HoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 20,
    this.hasTopPurpleAccent = false,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.card,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.hasTopPurpleAccent && _isHovered
                ? const Border(
                    top: BorderSide(color: AppColors.primary, width: 3.5),
                    left: BorderSide(color: AppColors.border, width: 1),
                    right: BorderSide(color: AppColors.border, width: 1),
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  )
                : widget.border ?? Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _isHovered ? 0.12 : 0.04),
                blurRadius: _isHovered ? 28 : 16,
                offset: Offset(0, _isHovered ? 12 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
