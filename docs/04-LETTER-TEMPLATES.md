# SFDIFY Credit Dispute Letter System - Letter Templates

## Template Variable Reference

### Consumer Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `{{consumer_name}}` | Full legal name | John Michael Smith |
| `{{consumer_first_name}}` | First name only | John |
| `{{consumer_last_name}}` | Last name only | Smith |
| `{{consumer_dob}}` | Date of birth | March 15, 1985 |
| `{{consumer_ssn_last4}}` | Last 4 of SSN | 6789 |
| `{{consumer_current_address}}` | Full current address | 456 Oak Avenue, Apt 7B, Los Angeles, CA 90001 |
| `{{consumer_address_line1}}` | Street address | 456 Oak Avenue, Apt 7B |
| `{{consumer_city}}` | City | Los Angeles |
| `{{consumer_state}}` | State | CA |
| `{{consumer_zip}}` | ZIP code | 90001 |
| `{{consumer_phone}}` | Primary phone | (310) 555-1234 |
| `{{consumer_email}}` | Primary email | john.smith@email.com |
| `{{previous_addresses}}` | List of previous addresses | 789 Pine St, San Francisco, CA 94102 |

### Bureau Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `{{bureau_name}}` | Full bureau name | Equifax Information Services LLC |
| `{{bureau_address}}` | Bureau mailing address | P.O. Box 740256, Atlanta, GA 30374 |
| `{{equifax_address}}` | Equifax address | P.O. Box 740256, Atlanta, GA 30374 |
| `{{experian_address}}` | Experian address | P.O. Box 4500, Allen, TX 75013 |
| `{{transunion_address}}` | TransUnion address | P.O. Box 2000, Chester, PA 19016 |

### Tradeline Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `{{creditor_name}}` | Creditor/lender name | Capital One Bank |
| `{{account_number_masked}}` | Masked account number | XXXX-XXXX-XXXX-5678 |
| `{{account_type}}` | Type of account | Credit Card |
| `{{opened_date}}` | Account open date | June 15, 2019 |
| `{{reported_balance}}` | Currently reported balance | $2,450.00 |
| `{{credit_limit}}` | Credit limit | $5,000.00 |
| `{{payment_status}}` | Current payment status | Current |
| `{{account_status}}` | Account status | Open |

### Dispute Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `{{dispute_number}}` | Dispute reference | DSP-00000042 |
| `{{dispute_reason}}` | Primary dispute reason | Inaccurate Balance |
| `{{reason_codes}}` | All reason codes | Inaccurate Balance, Wrong Payment History |
| `{{dispute_narrative}}` | Consumer's dispute explanation | The balance reported is incorrect... |
| `{{evidence_index}}` | List of attached evidence | See Exhibit A: Bank Statement |

### Date Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `{{current_date}}` | Today's date | January 21, 2024 |
| `{{current_date_formal}}` | Formal date | the 21st day of January, 2024 |
| `{{response_deadline}}` | 30-day deadline | February 20, 2024 |

---

## Template 1: FCRA 609 Information Request

**Purpose:** Request verification of what information the bureau has on file.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .header { text-align: center; margin-bottom: 20px; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .subject { font-weight: bold; margin-bottom: 20px; }
    .body { text-align: justify; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{bureau_name}}<br>
  {{bureau_address}}
</div>

<div class="address-block">
  <strong>RE: Request for Disclosure of Information</strong><br>
  Consumer: {{consumer_name}}<br>
  SSN: XXX-XX-{{consumer_ssn_last4}}<br>
  DOB: {{consumer_dob}}<br>
  Address: {{consumer_current_address}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>Pursuant to my rights under Section 609 of the Fair Credit Reporting Act (15 U.S.C. § 1681g), I am formally requesting a complete disclosure of all information in my consumer file.</p>

  <p>Specifically, I request:</p>
  <ol>
    <li>All information in my file at the time of my request;</li>
    <li>The sources of all information in my file;</li>
    <li>Identification of each person who procured a consumer report on me for employment purposes within the past two years;</li>
    <li>Identification of each person who procured a consumer report on me for any other purpose within the past year;</li>
    <li>The dates, original payees, and amounts of any checks upon which adverse information is based.</li>
  </ol>

  <p>Under Section 609(a)(1), you are required to clearly and accurately disclose this information to me upon request. Please provide this disclosure within the timeframe required by law.</p>

  <p>For identification purposes, I have enclosed copies of the following documents:</p>
  <ul>
    {{#evidence_list}}
    <li>{{evidence_name}}</li>
    {{/evidence_list}}
  </ul>

  <p>Please send the requested disclosure to:</p>
  <p>
    {{consumer_name}}<br>
    {{consumer_current_address}}
  </p>

  <p>Thank you for your prompt attention to this matter.</p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
  <p>{{consumer_phone}}</p>
</div>

<div class="disclaimer">
  This letter is a request for information under the Fair Credit Reporting Act and does not constitute legal advice. The sender is exercising their consumer rights under federal law.
</div>

</body>
</html>
```

### Sample with Demo Data:

```
January 21, 2024

Equifax Information Services LLC
P.O. Box 740256
Atlanta, GA 30374

RE: Request for Disclosure of Information
Consumer: John Michael Smith
SSN: XXX-XX-6789
DOB: March 15, 1985
Address: 456 Oak Avenue, Apt 7B, Los Angeles, CA 90001

To Whom It May Concern:

Pursuant to my rights under Section 609 of the Fair Credit Reporting Act (15 U.S.C. § 1681g),
I am formally requesting a complete disclosure of all information in my consumer file.

[...]
```

---

## Template 2: FCRA 611 Dispute of Accuracy

**Purpose:** Dispute inaccurate information on a credit report.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .header { text-align: center; margin-bottom: 20px; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .subject { font-weight: bold; margin-bottom: 20px; }
    .body { text-align: justify; }
    .account-box { border: 1px solid #000; padding: 15px; margin: 20px 0; background: #f9f9f9; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{bureau_name}}<br>
  {{bureau_address}}
</div>

<div class="address-block">
  <strong>RE: Formal Dispute of Inaccurate Information</strong><br>
  Dispute Reference: {{dispute_number}}<br>
  Consumer: {{consumer_name}}<br>
  SSN: XXX-XX-{{consumer_ssn_last4}}<br>
  DOB: {{consumer_dob}}<br>
  Current Address: {{consumer_current_address}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>Pursuant to Section 611 of the Fair Credit Reporting Act (15 U.S.C. § 1681i), I am writing to formally dispute inaccurate information appearing on my credit report.</p>

  <div class="account-box">
    <strong>DISPUTED ACCOUNT INFORMATION:</strong><br><br>
    Creditor Name: {{creditor_name}}<br>
    Account Number: {{account_number_masked}}<br>
    Account Type: {{account_type}}<br>
    Date Opened: {{opened_date}}<br>
    Reported Balance: {{reported_balance}}<br>
    Current Status: {{account_status}}
  </div>

  <p><strong>REASON FOR DISPUTE:</strong></p>
  <p>{{dispute_narrative}}</p>

  <p><strong>DISPUTED ITEMS:</strong></p>
  <ul>
    {{#reason_codes_list}}
    <li>{{reason_description}}</li>
    {{/reason_codes_list}}
  </ul>

  <p>Under Section 611(a)(1)(A), you are required to conduct a reasonable investigation of this disputed information within 30 days of receiving this notice. You must also forward all relevant information to the furnisher of this information.</p>

  <p>Pursuant to Section 611(a)(5), if the investigation reveals that the disputed information is inaccurate, incomplete, or cannot be verified, you must promptly delete or modify the item and notify me of the results.</p>

  <p>Pursuant to Section 611(a)(6), you must provide me with written notice of the results of your reinvestigation within 5 business days of completion, including:</p>
  <ul>
    <li>A statement that the reinvestigation is complete;</li>
    <li>A consumer report based on my file as it exists after the reinvestigation;</li>
    <li>A notice that I have the right to add a statement to my file;</li>
    <li>A description of the procedure for adding such statement.</li>
  </ul>

  <p><strong>SUPPORTING DOCUMENTATION:</strong></p>
  <p>I have enclosed the following documents to support my dispute:</p>
  {{evidence_index}}

  <p>Please investigate this matter promptly and provide me with written confirmation of the correction or deletion of this inaccurate information.</p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
  <p>{{consumer_phone}}</p>
  <p>{{consumer_email}}</p>
</div>

<div class="disclaimer">
  This letter constitutes a formal dispute under the Fair Credit Reporting Act. The consumer is exercising their legal right to dispute inaccurate information. This is not legal advice.
</div>

</body>
</html>
```

### Sample with Demo Data:

```
January 21, 2024

Equifax Information Services LLC
P.O. Box 740256
Atlanta, GA 30374

RE: Formal Dispute of Inaccurate Information
Dispute Reference: DSP-00000042
Consumer: John Michael Smith
SSN: XXX-XX-6789
DOB: March 15, 1985
Current Address: 456 Oak Avenue, Apt 7B, Los Angeles, CA 90001

To Whom It May Concern:

Pursuant to Section 611 of the Fair Credit Reporting Act (15 U.S.C. § 1681i), I am writing to
formally dispute inaccurate information appearing on my credit report.

┌─────────────────────────────────────────────────────────────────┐
│ DISPUTED ACCOUNT INFORMATION:                                    │
│                                                                  │
│ Creditor Name: Capital One Bank                                 │
│ Account Number: XXXX-XXXX-XXXX-5678                             │
│ Account Type: Credit Card                                        │
│ Date Opened: June 15, 2019                                      │
│ Reported Balance: $2,450.00                                     │
│ Current Status: Open                                            │
└─────────────────────────────────────────────────────────────────┘

REASON FOR DISPUTE:
The balance reported of $2,450.00 is incorrect. My most recent statement shows a balance of
$1,850.00. Additionally, the payment history shows a 30-day late payment for October 2023,
but I have documentation proving that payment was made on time.

DISPUTED ITEMS:
• Inaccurate Balance Reported
• Incorrect Payment History

[...]

SUPPORTING DOCUMENTATION:
• Exhibit A: Capital One Statement dated January 15, 2024 (Pages 1-2)
• Exhibit B: Bank payment confirmation for October 2023 payment
• Exhibit C: Copy of government-issued ID

[...]
```

---

## Template 3: Method of Verification Request

**Purpose:** Request the method used to verify disputed information after a dispute.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{bureau_name}}<br>
  {{bureau_address}}
</div>

<div class="address-block">
  <strong>RE: Request for Method of Verification</strong><br>
  Previous Dispute Reference: {{dispute_number}}<br>
  Consumer: {{consumer_name}}<br>
  SSN: XXX-XX-{{consumer_ssn_last4}}<br>
  DOB: {{consumer_dob}}<br>
  Current Address: {{consumer_current_address}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>I recently received the results of my dispute regarding the following account:</p>

  <p style="margin-left: 40px;">
    <strong>Creditor:</strong> {{creditor_name}}<br>
    <strong>Account:</strong> {{account_number_masked}}
  </p>

  <p>Your investigation verified the information as accurate. However, pursuant to Section 611(a)(7) of the Fair Credit Reporting Act (15 U.S.C. § 1681i(a)(7)), I am requesting a description of the procedure used to determine the accuracy and completeness of this information, including:</p>

  <ol>
    <li>The business name and address of any furnisher of information contacted in connection with the reinvestigation;</li>
    <li>The telephone number of the furnisher, if reasonably available;</li>
    <li>A description of the method by which the furnisher was contacted;</li>
    <li>A summary of the information provided by the furnisher.</li>
  </ol>

  <p>Under Section 611(a)(7), you are required to provide this information within 15 days of receiving my request.</p>

  <p>I maintain that the information being reported is inaccurate, and I am entitled to understand what verification procedures were followed. If the furnisher was not contacted directly, or if the verification was performed solely through an automated system without meaningful review, I request that you conduct a more thorough reinvestigation.</p>

  <p>Please send the requested information to:</p>
  <p>
    {{consumer_name}}<br>
    {{consumer_current_address}}
  </p>

  <p>Thank you for your prompt attention to this request.</p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
</div>

<div class="disclaimer">
  This letter is a request under the Fair Credit Reporting Act and does not constitute legal advice.
</div>

</body>
</html>
```

---

## Template 4: 30-Day Reinvestigation Follow-Up

**Purpose:** Follow up when bureau hasn't responded within 30 days.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .urgent { color: red; font-weight: bold; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{bureau_name}}<br>
  {{bureau_address}}
</div>

<div class="address-block">
  <strong>RE: <span class="urgent">SECOND NOTICE</span> - Reinvestigation Follow-Up</strong><br>
  Original Dispute Reference: {{dispute_number}}<br>
  Original Dispute Date: {{original_dispute_date}}<br>
  Consumer: {{consumer_name}}<br>
  SSN: XXX-XX-{{consumer_ssn_last4}}<br>
  DOB: {{consumer_dob}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>On {{original_dispute_date}}, I sent a written dispute regarding inaccurate information on my credit report. As of this date, <strong>more than 30 days have passed</strong> and I have not received the results of your reinvestigation as required by law.</p>

  <p>The disputed account is:</p>
  <p style="margin-left: 40px;">
    <strong>Creditor:</strong> {{creditor_name}}<br>
    <strong>Account:</strong> {{account_number_masked}}
  </p>

  <p>Under Section 611(a)(1) of the Fair Credit Reporting Act (15 U.S.C. § 1681i), you are required to:</p>
  <ol>
    <li>Conduct a reasonable reinvestigation within <strong>30 days</strong> of receiving a dispute;</li>
    <li>Record the current status of the disputed information or delete the item before the end of such period;</li>
    <li>Provide written results of the reinvestigation within <strong>5 business days</strong> of completion.</li>
  </ol>

  <p>Your failure to comply with these requirements constitutes a violation of the FCRA. Under Section 616 and 617, consumers may recover actual damages, statutory damages of $100 to $1,000 per violation for willful noncompliance, punitive damages, and attorney's fees.</p>

  <p><strong>I demand that you:</strong></p>
  <ol>
    <li>Immediately delete the disputed information from my credit file, as you have failed to verify it within the legally required timeframe; OR</li>
    <li>Provide the results of your reinvestigation within 5 business days of this letter.</li>
  </ol>

  <p>If I do not receive a satisfactory response within 10 business days, I will file a complaint with the Consumer Financial Protection Bureau and consider pursuing my legal remedies.</p>

  <p>I have enclosed a copy of my original dispute letter and proof of delivery for your reference.</p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
</div>

<div class="disclaimer">
  This letter is a follow-up demand under the Fair Credit Reporting Act. This is not legal advice.
</div>

</body>
</html>
```

---

## Template 5: Goodwill Adjustment Request

**Purpose:** Request removal of negative item based on goodwill (sent to creditor).

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .signature { margin-top: 40px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{creditor_name}}<br>
  {{creditor_address}}
</div>

<div class="address-block">
  <strong>RE: Goodwill Adjustment Request</strong><br>
  Account Number: {{account_number_masked}}<br>
  Account Holder: {{consumer_name}}
</div>

<div class="body">
  <p>Dear Customer Service Manager,</p>

  <p>I am writing to respectfully request a goodwill adjustment to remove a negative mark from my credit report associated with the above-referenced account.</p>

  <p>I have been a loyal customer of {{creditor_name}} since {{opened_date}}, and I value our business relationship. Unfortunately, {{late_payment_explanation}}.</p>

  <p>Since that time, I have:</p>
  <ul>
    <li>Brought my account current and maintained consistent on-time payments;</li>
    <li>Demonstrated my commitment to responsible credit management;</li>
    <li>Continued to be a customer in good standing.</li>
  </ul>

  <p>I understand that {{creditor_name}} accurately reported the late payment based on the account history. However, I am hoping you might consider removing this negative mark as a goodwill gesture, given:</p>
  <ul>
    <li>My overall positive payment history with your company;</li>
    <li>The circumstances that led to the late payment;</li>
    <li>My continued loyalty as a customer.</li>
  </ul>

  <p>This single negative mark is significantly impacting my credit score and my ability to {{credit_goal}}. A goodwill adjustment would make a tremendous difference in my financial situation.</p>

  <p>I would be deeply grateful if you would consider this request. I remain committed to being a responsible customer and maintaining our positive business relationship.</p>

  <p>Thank you for taking the time to review my request. I look forward to your response.</p>
</div>

<div class="signature">
  <p>Respectfully,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
  <p>{{consumer_phone}}</p>
  <p>Account: {{account_number_masked}}</p>
</div>

</body>
</html>
```

---

## Template 6: Pay for Delete Offer

**Purpose:** Offer to pay collection account in exchange for deletion.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .offer-box { border: 2px solid #000; padding: 15px; margin: 20px 0; background: #f0f0f0; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{collector_name}}<br>
  {{collector_address}}
</div>

<div class="address-block">
  <strong>RE: Settlement Offer with Deletion Request</strong><br>
  Account Reference: {{account_number_masked}}<br>
  Original Creditor: {{original_creditor}}<br>
  Reported Balance: {{reported_balance}}<br>
  Consumer: {{consumer_name}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>I am writing regarding the above-referenced account that appears on my credit report. I am prepared to resolve this account and am offering the following settlement:</p>

  <div class="offer-box">
    <strong>SETTLEMENT OFFER</strong><br><br>
    <strong>Settlement Amount:</strong> {{settlement_amount}}<br>
    <strong>Payment Method:</strong> {{payment_method}}<br>
    <strong>Condition:</strong> Complete deletion from all three credit bureaus within 30 days of payment
  </div>

  <p>This offer is contingent upon your written agreement to:</p>
  <ol>
    <li>Accept {{settlement_amount}} as payment in full satisfaction of this debt;</li>
    <li>Request deletion (not "paid" or "settled" status) of this account from Equifax, Experian, and TransUnion within 30 days of receiving payment;</li>
    <li>Cease all collection activity upon receipt of payment;</li>
    <li>Provide written confirmation that this account has been satisfied and deletion has been requested.</li>
  </ol>

  <p>If you agree to these terms, please respond in writing on your company letterhead within 15 days. Upon receipt of your written agreement, I will arrange for immediate payment via {{payment_method}}.</p>

  <p><strong>Important:</strong> This letter is not an acknowledgment of the validity of this debt, nor is it a promise to pay unless you agree to the terms specified above. If you cannot agree to deletion, please disregard this offer.</p>

  <p>Please respond to:</p>
  <p>
    {{consumer_name}}<br>
    {{consumer_current_address}}
  </p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
</div>

<div class="disclaimer">
  This is a settlement negotiation. This letter does not constitute an admission of liability or a promise to pay. Any agreement must be in writing.
</div>

</body>
</html>
```

---

## Template 7: Identity Theft Dispute (FCRA 605B)

**Purpose:** Block fraudulent accounts resulting from identity theft.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .fraud-alert { border: 2px solid red; padding: 15px; margin: 20px 0; background: #fff0f0; }
    .signature { margin-top: 40px; }
    .disclaimer { font-size: 10pt; font-style: italic; margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  {{bureau_name}}<br>
  Fraud Victim Assistance<br>
  {{bureau_fraud_address}}
</div>

<div class="address-block">
  <strong>RE: Identity Theft - Request to Block Fraudulent Information</strong><br>
  Consumer: {{consumer_name}}<br>
  SSN: XXX-XX-{{consumer_ssn_last4}}<br>
  DOB: {{consumer_dob}}<br>
  Current Address: {{consumer_current_address}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>I am a victim of identity theft. Pursuant to Section 605B of the Fair Credit Reporting Act (15 U.S.C. § 1681c-2), I am requesting that you block the following fraudulent information from my credit file:</p>

  <div class="fraud-alert">
    <strong>FRAUDULENT ACCOUNT INFORMATION:</strong><br><br>
    Creditor Name: {{creditor_name}}<br>
    Account Number: {{account_number_masked}}<br>
    Date Opened: {{opened_date}}<br>
    Reported Balance: {{reported_balance}}<br><br>
    <strong>This account was opened fraudulently without my knowledge or authorization.</strong>
  </div>

  <p>As required by Section 605B, I am providing:</p>
  <ol>
    <li>A copy of my FTC Identity Theft Report (enclosed);</li>
    <li>Proof of my identity (copy of government-issued ID enclosed);</li>
    <li>A statement identifying the specific information that resulted from identity theft.</li>
  </ol>

  <p>Under Section 605B(a), you must block this information within 4 business days of receiving this request and the required documentation.</p>

  <p>Additionally, under Section 605B(b), you must promptly notify the furnisher of this information that:</p>
  <ul>
    <li>The information may be the result of identity theft;</li>
    <li>An identity theft report has been filed;</li>
    <li>A block has been requested.</li>
  </ul>

  <p>I also request that you place an extended fraud alert on my file pursuant to Section 605A(b).</p>

  <p><strong>Enclosed Documents:</strong></p>
  <ul>
    <li>FTC Identity Theft Report / Affidavit</li>
    <li>Police Report (Report #: {{police_report_number}})</li>
    <li>Copy of Driver's License</li>
    <li>Copy of Social Security Card</li>
    <li>Proof of Current Address (Utility Bill)</li>
  </ul>

  <p>Please confirm in writing that this fraudulent information has been blocked and that an extended fraud alert has been placed on my file.</p>
</div>

<div class="signature">
  <p>Sincerely,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
  <p>{{consumer_phone}}</p>
</div>

<div class="disclaimer">
  I declare under penalty of perjury that the information I have provided is true and correct to the best of my knowledge. I understand that making false statements is a federal crime.
</div>

</body>
</html>
```

---

## Template 8: CFPB Complaint Package Cover Letter

**Purpose:** Cover letter for filing complaint with CFPB.

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; margin: 1in; }
    .date { margin-bottom: 20px; }
    .address-block { margin-bottom: 20px; }
    .body { text-align: justify; }
    .complaint-summary { border: 1px solid #000; padding: 15px; margin: 20px 0; background: #f9f9f9; }
    .signature { margin-top: 40px; }
  </style>
</head>
<body>

<div class="date">{{current_date}}</div>

<div class="address-block">
  Consumer Financial Protection Bureau<br>
  P.O. Box 4503<br>
  Iowa City, Iowa 52244
</div>

<div class="address-block">
  <strong>RE: Complaint Against {{company_name}}</strong><br>
  Consumer: {{consumer_name}}<br>
  Account/Reference: {{account_number_masked}}
</div>

<div class="body">
  <p>To Whom It May Concern:</p>

  <p>I am filing this complaint against {{company_name}} for violations of the Fair Credit Reporting Act.</p>

  <div class="complaint-summary">
    <strong>COMPLAINT SUMMARY:</strong><br><br>
    <strong>Company:</strong> {{company_name}}<br>
    <strong>Company Type:</strong> {{company_type}}<br>
    <strong>Issue:</strong> {{complaint_issue}}<br>
    <strong>Date Issue Began:</strong> {{issue_start_date}}<br>
    <strong>Amount in Dispute:</strong> {{disputed_amount}}
  </div>

  <p><strong>Background:</strong></p>
  <p>{{complaint_narrative}}</p>

  <p><strong>Steps I Have Taken:</strong></p>
  <ol>
    {{#steps_taken}}
    <li>{{step_date}}: {{step_description}}</li>
    {{/steps_taken}}
  </ol>

  <p><strong>Company's Response:</strong></p>
  <p>{{company_response}}</p>

  <p><strong>Desired Resolution:</strong></p>
  <p>{{desired_resolution}}</p>

  <p><strong>Supporting Documentation:</strong></p>
  <p>I have enclosed the following documents:</p>
  {{evidence_index}}

  <p>I request that the CFPB investigate this matter and take appropriate enforcement action.</p>
</div>

<div class="signature">
  <p>Respectfully submitted,</p>
  <br><br>
  <p>{{consumer_name}}</p>
  <p>{{consumer_current_address}}</p>
  <p>{{consumer_phone}}</p>
  <p>{{consumer_email}}</p>
</div>

</body>
</html>
```

---

## Evidence Index Template

Used to generate the evidence attachment index for letters:

```html
<div class="evidence-index">
  <p><strong>INDEX OF EXHIBITS</strong></p>
  <table style="width: 100%; border-collapse: collapse;">
    <thead>
      <tr style="background: #f0f0f0;">
        <th style="border: 1px solid #000; padding: 8px; text-align: left;">Exhibit</th>
        <th style="border: 1px solid #000; padding: 8px; text-align: left;">Description</th>
        <th style="border: 1px solid #000; padding: 8px; text-align: left;">Pages</th>
      </tr>
    </thead>
    <tbody>
      {{#evidence_items}}
      <tr>
        <td style="border: 1px solid #000; padding: 8px;">{{exhibit_letter}}</td>
        <td style="border: 1px solid #000; padding: 8px;">{{description}}</td>
        <td style="border: 1px solid #000; padding: 8px;">{{page_range}}</td>
      </tr>
      {{/evidence_items}}
    </tbody>
  </table>
</div>
```

### Sample Output:

```
INDEX OF EXHIBITS

| Exhibit | Description                                          | Pages |
|---------|------------------------------------------------------|-------|
| A       | Capital One Statement - January 2024                 | 1-2   |
| B       | Bank Payment Confirmation - October 2023 Payment     | 3     |
| C       | Copy of Driver's License                             | 4     |
| D       | Copy of Utility Bill (Proof of Address)              | 5     |
```

---

## AI Narrative Generation Guidelines

When using AI to generate dispute narratives, the following guardrails apply:

### DO:
- Use factual, objective language
- Cite specific dates, amounts, and account details
- Reference attached evidence
- Keep tone professional and respectful
- Use straightforward explanations

### DO NOT:
- Provide legal advice or interpretations
- Use accusatory or threatening language
- Make claims that cannot be supported by evidence
- Include emotional appeals
- Reference case law or legal precedents (leave for templates)

### Sample AI Prompt:

```
Generate a factual dispute narrative for a consumer credit report error.

Facts:
- Account: Capital One Credit Card ending in 5678
- Issue: Balance reported as $2,450 but actual balance is $1,850
- Evidence: Bank statement showing current balance
- Additional: Payment marked 30 days late in October 2023, but payment was made on time

Requirements:
- Keep under 300 words
- Use first person ("I")
- Be factual and specific
- Reference the attached evidence
- Do not provide legal advice
- Do not use threatening language

Output only the narrative paragraph, no headers or formatting.
```

### Sample AI Output:

```
I am disputing the information reported for my Capital One credit card account ending in 5678.
The balance currently reported is $2,450.00, which is incorrect. As shown in Exhibit A, my
January 2024 statement clearly indicates my actual balance is $1,850.00 - a difference of
$600.00. Additionally, my payment history shows a 30-day late payment for October 2023.
This is inaccurate. As demonstrated in Exhibit B, my payment was processed on October 15, 2023,
well before the due date of October 25, 2023. I request that the balance be corrected to
$1,850.00 and the October 2023 payment status be updated to reflect on-time payment.
```
