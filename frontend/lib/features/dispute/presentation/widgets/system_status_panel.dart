import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/core/theme/app_colors.dart';

class SystemStatusPanel extends StatelessWidget {
  const SystemStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.info,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  'System Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),

            _buildStatusItem(
              context,
              'Lob API',
              'Operational',
              AppColors.success,
            ),
            const Gap(12),
            _buildStatusItem(
              context,
              'SmartCredit',
              'Operational',
              AppColors.success,
            ),
            const Gap(12),
            _buildStatusItem(
              context,
              'Queue Latency',
              '120ms',
              AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color statusColor,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
