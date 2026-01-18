import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/tradeline_entity.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_bloc.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_event.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_state.dart';
import 'package:ustaxx_csm/features/dispute/presentation/widgets/consumer_selector.dart';
import 'package:ustaxx_csm/features/dispute/presentation/widgets/reason_code_picker.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';
import 'package:ustaxx_csm/injection/injection.dart';

class DisputeCreatePage extends StatelessWidget {
  const DisputeCreatePage({
    super.key,
    this.preselectedConsumerId,
  });

  final String? preselectedConsumerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DisputeCreateBloc>()
        ..add(DisputeCreateLoadRequested(
            preselectedConsumerId: preselectedConsumerId)),
      child: const DisputeCreateView(),
    );
  }
}

class DisputeCreateView extends StatefulWidget {
  const DisputeCreateView({super.key});

  @override
  State<DisputeCreateView> createState() => _DisputeCreateViewState();
}

class _DisputeCreateViewState extends State<DisputeCreateView> {
  final _narrativeController = TextEditingController();
  final _creditorNameController = TextEditingController();
  final _creditorAddressController = TextEditingController();
  List<String> _selectedReasonCodes = [];
  String _selectedPriority = 'medium';

  @override
  void dispose() {
    _narrativeController.dispose();
    _creditorNameController.dispose();
    _creditorAddressController.dispose();
    super.dispose();
  }

  void _submitDispute(DisputeCreateState state) {
    if (!state.canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Determine bureau from selected tradelines
    final bureaus = state.selectedTradelines
        .map((t) => t.bureau)
        .toSet()
        .toList();
    final primaryBureau = state.selectedBureaus.isNotEmpty
        ? state.selectedBureaus.first
        : (bureaus.isNotEmpty ? bureaus.first : 'equifax');

    context.read<DisputeCreateBloc>().add(
          DisputeCreateSubmitted(
            consumerId: state.selectedConsumerId!,
            bureau: primaryBureau,
            type: state.selectedTemplate?.type ?? '611_dispute',
            reasonCodes: _selectedReasonCodes,
            narrative: _narrativeController.text.trim(),
            priority: _selectedPriority,
            tradelineIds: state.selectedTradelineIds,
            templateId: state.selectedTemplateId,
            recipientType: state.recipientType,
            creditorName: state.creditorName,
            creditorAddress: state.creditorAddress,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DisputeCreateBloc, DisputeCreateState>(
      listener: (context, state) {
        if (state.status == DisputeCreateStatus.success &&
            state.savedDispute != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispute created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/disputes/${state.savedDispute!.id}');
        }
        if (state.status == DisputeCreateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state.status) {
          DisputeCreateStatus.initial ||
          DisputeCreateStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          DisputeCreateStatus.failure when state.consumers.isEmpty => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const Gap(16),
                  Text(state.errorMessage ?? 'Failed to load data'),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () => context.go('/disputes'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          _ => Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: Row(
                    children: [
                      // Stepper sidebar
                      _buildStepperSidebar(context, state),
                      // Main content
                      Expanded(
                        child: _buildStepContent(context, state),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        };
      },
    );
  }

  Widget _buildHeader(BuildContext context, DisputeCreateState state) {
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
          Text(
            'Create New Dispute',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Progress indicator
          Text(
            'Step ${state.currentStep + 1} of 4',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperSidebar(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    final steps = [
      _StepInfo(
        title: 'Select Items',
        subtitle: 'Choose consumer & tradelines',
        isComplete: state.isStep1Valid,
        isActive: state.currentStep == 0,
      ),
      _StepInfo(
        title: 'Letter Type',
        subtitle: 'Choose dispute template',
        isComplete: state.isStep2Valid,
        isActive: state.currentStep == 1,
      ),
      _StepInfo(
        title: 'Recipients',
        subtitle: 'Select bureaus/creditors',
        isComplete: state.isStep3Valid,
        isActive: state.currentStep == 2,
      ),
      _StepInfo(
        title: 'Review & Submit',
        subtitle: 'Confirm and create',
        isComplete: false,
        isActive: state.currentStep == 3,
      ),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isEnabled = index == 0 ||
                    (index == 1 && state.isStep1Valid) ||
                    (index == 2 && state.isStep2Valid) ||
                    (index == 3 && state.isStep3Valid);

                return InkWell(
                  onTap: isEnabled
                      ? () => context
                          .read<DisputeCreateBloc>()
                          .add(DisputeCreateStepChanged(index))
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: step.isActive
                          ? theme.colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: step.isComplete
                                ? Colors.green
                                : step.isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: step.isComplete
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: step.isActive
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: step.isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                step.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: switch (state.currentStep) {
                  0 => _buildStep1ConsumerTradelines(context, state),
                  1 => _buildStep2LetterType(context, state),
                  2 => _buildStep3Recipients(context, state),
                  3 => _buildStep4Review(context, state),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ),
        // Bottom navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.currentStep > 0)
                OutlinedButton.icon(
                  onPressed: () => context.read<DisputeCreateBloc>().add(
                      DisputeCreateStepChanged(state.currentStep - 1)),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/disputes'),
                    child: const Text('Cancel'),
                  ),
                  const Gap(8),
                  if (state.currentStep < 3)
                    FilledButton.icon(
                      onPressed: _canProceed(state)
                          ? () => context.read<DisputeCreateBloc>().add(
                              DisputeCreateStepChanged(state.currentStep + 1))
                          : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Continue'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: state.status == DisputeCreateStatus.submitting
                          ? null
                          : () => _submitDispute(state),
                      icon: state.status == DisputeCreateStatus.submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: const Text('Create Dispute'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canProceed(DisputeCreateState state) {
    return switch (state.currentStep) {
      0 => state.isStep1Valid,
      1 => state.isStep2Valid,
      2 => state.isStep3Valid,
      _ => true,
    };
  }

  Widget _buildStep1ConsumerTradelines(
      BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Consumer & Tradelines',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          'Choose the consumer and select which tradelines to dispute.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Gap(24),

        // Consumer selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consumer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),
                ConsumerSelector(
                  consumers: state.consumers,
                  selectedConsumerId: state.selectedConsumerId,
                  onChanged: (consumerId) {
                    context
                        .read<DisputeCreateBloc>()
                        .add(DisputeCreateConsumerChanged(consumerId));
                  },
                ),
              ],
            ),
          ),
        ),
        const Gap(24),

        // Tradelines
        if (state.selectedConsumerId != null) ...[
          if (state.status == DisputeCreateStatus.loadingTradelines)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.tradelines.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const Gap(16),
                      Text(
                        'No tradelines found',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Gap(8),
                      Text(
                        'Import a credit report to see tradelines',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _buildTradelineSelection(context, state),
        ],
      ],
    );
  }

  Widget _buildTradelineSelection(
      BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    // Group tradelines by bureau
    final bureauGroups = <String, List<TradelineEntity>>{};
    for (final tl in state.tradelines) {
      bureauGroups.putIfAbsent(tl.bureau, () => []).add(tl);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Tradelines to Dispute',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${state.selectedTradelineIds.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(8),
                    TextButton(
                      onPressed: () => context.read<DisputeCreateBloc>().add(
                          const DisputeCreateSelectAllTradelines(
                              selected: true)),
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () => context.read<DisputeCreateBloc>().add(
                          const DisputeCreateSelectAllTradelines(
                              selected: false)),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            ...bureauGroups.entries.map((entry) {
              final bureau = entry.key;
              final tradelines = entry.value;
              final bureauSelectedCount = tradelines
                  .where((t) => state.selectedTradelineIds.contains(t.id))
                  .length;

              return ExpansionTile(
                title: Row(
                  children: [
                    _getBureauIcon(bureau),
                    const Gap(12),
                    Text(
                      _getBureauName(bureau),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bureauSelectedCount > 0
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$bureauSelectedCount/${tradelines.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: bureauSelectedCount > 0
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children: tradelines.map((tl) {
                  final isSelected =
                      state.selectedTradelineIds.contains(tl.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => context
                        .read<DisputeCreateBloc>()
                        .add(DisputeCreateTradelineToggled(tl.id)),
                    title: Text(tl.creditorName),
                    subtitle: Row(
                      children: [
                        Text(
                          tl.accountTypeDisplayName,
                          style: theme.textTheme.bodySmall,
                        ),
                        const Gap(8),
                        Text(
                          tl.accountNumberMasked ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const Gap(8),
                        _buildStatusChip(context, tl),
                      ],
                    ),
                    secondary: Text(
                      tl.formattedBalance,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, TradelineEntity tl) {
    Color color;
    String text;

    if (tl.isCollection) {
      color = Colors.red;
      text = 'Collection';
    } else if (tl.hasLatePayments) {
      color = Colors.orange;
      text = 'Late';
    } else {
      color = Colors.green;
      text = 'Current';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStep2LetterType(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    // Group templates by category
    final bureauTemplates = state.templates
        .where((t) =>
            t.type == '609_request' ||
            t.type == '611_dispute' ||
            t.type == '605b_id_theft' ||
            t.type == 'mov_request')
        .toList();
    final creditorTemplates = state.templates
        .where((t) => t.type == 'goodwill' || t.type == 'pay_for_delete')
        .toList();
    final collectorTemplates = state.templates
        .where((t) => t.type == 'debt_validation' || t.type == 'cease_desist')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Letter Type',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          'Choose the type of dispute letter to send.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Gap(24),

        _buildTemplateCategory(
          context,
          state,
          title: 'Bureau Dispute Letters',
          description: 'Letters sent directly to credit bureaus',
          templates: bureauTemplates,
          icon: Icons.account_balance,
        ),
        const Gap(16),

        _buildTemplateCategory(
          context,
          state,
          title: 'Creditor Letters',
          description: 'Letters sent to original creditors',
          templates: creditorTemplates,
          icon: Icons.business,
        ),
        const Gap(16),

        _buildTemplateCategory(
          context,
          state,
          title: 'Collector Letters',
          description: 'Letters sent to debt collectors',
          templates: collectorTemplates,
          icon: Icons.phone_in_talk,
        ),
      ],
    );
  }

  Widget _buildTemplateCategory(
    BuildContext context,
    DisputeCreateState state, {
    required String title,
    required String description,
    required List<LetterTemplateEntity> templates,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates.map((template) {
                final isSelected = state.selectedTemplateId == template.id;
                return ChoiceChip(
                  label: Text(template.name),
                  selected: isSelected,
                  onSelected: (_) => context
                      .read<DisputeCreateBloc>()
                      .add(DisputeCreateTemplateChanged(template.id)),
                  avatar: isSelected
                      ? const Icon(Icons.check, size: 16)
                      : null,
                );
              }).toList(),
            ),
            if (templates.any((t) => t.id == state.selectedTemplateId)) ...[
              const Gap(16),
              const Divider(),
              const Gap(8),
              _buildSelectedTemplatePreview(
                context,
                templates.firstWhere((t) => t.id == state.selectedTemplateId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTemplatePreview(
      BuildContext context, LetterTemplateEntity template) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description,
                  size: 16, color: theme.colorScheme.primary),
              const Gap(8),
              Text(
                'Selected: ${template.name}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (template.description != null) ...[
            const Gap(8),
            Text(
              template.description!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (template.legalCitations.isNotEmpty) ...[
            const Gap(8),
            Wrap(
              spacing: 4,
              children: template.legalCitations.map((citation) {
                return Chip(
                  label: Text(
                    citation,
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Recipients(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Recipients',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          'Choose who should receive this dispute letter.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Gap(24),

        // Recipient type selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipient Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(16),
                SegmentedButton<RecipientType>(
                  segments: const [
                    ButtonSegment(
                      value: RecipientType.bureau,
                      icon: Icon(Icons.account_balance),
                      label: Text('Credit Bureaus'),
                    ),
                    ButtonSegment(
                      value: RecipientType.creditor,
                      icon: Icon(Icons.business),
                      label: Text('Creditor'),
                    ),
                    ButtonSegment(
                      value: RecipientType.collector,
                      icon: Icon(Icons.phone_in_talk),
                      label: Text('Collector'),
                    ),
                  ],
                  selected: {state.recipientType},
                  onSelectionChanged: (selected) {
                    context.read<DisputeCreateBloc>().add(
                        DisputeCreateRecipientTypeChanged(selected.first));
                  },
                ),
              ],
            ),
          ),
        ),
        const Gap(16),

        // Bureau selection
        if (state.recipientType == RecipientType.bureau)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Bureaus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(16),
                  ...['equifax', 'experian', 'transunion'].map((bureau) {
                    final isSelected = state.selectedBureaus.contains(bureau);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => context
                          .read<DisputeCreateBloc>()
                          .add(DisputeCreateBureauToggled(bureau)),
                      title: Row(
                        children: [
                          _getBureauIcon(bureau),
                          const Gap(12),
                          Text(_getBureauName(bureau)),
                        ],
                      ),
                      secondary: Text(
                        '${state.tradelines.where((t) => t.bureau == bureau).length} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Creditor/Collector info
        if (state.recipientType != RecipientType.bureau)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.recipientType == RecipientType.creditor
                        ? 'Creditor Information'
                        : 'Collector Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _creditorNameController,
                    decoration: InputDecoration(
                      labelText: state.recipientType == RecipientType.creditor
                          ? 'Creditor Name'
                          : 'Collector Name',
                      hintText: 'Enter company name',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => context.read<DisputeCreateBloc>().add(
                        DisputeCreateCreditorChanged(name: value)),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _creditorAddressController,
                    decoration: InputDecoration(
                      labelText: 'Mailing Address',
                      hintText: 'Enter full mailing address',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => context.read<DisputeCreateBloc>().add(
                        DisputeCreateCreditorChanged(address: value)),
                  ),
                ],
              ),
            ),
          ),

        const Gap(16),

        // Additional options
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(16),
                ReasonCodePicker(
                  selectedCodes: _selectedReasonCodes,
                  onChanged: (codes) {
                    setState(() => _selectedReasonCodes = codes);
                  },
                ),
                const Gap(16),
                TextFormField(
                  controller: _narrativeController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Narrative (Optional)',
                    hintText: 'Add any specific details about your dispute...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const Gap(16),
                Row(
                  children: [
                    Text(
                      'Priority:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(16),
                    ...['low', 'medium', 'high', 'urgent'].map((priority) {
                      final isSelected = _selectedPriority == priority;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(priority.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedPriority = priority);
                          },
                          selectedColor: _getPriorityColor(priority),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Review(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          'Review your dispute details before submitting.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Gap(24),

        // Consumer summary
        _buildReviewCard(
          context,
          title: 'Consumer',
          icon: Icons.person,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.selectedConsumer?.fullName ?? 'Unknown',
                style: theme.textTheme.titleMedium,
              ),
              if (state.selectedConsumer?.email != null)
                Text(
                  state.selectedConsumer!.email!,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const Gap(16),

        // Tradelines summary
        _buildReviewCard(
          context,
          title: 'Tradelines (${state.selectedTradelineIds.length})',
          icon: Icons.receipt_long,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: state.selectedTradelines.map((tl) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _getBureauIcon(tl.bureau, size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        '${tl.creditorName} - ${tl.accountTypeDisplayName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      tl.formattedBalance,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const Gap(16),

        // Letter type summary
        _buildReviewCard(
          context,
          title: 'Letter Type',
          icon: Icons.description,
          content: Text(
            state.selectedTemplate?.name ?? 'Not selected',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Gap(16),

        // Recipients summary
        _buildReviewCard(
          context,
          title: 'Recipients',
          icon: Icons.send,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.recipientType == RecipientType.bureau)
                Wrap(
                  spacing: 8,
                  children: state.selectedBureaus.map((bureau) {
                    return Chip(
                      avatar: _getBureauIcon(bureau, size: 16),
                      label: Text(_getBureauName(bureau)),
                    );
                  }).toList(),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.recipientType == RecipientType.creditor
                          ? 'Creditor'
                          : 'Collector',
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      state.creditorName ?? 'Not specified',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Gap(16),

        // Details summary
        _buildReviewCard(
          context,
          title: 'Dispute Details',
          icon: Icons.info,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Priority:', style: theme.textTheme.bodyMedium),
                  const Gap(8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(_selectedPriority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedPriority.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedReasonCodes.isNotEmpty) ...[
                const Gap(8),
                Text('Reason Codes:', style: theme.textTheme.bodyMedium),
                const Gap(4),
                Wrap(
                  spacing: 4,
                  children: _selectedReasonCodes.map((code) {
                    return Chip(
                      label: Text(code, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (_narrativeController.text.isNotEmpty) ...[
                const Gap(8),
                Text('Narrative:', style: theme.textTheme.bodyMedium),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _narrativeController.text,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _getBureauIcon(String bureau, {double size = 24}) {
    Color color;
    IconData icon;

    switch (bureau.toLowerCase()) {
      case 'equifax':
        color = Colors.red;
        icon = Icons.account_balance;
        break;
      case 'experian':
        color = Colors.blue;
        icon = Icons.account_balance;
        break;
      case 'transunion':
        color = Colors.green;
        icon = Icons.account_balance;
        break;
      default:
        color = Colors.grey;
        icon = Icons.account_balance;
    }

    return Icon(icon, size: size, color: color);
  }

  String _getBureauName(String bureau) {
    return switch (bureau.toLowerCase()) {
      'equifax' => 'Equifax',
      'experian' => 'Experian',
      'transunion' => 'TransUnion',
      _ => bureau,
    };
  }

  Color _getPriorityColor(String priority) {
    return switch (priority) {
      'urgent' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.blue,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }
}

class _StepInfo {
  final String title;
  final String subtitle;
  final bool isComplete;
  final bool isActive;

  _StepInfo({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.isActive,
  });
}
