import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/shared/presentation/widgets/navigation_menu_item.dart';
import 'package:sfdify_scm/shared/presentation/widgets/user_profile_card.dart';

/// Main navigation sidebar for the application
///
/// Contains logo, navigation menu, system section, and user profile
class AppNavigationSidebar extends StatelessWidget {
  const AppNavigationSidebar({
    this.currentRoute = '/',
    super.key,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // SFDIFY logo icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Text(
                  'SFDIFY',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Main navigation section
                NavigationMenuItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: currentRoute == RoutePaths.home,
                  onTap: () => context.go(RoutePaths.home),
                ),
                NavigationMenuItem(
                  icon: Icons.people,
                  label: 'Consumers',
                  isActive: currentRoute.startsWith('/consumers'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Consumers page coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                NavigationMenuItem(
                  icon: Icons.gavel,
                  label: 'Disputes',
                  isActive: currentRoute == RoutePaths.disputeOverview,
                  onTap: () => context.go(RoutePaths.disputeOverview),
                ),
                NavigationMenuItem(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  isActive: currentRoute.startsWith('/reports'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports page coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                NavigationMenuItem(
                  icon: Icons.mail,
                  label: 'Letters',
                  isActive: currentRoute.startsWith('/letters'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Letters page coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                const Gap(16),

                // System section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'SYSTEM',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const Gap(8),

                NavigationMenuItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isActive: currentRoute.startsWith('/settings'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings page coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                NavigationMenuItem(
                  icon: Icons.extension,
                  label: 'Integrations',
                  isActive: currentRoute.startsWith('/integrations'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Integrations page coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // User profile at bottom
          UserProfileCard(
            name: 'Jane Smith',
            role: 'Operator Admin',
            initials: 'JS',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile page coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
