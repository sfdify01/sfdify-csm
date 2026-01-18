import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_generate_bloc.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_generate_event.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_generate_state.dart';
import 'package:ustaxx_csm/features/letter/presentation/widgets/mail_type_selector.dart';
import 'package:ustaxx_csm/features/letter/presentation/widgets/template_selector.dart';
import 'package:ustaxx_csm/injection/injection.dart';

class LetterGeneratePage extends StatelessWidget {
  const LetterGeneratePage({
    super.key,
    required this.disputeId,
  });

  final String disputeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LetterGenerateBloc>()
        ..add(LetterGenerateLoadRequested(disputeId)),
      child: const LetterGenerateView(),
    );
  }
}

class LetterGenerateView extends StatelessWidget {
  const LetterGenerateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LetterGenerateBloc, LetterGenerateState>(
      listener: (context, state) {
        if (state.status == LetterGenerateStatus.success &&
            state.generatedLetter != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Letter generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/letters/${state.generatedLetter!.id}');
        }
        if (state.status == LetterGenerateStatus.failure) {
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

  Widget _buildHeader(BuildContext context, LetterGenerateState state) {
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
            onPressed: () {
              if (state.dispute != null) {
                context.go('/disputes/${state.dispute!.id}');
              } else {
                context.go('/disputes');
              }
            },
            tooltip: 'Back',
          ),
          const Gap(8),
          Text(
            'Generate Letter',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LetterGenerateState state) {
    return switch (state.status) {
      LetterGenerateStatus.initial ||
      LetterGenerateStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      LetterGenerateStatus.failure when state.dispute == null => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const Gap(16),
              Text(state.errorMessage ?? 'Failed to load dispute'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => context.go('/disputes'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      _ => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dispute info card
                  if (state.dispute != null) _buildDisputeCard(context, state),
                  const Gap(24),
                  // Template selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: TemplateSelector(
                        templates: state.templates,
                        selectedTemplateId: state.selectedTemplateId,
                        onChanged: (templateId) {
                          context
                              .read<LetterGenerateBloc>()
                              .add(LetterGenerateTemplateChanged(templateId));
                        },
                      ),
                    ),
                  ),
                  const Gap(24),
                  // Mail type selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MailTypeSelector(
                        selectedMailType: state.selectedMailType,
                        onChanged: (mailType) {
                          context
                              .read<LetterGenerateBloc>()
                              .add(LetterGenerateMailTypeChanged(mailType));
                        },
                      ),
                    ),
                  ),
                  const Gap(24),
                  // Cost summary
                  _buildCostSummary(context, state),
                  const Gap(32),
                  // Submit buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (state.dispute != null) {
                            context.go('/disputes/${state.dispute!.id}');
                          } else {
                            context.go('/disputes');
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const Gap(16),
                      FilledButton.icon(
                        onPressed: state.canSubmit &&
                                state.status != LetterGenerateStatus.submitting
                            ? () => context
                                .read<LetterGenerateBloc>()
                                .add(const LetterGenerateSubmitted())
                            : null,
                        icon: state.status == LetterGenerateStatus.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add, size: 18),
                        label: const Text('Generate Letter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    };
  }

  Widget _buildDisputeCard(BuildContext context, LetterGenerateState state) {
    final theme = Theme.of(context);
    final dispute = state.dispute!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Dispute Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                _InfoItem(
                  label: 'Bureau',
                  value: dispute.bureau.toUpperCase(),
                ),
                const Gap(24),
                _InfoItem(
                  label: 'Type',
                  value: dispute.typeDisplayName,
                ),
                const Gap(24),
                _InfoItem(
                  label: 'Status',
                  value: dispute.statusDisplayName,
                ),
              ],
            ),
            if (dispute.narrative?.isNotEmpty == true) ...[
              const Gap(12),
              Text(
                'Narrative:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Gap(4),
              Text(
                dispute.narrative ?? '',
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary(BuildContext context, LetterGenerateState state) {
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
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Estimated Cost',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Postage + Processing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '\$${state.estimatedCost.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'You will be able to review the letter before approving and sending.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
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
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
