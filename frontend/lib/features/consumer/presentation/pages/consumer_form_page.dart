import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_form_bloc.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_form_event.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_form_state.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/address_form_field.dart';
import 'package:ustaxx_csm/features/consumer/presentation/widgets/phone_form_field.dart';
import 'package:ustaxx_csm/injection/injection.dart';

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
  final _ssnLast4Controller = TextEditingController();
  final _smartCreditUsernameController = TextEditingController();
  final _smartCreditPasswordController = TextEditingController();
  DateTime? _dateOfBirth;
  String _smartCreditSource = 'smart_credit';
  bool _hasConsent = false;
  bool _showSmartCreditPassword = false;

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
    _ssnLast4Controller.dispose();
    _smartCreditUsernameController.dispose();
    _smartCreditPasswordController.dispose();
    super.dispose();
  }

  void _populateForm(ConsumerFormState state) {
    if (state.consumer != null) {
      _firstNameController.text = state.consumer!.firstName;
      _lastNameController.text = state.consumer!.lastName;
      _emailController.text = state.consumer!.email;
      _phoneController.text = state.consumer!.phone ?? '';
      _ssnLast4Controller.text = state.consumer!.ssnLast4 ?? '';
      _dateOfBirth = state.consumer!.dateOfBirth;
      _smartCreditUsernameController.text = state.consumer!.smartCreditUsername ?? '';
      if (state.consumer!.smartCreditSource != null) {
        _smartCreditSource = _smartCreditSourceToString(state.consumer!.smartCreditSource!);
      }
      // Populate address from primary address
      final primaryAddress = state.consumer!.primaryAddress;
      if (primaryAddress != null) {
        _streetController.text = primaryAddress.street;
        _cityController.text = primaryAddress.city;
        _stateController.text = primaryAddress.state;
        _zipCodeController.text = primaryAddress.zipCode;
      }
      _hasConsent = state.consumer!.hasConsent;
    }
  }

  String _smartCreditSourceToString(dynamic source) {
    if (source.toString().contains('smartCredit')) return 'smart_credit';
    if (source.toString().contains('identityIq')) return 'identity_iq';
    if (source.toString().contains('myScoreIq')) return 'my_score_iq';
    return 'smart_credit';
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      helpText: 'Select Date of Birth',
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
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
              dateOfBirth: _dateOfBirth,
              ssnLast4: _ssnLast4Controller.text.trim(),
              street: _streetController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              zipCode: _zipCodeController.text.trim(),
              smartCreditSource: _smartCreditSource,
              smartCreditUsername: _smartCreditUsernameController.text.trim(),
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

  Widget _buildSmartCreditSection(BuildContext context, ConsumerFormState state) {
    final theme = Theme.of(context);
    final isConnected = state.consumer?.isSmartCreditConnected ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.link : Icons.link_off,
                color: isConnected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                size: 20,
              ),
              const Gap(8),
              Text(
                'Credit Report Connection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const Gap(4),
                      Text(
                        'Connected',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(16),

          // Source Dropdown
          DropdownButtonFormField<String>(
            value: _smartCreditSource,
            decoration: const InputDecoration(
              labelText: 'Credit Report Provider',
              prefixIcon: Icon(Icons.credit_score),
            ),
            items: const [
              DropdownMenuItem(
                value: 'smart_credit',
                child: Text('SmartCredit'),
              ),
              DropdownMenuItem(
                value: 'identity_iq',
                child: Text('IdentityIQ'),
              ),
              DropdownMenuItem(
                value: 'my_score_iq',
                child: Text('MyScoreIQ'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _smartCreditSource = value;
                });
              }
            },
          ),
          const Gap(16),

          // Username field
          TextFormField(
            controller: _smartCreditUsernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter credit provider username',
              prefixIcon: Icon(Icons.account_circle_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const Gap(16),

          // Password field (only for OAuth flow)
          if (!isConnected) ...[
            TextFormField(
              controller: _smartCreditPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter credit provider password',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showSmartCreditPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSmartCreditPassword = !_showSmartCreditPassword;
                    });
                  },
                ),
                helperText: 'Password is used only for OAuth connection and is not stored',
              ),
              obscureText: !_showSmartCreditPassword,
              textInputAction: TextInputAction.done,
            ),
            const Gap(16),

            // Connect Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SmartCredit OAuth connection coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect to Credit Provider'),
              ),
            ),
          ] else ...[
            // Disconnect Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disconnect functionality coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
              ),
            ),
          ],
        ],
      ),
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
              const Gap(16),

              // DOB and SSN Last 4 Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _dateOfBirth != null ? _formatDate(_dateOfBirth!) : '',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth *',
                        hintText: 'MM/DD/YYYY',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDateOfBirth(context),
                        ),
                      ),
                      onTap: () => _selectDateOfBirth(context),
                      validator: (value) {
                        if (_dateOfBirth == null) {
                          return 'Date of birth is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _ssnLast4Controller,
                      decoration: const InputDecoration(
                        labelText: 'SSN Last 4 *',
                        hintText: '1234',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'SSN last 4 is required';
                        }
                        if (value.length != 4 || int.tryParse(value) == null) {
                          return 'Enter 4 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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

              // SmartCredit Credentials Section
              _buildSmartCreditSection(context, state),
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
                            'authorizing USTAXX to pull their credit report, submit disputes '
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
