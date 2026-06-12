import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final bool compact;

  const AppLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 32,
          height: compact ? 28 : 32,
          decoration: BoxDecoration(
            color: AppColors.brandOrange,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandOrange.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(
                text: 'GYM',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              const TextSpan(
                text: 'LOG',
                style: TextStyle(
                  color: AppColors.brandOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
