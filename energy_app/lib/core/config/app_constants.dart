class AppConstants {
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';

  // Pagination
  static const int pageSize = 20;

  // Chart limits
  static const int maxChartPoints = 30;

  // Alert severity thresholds
  static const double criticalUsagePercent = 95.0;
  static const double highUsagePercent = 80.0;
  static const double mediumUsagePercent = 60.0;

  // Retry policy
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // App info
  static const String appName = 'EnergyIQ';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
}

class AppDimensions {
  // Padding & Margin
  static const double spacerXs = 4.0;
  static const double spacerSm = 8.0;
  static const double spacerMd = 12.0;
  static const double spacerLg = 16.0;
  static const double spacerXl = 20.0;
  static const double spacerXxl = 24.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Component heights
  static const double buttonHeight = 48.0;
  static const double appBarHeight = 56.0;
  static const double cardHeight = 120.0;
}

class ApiEndpoints {
  // Base paths
  static const String baseUrl = 'https://api.energyiq.local/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Users
  static const String currentUser = '/users/me';

  // Devices
  static const String devices = '/devices';
  static String deviceDetail(String id) => '/devices/$id';

  // Consumption
  static const String consumptionCreate = '/consumption';
  static const String consumptionDaily = '/consumption/daily';
  static const String consumptionMonthly = '/consumption/monthly';
  static const String consumptionSummary = '/consumption/summary';
  static const String consumptionPerDeviceDaily = '/consumption/per-device-daily';

  // Plans
  static const String plansCreate = '/plans/create';
  static const String plansAvailable = '/plans/available';
  static const String plansSubscribe = '/plans/subscribe';
  static const String plansSubscription = '/plans/subscription';

  // Alerts
  static const String alerts = '/alerts';

  // AI
  static const String aiAnalysis = '/ai/analysis';
  static const String aiPrediction = '/ai/prediction';
  static const String aiPlanExhaustion = '/ai/plan-exhaustion';
  static const String aiRecommendations = '/ai/recommendations';
}
