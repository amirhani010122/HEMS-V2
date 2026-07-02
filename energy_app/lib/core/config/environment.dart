enum Environment { development, staging, production }

class EnvironmentConfig {
  // تم تغيير البيئة هنا إلى production ليعتمد التطبيق الرابط السحابي
  static const Environment _currentEnvironment = Environment.production;

  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://0.0.0.0:8000/api/v1';
      case Environment.staging:
        return 'https://staging-api.energyiq.com/api/v1';
      case Environment.production:
      // تم وضع رابط سيرفر ريلواي الخاص بك مع مسار الـ API المعتاد
        return 'https://hems-v2-production.up.railway.app/api/v1';
    }
  }

  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;

  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableCrashReporting => isProduction;

  // Feature flags
  static const bool enableOfflineSync = false;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableDataEncryption = true;
}
