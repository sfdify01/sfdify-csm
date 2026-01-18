import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/core/services/firebase_auth_service.dart';

/// User profile card displayed at the bottom of the navigation sidebar
///
/// Shows user avatar, name, and role with a menu for logout
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    this.authState,
    this.onLogout,
    super.key,
  });

  final AuthState? authState;
  final VoidCallback? onLogout;

  /// Extract initials from displayName or email
  String _getInitials() {
    if (authState == null) return '?';

    final name = authState?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        // Multi-word name: first two initials
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        // Single-word name: first letter
        return parts[0][0].toUpperCase();
      }
    }

    // Fallback to email first letter
    final email = authState?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  /// Get display name with fallback to email
  String _getDisplayName() {
    if (authState == null) return 'Unknown User';

    final name = authState?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    return authState?.email ?? 'Unknown User';
  }

  /// Get role display text
  String _getRoleDisplay() {
    if (authState == null) return 'NO ROLE';
    return authState?.role.name.toUpperCase() ?? 'NO ROLE';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar with initials
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: Text(
              _getInitials(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),

          // Name and role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getDisplayName(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getRoleDisplay(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                onLogout?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const Gap(12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
