class AppCheckConfig {
  AppCheckConfig._();

  static const String androidDebugToken = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN_ANDROID',
  );

  static const String webDebugToken = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN_WEB',
  );
}
