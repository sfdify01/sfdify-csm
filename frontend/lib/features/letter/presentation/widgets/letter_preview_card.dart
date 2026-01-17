import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class LetterPreviewCard extends StatelessWidget {
  const LetterPreviewCard({
    super.key,
    required this.letter,
  });

  final LetterEntity letter;

  Future<void> _openPdf() async {
    if (letter.pdfUrl != null) {
      final uri = Uri.parse(letter.pdfUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Letter Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (letter.pdfUrl != null)
                  TextButton.icon(
                    onPressed: _openPdf,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open PDF'),
                  ),
              ],
            ),
          ),
          // Preview content
          if (letter.pdfUrl != null) ...[
            Container(
              height: 400,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const Gap(16),
                    Text(
                      'PDF Available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Gap(8),
                    FilledButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: letter.contentMarkdown != null
                  ? SelectableText(
                      letter.contentMarkdown!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    )
                  : Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const Gap(8),
                          Text(
                            'Letter content not yet generated',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
          // Address info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${letter.recipientAddress.street1}\n${letter.recipientAddress.city}, ${letter.recipientAddress.state} ${letter.recipientAddress.zip}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Address',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${letter.returnAddress.street1}\n${letter.returnAddress.city}, ${letter.returnAddress.state} ${letter.returnAddress.zip}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
