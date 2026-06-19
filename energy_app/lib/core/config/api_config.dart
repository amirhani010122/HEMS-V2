import 'environment.dart';

class ApiConfig {
  /// Base URL is driven by the active environment so the app talks to the
  /// running backend (dev: http://localhost:8000/api/v1).
  static String get baseUrl => EnvironmentConfig.baseUrl;

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String me = '/users/me';

  // Devices
  static const String devices = '/devices';
  static String deviceById(String id) => '/devices/$id';

  // Consumption
  static const String consumptionCreate = '/consumption';
  static const String consumptionDaily = '/consumption/daily';
  static const String consumptionMonthly = '/consumption/monthly';
  static const String consumptionSummary = '/consumption/summary';
  static const String consumptionPerDeviceDaily =
      '/consumption/per-device-daily';

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
