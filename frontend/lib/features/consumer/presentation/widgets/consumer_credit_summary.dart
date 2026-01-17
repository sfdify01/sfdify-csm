import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ConsumerCreditSummary extends StatelessWidget {
  const ConsumerCreditSummary({
    super.key,
    required this.isConnected,
    this.creditScore,
    this.onConnect,
    this.onRefresh,
  });

  final bool isConnected;
  final int? creditScore;
  final VoidCallback? onConnect;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isConnected) {
      return _buildConnectCard(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const Gap(4),
                          Text(
                            'SmartCredit Connected',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: onRefresh,
                      tooltip: 'Refresh Credit Report',
                    ),
                  ],
                ),
              ],
            ),
            const Gap(24),
            // Credit Score Display
            Row(
              children: [
                _buildScoreCircle(context),
                const Gap(32),
                Expanded(
                  child: Column(
                    children: [
                      _buildBureauScore(
                        context,
                        bureau: 'Equifax',
                        score: creditScore,
                      ),
                      const Gap(8),
                      _buildBureauScore(
                        context,
                        bureau: 'Experian',
                        score: creditScore,
                      ),
                      const Gap(8),
                      _buildBureauScore(
                        context,
                        bureau: 'TransUnion',
                        score: creditScore,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.link_off,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const Gap(16),
            Text(
              'SmartCredit Not Connected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Connect SmartCredit to view credit reports and pull tradelines for disputes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link, size: 20),
              label: const Text('Connect SmartCredit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context) {
    final theme = Theme.of(context);
    final score = creditScore ?? 0;
    final scoreColor = _getScoreColor(score);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scoreColor,
          width: 8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score > 0 ? score.toString() : '---',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              _getScoreLabel(score),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBureauScore(
    BuildContext context, {
    required String bureau,
    required int? score,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            bureau,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score != null ? score / 850 : 0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              _getScoreColor(score ?? 0),
            ),
          ),
        ),
        const Gap(8),
        SizedBox(
          width: 40,
          child: Text(
            score?.toString() ?? '---',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 750) return Colors.green;
    if (score >= 700) return Colors.lightGreen;
    if (score >= 650) return Colors.yellow.shade700;
    if (score >= 600) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 750) return 'Excellent';
    if (score >= 700) return 'Good';
    if (score >= 650) return 'Fair';
    if (score >= 600) return 'Poor';
    if (score > 0) return 'Very Poor';
    return 'N/A';
  }
}
