import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:ustaxx_csm/shared/widgets/score_gauge.dart';

class CreditReportTab extends StatelessWidget {
  const CreditReportTab({
    super.key,
    required this.consumer,
    required this.isSmartCreditConnected,
    required this.onConnect,
    required this.onRefresh,
  });

  final ConsumerEntity consumer;
  final bool isSmartCreditConnected;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!isSmartCreditConnected) {
      return _buildNotConnectedState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Gauges Row
            _buildScoreGaugesRow(context),
            const Gap(24),

            // Refresh Status Banner
            _buildRefreshBanner(context),
            const Gap(24),

            // Summary Information Table
            _buildSummaryTable(context),
            const Gap(24),

            // Tradelines Section
            _buildTradelinesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConnectedState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_score_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const Gap(24),
            Text(
              'Credit Report Not Connected',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Connect this consumer\'s credit report provider to view their credit scores, tradelines, and more.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link),
              label: const Text('Connect Credit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGaugesRow(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Scores',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: ScoreGauge(
                    score: null, // Will be populated from actual data
                    bureauName: 'Equifax',
                    bureauLogo: Icons.shield_outlined,
                  ),
                ),
                Expanded(
                  child: ScoreGauge(
                    score: null, // Will be populated from actual data
                    bureauName: 'Experian',
                    bureauLogo: Icons.security,
                  ),
                ),
                Expanded(
                  child: ScoreGauge(
                    score: null, // Will be populated from actual data
                    bureauName: 'TransUnion',
                    bureauLogo: Icons.verified_user,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshBanner(BuildContext context) {
    final theme = Theme.of(context);
    final lastRefresh = consumer.lastCreditReportAt;
    final canRefresh = lastRefresh == null ||
        DateTime.now().difference(lastRefresh).inDays >= 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canRefresh
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            canRefresh ? Icons.refresh : Icons.schedule,
            color: canRefresh
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canRefresh ? 'Refresh Available' : 'Refresh Available Soon',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: canRefresh
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (lastRefresh != null)
                  Text(
                    canRefresh
                        ? 'Last refreshed ${_formatRelativeTime(lastRefresh)}'
                        : 'Next refresh available in ${7 - DateTime.now().difference(lastRefresh).inDays} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: canRefresh
                          ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (canRefresh)
            FilledButton(
              onPressed: onRefresh,
              child: const Text('Refresh Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary by Bureau',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  children: [
                    _buildTableHeader('Bureau'),
                    _buildTableHeader('Negative'),
                    _buildTableHeader('Positive'),
                    _buildTableHeader('Total'),
                    _buildTableHeader('Inquiries'),
                  ],
                ),
                _buildTableRow(
                  'Equifax',
                  negativeAccounts: '-',
                  positiveAccounts: '-',
                  totalAccounts: '-',
                  inquiries: '-',
                ),
                _buildTableRow(
                  'Experian',
                  negativeAccounts: '-',
                  positiveAccounts: '-',
                  totalAccounts: '-',
                  inquiries: '-',
                ),
                _buildTableRow(
                  'TransUnion',
                  negativeAccounts: '-',
                  positiveAccounts: '-',
                  totalAccounts: '-',
                  inquiries: '-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String bureau, {
    required String negativeAccounts,
    required String positiveAccounts,
    required String totalAccounts,
    required String inquiries,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(bureau, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            negativeAccounts,
            style: TextStyle(
              color: negativeAccounts != '-' && negativeAccounts != '0'
                  ? Colors.red
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            positiveAccounts,
            style: TextStyle(
              color: positiveAccounts != '-' && positiveAccounts != '0'
                  ? Colors.green
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(totalAccounts),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(inquiries),
        ),
      ],
    );
  }

  Widget _buildTradelinesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tradelines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to full tradelines view
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const Gap(16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const Gap(16),
                    Text(
                      'No tradelines loaded',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Refresh the credit report to load tradelines',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
