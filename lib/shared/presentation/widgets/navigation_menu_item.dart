import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A navigation menu item widget for the sidebar
///
/// Displays an icon and label with active state styling
class NavigationMenuItem extends StatelessWidget {
  const NavigationMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? colorScheme.primary : colorScheme.onSurface,
            ),
            const Gap(12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isActive ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
