import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SignalIndicator extends StatelessWidget {
  const SignalIndicator({
    super.key,
    required this.score,
  });

  final double score;

  @override
  Widget build(BuildContext context) {
    final normalized = score.clamp(0.0, 1.0);
    final activeBars = (normalized * 4).ceil().clamp(1, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final active = index < activeBars;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 6,
          height: 8 + (index * 6),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: active ? AppTheme.neonGreen : AppTheme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
