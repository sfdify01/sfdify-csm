/// Constants for SmartCredit API Integration
class SmartCreditConstants {
  SmartCreditConstants._();

  // API Endpoints (relative to base URL)
  static const String endpointAuth = '/oauth/authorize';
  static const String endpointToken = '/oauth/token';
  static const String endpointRefreshToken = '/oauth/token/refresh';
  static const String endpointCreditReports = '/v1/credit-reports';
  static const String endpointTradelines = '/v1/tradelines';
  static const String endpointAlerts = '/v1/alerts';
  static const String endpointScoreFactors = '/v1/score-factors';
  static const String endpointConsumerProfile = '/v1/profile';
  static const String endpointDisconnect = '/v1/connection/disconnect';

  // OAuth Scopes
  static const List<String> requiredScopes = [
    'read:credit_reports',
    'read:tradelines',
    'read:alerts',
    'read:profile',
  ];

  // Grant Types
  static const String grantTypeAuthorizationCode = 'authorization_code';
  static const String grantTypeRefreshToken = 'refresh_token';

  // Report Types
  static const String reportTypeEquifax = 'equifax';
  static const String reportTypeExperian = 'experian';
  static const String reportTypeTransUnion = 'transunion';
  static const String reportTypeThreeBureau = 'three_bureau';

  // Connection Status
  static const String connectionStatusActive = 'active';
  static const String connectionStatusExpired = 'expired';
  static const String connectionStatusRevoked = 'revoked';
  static const String connectionStatusError = 'error';

  // Cache Duration
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration reportCacheDuration = Duration(hours: 24);

  // Rate Limits
  static const int maxRequestsPerMinute = 60;
  static const int maxReportPullsPerDay = 10;

  // Error Codes
  static const String errorCodeInvalidToken = 'invalid_token';
  static const String errorCodeExpiredToken = 'expired_token';
  static const String errorCodeInsufficientScope = 'insufficient_scope';
  static const String errorCodeRateLimitExceeded = 'rate_limit_exceeded';
  static const String errorCodeReportNotAvailable = 'report_not_available';
  static const String errorCodeConsumerNotFound = 'consumer_not_found';

  // Webhook Event Types
  static const String webhookCreditReportUpdate = 'credit_report.updated';
  static const String webhookTradelineChange = 'tradeline.changed';
  static const String webhookScoreChange = 'score.changed';
  static const String webhookConnectionRevoked = 'connection.revoked';
}
