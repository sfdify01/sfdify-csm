import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_detail_bloc.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_detail_event.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_detail_state.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_actions_panel.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_header_card.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_timeline.dart';
import 'package:sfdify_scm/injection/injection.dart';

class DisputeDetailPage extends StatelessWidget {
  const DisputeDetailPage({
    super.key,
    required this.disputeId,
  });

  final String disputeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DisputeDetailBloc>()
        ..add(DisputeDetailLoadRequested(disputeId)),
      child: const DisputeDetailView(),
    );
  }
}

class DisputeDetailView extends StatelessWidget {
  const DisputeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DisputeDetailBloc, DisputeDetailState>(
      listener: (context, state) {
        if (state.actionSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccess!),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state.status) {
          DisputeDetailStatus.initial ||
          DisputeDetailStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          DisputeDetailStatus.failure => Center(
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
                    state.errorMessage ?? 'Failed to load dispute',
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () => context.go('/disputes'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          DisputeDetailStatus.success => Column(
              children: [
                // Header
                _buildHeader(context, state),

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<DisputeDetailBloc>()
                          .add(const DisputeDetailRefreshRequested());
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
                                // Header Card with status, type, dates
                                DisputeHeaderCard(dispute: state.dispute!),
                                const Gap(24),

                                // Narrative Section
                                _buildNarrativeSection(context, state),
                                const Gap(24),

                                // Timeline
                                DisputeTimeline(dispute: state.dispute!),
                                const Gap(24),

                                // Reason Codes
                                _buildReasonCodesSection(context, state),
                              ],
                            ),
                          ),
                        ),

                        // Right sidebar with actions
                        SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: DisputeActionsPanel(
                              dispute: state.dispute!,
                              isSubmitting: state.isSubmitting,
                              onSubmit: () {
                                context
                                    .read<DisputeDetailBloc>()
                                    .add(const DisputeDetailSubmitRequested());
                              },
                              onApprove: () {
                                context
                                    .read<DisputeDetailBloc>()
                                    .add(const DisputeDetailApproveRequested());
                              },
                              onGenerateLetter: () {
                                context.go(
                                  '/disputes/${state.dispute!.id}/letters/new',
                                );
                              },
                              onClose: () =>
                                  _showCloseDialog(context, state.dispute!.id),
                              onViewLetter: () {
                                // Navigate to letters list for this dispute
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('View letter coming soon'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
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

  Widget _buildHeader(BuildContext context, DisputeDetailState state) {
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
            onPressed: () => context.go('/disputes'),
            tooltip: 'Back to Disputes',
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Details',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${state.dispute?.id ?? 'Unknown'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (state.dispute?.consumer != null) ...[
            OutlinedButton.icon(
              onPressed: () {
                context.go('/consumers/${state.dispute!.consumerId}');
              },
              icon: const Icon(Icons.person_outline, size: 18),
              label: Text(state.dispute!.consumer!.fullName),
            ),
            const Gap(8),
          ],
        ],
      ),
    );
  }

  Widget _buildNarrativeSection(
    BuildContext context,
    DisputeDetailState state,
  ) {
    final theme = Theme.of(context);
    final narrative = state.dispute?.narrative;

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
                  'Dispute Narrative',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.dispute?.status == 'draft')
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit narrative coming soon'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Edit',
                  ),
              ],
            ),
            const Gap(16),
            if (narrative != null && narrative.isNotEmpty)
              Text(
                narrative,
                style: theme.textTheme.bodyMedium,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const Gap(8),
                    Text(
                      'No narrative provided',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCodesSection(
    BuildContext context,
    DisputeDetailState state,
  ) {
    final theme = Theme.of(context);
    final reasonCodes = state.dispute?.reasonCodes ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason Codes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            if (reasonCodes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reasonCodes.map((code) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Text(
                'No reason codes specified',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCloseDialog(BuildContext context, String disputeId) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a resolution note:'),
            const Gap(16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter resolution details...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Close Dispute'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      context.read<DisputeDetailBloc>().add(DisputeDetailCloseRequested(result));
    }
  }
}
