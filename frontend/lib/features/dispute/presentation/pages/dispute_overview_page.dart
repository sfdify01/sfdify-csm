import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/core/theme/app_colors.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_overview_bloc.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_overview_event.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_overview_state.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/bureau_filter_chips.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_list_item.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_metric_card.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/quick_actions_panel.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/system_status_panel.dart';
import 'package:sfdify_scm/injection/injection.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

class DisputeOverviewPage extends StatelessWidget {
  const DisputeOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DisputeOverviewBloc>()
        ..add(const DisputeOverviewLoadRequested()),
      child: const DisputeOverviewView(),
    );
  }
}

class DisputeOverviewView extends StatelessWidget {
  const DisputeOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisputeOverviewBloc, DisputeOverviewState>(
        builder: (context, state) {
          return switch (state.status) {
            DisputeOverviewStatus.initial ||
            DisputeOverviewStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            DisputeOverviewStatus.failure => Center(
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
                      state.errorMessage ?? 'Failed to load data',
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DisputeOverviewBloc>()
                          .add(const DisputeOverviewLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            DisputeOverviewStatus.success => Column(
                children: [
                  // Custom Header with Search
                  _buildHeader(context),

                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<DisputeOverviewBloc>()
                            .add(const DisputeOverviewRefreshRequested());
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main content area
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Metric Cards Grid
                                  _buildMetricsGrid(context, state.metrics!),
                            const Gap(24),

                            // Recent Activity Section
                            Text(
                              'Recent Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Gap(16),

                            // Bureau Filter Chips
                            BureauFilterChips(
                              selectedBureau: state.selectedBureau,
                              onBureauSelected: (bureau) {
                                context.read<DisputeOverviewBloc>().add(
                                      DisputeOverviewBureauFilterChanged(
                                        bureau,
                                      ),
                                    );
                              },
                            ),
                            const Gap(16),

                            // Disputes Table
                            _buildDisputesTable(context, state.disputes),
                            const Gap(16),

                            // Pagination
                            _buildPagination(context, state),
                          ],
                        ),
                      ),
                    ),

                          // Right Sidebar
                          SizedBox(
                            width: 300,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const QuickActionsPanel(),
                                  const Gap(16),
                                  const SystemStatusPanel(),
                                  const Gap(16),
                                  _buildBureauApiBanner(context),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          };
        },
      );
  }

  /// Builds custom header with title, search field, and action icons
  Widget _buildHeader(BuildContext context) {
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
          // Title
          Text(
            'Dispute Overview',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Search input field
          SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Tracking ID, Consumer, or Bureau...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onChanged: (query) {
                // TODO: Implement search logic
                // context.read<DisputeOverviewBloc>().add(
                //   DisputeOverviewSearchChanged(query),
                // );
              },
            ),
          ),

          const Gap(16),

          // Notification icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Notifications',
          ),

          // Help icon
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    DisputeMetricsEntity metrics,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 4 columns on desktop, 2 on tablet, 1 on mobile
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            DisputeMetricCard(
              title: 'Total Disputes',
              value: metrics.totalDisputes.toString(),
              trend: metrics.formattedPercentageChange,
              color: AppColors.primary,
            ),
            DisputeMetricCard(
              title: 'Pending Approval',
              value: metrics.pendingApproval.toString(),
              subtitle: 'Needs review',
              color: AppColors.warning,
              icon: Icons.warning_amber,
            ),
            DisputeMetricCard(
              title: 'In-Transit via Lob',
              value: metrics.inTransitViaLob.toString(),
              subtitle: 'Active mailings',
              color: AppColors.info,
            ),
            DisputeMetricCard(
              title: 'SLA Breaches',
              value: metrics.slaBreaches.toString(),
              trend: metrics.formattedSlaBreachesToday,
              color: AppColors.error,
              icon: Icons.error_outline,
              badge: metrics.slaBreachesToday > 0
                  ? metrics.slaBreachesToday.toString()
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDisputesTable(
    BuildContext context,
    List<DisputeEntity> disputes,
  ) {
    if (disputes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const Gap(16),
                Text(
                  'No disputes found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('CONSUMER', style: _headerStyle(context)),
                ),
                Expanded(child: Text('BUREAU', style: _headerStyle(context))),
                Expanded(
                  flex: 2,
                  child: Text('DISPUTE TYPE', style: _headerStyle(context)),
                ),
                Expanded(
                  child: Text('LOB STATUS', style: _headerStyle(context)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('ACTIONS', style: _headerStyle(context)),
                ),
              ],
            ),
          ),

          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: disputes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return DisputeListItem(
                dispute: disputes[index],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dispute detail view for ${disputes[index].id} coming soon',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        );
  }

  Widget _buildPagination(
    BuildContext context,
    DisputeOverviewState state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${state.disputes.length} results',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.hasMore)
          TextButton(
            onPressed: () => context
                .read<DisputeOverviewBloc>()
                .add(const DisputeOverviewLoadMore()),
            child: const Text('Load More'),
          ),
      ],
    );
  }

  Widget _buildBureauApiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Bureau API v2.0',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(4),
          Text(
            'Update available now',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}
