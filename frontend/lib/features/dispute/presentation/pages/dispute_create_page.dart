import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_create_bloc.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_create_event.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_create_state.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/bureau_selector.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/consumer_selector.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/dispute_type_selector.dart';
import 'package:sfdify_scm/features/dispute/presentation/widgets/reason_code_picker.dart';
import 'package:sfdify_scm/injection/injection.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _narrativeController = TextEditingController();

  String? _selectedBureau;
  String? _selectedType;
  List<String> _selectedReasonCodes = [];
  String _selectedPriority = 'medium';

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  void _submitForm(DisputeCreateState state) {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a dispute type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<DisputeCreateBloc>().add(
            DisputeCreateSubmitted(
              consumerId: state.selectedConsumerId!,
              bureau: _selectedBureau!,
              type: _selectedType!,
              reasonCodes: _selectedReasonCodes,
              narrative: _narrativeController.text.trim(),
              priority: _selectedPriority,
            ),
          );
    }
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
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildForm(context, state),
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
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, DisputeCreateState state) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Step 1: Consumer Selection
          _buildSection(
            context,
            title: '1. Select Consumer',
            child: ConsumerSelector(
              consumers: state.consumers,
              selectedConsumerId: state.selectedConsumerId,
              onChanged: (consumerId) {
                context
                    .read<DisputeCreateBloc>()
                    .add(DisputeCreateConsumerChanged(consumerId));
              },
            ),
          ),
          const Gap(24),

          // Step 2: Bureau Selection
          _buildSection(
            context,
            title: '2. Select Bureau',
            child: BureauSelector(
              selectedBureau: _selectedBureau,
              onChanged: (bureau) {
                setState(() => _selectedBureau = bureau);
              },
            ),
          ),
          const Gap(24),

          // Step 3: Dispute Type
          _buildSection(
            context,
            title: '3. Dispute Type',
            child: DisputeTypeSelector(
              selectedType: _selectedType,
              onChanged: (type) {
                setState(() => _selectedType = type);
              },
            ),
          ),
          const Gap(24),

          // Step 4: Reason Codes
          _buildSection(
            context,
            title: '4. Reason Codes',
            child: ReasonCodePicker(
              selectedCodes: _selectedReasonCodes,
              onChanged: (codes) {
                setState(() => _selectedReasonCodes = codes);
              },
            ),
          ),
          const Gap(24),

          // Step 5: Narrative
          _buildSection(
            context,
            title: '5. Dispute Narrative',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _narrativeController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe the dispute in detail. Include specific facts and dates...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(8),
                Text(
                  'Provide a clear and detailed narrative explaining why this information is being disputed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Step 6: Priority
          _buildSection(
            context,
            title: '6. Priority',
            child: Row(
              children: ['low', 'medium', 'high', 'urgent'].map((priority) {
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
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(32),

          // Submit Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/disputes'),
                child: const Text('Cancel'),
              ),
              const Gap(16),
              FilledButton.icon(
                onPressed: state.status == DisputeCreateStatus.submitting
                    ? null
                    : () => _submitForm(state),
                icon: state.status == DisputeCreateStatus.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, size: 18),
                label: const Text('Create Dispute'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
