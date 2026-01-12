/// Constants for Lob API Integration
class LobConstants {
  LobConstants._();

  // API Endpoints (relative to base URL)
  static const String endpointLetters = '/v1/letters';
  static const String endpointAddresses = '/v1/addresses';
  static const String endpointVerifyAddress = '/v1/us_verifications';
  static const String endpointWebhooks = '/v1/webhooks';

  // Letter Sizes
  static const String sizeUsLetter = 'us_letter';

  // Mail Types
  static const String mailTypeFirstClass = 'usps_first_class';
  static const String mailTypeCertified = 'usps_certified';

  // Extra Services
  static const String extraServiceCertified = 'certified';
  static const String extraServiceReturnReceipt = 'certified_return_receipt';

  // Colors
  static const bool colorTrue = true; // Full color
  static const bool colorFalse = false; // Black and white

  // Double-sided printing
  static const bool doubleSidedTrue = true;
  static const bool doubleSidedFalse = false;

  // Address placement
  static const String addressPlacementTopFirstPage = 'top_first_page';
  static const String addressPlacementInsertBlankPage = 'insert_blank_page';

  // Mail merge
  static const String mergeVariableDefault = 'default';

  // Webhook Event Types
  static const String webhookLetterCreated = 'letter.created';
  static const String webhookLetterRenderedPdf = 'letter.rendered_pdf';
  static const String webhookLetterRenderedThumb = 'letter.rendered_thumbnails';
  static const String webhookLetterInTransit = 'letter.in_transit';
  static const String webhookLetterInLocalArea = 'letter.in_local_area';
  static const String webhookLetterProcessedForDelivery =
      'letter.processed_for_delivery';
  static const String webhookLetterReRoutedRequested = 're_routed';
  static const String webhookLetterReturnedToSender = 'letter.returned_to_sender';
  static const String webhookLetterCertifiedDelivered =
      'letter.certified_delivered';
  static const String webhookLetterMailed = 'letter.mailed';

  // Status Codes
  static const String statusCreated = 'created';
  static const String statusRendered = 'rendered';
  static const String statusMailed = 'mailed';
  static const String statusInTransit = 'in_transit';
  static const String statusInLocalArea = 'in_local_area';
  static const String statusProcessedForDelivery = 'processed_for_delivery';
  static const String statusDelivered = 'delivered';
  static const String statusReturnedToSender = 'returned_to_sender';
  static const String statusFailed = 'failed';

  // Estimated delivery days
  static const int estimatedDeliveryFirstClass = 5; // 3-5 business days
  static const int estimatedDeliveryCertified = 7; // 5-7 business days

  // Pricing (USD - approximate, check current Lob pricing)
  static const double costFirstClassBase = 0.60;
  static const double costCertifiedBase = 7.23;
  static const double costReturnReceiptBase = 3.50;
  static const double costPerPage = 0.05;
  static const double costColor = 0.20; // Additional per page for color

  // Validation
  static const int maxLetterPages = 60;
  static const int maxFileSizeMb = 40;

  // Rate Limits
  static const int maxRequestsPerSecond = 10;
  static const int maxLettersPerBatch = 100;

  // Test Mode
  static const bool testModeEnabled = true;
  static const bool testModeDisabled = false;

  // Address Verification Strictness
  static const String strictnessRelaxed = 'relaxed';
  static const String strictnessNormal = 'normal';
  static const String strictnessStrict = 'strict';

  // Error Codes
  static const String errorInvalidAddress = 'invalid_address';
  static const String errorUndeliverable = 'undeliverable_address';
  static const String errorInsufficientFunds = 'insufficient_funds';
  static const String errorInvalidPdf = 'invalid_pdf';
  static const String errorTooManyPages = 'too_many_pages';

  // Tracking URL Template
  static String getTrackingUrl(String trackingNumber) =>
      'https://tools.usps.com/go/TrackConfirmAction?tLabels=$trackingNumber';

  // Letter URL Template (for viewing)
  static String getLetterUrl(String letterId) =>
      'https://api.lob.com/v1/letters/$letterId';
}
