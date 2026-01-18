abstract class RouteNames {
  static const String splash = 'splash';
  static const String home = 'home';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
  static const String settings = 'settings';
  static const String profile = 'profile';

  // Dispute routes
  static const String disputeOverview = 'dispute_overview';
  static const String disputeDetail = 'dispute_detail';
  static const String disputeCreate = 'dispute_create';

  // Consumer routes
  static const String consumerList = 'consumer_list';
  static const String consumerDetail = 'consumer_detail';
  static const String consumerCreate = 'consumer_create';

  // Letter routes
  static const String letterList = 'letter_list';
  static const String letterDetail = 'letter_detail';
  static const String letterGenerate = 'letter_generate';
}

abstract class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Dispute routes
  static const String disputeOverview = '/disputes';
  static const String disputeDetail = '/disputes/:id';
  static const String disputeCreate = '/disputes/new';

  // Consumer routes
  static const String consumerList = '/consumers';
  static const String consumerDetail = '/consumers/:id';
  static const String consumerCreate = '/consumers/new';

  // Letter routes
  static const String letterList = '/letters';
  static const String letterDetail = '/letters/:id';
  static const String letterGenerate = '/disputes/:disputeId/letters/new';
}
