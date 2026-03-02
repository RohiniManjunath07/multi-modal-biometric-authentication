import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small circular badge showing the count of registered faces.
/// Tapping navigates to the manage screen (wired by the parent).
class StatsBadge extends StatelessWidget {
  final int count;
  const StatsBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline,
              size: 18, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
