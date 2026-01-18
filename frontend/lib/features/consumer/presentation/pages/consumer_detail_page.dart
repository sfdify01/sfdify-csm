import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_detail_bloc.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_detail_event.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_detail_state.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/credit_report_tab.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/consumer_disputes_tab.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/client_info_tab.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/notes_tab.dart';
import 'package:ustaxx_csm/injection/injection.dart';

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

class ConsumerDetailView extends StatefulWidget {
  const ConsumerDetailView({super.key});

  @override
  State<ConsumerDetailView> createState() => _ConsumerDetailViewState();
}

class _ConsumerDetailViewState extends State<ConsumerDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

                // Tab Bar
                _buildTabBar(context),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Credit Report Tab
                      CreditReportTab(
                        consumer: state.consumer!,
                        isSmartCreditConnected: state.isSmartCreditConnected,
                        onConnect: () {
                          context.read<ConsumerDetailBloc>().add(
                                const ConsumerDetailSmartCreditConnectRequested(),
                              );
                        },
                        onRefresh: () {
                          context.read<ConsumerDetailBloc>().add(
                                const ConsumerDetailCreditReportRefreshRequested(),
                              );
                        },
                      ),

                      // Disputes Tab
                      ConsumerDisputesTab(
                        disputes: state.disputes,
                        consumerId: state.consumer!.id,
                      ),

                      // Client Information Tab
                      ClientInfoTab(consumer: state.consumer!),

                      // Notes Tab
                      NotesTab(consumerId: state.consumer!.id),
                    ],
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

          // Title with status chip
          Expanded(
            child: Row(
              children: [
                Column(
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
                const Gap(16),
                if (state.consumer != null)
                  _buildStatusChip(context, state.consumer!.status),
              ],
            ),
          ),

          // Action Buttons
          OutlinedButton.icon(
            onPressed: () {
              context.go('/consumers/${state.consumer?.id}/edit');
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
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

  Widget _buildStatusChip(BuildContext context, dynamic status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'unsent':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Unsent';
        icon = Icons.hourglass_empty;
        break;
      case 'awaitingResponse':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Awaiting Response';
        icon = Icons.schedule;
        break;
      case 'inProgress':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'In Progress';
        icon = Icons.pending_actions;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.credit_score),
            text: 'Credit Report',
          ),
          Tab(
            icon: Icon(Icons.description),
            text: 'Disputes',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: 'Client Information',
          ),
          Tab(
            icon: Icon(Icons.note),
            text: 'Notes',
          ),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
      ),
    );
  }
}
