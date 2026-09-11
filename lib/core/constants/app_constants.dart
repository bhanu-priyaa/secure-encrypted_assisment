abstract final class PrefsKeys {
  static const introSeen = 'intro_seen';
  static const themeMode = 'theme_mode';
}

abstract final class SecureKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const cacheKey = 'cache_data_key';
  static const pinSalt = 'pin_salt';
  static const pinHash = 'pin_hash';
}

abstract final class ApiConfig {
  static const baseUrl = 'https://dummyjson.com';
  static const sessionMinutes = 1;
  static const loginPath = '/auth/login';
  static const profilePath = '/auth/me';
  static const refreshPath = '/auth/refresh';
}

abstract final class AppConfig {
  static const splashMaxDuration = Duration(milliseconds: 1500);
  static const splashMinDuration = Duration(milliseconds: 400);
  static const maxPinAttempts = 3;
  static const pinLength = 6;
  static const minPasswordLength = 6;
}
