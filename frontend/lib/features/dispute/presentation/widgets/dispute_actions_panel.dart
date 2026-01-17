import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

class DisputeActionsPanel extends StatelessWidget {
  const DisputeActionsPanel({
    super.key,
    required this.dispute,
    required this.isSubmitting,
    this.onSubmit,
    this.onApprove,
    this.onGenerateLetter,
    this.onClose,
    this.onViewLetter,
  });

  final DisputeEntity dispute;
  final bool isSubmitting;
  final VoidCallback? onSubmit;
  final VoidCallback? onApprove;
  final VoidCallback? onGenerateLetter;
  final VoidCallback? onClose;
  final VoidCallback? onViewLetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),

            // Primary Actions based on status
            ..._buildActions(context),

            const Gap(16),

            // Quick Links
            _buildQuickLinks(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    switch (dispute.status) {
      case 'draft':
        actions.add(_buildActionButton(
          context,
          label: 'Submit for Review',
          icon: Icons.send,
          onPressed: isSubmitting ? null : onSubmit,
          isPrimary: true,
        ));
        actions.add(const Gap(8));
        actions.add(_buildActionButton(
          context,
          label: 'Edit Dispute',
          icon: Icons.edit,
          onPressed: () {},
        ));
        break;

      case 'pending_review':
        actions.add(_buildActionButton(
          context,
          label: 'Approve Dispute',
          icon: Icons.check_circle,
          onPressed: isSubmitting ? null : onApprove,
          isPrimary: true,
        ));
        actions.add(const Gap(8));
        actions.add(_buildActionButton(
          context,
          label: 'Reject & Return',
          icon: Icons.cancel,
          onPressed: () {},
          isDestructive: true,
        ));
        break;

      case 'approved':
        actions.add(_buildActionButton(
          context,
          label: 'Generate Letter',
          icon: Icons.description,
          onPressed: onGenerateLetter,
          isPrimary: true,
        ));
        break;

      case 'mailed':
      case 'in_transit':
        actions.add(_buildActionButton(
          context,
          label: 'View Letter',
          icon: Icons.visibility,
          onPressed: onViewLetter,
        ));
        actions.add(const Gap(8));
        actions.add(_buildActionButton(
          context,
          label: 'Track Delivery',
          icon: Icons.local_shipping,
          onPressed: () {},
        ));
        break;

      case 'delivered':
      case 'bureau_investigating':
        actions.add(_buildActionButton(
          context,
          label: 'View Letter',
          icon: Icons.visibility,
          onPressed: onViewLetter,
        ));
        actions.add(const Gap(8));
        actions.add(_buildActionButton(
          context,
          label: 'Record Response',
          icon: Icons.reply,
          onPressed: () {},
          isPrimary: true,
        ));
        actions.add(const Gap(8));
        actions.add(_buildActionButton(
          context,
          label: 'Follow Up',
          icon: Icons.refresh,
          onPressed: onGenerateLetter,
        ));
        break;

      case 'resolved':
      case 'closed':
        actions.add(_buildActionButton(
          context,
          label: 'View Letter',
          icon: Icons.visibility,
          onPressed: onViewLetter,
        ));
        if (dispute.status != 'resolved') {
          actions.add(const Gap(8));
          actions.add(_buildActionButton(
            context,
            label: 'Reopen Dispute',
            icon: Icons.replay,
            onPressed: () {},
          ));
        }
        break;

      case 'cancelled':
        actions.add(_buildActionButton(
          context,
          label: 'Reopen Dispute',
          icon: Icons.replay,
          onPressed: () {},
        ));
        break;
    }

    // Always show close option if not already closed
    if (dispute.status != 'closed' &&
        dispute.status != 'cancelled' &&
        dispute.status != 'resolved') {
      actions.add(const Gap(8));
      actions.add(_buildActionButton(
        context,
        label: 'Close Dispute',
        icon: Icons.archive,
        onPressed: onClose,
        isDestructive: true,
      ));
    }

    return actions;
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: isSubmitting && onPressed == null
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }

    if (isDestructive) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Gap(16),
        Text(
          'Quick Links',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(8),
        if (dispute.consumer != null)
          _buildQuickLink(
            context,
            label: 'View Consumer',
            icon: Icons.person_outline,
            onTap: () {},
          ),
        _buildQuickLink(
          context,
          label: 'View All Letters',
          icon: Icons.mail_outline,
          onTap: () {},
        ),
        _buildQuickLink(
          context,
          label: 'Upload Evidence',
          icon: Icons.upload_file,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const Gap(8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
