// ignore_for_file: prefer_initializing_formals

/// Public build configuration, supplied with --dart-define-from-file=.env.
/// Values are compiled into the app and must never contain secrets.
class GoogleOAuthConfig {
  const GoogleOAuthConfig({
    String serverClientId = '',
    String driveScope = defaultDriveScope,
    int driveTimeoutSeconds = defaultDriveTimeoutSeconds,
  }) : _serverClientId = serverClientId,
       _driveScope = driveScope,
       _driveTimeoutSeconds = driveTimeoutSeconds;

  const GoogleOAuthConfig.fromEnvironment()
    : _serverClientId = const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      _driveScope = const String.fromEnvironment(
        'GOOGLE_DRIVE_SCOPE',
        defaultValue: defaultDriveScope,
      ),
      _driveTimeoutSeconds = const int.fromEnvironment(
        'GOOGLE_DRIVE_TIMEOUT_SECONDS',
        defaultValue: defaultDriveTimeoutSeconds,
      );

  static const String defaultDriveScope =
      'https://www.googleapis.com/auth/drive.file';
  static const int defaultDriveTimeoutSeconds = 15;

  final String _serverClientId;
  final String _driveScope;
  final int _driveTimeoutSeconds;

  String get serverClientId => _serverClientId.trim();

  String get driveScope =>
      _driveScope.trim().isNotEmpty ? _driveScope.trim() : defaultDriveScope;

  int get driveTimeoutSeconds => _driveTimeoutSeconds > 0
      ? _driveTimeoutSeconds
      : defaultDriveTimeoutSeconds;

  /// Presence does not prove that this ID is registered or valid with Google.
  bool get hasServerClientId => serverClientId.isNotEmpty;
}
