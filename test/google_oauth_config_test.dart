import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/services/google_oauth_config.dart';

void main() {
  group('GoogleOAuthConfig', () {
    test('missing configuration does not require Google sign-in', () {
      const config = GoogleOAuthConfig();
      expect(config.serverClientId, isEmpty);
      expect(config.hasServerClientId, isFalse);
      expect(config.driveScope, GoogleOAuthConfig.defaultDriveScope);
      expect(
        config.driveTimeoutSeconds,
        GoogleOAuthConfig.defaultDriveTimeoutSeconds,
      );
    });

    test(
      'whitespace-only configuration is treated as missing and uses defaults',
      () {
        const config = GoogleOAuthConfig(
          serverClientId: ' \n\t ',
          driveScope: '   ',
          driveTimeoutSeconds: 0,
        );
        expect(config.serverClientId, isEmpty);
        expect(config.hasServerClientId, isFalse);
        expect(config.driveScope, GoogleOAuthConfig.defaultDriveScope);
        expect(
          config.driveTimeoutSeconds,
          GoogleOAuthConfig.defaultDriveTimeoutSeconds,
        );
      },
    );

    test('injected public parameters are normalized and respected', () {
      const config = GoogleOAuthConfig(
        serverClientId: ' 1234567890-fixture.apps.googleusercontent.com ',
        driveScope: ' https://www.googleapis.com/auth/drive.appdata ',
        driveTimeoutSeconds: 30,
      );
      expect(
        config.serverClientId,
        '1234567890-fixture.apps.googleusercontent.com',
      );
      expect(
        config.driveScope,
        'https://www.googleapis.com/auth/drive.appdata',
      );
      expect(config.driveTimeoutSeconds, 30);
      expect(config.hasServerClientId, isTrue);
    });

    test('presence does not claim validation with Google', () {
      const config = GoogleOAuthConfig(
        serverClientId: 'not-a-registered-client',
      );
      expect(config.hasServerClientId, isTrue);
    });

    test('reads compile-time declarations without runtime file access', () {
      const config = GoogleOAuthConfig.fromEnvironment();
      const expectedId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      expect(config.serverClientId, expectedId.trim());
      expect(config.hasServerClientId, expectedId.trim().isNotEmpty);
    });
  });
}
