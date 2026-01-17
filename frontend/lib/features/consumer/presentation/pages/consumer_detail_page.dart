import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_detail_bloc.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_detail_event.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_detail_state.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_credit_summary.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_disputes_tab.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_info_card.dart';
import 'package:sfdify_scm/injection/injection.dart';

class ConsumerDetailPage extends StatelessWidget {
  const ConsumerDetailPage({
    super.key,
    required this.consumerId,
  });

  final String consumerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConsumerDetailBloc>()
        ..add(ConsumerDetailLoadRequested(consumerId)),
      child: const ConsumerDetailView(),
    );
  }
}

class ConsumerDetailView extends StatelessWidget {
  const ConsumerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsumerDetailBloc, ConsumerDetailState>(
      builder: (context, state) {
        return switch (state.status) {
          ConsumerDetailStatus.initial ||
          ConsumerDetailStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          ConsumerDetailStatus.failure => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const Gap(16),
                  Text(
                    state.errorMessage ?? 'Failed to load consumer',
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ConsumerDetailStatus.success => Column(
              children: [
                // Header
                _buildHeader(context, state),

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ConsumerDetailBloc>()
                          .add(const ConsumerDetailRefreshRequested());
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Consumer Info Card
                          ConsumerInfoCard(
                            consumer: state.consumer!,
                            onEdit: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Edit consumer coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          const Gap(24),

                          // Credit Summary
                          ConsumerCreditSummary(
                            isConnected: state.isSmartCreditConnected,
                            creditScore: state.creditScore,
                            onConnect: () {
                              context.read<ConsumerDetailBloc>().add(
                                    const ConsumerDetailSmartCreditConnectRequested(),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('SmartCredit connection coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            onRefresh: () {
                              context.read<ConsumerDetailBloc>().add(
                                    const ConsumerDetailCreditReportRefreshRequested(),
                                  );
                            },
                          ),
                          const Gap(24),

                          // Disputes Tab
                          ConsumerDisputesTab(
                            disputes: state.disputes,
                            consumerId: state.consumer!.id,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        };
      },
    );
  }

  Widget _buildHeader(BuildContext context, ConsumerDetailState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/consumers'),
            tooltip: 'Back to Consumers',
          ),
          const Gap(8),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.consumer?.fullName ?? 'Consumer',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.consumer != null)
                  Text(
                    state.consumer!.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('View credit report coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.credit_score, size: 18),
            label: const Text('Credit Report'),
          ),
          const Gap(8),
          FilledButton.icon(
            onPressed: () {
              context.go('/disputes/new?consumerId=${state.consumer?.id}');
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Dispute'),
          ),
        ],
      ),
    );
  }
}
