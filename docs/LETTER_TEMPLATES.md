# SFDIFY Credit Dispute Letter Templates

## Template Variables

### Global Variables (Available in all templates)
- `{{consumer_name}}`: Full name of the consumer
- `{{first_name}}`: Consumer's first name
- `{{last_name}}`: Consumer's last name
- `{{dob}}`: Date of birth (formatted)
- `{{ssn_last4}}`: Last 4 digits of SSN
- `{{current_address}}`: Current address (formatted)
- `{{city}}`: Current city
- `{{state}}`: Current state
- `{{zip}}`: Current ZIP code
- `{{phone}}`: Primary phone number
- `{{email}}`: Primary email address
- `{{date}}`: Current date
- `{{bureau_name}}`: Bureau name (Equifax, Experian, TransUnion)
- `{{bureau_address}}`: Bureau mailing address (formatted)

### Tradeline Variables
- `{{creditor_name}}`: Name of the creditor
- `{{account_number}}`: Masked account number
- `{{account_type}}`: Type of account
- `{{balance}}`: Current balance
- `{{opened_date}}`: Date account was opened
- `{{payment_status}}`: Payment status

### Loop Variables
- `{{#tradelines}}...{{/tradelines}}`: Loop through disputed tradelines
- `{{#reason_codes}}...{{/reason_codes}}`: Loop through reason codes
- `{{#evidence}}...{{/evidence}}`: Loop through evidence documents

---

## Template 1: FCRA 609 Information Request

**Type:** `609_request`
**Description:** Request for credit file information and method of verification under FCRA § 609.

```markdown
{{date}}

{{bureau_name}}
{{bureau_address}}

RE: Request for Credit File Information under FCRA § 609

Dear {{bureau_name}},

I am writing to request information about my credit file pursuant to my rights under the Fair Credit Reporting Act (FCRA), 15 U.S.C. § 1681g.

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number: XXX-XX-{{ssn_last4}}
Current Address: {{current_address}}

**Requested Information:**

I request the following information regarding my credit file:

1. A complete copy of my credit file, including all information you have collected and maintained about me.

2. The names and addresses of all persons or entities that have received information from my credit file within the past two years for employment purposes, and within the past year for all other purposes.

3. The method of verification used to verify the accuracy and completeness of the information in my credit file, particularly regarding the following accounts:

{{#tradelines}}
- Account: {{creditor_name}}
  Account Number: {{account_number}}
  Current Status: {{payment_status}}
{{/tradelines}}

4. Documentation showing the original creditor's verification of the debt, including:
   - The original signed contract or agreement
   - Complete payment history
   - Account statements
   - Verification of the current account holder

**Legal Basis:**

Under FCRA § 609(a)(1), I have the right to receive "[a]ll information in the consumer's file at the time of the request." I am also entitled to know the method by which you verified the accuracy of the information in my file under FCRA § 611(a)(7).

**Supporting Documentation:**

Enclosed please find the following documents to verify my identity:

{{#evidence}}
- {{filename}}: {{description}}
{{/evidence}}

Please provide the requested information within 30 days as required by law. If you are unable to provide this information, please delete the disputed items from my credit file immediately.

**Contact Information:**

If you require any additional information, please contact me at:

Phone: {{phone}}
Email: {{email}}

Thank you for your prompt attention to this matter.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Disclaimer:** This letter is for informational purposes only and does not constitute legal advice. The consumer has the right to dispute inaccurate information under the Fair Credit Reporting Act (FCRA).

**Legal Citation:** 15 U.S.C. § 1681g - Disclosures to consumers
```

---

## Template 2: FCRA 611 Dispute Letter

**Type:** `611_dispute`
**Description:** Standard dispute letter for inaccurate or unverifiable information.

```markdown
{{date}}

{{bureau_name}}
{{bureau_address}}

RE: Formal Dispute of Inaccurate Credit Information under FCRA § 611

Dear {{bureau_name}},

I am writing to formally dispute inaccurate information appearing on my credit report. Under the Fair Credit Reporting Act (FCRA), 15 U.S.C. § 1681i, you are required to conduct a reasonable reinvestigation of the disputed information.

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number: XXX-XX-{{ssn_last4}}
Current Address: {{current_address}}

**Disputed Accounts:**

I dispute the accuracy and completeness of the following items on my credit report:

{{#tradelines}}
**Account {{@index + 1}}:**
Creditor: {{creditor_name}}
Account Number: {{account_number}}
Account Type: {{account_type_display}}
Reported Balance: {{formatted_balance}}

**Reason for Dispute:**
{{#reason_codes}}
- {{this}}
{{/reason_codes}}

**Detailed Explanation:**
{{narrative}}

**Requested Action:** {{requested_action}}

---

{{/tradelines}}

**Legal Requirements:**

Under FCRA § 611(a)(1)(A), you must conduct a reasonable reinvestigation to determine whether the disputed information is inaccurate. If you cannot verify the accuracy of this information, you must promptly delete it from my credit file pursuant to FCRA § 611(a)(5)(A).

I have provided supporting documentation that substantiates my dispute. Please review these documents carefully during your reinvestigation.

**Supporting Evidence:**

{{#evidence}}
{{@index + 1}}. {{filename}} - {{description}}
{{/evidence}}

**Requested Outcome:**

I request that you:

1. Conduct a thorough and reasonable reinvestigation of the disputed items
2. Contact the furnisher of the information to verify its accuracy
3. Provide me with documentation of your verification process
4. Correct or delete any information that cannot be verified as accurate and complete
5. Send updated credit reports to all entities that received my credit report in the past six months (two years for employment purposes)

Please provide written confirmation of the results of your investigation within 30 days, as required by FCRA § 611(a)(1). If additional information is needed, the investigation period may be extended to 45 days pursuant to FCRA § 611(a)(1)(B).

**Notice of Intent:**

If this matter is not resolved satisfactorily, I reserve the right to file a complaint with the Consumer Financial Protection Bureau (CFPB) and pursue all available legal remedies under the FCRA, including statutory damages for willful noncompliance.

**Contact Information:**

Phone: {{phone}}
Email: {{email}}

Thank you for your immediate attention to this serious matter.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Disclaimer:** This letter is for informational purposes only and does not constitute legal advice. The consumer has the right to dispute inaccurate information under the Fair Credit Reporting Act (FCRA).

**Legal Citations:**
- 15 U.S.C. § 1681i - Procedure in case of disputed accuracy
- 15 U.S.C. § 1681e - Compliance procedures
```

---

## Template 3: Method of Verification (MOV) Request

**Type:** `mov_request`
**Description:** Request for method of verification after dispute investigation.

```markdown
{{date}}

{{bureau_name}}
{{bureau_address}}

RE: Request for Method of Verification under FCRA § 611(a)(7)

Dear {{bureau_name}},

I previously submitted a dispute regarding inaccurate information on my credit report. You responded that you "verified" the information; however, you failed to provide the method of verification as required by law.

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number: XXX-XX-{{ssn_last4}}
Current Address: {{current_address}}

**Previous Dispute Reference:**
Date of Original Dispute: {{dispute_submitted_date}}
Disputed Account(s):

{{#tradelines}}
- {{creditor_name}}, Account {{account_number}}
{{/tradelines}}

**Legal Requirement:**

Under FCRA § 611(a)(7), I am entitled to receive a description of the procedure used to determine the accuracy and completeness of the information, including the business name and address of any furnisher of information contacted in connection with such information.

**Requested Information:**

I request that you provide:

1. A detailed description of your verification procedure
2. The name and address of the person or entity you contacted to verify the information
3. Copies of all documents received from the furnisher during your investigation
4. The specific data or documentation used to verify the account information
5. The date(s) verification was conducted
6. The name and title of the individual who conducted the verification

**Legal Basis:**

The requirement to provide the method of verification is not optional. Failure to provide this information may constitute a violation of the FCRA and could result in liability for actual damages, statutory damages, punitive damages, and attorney's fees.

**Deadline:**

Please provide the requested information within 15 business days of receipt of this letter.

If you cannot provide adequate verification documentation, you must delete the disputed information from my credit report immediately, as unverifiable information cannot legally remain on a consumer's credit file.

**Contact Information:**

Phone: {{phone}}
Email: {{email}}

I expect your full cooperation in this matter.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Disclaimer:** This letter is for informational purposes only and does not constitute legal advice.

**Legal Citation:** 15 U.S.C. § 1681i(a)(7) - Method of verification
```

---

## Template 4: Reinvestigation Follow-Up Letter

**Type:** `reinvestigation`
**Description:** Follow-up letter after 30 days if no response or unsatisfactory response.

```markdown
{{date}}

{{bureau_name}}
{{bureau_address}}

RE: Second Request for Reinvestigation - FCRA Violation Notice

Dear {{bureau_name}},

This is my second request regarding inaccurate information on my credit report. On {{original_dispute_date}}, I sent a dispute letter regarding the following accounts. To date, I have not received a response, or the response was inadequate and did not comply with FCRA requirements.

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number: XXX-XX-{{ssn_last4}}
Current Address: {{current_address}}

**Timeline:**
- Original Dispute Sent: {{original_dispute_date}}
- FCRA Deadline: {{original_deadline}}
- Days Overdue: {{days_overdue}}

**Disputed Accounts:**

{{#tradelines}}
- {{creditor_name}}, Account {{account_number}}
  Status: Still reporting as {{payment_status}}
  Issue: {{dispute_reason}}
{{/tradelines}}

**Legal Violations:**

Your failure to respond within 30 days (or 45 days if applicable) constitutes a violation of FCRA § 611(a)(1). Additionally, your continued reporting of unverified information may violate FCRA § 1681e(b), which requires reasonable procedures to assure maximum possible accuracy.

**Required Actions:**

I demand that you immediately:

1. Complete a thorough reinvestigation of the disputed items
2. Provide written results of your investigation
3. Provide the method of verification
4. Delete any information that cannot be verified as accurate
5. Send updated reports to all who received my credit report in the past 6 months (2 years for employment)

**Notice of CFPB Complaint:**

If this matter is not resolved within 15 business days of receipt of this letter, I will file a formal complaint with the Consumer Financial Protection Bureau (CFPB) and pursue all available legal remedies, including:

- Actual damages
- Statutory damages up to $1,000 per violation
- Punitive damages
- Attorney's fees and court costs

**Preservation of Evidence:**

Please be advised that I am preserving all evidence related to this matter, including copies of credit reports, correspondence, and timelines of your noncompliance.

**Final Opportunity:**

This letter serves as your final opportunity to comply with federal law before I escalate this matter to regulatory authorities and consider legal action.

**Contact Information:**

Phone: {{phone}}
Email: {{email}}

I expect immediate action on this matter.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Disclaimer:** This letter is for informational purposes only and does not constitute legal advice.

**Legal Citations:**
- 15 U.S.C. § 1681i - Procedure in case of disputed accuracy
- 15 U.S.C. § 1681e(b) - Reasonable procedures to assure maximum possible accuracy
- 15 U.S.C. § 1681n - Civil liability for willful noncompliance
```

---

## Template 5: Goodwill Adjustment Request

**Type:** `goodwill`
**Description:** Request to creditor for goodwill removal of negative marks.

```markdown
{{date}}

{{creditor_name}}
{{creditor_address}}

RE: Goodwill Adjustment Request

Dear {{creditor_name}},

I am writing to request a goodwill adjustment to my account reporting. I have been a customer of {{creditor_name}} since {{account_opened_date}} and have maintained a generally positive relationship with your company.

**Account Information:**
Account Holder: {{consumer_name}}
Account Number: {{account_number}}
Current Address: {{current_address}}

**Request:**

I am respectfully requesting that you consider removing the late payment(s) reported on my account from {{late_payment_dates}}. While I take full responsibility for the late payment(s), I would like to explain the circumstances:

{{narrative}}

**Account History:**

I have been a loyal customer for {{account_age_years}} years and have made {{total_payments}} on-time payments. The late payment(s) in question represent only {{percentage}}% of my payment history and do not reflect my typical financial behavior.

{{#if_recent_on_time_payments}}
Since the late payment(s), I have made {{consecutive_on_time_payments}} consecutive on-time payments, demonstrating my commitment to maintaining good standing with your company.
{{/if_recent_on_time_payments}}

**Impact:**

This negative mark is significantly impacting my credit score and my ability to:
- {{impact_item_1}}
- {{impact_item_2}}
- {{impact_item_3}}

**Request for Consideration:**

I am kindly asking that you exercise your discretion and remove this negative reporting as a gesture of goodwill. I understand that you are not required to grant this request, but I hope you will consider:

1. My long history as a customer
2. My overall positive payment record
3. The exceptional circumstances surrounding the late payment
4. My demonstrated ability to maintain on-time payments since the incident

I value my relationship with {{creditor_name}} and hope to continue as a customer for many years to come. A goodwill adjustment would not only help me financially but would also strengthen my loyalty to your company.

**Contact Information:**

If you would like to discuss this matter, please feel free to contact me:

Phone: {{phone}}
Email: {{email}}

Thank you for taking the time to consider my request. I greatly appreciate your understanding and look forward to your positive response.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Note:** This is a goodwill request and not a formal dispute under the FCRA. The creditor has discretion to grant or deny this request.
```

---

## Template 6: Pay for Delete Offer

**Type:** `pay_for_delete`
**Description:** Offer to pay collection account in exchange for deletion.

```markdown
{{date}}

{{collector_name}}
{{collector_address}}

RE: Settlement Offer - Account {{account_number}}

Dear {{collector_name}},

I am writing regarding the collection account listed below. I would like to resolve this matter and am prepared to make a payment in exchange for complete deletion of this account from my credit reports.

**Account Information:**
Account Holder: {{consumer_name}}
Account Number: {{account_number}}
Original Creditor: {{original_creditor}}
Current Balance: {{current_balance}}
Current Address: {{current_address}}

**Settlement Offer:**

I am offering to pay {{settlement_amount}} ({{settlement_percentage}}% of the balance) in exchange for:

1. Complete deletion of this account from all three credit bureaus (Equifax, Experian, and TransUnion)
2. A signed agreement confirming the deletion
3. Written confirmation that the account is settled and $0 is owed

**Terms:**

This offer is contingent upon the following conditions:

1. **Pay for Delete Agreement:** You must agree in writing to delete all references to this account from my credit reports with all three bureaus upon receipt of payment.

2. **Payment Method:** Payment will be made via {{payment_method}} within {{payment_days}} business days of receiving your written agreement.

3. **No Re-aging:** You agree not to re-age this debt or report it to credit bureaus in the future.

4. **No Further Collection Activity:** Upon acceptance of this settlement, you agree to cease all collection activities and not sell or transfer this debt to any other party.

5. **No 1099-C:** You agree not to file a 1099-C form for cancellation of debt with the IRS.

**Required Documentation:**

Before I submit payment, I require:

1. A written agreement on company letterhead confirming the pay-for-delete arrangement
2. Confirmation that you have the authority to agree to this offer
3. Assurance that the debt will be reported as $0 and deleted from all credit reports

**Timeline:**

This offer is valid for {{offer_valid_days}} days from the date of this letter. After this period, the offer will expire and I may pursue other options for resolving this matter.

**Legal Disclaimer:**

Please note that this letter is not an acknowledgment that I owe this debt or that the statute of limitations has not expired. This is a settlement offer made without prejudice. If you do not accept this offer, I reserve all rights and defenses under the Fair Debt Collection Practices Act (FDCPA) and applicable state law.

**Contact Information:**

If you agree to these terms, please send written confirmation to:

{{consumer_name}}
{{current_address}}
Phone: {{phone}}
Email: {{email}}

I look forward to resolving this matter amicably.

Sincerely,

{{consumer_name}}

---

**Important:** This is a settlement negotiation. Do not make any payment until you receive written confirmation of the pay-for-delete agreement.
```

---

## Template 7: Identity Theft Block (FCRA § 605B)

**Type:** `identity_theft_block`
**Description:** Request to block fraudulent information resulting from identity theft.

```markdown
{{date}}

{{bureau_name}}
{{bureau_address}}

RE: Request for Identity Theft Block under FCRA § 605B

Dear {{bureau_name}},

I am a victim of identity theft. I am writing to request that you block the following fraudulent information from appearing on my credit report pursuant to my rights under the Fair Credit Reporting Act (FCRA), 15 U.S.C. § 1681c-2.

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number: XXX-XX-{{ssn_last4}}
Current Address: {{current_address}}

**Identity Theft Report:**

I have filed a report with law enforcement regarding this identity theft. Please find enclosed:

1. Identity Theft Report (FTC Identity Theft Affidavit)
2. Police Report Number: {{police_report_number}}
3. Police Department: {{police_department}}
4. Report Date: {{police_report_date}}

**Fraudulent Accounts:**

The following accounts on my credit report are fraudulent and resulted from identity theft:

{{#tradelines}}
**Fraudulent Account {{@index + 1}}:**
Creditor: {{creditor_name}}
Account Number: {{account_number}}
Date Opened: {{opened_date}}
Balance: {{formatted_balance}}

I did not open this account, authorize anyone to open it, or benefit from it in any way.

---

{{/tradelines}}

**Legal Requirements under FCRA § 605B:**

Under FCRA § 605B(a), you must block the reporting of fraudulent information that resulted from identity theft within 4 business days of receiving:

1. Appropriate proof of my identity
2. A copy of the identity theft report
3. Identification of the fraudulent information
4. A statement that the information resulted from identity theft

**Proof of Identity:**

Enclosed please find:

{{#evidence}}
- {{filename}}: {{description}}
{{/evidence}}

**Request for Immediate Action:**

I request that you:

1. Block all fraudulent accounts listed above from appearing on my credit report within 4 business days
2. Notify furnishers of the information that the accounts are blocked
3. Provide written confirmation of the block
4. Ensure the blocked information does not reappear on my credit report

**Prevention of Reappearance:**

Under FCRA § 605B(c), once information is blocked, you may not report it again unless you send me written notice and provide supporting documentation that the information was not identity theft.

**Criminal Investigation:**

Please be advised that this identity theft is under criminal investigation. Case Number: {{case_number}}. If you have any information regarding the perpetrator of this fraud, please contact {{investigating_officer}} at {{officer_phone}}.

**Contact Information:**

For any questions or to provide confirmation of the block, please contact me:

Phone: {{phone}}
Email: {{email}}

I appreciate your prompt attention to this serious matter and expect full compliance with FCRA § 605B.

Sincerely,

{{consumer_name}}
{{current_address}}

---

**Enclosures:**
- Identity Theft Report
- Police Report
- Proof of Identity
- Supporting Documentation

**Legal Citation:** 15 U.S.C. § 1681c-2 - Block of information resulting from identity theft
```

---

## Template 8: CFPB Complaint Package

**Type:** `cfpb_complaint`
**Description:** Cover letter for filing complaint with Consumer Financial Protection Bureau.

```markdown
{{date}}

Consumer Financial Protection Bureau
P.O. Box 4503
Iowa City, IA 52244

RE: Formal Complaint Against {{bureau_name}} for FCRA Violations

Dear CFPB,

I am filing this formal complaint against {{bureau_name}} for violations of the Fair Credit Reporting Act (FCRA). Despite multiple attempts to resolve inaccurate information on my credit report, {{bureau_name}} has failed to comply with federal law.

**Complainant Information:**
Name: {{consumer_name}}
Address: {{current_address}}
Phone: {{phone}}
Email: {{email}}

**Respondent:**
{{bureau_name}}
{{bureau_address}}

**Nature of Complaint:**

{{bureau_name}} has violated the FCRA by:

{{#violations}}
- {{violation_description}}
{{/violations}}

**Timeline of Events:**

{{#timeline}}
**{{date}}:** {{event_description}}
{{/timeline}}

**Disputed Accounts:**

{{#tradelines}}
- {{creditor_name}}, Account {{account_number}}
  Issue: {{dispute_reason}}
  Status: {{current_status}}
{{/tradelines}}

**Legal Violations:**

I believe {{bureau_name}} has violated the following provisions of the FCRA:

1. **§ 611(a)(1)** - Failure to conduct reasonable reinvestigation within 30 days
2. **§ 611(a)(5)** - Failure to delete unverified information
3. **§ 611(a)(7)** - Failure to provide method of verification
4. **§ 1681e(b)** - Failure to maintain reasonable procedures for maximum accuracy

**Damages Suffered:**

As a result of {{bureau_name}}'s FCRA violations, I have suffered:

- Denial of credit application with {{lender_name}} on {{denial_date}}
- Inability to obtain favorable interest rates
- Emotional distress and frustration
- Time and expense pursuing this matter

**Documentation Provided:**

Enclosed please find:

1. Original dispute letter dated {{original_dispute_date}}
2. Follow-up correspondence
3. {{bureau_name}}'s inadequate responses
4. Credit reports showing inaccurate information
5. Evidence supporting my disputes
6. Timeline of all communications

**Requested Resolution:**

I request that the CFPB:

1. Investigate {{bureau_name}}'s FCRA violations
2. Order {{bureau_name}} to correct or delete the inaccurate information
3. Order {{bureau_name}} to implement proper procedures
4. Consider appropriate enforcement action
5. Award damages as appropriate under the FCRA

**Previous Attempts to Resolve:**

I have made {{number_of_attempts}} attempts to resolve this matter directly with {{bureau_name}}:

- {{attempt_1_description}}
- {{attempt_2_description}}
- {{attempt_3_description}}

All attempts have been unsuccessful or inadequately addressed.

**Legal Action Consideration:**

If this matter is not resolved through the CFPB complaint process, I am prepared to pursue private legal action under FCRA § 1681n and § 1681o, which provide for actual damages, statutory damages, punitive damages, and attorney's fees.

**Request for Investigation:**

I respectfully request that the CFPB conduct a thorough investigation of {{bureau_name}}'s practices and take appropriate enforcement action to protect consumers from similar violations.

Thank you for your attention to this matter. I am available to provide any additional information needed for your investigation.

Sincerely,

{{consumer_name}}
{{current_address}}
Phone: {{phone}}
Email: {{email}}

---

**Enclosures:**
1. Chronological documentation of all disputes
2. Credit reports
3. Correspondence with {{bureau_name}}
4. Supporting evidence
5. Timeline of events

**File Online:** This complaint can also be filed online at consumerfinance.gov/complaint
```

---

## Variable Reference Guide

### Required Variables by Template Type

**609 Request:**
- consumer_name, dob, ssn_last4, current_address, phone, email
- bureau_name, bureau_address, date
- tradelines[] with creditor_name, account_number, payment_status
- evidence[] with filename, description

**611 Dispute:**
- All 609 variables plus:
- reason_codes[], narrative, requested_action
- dispute_submitted_date (for follow-ups)

**MOV Request:**
- All 609 variables plus:
- dispute_submitted_date, original_deadline

**Reinvestigation:**
- All 611 variables plus:
- days_overdue, original_deadline

**Goodwill:**
- consumer_name, current_address, phone, email
- creditor_name, creditor_address, account_number
- account_opened_date, late_payment_dates, narrative
- account_age_years, total_payments, consecutive_on_time_payments

**Pay for Delete:**
- consumer_name, current_address, phone, email
- collector_name, collector_address, account_number
- original_creditor, current_balance, settlement_amount
- settlement_percentage, payment_method, offer_valid_days

**Identity Theft Block:**
- All 609 variables plus:
- police_report_number, police_department, police_report_date
- case_number, investigating_officer, officer_phone

**CFPB Complaint:**
- All 611 variables plus:
- violations[], timeline[], damages description
- number_of_attempts, attempt descriptions

---

## Formatting Guidelines

1. **Date Format:** Month DD, YYYY (e.g., January 12, 2026)
2. **Address Format:** Multi-line with proper capitalization
3. **Currency:** Format as $X,XXX.XX
4. **Percentages:** Format as XX.X%
5. **Account Numbers:** Always mask (****1234)
6. **SSN:** Always mask as XXX-XX-XXXX

---

**Document Version**: 1.0
**Last Updated**: 2026-01-12
**Total Templates**: 8 base templates
