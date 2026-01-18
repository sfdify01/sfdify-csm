import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';
import 'package:ustaxx_csm/features/letter/presentation/widgets/template_library_card.dart';
import 'package:ustaxx_csm/features/letter/presentation/widgets/template_preview_dialog.dart';

/// Letter Library page showing available letter templates
class LetterLibraryPage extends StatefulWidget {
  const LetterLibraryPage({super.key});

  @override
  State<LetterLibraryPage> createState() => _LetterLibraryPageState();
}

class _LetterLibraryPageState extends State<LetterLibraryPage> {
  String _searchQuery = '';
  String? _selectedCategory;
  String _selectedRecipientType = 'all';

  // Template categories
  static const _categories = [
    {'id': 'fcra', 'name': 'FCRA Disputes', 'icon': Icons.gavel},
    {'id': 'creditor', 'name': 'Creditor Letters', 'icon': Icons.business},
    {'id': 'collector', 'name': 'Collector Letters', 'icon': Icons.phone_in_talk},
    {'id': 'other', 'name': 'Other Letters', 'icon': Icons.mail},
  ];

  // Recipient types for filtering
  static const _recipientTypes = [
    {'id': 'all', 'name': 'All Recipients'},
    {'id': 'bureau', 'name': 'Credit Bureaus'},
    {'id': 'creditor', 'name': 'Creditors'},
    {'id': 'collector', 'name': 'Collectors'},
  ];

  // Mock templates - in production, these would come from the backend
  List<LetterTemplateEntity> get _templates => [
    // FCRA Bureau Letters
    LetterTemplateEntity(
      id: 'tmpl_609_request',
      name: 'FCRA 609 Information Request',
      type: '609_request',
      description: 'Request verification of account information under FCRA Section 609. Use this as your first letter to bureaus.',
      content: '''Dear {{bureau_name}},

I am writing to request verification of the following account information appearing on my credit report pursuant to the Fair Credit Reporting Act, Section 609(a)(1).

**Consumer Information:**
- Name: {{consumer_name}}
- Address: {{consumer_address}}
- Date of Birth: {{consumer_dob}}
- SSN (last 4): {{consumer_ssn_last4}}

**Account in Question:**
- Creditor Name: {{account_creditor}}
- Account Number: {{account_number}}

Please provide copies of all documents used to verify the accuracy of this account, including but not limited to:
1. The original signed contract or agreement
2. Payment history records
3. Any documentation proving the debt is mine

If you cannot provide proper verification within 30 days, please remove this account from my credit report immediately.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'bureau_name': {'type': 'string', 'required': true, 'description': 'Name of the credit bureau'},
        'consumer_name': {'type': 'string', 'required': true, 'description': 'Consumer full name'},
        'consumer_address': {'type': 'string', 'required': true, 'description': 'Consumer address'},
        'consumer_dob': {'type': 'date', 'required': true, 'description': 'Consumer date of birth'},
        'consumer_ssn_last4': {'type': 'string', 'required': true, 'description': 'Last 4 digits of SSN'},
        'account_creditor': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1681g(a)(1)', 'FCRA Section 609'],
      complianceNotes: 'Bureaus must respond within 30 days with verification or remove the item.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LetterTemplateEntity(
      id: 'tmpl_611_dispute',
      name: 'FCRA 611 Dispute Letter',
      type: '611_dispute',
      description: 'Dispute inaccurate information under FCRA Section 611. Use when you believe information is incorrect.',
      content: '''Dear {{bureau_name}},

I am disputing the accuracy of the following information on my credit report pursuant to the Fair Credit Reporting Act, Section 611.

**Consumer Information:**
- Name: {{consumer_name}}
- Address: {{consumer_address}}
- Date of Birth: {{consumer_dob}}
- SSN (last 4): {{consumer_ssn_last4}}

**Disputed Item:**
- Creditor/Account: {{account_creditor}}
- Account Number: {{account_number}}
- Reason for Dispute: {{dispute_reason}}

{{dispute_explanation}}

I am requesting that you investigate this matter and correct or delete this inaccurate information from my credit report within 30 days as required by law.

Please send me written confirmation of the results of your reinvestigation.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'bureau_name': {'type': 'string', 'required': true, 'description': 'Name of the credit bureau'},
        'consumer_name': {'type': 'string', 'required': true, 'description': 'Consumer full name'},
        'consumer_address': {'type': 'string', 'required': true, 'description': 'Consumer address'},
        'consumer_dob': {'type': 'date', 'required': true, 'description': 'Consumer date of birth'},
        'consumer_ssn_last4': {'type': 'string', 'required': true, 'description': 'Last 4 digits of SSN'},
        'account_creditor': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'dispute_reason': {'type': 'string', 'required': true, 'description': 'Primary dispute reason code'},
        'dispute_explanation': {'type': 'text', 'required': true, 'description': 'Detailed explanation'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1681i', 'FCRA Section 611'],
      complianceNotes: 'Bureau must complete reinvestigation within 30 days (45 days if consumer provides additional info).',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LetterTemplateEntity(
      id: 'tmpl_605b_id_theft',
      name: 'FCRA 605B Identity Theft Block',
      type: '605b_id_theft',
      description: 'Request blocking of fraudulent information resulting from identity theft under FCRA Section 605B.',
      content: '''Dear {{bureau_name}},

I am a victim of identity theft. Pursuant to FCRA Section 605B, I am requesting that you block the following fraudulent information from my credit report.

**Consumer Information:**
- Name: {{consumer_name}}
- Address: {{consumer_address}}
- Date of Birth: {{consumer_dob}}
- SSN (last 4): {{consumer_ssn_last4}}

**Fraudulent Account:**
- Creditor Name: {{account_creditor}}
- Account Number: {{account_number}}
- Approximate Date Opened: {{fraud_date}}

I have enclosed copies of:
1. FTC Identity Theft Report
2. Government-issued ID
3. Proof of address
4. Identity Theft Affidavit

Please block this fraudulent information within 4 business days as required by law.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'bureau_name': {'type': 'string', 'required': true, 'description': 'Name of the credit bureau'},
        'consumer_name': {'type': 'string', 'required': true, 'description': 'Consumer full name'},
        'consumer_address': {'type': 'string', 'required': true, 'description': 'Consumer address'},
        'consumer_dob': {'type': 'date', 'required': true, 'description': 'Consumer date of birth'},
        'consumer_ssn_last4': {'type': 'string', 'required': true, 'description': 'Last 4 digits of SSN'},
        'account_creditor': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'fraud_date': {'type': 'date', 'required': true, 'description': 'Date fraud occurred'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1681c-2', 'FCRA Section 605B'],
      complianceNotes: 'Bureau must block information within 4 business days of receiving required documentation.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LetterTemplateEntity(
      id: 'tmpl_mov_request',
      name: 'Method of Verification Request',
      type: 'mov_request',
      description: 'Request the method used to verify disputed information. Use as a follow-up after initial dispute.',
      content: '''Dear {{bureau_name}},

Pursuant to FCRA Section 611(a)(6)(B)(iii) and Section 611(a)(7), I am requesting that you provide me with a description of the procedure used to determine the accuracy and completeness of the disputed information, including:

**Previous Dispute Reference:**
- Previous Dispute ID: {{dispute_id}}
- Account in Question: {{account_creditor}} - {{account_number}}

Please provide:
1. The business name and address of any furnisher contacted
2. The telephone number of the furnisher, if reasonably available
3. A description of the reinvestigation procedure used
4. All documentation used to verify this account

If you verified this account by simply contacting the creditor, I request that you obtain actual documentation proving the accuracy of this account.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'bureau_name': {'type': 'string', 'required': true, 'description': 'Name of the credit bureau'},
        'dispute_id': {'type': 'string', 'required': false, 'description': 'Previous dispute reference number'},
        'account_creditor': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1681i(a)(6)', '15 U.S.C. § 1681i(a)(7)', 'FCRA Section 611'],
      complianceNotes: 'Consumer has the right to know how disputed information was verified.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    // Creditor Letters
    LetterTemplateEntity(
      id: 'tmpl_goodwill',
      name: 'Goodwill Adjustment Letter',
      type: 'goodwill',
      description: 'Request removal of negative mark as a gesture of goodwill. Best for accounts in good standing.',
      content: '''Dear {{creditor_name}},

I am writing to request a goodwill adjustment to my credit report.

**Account Information:**
- Account Number: {{account_number}}
- Current Status: {{account_status}}

{{goodwill_explanation}}

I have been a loyal customer and my payment history since then has been excellent. I am hoping you would consider removing this negative mark as a gesture of goodwill.

I understand this is entirely at your discretion, but I would greatly appreciate your consideration.

Thank you for your time.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'creditor_name': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'account_status': {'type': 'string', 'required': true, 'description': 'Current account status'},
        'goodwill_explanation': {'type': 'text', 'required': true, 'description': 'Explanation of circumstances'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: [],
      complianceNotes: 'This is a courtesy request. Creditors are not legally obligated to make goodwill adjustments.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LetterTemplateEntity(
      id: 'tmpl_pay_for_delete',
      name: 'Pay for Delete Agreement',
      type: 'pay_for_delete',
      description: 'Offer payment in exchange for deletion of negative account. Use with collections or charge-offs.',
      content: '''Dear {{creditor_name}},

I am writing regarding the following account:

**Account Information:**
- Account Number: {{account_number}}
- Current Balance: {{current_balance}}

I am prepared to pay {{settlement_amount}} as settlement in full for this account, contingent upon your agreement to:

1. Accept this amount as payment in full
2. Request deletion of this account from all credit bureaus
3. Report this account as "Paid in Full" or "Deleted" rather than "Settled"

If you agree to these terms, please respond in writing on your company letterhead.

This is not an acknowledgment of the debt or a promise to pay unless you agree to the above terms.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'creditor_name': {'type': 'string', 'required': true, 'description': 'Creditor name'},
        'account_number': {'type': 'string', 'required': true, 'description': 'Account number'},
        'current_balance': {'type': 'string', 'required': true, 'description': 'Current balance owed'},
        'settlement_amount': {'type': 'string', 'required': true, 'description': 'Proposed settlement amount'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: [],
      complianceNotes: 'Get agreement in writing before making payment. Not all creditors accept pay-for-delete.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    // Collector Letters
    LetterTemplateEntity(
      id: 'tmpl_debt_validation',
      name: 'Debt Validation Request',
      type: 'debt_validation',
      description: 'Request validation of debt under FDCPA Section 809. Send within 30 days of first contact.',
      content: '''Dear {{collector_name}},

I am writing in response to your recent communication regarding an alleged debt.

Pursuant to the Fair Debt Collection Practices Act, Section 809(b), I am requesting validation of this debt. Please provide:

1. The amount of the debt and how it was calculated
2. The name of the original creditor
3. Proof that you are licensed to collect in my state
4. A copy of the original signed agreement
5. Verification that the statute of limitations has not expired
6. A complete payment history

Please cease all collection activities until you have provided the requested validation.

This is not a refusal to pay, but a request for verification as allowed by federal law.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'collector_name': {'type': 'string', 'required': true, 'description': 'Collection agency name'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1692g', 'FDCPA Section 809'],
      complianceNotes: 'Must be sent within 30 days of initial contact to preserve validation rights.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LetterTemplateEntity(
      id: 'tmpl_cease_desist',
      name: 'Cease and Desist Letter',
      type: 'cease_desist',
      description: 'Demand collector stop all contact. Use when you want no further communication.',
      content: '''Dear {{collector_name}},

Pursuant to the Fair Debt Collection Practices Act, Section 805(c), I am formally requesting that you cease and desist all communication with me regarding the alleged debt referenced below:

**Alleged Account:**
- Reference Number: {{account_number}}

Effective immediately, you are directed to:
1. Stop all telephone calls to me
2. Stop all contact at my place of employment
3. Cease all written communication except to notify me of:
   - Termination of collection efforts
   - Intent to invoke legal remedy

Any violation of this request will be documented and may result in legal action under the FDCPA.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'collector_name': {'type': 'string', 'required': true, 'description': 'Collection agency name'},
        'account_number': {'type': 'string', 'required': false, 'description': 'Reference or account number'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['15 U.S.C. § 1692c(c)', 'FDCPA Section 805(c)'],
      complianceNotes: 'Does not eliminate the debt. Collector may still pursue legal action.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    // Other Letters
    LetterTemplateEntity(
      id: 'tmpl_cfpb_complaint',
      name: 'CFPB Complaint Letter',
      type: 'cfpb_complaint',
      description: 'Formal complaint to the Consumer Financial Protection Bureau for violations.',
      content: '''Consumer Financial Protection Bureau
P.O. Box 4503
Iowa City, Iowa 52244

Re: Formal Complaint Against {{company_name}}

Dear CFPB:

I am filing this complaint against {{company_name}} for the following violations:

**Consumer Information:**
- Name: {{consumer_name}}
- Address: {{consumer_address}}

**Complaint Details:**
{{complaint_details}}

**Violations:**
{{violations_list}}

**Resolution Requested:**
{{resolution_requested}}

I have enclosed supporting documentation including:
{{documentation_list}}

Please investigate this matter and take appropriate action.

Sincerely,
{{consumer_signature}}''',
      variables: {
        'company_name': {'type': 'string', 'required': true, 'description': 'Company being complained about'},
        'consumer_name': {'type': 'string', 'required': true, 'description': 'Consumer full name'},
        'consumer_address': {'type': 'string', 'required': true, 'description': 'Consumer address'},
        'complaint_details': {'type': 'text', 'required': true, 'description': 'Detailed description of complaint'},
        'violations_list': {'type': 'text', 'required': true, 'description': 'List of alleged violations'},
        'resolution_requested': {'type': 'text', 'required': true, 'description': 'What resolution you want'},
        'documentation_list': {'type': 'text', 'required': false, 'description': 'List of enclosed documents'},
        'consumer_signature': {'type': 'string', 'required': true, 'description': 'Consumer signature'},
      },
      legalCitations: ['12 U.S.C. § 5534', 'Consumer Financial Protection Act'],
      complianceNotes: 'CFPB will forward complaint to company and request response within 15 days.',
      active: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  List<LetterTemplateEntity> get _filteredTemplates {
    var templates = _templates;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      templates = templates.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.description?.toLowerCase().contains(query) == true ||
            t.type.toLowerCase().contains(query) ||
            t.legalCitations.any((c) => c.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      templates = templates.where((t) {
        switch (_selectedCategory) {
          case 'fcra':
            return ['609_request', '611_dispute', '605b_id_theft', 'mov_request'].contains(t.type);
          case 'creditor':
            return ['goodwill', 'pay_for_delete'].contains(t.type);
          case 'collector':
            return ['debt_validation', 'cease_desist'].contains(t.type);
          case 'other':
            return ['cfpb_complaint', 'custom'].contains(t.type);
          default:
            return true;
        }
      }).toList();
    }

    // Filter by recipient type
    if (_selectedRecipientType != 'all') {
      templates = templates.where((t) {
        switch (_selectedRecipientType) {
          case 'bureau':
            return ['609_request', '611_dispute', '605b_id_theft', 'mov_request'].contains(t.type);
          case 'creditor':
            return ['goodwill', 'pay_for_delete'].contains(t.type);
          case 'collector':
            return ['debt_validation', 'cease_desist'].contains(t.type);
          default:
            return true;
        }
      }).toList();
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context),

        // Main content
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar - categories
              SizedBox(
                width: 240,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      _buildCategoryItem(context, null, 'All Templates', Icons.folder_open),
                      ..._categories.map((cat) => _buildCategoryItem(
                        context,
                        cat['id'] as String,
                        cat['name'] as String,
                        cat['icon'] as IconData,
                      )),
                      const Gap(24),
                      Text(
                        'Recipient Type',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      ..._recipientTypes.map((type) => _buildRecipientTypeItem(
                        context,
                        type['id'] as String,
                        type['name'] as String,
                      )),
                    ],
                  ),
                ),
              ),

              // Divider
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.dividerColor,
              ),

              // Main content - templates grid
              Expanded(
                child: _buildTemplatesGrid(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Letter Library',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Search input
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const Gap(16),
          // Create custom template button (for owners)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom template creation coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String? id, String name, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedCategory = id;
          });
        },
      ),
    );
  }

  Widget _buildRecipientTypeItem(BuildContext context, String id, String name) {
    final theme = Theme.of(context);
    final isSelected = _selectedRecipientType == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRecipientType = id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const Gap(8),
              Text(
                name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid(BuildContext context) {
    final templates = _filteredTemplates;

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const Gap(16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Gap(8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${templates.length} template${templates.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Gap(16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  return TemplateLibraryCard(
                    template: templates[index],
                    onPreview: () => _showTemplatePreview(templates[index]),
                    onUse: () => _useTemplate(templates[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTemplatePreview(LetterTemplateEntity template) {
    showDialog<void>(
      context: context,
      builder: (context) => TemplatePreviewDialog(template: template),
    );
  }

  void _useTemplate(LetterTemplateEntity template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using template: ${template.name}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Create Dispute',
          onPressed: () {
            // Navigate to dispute creation with template preselected
            // context.go('/disputes/new?templateId=${template.id}');
          },
        ),
      ),
    );
  }
}
