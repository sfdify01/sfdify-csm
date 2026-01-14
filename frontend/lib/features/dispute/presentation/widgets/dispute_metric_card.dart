import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DisputeMetricCard extends StatelessWidget {
  const DisputeMetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.color,
    this.icon,
    this.badge,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? trend; // e.g., "+5%", "+1 today"
  final Color? color;
  final IconData? icon;
  final String? badge; // e.g., "1" for SLA breaches badge overlay

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: color, size: 20),
                  ],
                ),
                const Gap(12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (trend != null) ...[
                      const Gap(8),
                      Text(
                        trend!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color ?? theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const Gap(4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Badge overlay (top-right)
        if (badge != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Center(
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
