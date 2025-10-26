import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Small reusable circular badge used across the app for avatars/icons.
///
/// Use backgroundColor for colored badges (icon will default to white), or
/// set backgroundColor to Colors.white and provide [iconColor] for a colored icon.
class AppBadge extends StatelessWidget {
  final double radius;
  final Color backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final Widget? child;
  final bool showRing;

  const AppBadge({
    super.key,
    this.radius = 22,
    this.backgroundColor = AppTheme.primaryGreen,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.showRing = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = backgroundColor.withValues(alpha: 15);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: showRing ? Border.all(color: ringColor) : null,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: child ??
            (icon != null
                ? Icon(
                    icon,
                    size: iconSize ?? radius * 1.05,
                    color: iconColor ?? (backgroundColor == Colors.white ? AppTheme.primaryGreen : Colors.white),
                  )
                : null),
      ),
    );
  }
}
