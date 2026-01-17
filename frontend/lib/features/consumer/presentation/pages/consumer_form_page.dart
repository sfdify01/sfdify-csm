import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_form_bloc.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_form_event.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_form_state.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/address_form_field.dart';
import 'package:sfdify_scm/features/consumer/presentation/widgets/phone_form_field.dart';
import 'package:sfdify_scm/injection/injection.dart';

class ConsumerFormPage extends StatelessWidget {
  const ConsumerFormPage({
    super.key,
    this.consumerId,
  });

  final String? consumerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConsumerFormBloc>()
        ..add(ConsumerFormLoadRequested(consumerId: consumerId)),
      child: const ConsumerFormView(),
    );
  }
}

class ConsumerFormView extends StatefulWidget {
  const ConsumerFormView({super.key});

  @override
  State<ConsumerFormView> createState() => _ConsumerFormViewState();
}

class _ConsumerFormViewState extends State<ConsumerFormView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _hasConsent = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _populateForm(ConsumerFormState state) {
    if (state.consumer != null) {
      _firstNameController.text = state.consumer!.firstName;
      _lastNameController.text = state.consumer!.lastName;
      _emailController.text = state.consumer!.email;
      _phoneController.text = state.consumer!.phone ?? '';
      // Note: Address would need to be fetched from a more complete consumer model
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_hasConsent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please acknowledge the consent to proceed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<ConsumerFormBloc>().add(
            ConsumerFormSubmitted(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              street: _streetController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              zipCode: _zipCodeController.text.trim(),
              hasConsent: _hasConsent,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConsumerFormBloc, ConsumerFormState>(
      listener: (context, state) {
        if (state.status == ConsumerFormStatus.ready && state.isEditMode) {
          _populateForm(state);
        }
        if (state.status == ConsumerFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEditMode
                    ? 'Consumer updated successfully'
                    : 'Consumer created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          if (state.savedConsumer != null) {
            context.go('/consumers/${state.savedConsumer!.id}');
          } else {
            context.go('/consumers');
          }
        }
        if (state.status == ConsumerFormStatus.failure) {
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
          ConsumerFormStatus.initial ||
          ConsumerFormStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          _ => Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
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

  Widget _buildHeader(BuildContext context, ConsumerFormState state) {
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
            onPressed: () => context.go('/consumers'),
            tooltip: 'Back to Consumers',
          ),
          const Gap(8),
          Text(
            state.isEditMode ? 'Edit Consumer' : 'Add New Consumer',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, ConsumerFormState state) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),

              // Name Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        hintText: 'John',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        hintText: 'Doe',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'john.doe@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Phone
              PhoneFormField(
                controller: _phoneController,
              ),
              const Gap(24),

              // Address Section
              AddressFormField(
                streetController: _streetController,
                cityController: _cityController,
                stateController: _stateController,
                zipCodeController: _zipCodeController,
              ),
              const Gap(24),

              // Consent Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasConsent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _hasConsent,
                      onChanged: (value) {
                        setState(() {
                          _hasConsent = value ?? false;
                        });
                      },
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consumer Consent *',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'I acknowledge that the consumer has provided written consent '
                            'authorizing SFDIFY to pull their credit report, submit disputes '
                            'on their behalf, and communicate with credit bureaus regarding '
                            'their credit file under the Fair Credit Reporting Act (FCRA).',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Submit Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => context.go('/consumers'),
                    child: const Text('Cancel'),
                  ),
                  const Gap(16),
                  FilledButton.icon(
                    onPressed: state.status == ConsumerFormStatus.submitting
                        ? null
                        : _submitForm,
                    icon: state.status == ConsumerFormStatus.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      state.isEditMode ? 'Update Consumer' : 'Create Consumer',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
