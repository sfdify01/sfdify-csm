import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sfdify_scm/injection/injection.dart';

/// Page for completing company setup after Google Sign-In.
///
/// Shown when a user signs in with Google but doesn't have
/// a tenant/company associated with their account yet.
class CompanySetupPage extends StatefulWidget {
  const CompanySetupPage({super.key});

  @override
  State<CompanySetupPage> createState() => _CompanySetupPageState();
}

class _CompanySetupPageState extends State<CompanySetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  String _selectedPlan = 'starter';

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  void _onCompleteSetup() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthGoogleSignUpCompleted(
              companyName: _companyNameController.text.trim(),
              plan: _selectedPlan,
            ),
          );
    }
  }

  void _onCancel() {
    // Sign out and go back to login
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(RoutePaths.home);
          } else if (state.status == AuthStatus.unauthenticated) {
            context.go(RoutePaths.login);
          }
        },
        builder: (context, state) {
          final userEmail = state.googleUserEmail ?? 'your account';
          final userName = state.googleUserDisplayName;

          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    minHeight: size.height - 48,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome icon
                        Icon(
                          Icons.celebration_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 24),

                        // Header
                        Text(
                          'Welcome${userName != null ? ', $userName' : ''}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your company setup to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Show email
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userEmail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Company Name
                        TextFormField(
                          controller: _companyNameController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onCompleteSetup(),
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business_outlined),
                            border: OutlineInputBorder(),
                            hintText: 'Your Credit Repair Company',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your company name';
                            }
                            if (value.trim().length < 2) {
                              return 'Company name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Plan Selection
                        DropdownButtonFormField<String>(
                          value: _selectedPlan,
                          decoration: const InputDecoration(
                            labelText: 'Plan',
                            prefixIcon: Icon(Icons.workspace_premium_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'starter',
                              child: Text('Starter (Free Trial)'),
                            ),
                            DropdownMenuItem(
                              value: 'professional',
                              child: Text('Professional'),
                            ),
                            DropdownMenuItem(
                              value: 'enterprise',
                              child: Text('Enterprise'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPlan = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Error message
                        if (state.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Complete Setup button
                        FilledButton(
                          onPressed: state.status == AuthStatus.loading
                              ? null
                              : _onCompleteSetup,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: state.status == AuthStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Complete Setup'),
                        ),
                        const SizedBox(height: 16),

                        // Cancel button
                        TextButton(
                          onPressed: state.status == AuthStatus.loading
                              ? null
                              : _onCancel,
                          child: const Text('Cancel and Sign Out'),
                        ),
                        const SizedBox(height: 24),

                        // Info text
                        Text(
                          'You can update your company details later in settings.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
