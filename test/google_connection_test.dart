import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/controllers/google_drive_controller.dart';
import 'package:mylink/services/drive_access_service.dart';
import 'package:mylink/services/google_connection.dart';
import 'package:mylink/services/google_oauth_config.dart';

import 'bookmarks_test.dart' show MemoryStorage;

class FakeGoogleConnection implements GoogleConnection {
  FakeGoogleConnection({
    this.configured = true,
    GoogleUser? initialUser,
    this.tokenToReturn,
  }) : _user = initialUser;

  bool configured;
  GoogleUser? _user;
  String? tokenToReturn;
  bool throwOnSignIn = false;
  bool throwOnAuthorize = false;
  bool throwOnSignOut = false;
  bool throwOnDisconnect = false;
  Completer<String?>? delayedTokenCompleter;

  final _controller = StreamController<GoogleUser?>.broadcast();

  @override
  bool get isConfigured => configured;

  @override
  GoogleUser? get currentUser => _user;

  @override
  Stream<GoogleUser?> get userStream => _controller.stream;

  @override
  Future<void> initialize() async {
    // No-op for fake
  }

  @override
  Future<GoogleUser?> signIn() async {
    if (!configured) {
      throw StateError(
        'Configuração ausente: defina GOOGLE_SERVER_CLIENT_ID no arquivo .env.',
      );
    }
    if (throwOnSignIn) {
      throw Exception('Sign in failed');
    }
    _user = const GoogleUser(
      id: 'test-id',
      email: 'user@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.png',
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    if (throwOnSignOut) {
      throw Exception('Sign out error');
    }
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> disconnect() async {
    if (throwOnDisconnect) {
      throw Exception('Disconnect error');
    }
    _user = null;
    _controller.add(null);
  }

  @override
  Future<String?> getDriveAccessToken({
    bool requestIfNotGranted = false,
  }) async {
    if (delayedTokenCompleter != null) {
      return delayedTokenCompleter!.future;
    }
    if (throwOnAuthorize) {
      throw Exception('Authorize error');
    }
    if (_user == null) return null;
    return tokenToReturn;
  }

  void emitUser(GoogleUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class FakeDriveAccessService implements DriveAccessService {
  DriveAccessResult resultToReturn = const DriveAccessResult(
    status: DriveAccessStatus.verified,
    rawStatusCode: 200,
    message: 'Verificado',
  );

  DriveBackupInfo? fakeBackupInfo;
  String? fakeRemoteCsv;
  bool throwOnUpload = false;
  bool throwOnDownload = false;
  DriveAccessStatus uploadStatusToReturn = DriveAccessStatus.verified;
  DriveAccessStatus downloadStatusToReturn = DriveAccessStatus.verified;

  Completer<DriveAccessResult>? delayedCompleter;
  int callCount = 0;
  int uploadCount = 0;
  int downloadCount = 0;
  int getBackupInfoCount = 0;
  String? lastAccessToken;
  String? lastUploadedCsv;

  @override
  Future<DriveAccessResult> verifyAccess({required String accessToken}) async {
    callCount++;
    lastAccessToken = accessToken;
    if (delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    return resultToReturn;
  }

  @override
  Future<DriveBackupInfoResult> getBackupInfo({
    required String accessToken,
  }) async {
    getBackupInfoCount++;
    lastAccessToken = accessToken;
    return DriveBackupInfoResult(
      status: DriveAccessStatus.verified,
      message: fakeBackupInfo != null
          ? 'Backup encontrado'
          : 'Nenhum backup encontrado',
      backupInfo: fakeBackupInfo,
      rawStatusCode: 200,
    );
  }

  @override
  Future<DriveOperationResult> uploadBackup({
    required String accessToken,
    required String csvContent,
  }) async {
    uploadCount++;
    lastAccessToken = accessToken;
    lastUploadedCsv = csvContent;
    if (throwOnUpload) throw Exception('Upload error');
    if (uploadStatusToReturn != DriveAccessStatus.verified) {
      return DriveOperationResult(
        status: uploadStatusToReturn,
        message: 'Erro no upload',
      );
    }
    fakeRemoteCsv = csvContent;
    fakeBackupInfo = DriveBackupInfo(
      fileId: 'fake-file-id',
      name: 'mylink_backup.csv',
      modifiedTime: DateTime.now(),
      sizeBytes: csvContent.length,
    );
    return DriveOperationResult(
      status: DriveAccessStatus.verified,
      message: 'Backup enviado com sucesso para o Google Drive.',
      backupInfo: fakeBackupInfo,
      rawStatusCode: 200,
    );
  }

  @override
  Future<DriveDownloadResult> downloadBackup({
    required String accessToken,
  }) async {
    downloadCount++;
    lastAccessToken = accessToken;
    if (throwOnDownload) throw Exception('Download error');
    if (downloadStatusToReturn != DriveAccessStatus.verified) {
      return DriveDownloadResult(
        status: downloadStatusToReturn,
        message: 'Erro no download',
      );
    }
    if (fakeRemoteCsv == null) {
      return const DriveDownloadResult(
        status: DriveAccessStatus.notFound,
        message: 'Nenhum backup encontrado no Google Drive.',
        rawStatusCode: 404,
      );
    }
    return DriveDownloadResult(
      status: DriveAccessStatus.verified,
      message: 'Backup baixado com sucesso.',
      csvContent: fakeRemoteCsv,
      backupInfo: fakeBackupInfo,
      modifiedTime: fakeBackupInfo?.modifiedTime ?? DateTime.now(),
      rawStatusCode: 200,
    );
  }
}

void main() {
  group('GoogleUser', () {
    test('value equality, hashCode and toString', () {
      const u1 = GoogleUser(
        id: '1',
        email: 'a@b.com',
        displayName: 'A',
        photoUrl: 'p',
      );
      const u2 = GoogleUser(
        id: '1',
        email: 'a@b.com',
        displayName: 'A',
        photoUrl: 'p',
      );
      const u3 = GoogleUser(id: '2', email: 'c@d.com');

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
      expect(u1.toString(), contains('a@b.com'));
    });
  });

  group('DefaultGoogleConnection configuration check', () {
    test(
      'signIn throws StateError if serverClientId is not configured',
      () async {
        final conn = DefaultGoogleConnection(config: const GoogleOAuthConfig());
        expect(conn.isConfigured, isFalse);
        expect(() => conn.signIn(), throwsStateError);
        conn.dispose();
      },
    );
  });

  group('GoogleDriveController', () {
    late FakeGoogleConnection connection;
    late FakeDriveAccessService driveService;
    late GoogleDriveController controller;

    setUp(() {
      connection = FakeGoogleConnection();
      driveService = FakeDriveAccessService();
      controller = GoogleDriveController(
        connection: connection,
        driveAccessService: driveService,
      );
    });

    tearDown(() {
      controller.dispose();
      connection.dispose();
    });

    test('initial state before initialize()', () {
      expect(controller.authStatus, AuthStatus.uninitialized);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.unknown);
      expect(controller.verificationStatus, DriveVerificationStatus.idle);
      expect(controller.user, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.statusMessage, isNull);
      expect(controller.isBusy, isFalse);
    });

    test('initialize() without saved user sets disconnected', () async {
      await controller.initialize();
      expect(controller.authStatus, AuthStatus.disconnected);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.notGranted);
      expect(controller.user, isNull);
    });

    test('initialize() with existing user checks drive token', () async {
      connection = FakeGoogleConnection(
        initialUser: const GoogleUser(id: '1', email: 'test@example.com'),
        tokenToReturn: 'valid-drive-token',
      );
      controller = GoogleDriveController(
        connection: connection,
        driveAccessService: driveService,
      );

      await controller.initialize();
      expect(controller.authStatus, AuthStatus.connected);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.granted);
      expect(controller.user?.email, 'test@example.com');
    });

    test('signIn() success updates user and drive status', () async {
      connection.tokenToReturn = 'drive-token';
      await controller.initialize();
      await controller.signIn();

      expect(controller.authStatus, AuthStatus.connected);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.granted);
      expect(controller.user?.email, 'user@example.com');
      expect(controller.errorMessage, isNull);
    });

    test('signIn() failure sets error and disconnected status', () async {
      connection.throwOnSignIn = true;
      await controller.initialize();
      await controller.signIn();

      expect(controller.authStatus, AuthStatus.disconnected);
      expect(controller.user, isNull);
      expect(controller.errorMessage, contains('cancelada ou não concluída'));
    });

    test('authorizeDrive() grants permission and sets statusMessage', () async {
      await controller.initialize();
      await controller.signIn();

      connection.tokenToReturn = 'newly-granted-token';
      await controller.authorizeDrive();

      expect(controller.driveAuthStatus, DriveAuthorizationStatus.granted);
      expect(controller.statusMessage, contains('concedida com sucesso'));
      expect(controller.errorMessage, isNull);
    });

    test('authorizeDrive() failure sets error and notGranted status', () async {
      await controller.initialize();
      await controller.signIn();

      connection.tokenToReturn = null;
      connection.throwOnAuthorize = true;
      await controller.authorizeDrive();

      expect(controller.driveAuthStatus, DriveAuthorizationStatus.notGranted);
      expect(controller.errorMessage, contains('Não foi possível autorizar'));
    });

    test(
      'verifyDriveAccess() success when token is present and valid',
      () async {
        connection.tokenToReturn = 'valid-token';
        await controller.initialize();
        await controller.signIn();

        driveService.resultToReturn = const DriveAccessResult(
          status: DriveAccessStatus.verified,
          rawStatusCode: 200,
          message: 'Acesso verificado',
        );

        await controller.verifyDriveAccess();

        expect(controller.verificationStatus, DriveVerificationStatus.success);
        expect(controller.statusMessage, 'Acesso verificado');
        expect(controller.errorMessage, isNull);
        expect(driveService.callCount, 1);
        expect(driveService.lastAccessToken, 'valid-token');
      },
    );

    test('verifyDriveAccess() fails if token is absent', () async {
      connection.tokenToReturn = null;
      await controller.initialize();
      await controller.signIn();

      await controller.verifyDriveAccess();

      expect(controller.verificationStatus, DriveVerificationStatus.failure);
      expect(controller.errorMessage, contains('Autorize o Drive primeiro'));
      expect(driveService.callCount, 0);
    });

    test(
      'verifyDriveAccess() failure updates verification and drive status on 401',
      () async {
        connection.tokenToReturn = 'expired-token';
        await controller.initialize();
        await controller.signIn();

        driveService.resultToReturn = const DriveAccessResult(
          status: DriveAccessStatus.unauthorized,
          rawStatusCode: 401,
          message: 'Sessão expirada',
        );

        await controller.verifyDriveAccess();

        expect(controller.verificationStatus, DriveVerificationStatus.failure);
        expect(controller.driveAuthStatus, DriveAuthorizationStatus.notGranted);
        expect(controller.errorMessage, 'Sessão expirada');
      },
    );

    test('signOut() clears user and resets statuses', () async {
      await controller.initialize();
      await controller.signIn();

      await controller.signOut();

      expect(controller.authStatus, AuthStatus.disconnected);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.notGranted);
      expect(controller.verificationStatus, DriveVerificationStatus.idle);
      expect(controller.user, isNull);
      expect(controller.statusMessage, contains('encerrada com sucesso'));
    });

    test('disconnect() clears user and revokes access', () async {
      await controller.initialize();
      await controller.signIn();

      await controller.disconnect();

      expect(controller.authStatus, AuthStatus.disconnected);
      expect(controller.driveAuthStatus, DriveAuthorizationStatus.notGranted);
      expect(controller.user, isNull);
      expect(controller.statusMessage, contains('revogado'));
    });

    test(
      'session generation discards delayed responses when user changes externally',
      () async {
        await controller.initialize();
        await controller.signIn();

        final completer = Completer<DriveAccessResult>();
        driveService.delayedCompleter = completer;
        connection.tokenToReturn = 'token-1';

        // Start verifying in flight
        final verifyFuture = controller.verifyDriveAccess();

        // User changed externally (stream emitted null / signed out)
        connection.emitUser(null);

        // Now complete the delayed response
        completer.complete(
          const DriveAccessResult(
            status: DriveAccessStatus.verified,
            rawStatusCode: 200,
            message: 'Old response',
          ),
        );
        await verifyFuture;

        // Old verification result should NOT overwrite signed-out state
        expect(controller.authStatus, AuthStatus.disconnected);
        expect(controller.user, isNull);
        expect(controller.verificationStatus, DriveVerificationStatus.idle);
      },
    );

    test('isBusy prevents overlapping operations', () async {
      await controller.initialize();
      await controller.signIn();

      final completer = Completer<DriveAccessResult>();
      driveService.delayedCompleter = completer;
      connection.tokenToReturn = 'token-1';

      final verifyFuture = controller.verifyDriveAccess();
      expect(controller.isBusy, isTrue);

      // Calling authorizeDrive or signOut while busy should be blocked
      await controller.authorizeDrive();
      expect(
        controller.driveAuthStatus,
        isNot(DriveAuthorizationStatus.authorizing),
      );

      completer.complete(
        const DriveAccessResult(
          status: DriveAccessStatus.verified,
          rawStatusCode: 200,
          message: 'Done',
        ),
      );
      await verifyFuture;
      expect(controller.isBusy, isFalse);
    });

    test('clearMessages() clears error and status messages', () {
      controller.clearMessages();
      expect(controller.errorMessage, isNull);
      expect(controller.statusMessage, isNull);
    });

    test('backup() fails with message if library has no links', () async {
      final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      connection.tokenToReturn = 'valid-token';
      await controller.initialize();
      await controller.signIn();

      final success = await controller.backup(library);
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Nenhum link disponível'));
    });

    test('backup() uploads CSV and updates backupInfo on success', () async {
      final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      await library.save(
        url: 'https://flutter.dev',
        title: 'Flutter',
        category: 'Technology',
      );
      connection.tokenToReturn = 'valid-token';
      await controller.initialize();
      await controller.signIn();

      final success = await controller.backup(library);
      expect(success, isTrue);
      expect(driveService.uploadCount, 1);
      expect(driveService.lastUploadedCsv, contains('https://flutter.dev'));
      expect(controller.backupInfo, isNotNull);
      expect(controller.backupInfo!.fileId, 'fake-file-id');
      expect(
        controller.statusMessage,
        contains('Backup realizado com sucesso'),
      );
    });

    test('backup() handles upload failure gracefully', () async {
      final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      await library.save(
        url: 'https://flutter.dev',
        title: 'Flutter',
        category: 'Technology',
      );
      connection.tokenToReturn = 'valid-token';
      driveService.uploadStatusToReturn = DriveAccessStatus.serverError;
      await controller.initialize();
      await controller.signIn();

      final success = await controller.backup(library);
      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test(
      'restore() downloads and imports CSV into library on success',
      () async {
        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();
        expect(library.state.links, isEmpty);

        connection.tokenToReturn = 'valid-token';
        driveService.fakeRemoteCsv =
            'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n'
            'Restored Link,https://example.com/restored,News,0,,TRUE\n';

        await controller.initialize();
        await controller.signIn();

        final success = await controller.restore(library);
        expect(success, isTrue);
        expect(driveService.downloadCount, 1);
        expect(library.state.links.length, 1);
        expect(library.state.links.first.title, 'Restored Link');
        expect(library.state.links.first.url, 'https://example.com/restored');
        expect(controller.statusMessage, contains('restaurado com sucesso'));
      },
    );

    test(
      'restore() fails with error message when no remote backup exists',
      () async {
        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();
        connection.tokenToReturn = 'valid-token';
        driveService.fakeRemoteCsv = null;

        await controller.initialize();
        await controller.signIn();

        final success = await controller.restore(library);
        expect(success, isFalse);
        expect(controller.errorMessage, contains('Nenhum backup encontrado'));
      },
    );

    test(
      'refreshBackupInfo() queries metadata and updates backupInfo',
      () async {
        connection.tokenToReturn = 'valid-token';
        driveService.fakeBackupInfo = DriveBackupInfo(
          fileId: 'cloud-file-1',
          name: 'mylink_backup.csv',
          modifiedTime: DateTime.now(),
          sizeBytes: 1024,
        );

        await controller.initialize();
        await controller.signIn();

        await controller.refreshBackupInfo();
        expect(controller.backupInfo, isNotNull);
        expect(controller.backupInfo!.fileId, 'cloud-file-1');
      },
    );
  });
}
