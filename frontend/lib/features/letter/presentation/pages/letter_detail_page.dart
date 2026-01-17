import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_bloc.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_event.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_state.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_actions_panel.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_cost_breakdown.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_preview_card.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_tracking_timeline.dart';
import 'package:sfdify_scm/injection/injection.dart';

class LetterDetailPage extends StatelessWidget {
  const LetterDetailPage({
    super.key,
    required this.letterId,
  });

  final String letterId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LetterDetailBloc>()
        ..add(LetterDetailLoadRequested(letterId)),
      child: const LetterDetailView(),
    );
  }
}

class LetterDetailView extends StatelessWidget {
  const LetterDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LetterDetailBloc, LetterDetailState>(
      listener: (context, state) {
        if (state.actionStatus == LetterActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state.actionStatus == LetterActionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
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

  Widget _buildHeader(BuildContext context, LetterDetailState state) {
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/letters'),
            tooltip: 'Back to Letters',
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.letter?.typeDisplayName ?? 'Letter Details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.letter != null) ...[
                  const Gap(4),
                  Text(
                    'ID: ${state.letter!.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<LetterDetailBloc>()
                .add(const LetterDetailRefreshRequested()),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LetterDetailState state) {
    return switch (state.status) {
      LetterDetailStatus.initial ||
      LetterDetailStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      LetterDetailStatus.failure when state.letter == null => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const Gap(16),
              Text(state.errorMessage ?? 'Failed to load letter'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => context.go('/letters'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      _ when state.letter != null => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content - Letter preview
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    LetterPreviewCard(letter: state.letter!),
                    const Gap(24),
                    LetterTrackingTimeline(letter: state.letter!),
                  ],
                ),
              ),
              const Gap(24),
              // Sidebar - Actions and cost
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    LetterActionsPanel(
                      letter: state.letter!,
                      state: state,
                    ),
                    const Gap(16),
                    LetterCostBreakdown(letter: state.letter!),
                    const Gap(16),
                    // Related dispute link
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.gavel,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Related Dispute'),
                        subtitle: Text(
                          'ID: ${state.letter!.disputeId}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/disputes/${state.letter!.disputeId}'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
