import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';

/// Card widget for displaying a letter template in the library
class TemplateLibraryCard extends StatelessWidget {
  const TemplateLibraryCard({
    super.key,
    required this.template,
    required this.onPreview,
    required this.onUse,
  });

  final LetterTemplateEntity template;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPreview,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and badges
              Row(
                children: [
                  // Template type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(template.type),
                      size: 20,
                      color: _getTypeColor(template.type),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          template.typeDisplayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // System template badge
                  if (template.isSystemTemplate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'System',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(12),

              // Description
              Expanded(
                child: Text(
                  template.description ?? 'No description available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Gap(12),

              // Legal citations
              if (template.legalCitations.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.legalCitations.take(2).map((citation) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        citation,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Gap(12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPreview,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Preview'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onUse,
                      icon: const Icon(Icons.edit_document, size: 16),
                      label: const Text('Use'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: theme.textTheme.labelMedium,
                      ),
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

  IconData _getTypeIcon(String type) {
    return switch (type) {
      '609_request' => Icons.description,
      '611_dispute' => Icons.gavel,
      '605b_id_theft' => Icons.security,
      'mov_request' => Icons.fact_check,
      'reinvestigation' => Icons.refresh,
      'goodwill' => Icons.volunteer_activism,
      'pay_for_delete' => Icons.payments,
      'identity_theft_block' => Icons.shield,
      'cfpb_complaint' => Icons.report,
      'cease_desist' => Icons.block,
      'debt_validation' => Icons.verified_user,
      _ => Icons.mail,
    };
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      '609_request' || '611_dispute' || '605b_id_theft' || 'mov_request' => Colors.blue,
      'goodwill' || 'pay_for_delete' => Colors.purple,
      'debt_validation' || 'cease_desist' => Colors.red,
      'cfpb_complaint' => Colors.orange,
      _ => Colors.grey,
    };
  }
}
