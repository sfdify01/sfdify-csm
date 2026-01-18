import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

class ClientInfoTab extends StatelessWidget {
  const ClientInfoTab({
    super.key,
    required this.consumer,
  });

  final ConsumerEntity consumer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildPersonalInfoSection(context),
          const Gap(24),

          // Address Section
          _buildAddressSection(context),
          const Gap(24),

          // SmartCredit Connection Section
          _buildSmartCreditSection(context),
          const Gap(24),

          // Documents Section
          _buildDocumentsSection(context),
          const Gap(24),

          // Consent Section
          _buildConsentSection(context),
          const Gap(24),

          // Timestamps Section
          _buildTimestampsSection(context),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            _buildInfoRow('Full Name', consumer.fullName),
            _buildInfoRow('Email', consumer.email),
            if (consumer.phone != null && consumer.phone!.isNotEmpty)
              _buildInfoRow('Phone', consumer.phone!),
            if (consumer.dateOfBirth != null)
              _buildInfoRow('Date of Birth', consumer.formattedDateOfBirth ?? '-'),
            if (consumer.ssnLast4 != null && consumer.ssnLast4!.isNotEmpty)
              _buildInfoRow('SSN Last 4', '****${consumer.ssnLast4}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAddress = consumer.primaryAddress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            if (primaryAddress != null) ...[
              _buildInfoRow('Street', primaryAddress.street),
              if (primaryAddress.street2 != null && primaryAddress.street2!.isNotEmpty)
                _buildInfoRow('Street 2', primaryAddress.street2!),
              _buildInfoRow('City', primaryAddress.city),
              _buildInfoRow('State', primaryAddress.state),
              _buildInfoRow('ZIP Code', primaryAddress.zipCode),
            ] else ...[
              Text(
                'No address on file',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCreditSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_score, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Credit Report Connection',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: consumer.isSmartCreditConnected
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        consumer.isSmartCreditConnected
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color: consumer.isSmartCreditConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const Gap(4),
                      Text(
                        consumer.isSmartCreditConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          color: consumer.isSmartCreditConnected
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (consumer.smartCreditSource != null) ...[
              const Gap(12),
              _buildInfoRow('Provider', _formatSmartCreditSource(consumer.smartCreditSource!)),
            ],
            if (consumer.smartCreditUsername != null &&
                consumer.smartCreditUsername!.isNotEmpty) ...[
              const Gap(4),
              _buildInfoRow('Username', consumer.smartCreditUsername!),
            ],
            if (consumer.lastCreditReportAt != null) ...[
              const Gap(4),
              _buildInfoRow('Last Pulled', _formatDateTime(consumer.lastCreditReportAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document upload coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Upload'),
                ),
              ],
            ),
            const Gap(16),
            if (consumer.documents.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const Gap(12),
                      Text(
                        'No documents uploaded',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Document list
              ...consumer.documents.map((doc) => _buildDocumentTile(context, doc)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, ConsumerDocument doc) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(doc.type),
            color: theme.colorScheme.primary,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDocumentType(doc.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () {
              // TODO: Download document
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              // TODO: Delete document
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Consent Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: consumer.hasConsent
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        consumer.hasConsent ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: consumer.hasConsent ? Colors.green : Colors.red,
                      ),
                      const Gap(4),
                      Text(
                        consumer.hasConsent ? 'Consent Given' : 'No Consent',
                        style: TextStyle(
                          color: consumer.hasConsent
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (consumer.consentDate != null) ...[
              const Gap(12),
              _buildInfoRow('Consent Date', _formatDateTime(consumer.consentDate!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Record Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            if (consumer.createdAt != null)
              _buildInfoRow('Created', _formatDateTime(consumer.createdAt!)),
            if (consumer.updatedAt != null)
              _buildInfoRow('Last Updated', _formatDateTime(consumer.updatedAt!)),
            if (consumer.lastSentLetterAt != null)
              _buildInfoRow('Last Letter Sent', _formatDateTime(consumer.lastSentLetterAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatSmartCreditSource(SmartCreditSource source) {
    switch (source) {
      case SmartCreditSource.smartCredit:
        return 'SmartCredit';
      case SmartCreditSource.identityIq:
        return 'IdentityIQ';
      case SmartCreditSource.myScoreIq:
        return 'MyScoreIQ';
    }
  }

  String _formatDocumentType(ConsumerDocumentType type) {
    switch (type) {
      case ConsumerDocumentType.idFront:
        return 'ID - Front';
      case ConsumerDocumentType.idBack:
        return 'ID - Back';
      case ConsumerDocumentType.addressVerification:
        return 'Address Verification';
      case ConsumerDocumentType.ssnCard:
        return 'SSN Card';
      case ConsumerDocumentType.idTheftAffidavit:
        return 'ID Theft Affidavit';
    }
  }

  IconData _getDocumentIcon(ConsumerDocumentType type) {
    switch (type) {
      case ConsumerDocumentType.idFront:
      case ConsumerDocumentType.idBack:
        return Icons.badge;
      case ConsumerDocumentType.addressVerification:
        return Icons.home;
      case ConsumerDocumentType.ssnCard:
        return Icons.credit_card;
      case ConsumerDocumentType.idTheftAffidavit:
        return Icons.gavel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
