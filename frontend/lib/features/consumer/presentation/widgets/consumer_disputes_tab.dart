import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';

class ConsumerDisputesTab extends StatefulWidget {
  const ConsumerDisputesTab({
    super.key,
    required this.disputes,
    required this.consumerId,
  });

  final List<DisputeEntity> disputes;
  final String consumerId;

  @override
  State<ConsumerDisputesTab> createState() => _ConsumerDisputesTabState();
}

class _ConsumerDisputesTabState extends State<ConsumerDisputesTab> {
  _LetterFilter _selectedFilter = _LetterFilter.unsent;
  final Set<String> _selectedDisputeIds = {};

  List<DisputeEntity> get _filteredDisputes {
    switch (_selectedFilter) {
      case _LetterFilter.unsent:
        // Letters with status draft, pending_review, or approved (not yet mailed)
        return widget.disputes.where((d) {
          final status = d.status.toLowerCase();
          return status == 'draft' ||
              status == 'pending_review' ||
              status == 'approved';
        }).toList();
      case _LetterFilter.sent:
        // Letters that have been mailed but not yet received a response
        return widget.disputes.where((d) {
          final status = d.status.toLowerCase();
          return status == 'mailed' ||
              status == 'in_transit' ||
              status == 'delivered' ||
              status == 'bureau_investigating';
        }).toList();
      case _LetterFilter.received:
        // Letters where we've received a response
        return widget.disputes.where((d) {
          final status = d.status.toLowerCase();
          return status == 'resolved' ||
              status == 'closed' ||
              status == 'response_received';
        }).toList();
    }
  }

  int get _unsentCount => widget.disputes.where((d) {
        final status = d.status.toLowerCase();
        return status == 'draft' ||
            status == 'pending_review' ||
            status == 'approved';
      }).length;

  int get _sentCount => widget.disputes.where((d) {
        final status = d.status.toLowerCase();
        return status == 'mailed' ||
            status == 'in_transit' ||
            status == 'delivered' ||
            status == 'bureau_investigating';
      }).length;

  int get _receivedCount => widget.disputes.where((d) {
        final status = d.status.toLowerCase();
        return status == 'resolved' ||
            status == 'closed' ||
            status == 'response_received';
      }).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action Buttons Row
        _buildActionButtonsRow(context),

        // Filter Tabs Row
        _buildFilterTabsRow(context),

        // Disputes List
        Expanded(
          child: _filteredDisputes.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _filteredDisputes.length,
                  itemBuilder: (context, index) {
                    return _buildDisputeItem(context, _filteredDisputes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () {
              context.go('/disputes/new?consumerId=${widget.consumerId}');
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Dispute'),
          ),
          OutlinedButton.icon(
            onPressed: _selectedDisputeIds.isEmpty
                ? null
                : () => _showReceivedReplyDialog(context),
            icon: const Icon(Icons.mail, size: 18),
            label: const Text('Received Reply'),
          ),
          OutlinedButton.icon(
            onPressed: _selectedDisputeIds.isEmpty
                ? null
                : () => _showFollowupDialog(context),
            icon: const Icon(Icons.repeat, size: 18),
            label: const Text('Followup'),
          ),
          OutlinedButton.icon(
            onPressed: () => _showOtherLetterDialog(context),
            icon: const Icon(Icons.edit_document, size: 18),
            label: const Text('Other Letter'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              context.go('/disputes?consumerId=${widget.consumerId}');
            },
            icon: const Icon(Icons.dashboard, size: 18),
            label: const Text('Overview'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabsRow(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildFilterTab(
            context,
            filter: _LetterFilter.unsent,
            label: 'Unsent',
            count: _unsentCount,
          ),
          const Gap(8),
          _buildFilterTab(
            context,
            filter: _LetterFilter.sent,
            label: 'Sent',
            count: _sentCount,
          ),
          const Gap(8),
          _buildFilterTab(
            context,
            filter: _LetterFilter.received,
            label: 'Received',
            count: _receivedCount,
          ),
          const Spacer(),
          if (_selectedDisputeIds.isNotEmpty)
            Text(
              '${_selectedDisputeIds.length} selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required _LetterFilter filter,
    required String label,
    required int count,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
            _selectedDisputeIds.clear();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    String message;
    String subMessage;
    IconData icon;

    switch (_selectedFilter) {
      case _LetterFilter.unsent:
        icon = Icons.drafts_outlined;
        message = 'No unsent letters';
        subMessage = 'Create a new dispute to generate letters';
        break;
      case _LetterFilter.sent:
        icon = Icons.local_shipping_outlined;
        message = 'No sent letters';
        subMessage = 'Letters will appear here after they are mailed';
        break;
      case _LetterFilter.received:
        icon = Icons.mark_email_read_outlined;
        message = 'No received replies';
        subMessage = 'Mark letters as received when you get a response';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const Gap(16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Gap(8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeItem(BuildContext context, DisputeEntity dispute) {
    final theme = Theme.of(context);
    final isSelected = _selectedDisputeIds.contains(dispute.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.go('/disputes/${dispute.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox for selection
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDisputeIds.add(dispute.id);
                    } else {
                      _selectedDisputeIds.remove(dispute.id);
                    }
                  });
                },
              ),
              const Gap(8),

              // Round Badge
              _buildRoundBadge(context, dispute),
              const Gap(12),

              // Dispute Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dispute.bureauDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        _buildStatusChip(context, dispute),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      dispute.typeDisplayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (dispute.createdAt != null) ...[
                      const Gap(2),
                      Text(
                        _formatDate(dispute.createdAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Days Remaining / Status
              if (_selectedFilter == _LetterFilter.sent &&
                  dispute.daysRemaining != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${dispute.daysRemaining}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dispute.isOverdue
                            ? Colors.red
                            : dispute.isSlaApproaching
                                ? Colors.orange
                                : theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'days left',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),

              const Gap(8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundBadge(BuildContext context, DisputeEntity dispute) {
    final theme = Theme.of(context);
    // TODO: Get actual round from dispute entity when implemented
    final round = 1;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'R$round',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, DisputeEntity dispute) {
    final color = _getStatusColor(dispute.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dispute.statusDisplayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'pending_review':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'mailed':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
      case 'bureau_investigating':
        return Colors.indigo;
      case 'resolved':
      case 'response_received':
        return Colors.green;
      case 'closed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showReceivedReplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now();

        return AlertDialog(
          title: const Text('Mark as Received'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark ${_selectedDisputeIds.length} dispute(s) as received.',
              ),
              const Gap(16),
              Text(
                'When did you receive the response?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Gap(8),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_formatDate(selectedDate)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Implement API call to mark disputes as received
                Navigator.of(context).pop();
                setState(() {
                  _selectedDisputeIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disputes marked as received'),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showFollowupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Followup Letter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create followup letters for ${_selectedDisputeIds.length} dispute(s)?',
              ),
              const Gap(8),
              Text(
                'This will create Round 2 letters for the selected disputes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Navigate to followup creation with selected disputes
                Navigator.of(context).pop();
                context.go(
                  '/disputes/new?consumerId=${widget.consumerId}&followup=true&disputes=${_selectedDisputeIds.join(",")}',
                );
              },
              child: const Text('Create Followup'),
            ),
          ],
        );
      },
    );
  }

  void _showOtherLetterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Other Letter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the type of letter to create:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(16),
              _buildLetterTypeOption(
                context,
                icon: Icons.volunteer_activism,
                title: 'Goodwill Letter',
                description: 'Request removal based on payment history',
              ),
              const Gap(8),
              _buildLetterTypeOption(
                context,
                icon: Icons.gavel,
                title: 'Cease & Desist',
                description: 'Stop collection communications',
              ),
              const Gap(8),
              _buildLetterTypeOption(
                context,
                icon: Icons.verified_user,
                title: 'Debt Validation',
                description: 'Request proof of debt ownership',
              ),
              const Gap(8),
              _buildLetterTypeOption(
                context,
                icon: Icons.money_off,
                title: 'Pay for Delete',
                description: 'Offer settlement for removal',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLetterTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          // TODO: Navigate to letter creation with selected type
          context.go(
            '/disputes/new?consumerId=${widget.consumerId}&letterType=${title.toLowerCase().replaceAll(' ', '_')}',
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LetterFilter {
  unsent,
  sent,
  received,
}
