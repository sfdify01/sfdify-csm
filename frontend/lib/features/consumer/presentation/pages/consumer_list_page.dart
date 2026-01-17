import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_list_bloc.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_list_event.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_list_state.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_filter_chips.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_list_item.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/consumer_search_bar.dart';
import 'package:sfdify_scm/injection/injection.dart';

class ConsumerListPage extends StatelessWidget {
  const ConsumerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConsumerListBloc>()
        ..add(const ConsumerListLoadRequested()),
      child: const ConsumerListView(),
    );
  }
}

class ConsumerListView extends StatelessWidget {
  const ConsumerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsumerListBloc, ConsumerListState>(
      builder: (context, state) {
        return switch (state.status) {
          ConsumerListStatus.initial ||
          ConsumerListStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          ConsumerListStatus.failure => Center(
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
                    state.errorMessage ?? 'Failed to load consumers',
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ConsumerListBloc>()
                        .add(const ConsumerListLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ConsumerListStatus.success => Column(
              children: [
                // Custom Header with Search
                _buildHeader(context, state),

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ConsumerListBloc>()
                          .add(const ConsumerListRefreshRequested());
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Cards
                          _buildStatsRow(context, state),
                          const Gap(24),

                          // Filter Chips
                          ConsumerFilterChips(
                            selectedStatus: state.selectedStatus,
                            onStatusSelected: (status) {
                              context.read<ConsumerListBloc>().add(
                                    ConsumerListStatusFilterChanged(status),
                                  );
                            },
                          ),
                          const Gap(16),

                          // Consumers Table
                          _buildConsumersTable(context, state.consumers),
                          const Gap(16),

                          // Pagination
                          _buildPagination(context, state),
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

  Widget _buildHeader(BuildContext context, ConsumerListState state) {
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
            'Consumers',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Search input field
          ConsumerSearchBar(
            initialQuery: state.searchQuery,
            onSearchChanged: (query) {
              context.read<ConsumerListBloc>().add(
                    ConsumerListSearchChanged(query),
                  );
            },
          ),

          const Gap(16),

          // Add Consumer button
          FilledButton.icon(
            onPressed: () {
              context.go('/consumers/new');
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Consumer'),
          ),

          const Gap(8),

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

  Widget _buildStatsRow(BuildContext context, ConsumerListState state) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
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
          childAspectRatio: 2.2,
          children: [
            _buildStatCard(
              context,
              title: 'Total Consumers',
              value: state.consumers.length.toString(),
              icon: Icons.people_outline,
              color: theme.colorScheme.primary,
            ),
            _buildStatCard(
              context,
              title: 'SmartCredit Connected',
              value: '0', // Would come from backend metrics
              icon: Icons.link,
              color: Colors.green,
            ),
            _buildStatCard(
              context,
              title: 'Active Disputes',
              value: '0', // Would come from backend metrics
              icon: Icons.description_outlined,
              color: Colors.orange,
            ),
            _buildStatCard(
              context,
              title: 'Added This Month',
              value: '0', // Would come from backend metrics
              icon: Icons.calendar_today,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumersTable(
    BuildContext context,
    List<ConsumerEntity> consumers,
  ) {
    if (consumers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const Gap(16),
                Text(
                  'No consumers found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                const Gap(8),
                Text(
                  'Add your first consumer to get started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
                const Gap(16),
                FilledButton.icon(
                  onPressed: () {
                    context.go('/consumers/new');
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Consumer'),
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
                const SizedBox(width: 56), // Avatar space
                Expanded(
                  flex: 2,
                  child: Text('CONSUMER', style: _headerStyle(context)),
                ),
                Expanded(child: Text('PHONE', style: _headerStyle(context))),
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
            itemCount: consumers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ConsumerListItem(
                consumer: consumers[index],
                onTap: () {
                  context.go('/consumers/${consumers[index].id}');
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
    ConsumerListState state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${state.consumers.length} results',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.hasMore)
          TextButton(
            onPressed: () => context
                .read<ConsumerListBloc>()
                .add(const ConsumerListLoadMore()),
            child: const Text('Load More'),
          ),
      ],
    );
  }
}
