/// Constants for the Credit Dispute System
class DisputeConstants {
  DisputeConstants._();

  // Dispute Types
  static const String dispute609Request = '609_request';
  static const String dispute611Dispute = '611_dispute';
  static const String disputeMovRequest = 'mov_request';
  static const String disputeReinvestigation = 'reinvestigation';
  static const String disputeGoodwill = 'goodwill';
  static const String disputePayForDelete = 'pay_for_delete';
  static const String disputeIdentityTheft = 'identity_theft_block';
  static const String disputeCfpbComplaint = 'cfpb_complaint';

  // Dispute Status
  static const String statusDraft = 'draft';
  static const String statusPendingReview = 'pending_review';
  static const String statusApproved = 'approved';
  static const String statusMailed = 'mailed';
  static const String statusDelivered = 'delivered';
  static const String statusInTransit = 'in_transit';
  static const String statusBureauInvestigating = 'bureau_investigating';
  static const String statusResolved = 'resolved';
  static const String statusClosed = 'closed';
  static const String statusCancelled = 'cancelled';

  // Dispute Outcomes
  static const String outcomePending = 'pending';
  static const String outcomeCorrected = 'corrected';
  static const String outcomeVerified = 'verified';
  static const String outcomeDeleted = 'deleted';
  static const String outcomeUpdated = 'updated';
  static const String outcomeNoChange = 'no_change';

  // Priority Levels
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Bureaus
  static const String bureauEquifax = 'equifax';
  static const String bureauExperian = 'experian';
  static const String bureauTransUnion = 'transunion';

  // Bureau Addresses
  static const Map<String, Map<String, String>> bureauAddresses = {
    bureauEquifax: {
      'name': 'Equifax Information Services LLC',
      'street1': 'P.O. Box 740256',
      'city': 'Atlanta',
      'state': 'GA',
      'zip': '30374',
      'country': 'US',
    },
    bureauExperian: {
      'name': 'Experian',
      'street1': 'P.O. Box 4500',
      'city': 'Allen',
      'state': 'TX',
      'zip': '75013',
      'country': 'US',
    },
    bureauTransUnion: {
      'name': 'TransUnion LLC',
      'street1': 'P.O. Box 2000',
      'city': 'Chester',
      'state': 'PA',
      'zip': '19016',
      'country': 'US',
    },
  };

  // Reason Codes
  static const String reasonNotMine = 'not_mine';
  static const String reasonInaccurateBalance = 'inaccurate_balance';
  static const String reasonPaidButReporting = 'paid_but_reporting';
  static const String reasonWrongDates = 'wrong_dates';
  static const String reasonDuplicate = 'duplicate';
  static const String reasonObsolete = 'obsolete';
  static const String reasonReAged = 're_aged';
  static const String reasonMissingDispute = 'missing_dispute_notice';
  static const String reasonIdentityTheft = 'identity_theft';
  static const String reasonFraud = 'fraud';
  static const String reasonInvalidVerification = 'invalid_verification';

  // Letter Types
  static const String letterType609 = '609_request';
  static const String letterType611 = '611_dispute';
  static const String letterTypeMov = 'mov_request';
  static const String letterTypeReinvestigation = 'reinvestigation';
  static const String letterTypeGoodwill = 'goodwill';
  static const String letterTypePayForDelete = 'pay_for_delete';
  static const String letterTypeIdentityTheft = 'identity_theft_block';
  static const String letterTypeCfpb = 'cfpb_complaint';

  // Mail Types
  static const String mailTypeFirstClass = 'usps_first_class';
  static const String mailTypeCertified = 'usps_certified';
  static const String mailTypeCertifiedReturnReceipt =
      'usps_certified_return_receipt';

  // Letter Status
  static const String letterStatusDraft = 'draft';
  static const String letterStatusPendingApproval = 'pending_approval';
  static const String letterStatusApproved = 'approved';
  static const String letterStatusRendering = 'rendering';
  static const String letterStatusReady = 'ready';
  static const String letterStatusQueued = 'queued';
  static const String letterStatusSent = 'sent';
  static const String letterStatusInTransit = 'in_transit';
  static const String letterStatusInLocalArea = 'in_local_area';
  static const String letterStatusProcessedForDelivery = 'processed_for_delivery';
  static const String letterStatusDelivered = 'delivered';
  static const String letterStatusReturnedToSender = 'returned_to_sender';
  static const String letterStatusFailed = 'failed';

  // SLA Timelines (in days)
  static const int slaStandardDays = 30;
  static const int slaExtendedDays = 45;

  // Account Types
  static const String accountTypeCreditCard = 'credit_card';
  static const String accountTypeMortgage = 'mortgage';
  static const String accountTypeAutoLoan = 'auto_loan';
  static const String accountTypeStudentLoan = 'student_loan';
  static const String accountTypePersonalLoan = 'personal_loan';
  static const String accountTypeCollection = 'collection';

  // Payment Status
  static const String paymentStatusCurrent = 'current';
  static const String paymentStatusLate30 = 'late_30';
  static const String paymentStatusLate60 = 'late_60';
  static const String paymentStatusLate90 = 'late_90';
  static const String paymentStatusLate120 = 'late_120';
  static const String paymentStatusChargeOff = 'charge_off';
  static const String paymentStatusCollection = 'collection';

  // KYC Status
  static const String kycStatusPending = 'pending';
  static const String kycStatusVerified = 'verified';
  static const String kycStatusFailed = 'failed';
  static const String kycStatusManualReview = 'manual_review';

  // Roles
  static const String roleOwner = 'owner';
  static const String roleOperator = 'operator';
  static const String roleViewer = 'viewer';
  static const String roleAuditor = 'auditor';

  // FCRA Citations
  static const Map<String, String> fcraCitations = {
    '607': '15 U.S.C. § 1681e - Compliance procedures',
    '609': '15 U.S.C. § 1681g - Disclosures to consumers',
    '611': '15 U.S.C. § 1681i - Procedure in case of disputed accuracy',
    '605B': '15 U.S.C. § 1681c-2 - Block of information from identity theft',
  };

  // Compliance Disclaimers
  static const String legalDisclaimer =
      'This letter is for informational purposes only and does not constitute legal advice. '
      'Consumer has the right to dispute inaccurate information under the Fair Credit Reporting Act (FCRA).';

  // File Upload Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxFilesPerDispute = 10;
  static const List<String> allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  // Storage Keys
  static const String keySelectedBureau = 'selected_bureau';
  static const String keyDisputeFilters = 'dispute_filters';
  static const String keyDashboardView = 'dashboard_view';
}
