import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class EvidenceUploadZone extends StatefulWidget {
  const EvidenceUploadZone({
    super.key,
    required this.onFilePicked,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    this.maxSizeBytes = 10 * 1024 * 1024, // 10 MB
  });

  final void Function(String filename, int fileSize, String mimeType, List<int> bytes) onFilePicked;
  final List<String> allowedExtensions;
  final int maxSizeBytes;

  @override
  State<EvidenceUploadZone> createState() => _EvidenceUploadZoneState();
}

class _EvidenceUploadZoneState extends State<EvidenceUploadZone> {
  bool _isDragging = false;

  String get _allowedExtensionsText {
    return widget.allowedExtensions.map((e) => '.$e').join(', ');
  }

  String get _maxSizeText {
    final mb = widget.maxSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragging = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragging = false);
        // Handle dropped files - in web this would use html.FileUploadInputElement
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: _isDragging ? 2 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: _isDragging
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(16),
              Text(
                'Drag & drop files here',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                'or',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Gap(8),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Browse Files'),
              ),
              const Gap(16),
              Text(
                'Accepted formats: $_allowedExtensionsText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Gap(4),
              Text(
                'Maximum file size: $_maxSizeText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickFile() {
    // In a real implementation, this would use file_picker package
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker would open here'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
