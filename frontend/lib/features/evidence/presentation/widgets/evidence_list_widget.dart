import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:sfdify_scm/features/evidence/presentation/widgets/evidence_preview_card.dart';
import 'package:sfdify_scm/features/letter/domain/entities/evidence_entity.dart';

class EvidenceListWidget extends StatefulWidget {
  const EvidenceListWidget({
    super.key,
    required this.evidenceList,
    this.onDelete,
    this.onUpload,
    this.showUploadButton = true,
    this.emptyMessage = 'No evidence documents yet',
  });

  final List<EvidenceEntity> evidenceList;
  final void Function(String evidenceId)? onDelete;
  final VoidCallback? onUpload;
  final bool showUploadButton;
  final String emptyMessage;

  @override
  State<EvidenceListWidget> createState() => _EvidenceListWidgetState();
}

class _EvidenceListWidgetState extends State<EvidenceListWidget> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: theme.colorScheme.primary,
            ),
            const Gap(8),
            Text(
              'Evidence Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.evidenceList.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            // View toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_list, size: 18),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.grid_view, size: 18),
                ),
              ],
              selected: {_isGridView},
              onSelectionChanged: (values) {
                setState(() => _isGridView = values.first);
              },
              showSelectedIcon: false,
            ),
            if (widget.showUploadButton) ...[
              const Gap(8),
              FilledButton.icon(
                onPressed: widget.onUpload,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Upload'),
              ),
            ],
          ],
        ),
        const Gap(16),
        // Content
        if (widget.evidenceList.isEmpty)
          _buildEmptyState(context)
        else if (_isGridView)
          _buildGridView(context)
        else
          _buildListView(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const Gap(16),
          Text(
            widget.emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (widget.showUploadButton) ...[
            const Gap(16),
            OutlinedButton.icon(
              onPressed: widget.onUpload,
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload Evidence'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Column(
      children: widget.evidenceList.map((evidence) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EvidencePreviewCard(
            evidence: evidence,
            onDelete: widget.onDelete != null
                ? () => widget.onDelete!(evidence.id)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridView(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: widget.evidenceList.map((evidence) {
        return SizedBox(
          width: 200,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getFileColor(evidence.mimeType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(evidence.mimeType),
                        color: _getFileColor(evidence.mimeType),
                        size: 24,
                      ),
                    ),
                    const Gap(12),
                    // Filename
                    Text(
                      evidence.filename,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    // Size
                    Text(
                      evidence.formattedFileSize,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Gap(4),
                    // Date
                    Text(
                      dateFormat.format(evidence.uploadedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
