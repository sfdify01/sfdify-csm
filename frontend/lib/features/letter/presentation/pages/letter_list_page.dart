import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_list_bloc.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_list_event.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_list_state.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_filter_bar.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_list_item.dart';
import 'package:sfdify_scm/injection/injection.dart';

class LetterListPage extends StatelessWidget {
  const LetterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<LetterListBloc>()..add(const LetterListLoadRequested()),
      child: const LetterListView(),
    );
  }
}

class LetterListView extends StatelessWidget {
  const LetterListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LetterListBloc, LetterListState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state),
            Expanded(child: _buildContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LetterListState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Letters',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context
                    .read<LetterListBloc>()
                    .add(const LetterListRefreshRequested()),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const Gap(16),
          // Stats cards
          _buildStatsRow(context, state),
          const Gap(16),
          // Filter bar
          LetterFilterBar(
            selectedStatus: state.statusFilter,
            searchQuery: state.searchQuery,
            onStatusChanged: (status) {
              context
                  .read<LetterListBloc>()
                  .add(LetterListStatusFilterChanged(status));
            },
            onSearchChanged: (query) {
              context
                  .read<LetterListBloc>()
                  .add(LetterListSearchChanged(query));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, LetterListState state) {
    return Row(
      children: [
        _StatCard(
          title: 'Total',
          value: state.letters.length.toString(),
          icon: Icons.mail,
          color: Colors.blue,
        ),
        const Gap(12),
        _StatCard(
          title: 'Pending',
          value: state.pendingApprovalCount.toString(),
          icon: Icons.hourglass_empty,
          color: Colors.amber,
        ),
        const Gap(12),
        _StatCard(
          title: 'In Transit',
          value: state.inTransitCount.toString(),
          icon: Icons.local_shipping,
          color: Colors.orange,
        ),
        const Gap(12),
        _StatCard(
          title: 'Delivered',
          value: state.deliveredCount.toString(),
          icon: Icons.done_all,
          color: Colors.green,
        ),
        const Gap(12),
        _StatCard(
          title: 'Total Cost',
          value: '\$${state.totalCost.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, LetterListState state) {
    return switch (state.status) {
      LetterListStatus.initial ||
      LetterListStatus.loading when state.letters.isEmpty =>
        const Center(child: CircularProgressIndicator()),
      LetterListStatus.failure when state.letters.isEmpty => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const Gap(16),
              Text(state.errorMessage ?? 'Failed to load letters'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => context
                    .read<LetterListBloc>()
                    .add(const LetterListRefreshRequested()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      _ when state.filteredLetters.isEmpty => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mail_outline,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const Gap(16),
              Text(
                state.searchQuery.isNotEmpty || state.statusFilter != null
                    ? 'No letters match your filters'
                    : 'No letters yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              if (state.searchQuery.isEmpty && state.statusFilter == null) ...[
                const Gap(8),
                Text(
                  'Letters will appear here when created from disputes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ],
          ),
        ),
      _ => RefreshIndicator(
          onRefresh: () async {
            context
                .read<LetterListBloc>()
                .add(const LetterListRefreshRequested());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.filteredLetters.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.filteredLetters.length) {
                // Load more indicator
                context
                    .read<LetterListBloc>()
                    .add(const LetterListLoadMoreRequested());
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final letter = state.filteredLetters[index];
              return LetterListItem(
                letter: letter,
                onTap: () => context.go('/letters/${letter.id}'),
              );
            },
          ),
        ),
    };
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
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
}
