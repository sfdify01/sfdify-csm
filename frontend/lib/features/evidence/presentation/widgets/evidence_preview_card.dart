import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/evidence_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class EvidencePreviewCard extends StatelessWidget {
  const EvidencePreviewCard({
    super.key,
    required this.evidence,
    this.onDelete,
    this.showActions = true,
  });

  final EvidenceEntity evidence;
  final VoidCallback? onDelete;
  final bool showActions;

  Future<void> _openFile() async {
    final uri = Uri.parse(evidence.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: _openFile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileColor(evidence.mimeType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(evidence.mimeType),
                  color: _getFileColor(evidence.mimeType),
                  size: 24,
                ),
              ),
              const Gap(16),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.filename,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Text(
                          evidence.formattedFileSize,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          evidence.fileTypeDisplayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (evidence.description != null &&
                        evidence.description!.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        evidence.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              if (showActions) ...[
                const Gap(16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: _openFile,
                      tooltip: 'Open',
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _showDeleteDialog(context),
                        tooltip: 'Delete',
                        color: theme.colorScheme.error,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Evidence'),
        content: Text(
          'Are you sure you want to delete "${evidence.filename}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    return Icons.attach_file;
  }

  Color _getFileColor(String mimeType) {
    if (mimeType == 'application/pdf') return Colors.red;
    if (mimeType.startsWith('image/')) return Colors.blue;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.indigo;
    }
    return Colors.grey;
  }
}
