import 'dart:async';

import 'package:flutter/foundation.dart';

import '../bookmarks.dart';
import '../services/drive_access_service.dart';
import '../services/google_connection.dart';

enum AuthStatus { uninitialized, disconnected, connecting, connected }

enum DriveAuthorizationStatus { unknown, notGranted, authorizing, granted }

enum DriveVerificationStatus { idle, verifying, success, failure }

class GoogleDriveController extends ChangeNotifier {
  GoogleDriveController({
    required this.connection,
    required this.driveAccessService,
  });

  final GoogleConnection connection;
  final DriveAccessService driveAccessService;

  AuthStatus _authStatus = AuthStatus.uninitialized;
  DriveAuthorizationStatus _driveAuthStatus = DriveAuthorizationStatus.unknown;
  DriveVerificationStatus _verificationStatus = DriveVerificationStatus.idle;

  GoogleUser? _user;
  DriveBackupInfo? _backupInfo;
  String? _errorMessage;
  String? _statusMessage;
  bool _isBusy = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isLoadingBackupInfo = false;
  int _sessionGeneration = 0;
  StreamSubscription<GoogleUser?>? _userSubscription;

  AuthStatus get authStatus => _authStatus;
  DriveAuthorizationStatus get driveAuthStatus => _driveAuthStatus;
  DriveVerificationStatus get verificationStatus => _verificationStatus;
  GoogleUser? get user => _user;
  DriveBackupInfo? get backupInfo => _backupInfo;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  bool get isBusy => _isBusy;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  bool get isLoadingBackupInfo => _isLoadingBackupInfo;
  bool get isConfigured => connection.isConfigured;

  Future<void> initialize() async {
    if (_authStatus != AuthStatus.uninitialized) return;

    _userSubscription = connection.userStream.listen(_onUserChanged);

    try {
      await connection.initialize();
      final current = connection.currentUser;
      if (current != null) {
        _user = current;
        _authStatus = AuthStatus.connected;
        await _checkDriveAuthorization(requestIfNotGranted: false);
      } else {
        _authStatus = AuthStatus.disconnected;
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      }
    } catch (e) {
      _authStatus = AuthStatus.disconnected;
      _driveAuthStatus = DriveAuthorizationStatus.unknown;
      _errorMessage = 'Falha ao inicializar conexão com Google.';
    }
    notifyListeners();
  }

  void _onUserChanged(GoogleUser? newUser) {
    _sessionGeneration++;
    final currentGeneration = _sessionGeneration;

    _user = newUser;
    _backupInfo = null;
    _verificationStatus = DriveVerificationStatus.idle;
    _statusMessage = null;

    if (newUser != null) {
      _authStatus = AuthStatus.connected;
      _driveAuthStatus = DriveAuthorizationStatus.unknown;
      notifyListeners();
      _checkDriveAuthorization(
        requestIfNotGranted: false,
        generation: currentGeneration,
      );
    } else {
      _authStatus = AuthStatus.disconnected;
      _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      notifyListeners();
    }
  }

  Future<void> _checkDriveAuthorization({
    required bool requestIfNotGranted,
    int? generation,
  }) async {
    final gen = generation ?? _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: requestIfNotGranted,
      );
      if (gen != _sessionGeneration) return;

      if (token != null && token.isNotEmpty) {
        _driveAuthStatus = DriveAuthorizationStatus.granted;
        notifyListeners();
        await _loadBackupInfo(token, gen);
      } else {
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        notifyListeners();
      }
    } catch (_) {
      if (gen != _sessionGeneration) return;
      _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      notifyListeners();
    }
  }

  Future<void> _loadBackupInfo(String token, int gen) async {
    if (gen != _sessionGeneration) return;
    _isLoadingBackupInfo = true;
    notifyListeners();

    try {
      final res = await driveAccessService.getBackupInfo(accessToken: token);
      if (gen != _sessionGeneration) return;
      if (res.isSuccess) {
        _backupInfo = res.backupInfo;
      }
    } catch (_) {
      // Ignored non-fatal failure loading backup metadata.
    } finally {
      if (gen == _sessionGeneration) {
        _isLoadingBackupInfo = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshBackupInfo() async {
    if (_user == null ||
        _driveAuthStatus != DriveAuthorizationStatus.granted ||
        _isBusy) {
      return;
    }
    final gen = _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: false,
      );
      if (gen != _sessionGeneration || token == null || token.isEmpty) return;
      await _loadBackupInfo(token, gen);
    } catch (_) {}
  }

  Future<void> signIn() async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    _authStatus = AuthStatus.connecting;
    notifyListeners();

    try {
      final user = await connection.signIn();
      if (user != null) {
        _user = user;
        _authStatus = AuthStatus.connected;
        await _checkDriveAuthorization(requestIfNotGranted: false);
      } else {
        _authStatus = AuthStatus.disconnected;
      }
    } catch (e) {
      _authStatus = AuthStatus.disconnected;
      _errorMessage = e is StateError
          ? e.message
          : 'Conexão cancelada ou não concluída.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> authorizeDrive() async {
    if (_isBusy || _user == null) return;
    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    _driveAuthStatus = DriveAuthorizationStatus.authorizing;
    notifyListeners();

    final gen = _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: true,
      );
      if (gen != _sessionGeneration) return;

      if (token != null && token.isNotEmpty) {
        _driveAuthStatus = DriveAuthorizationStatus.granted;
        _statusMessage = 'Permissão para o Google Drive concedida com sucesso.';
        notifyListeners();
        await _loadBackupInfo(token, gen);
      } else {
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        _errorMessage = 'Permissão para o Google Drive não foi concedida.';
      }
    } catch (e) {
      if (gen != _sessionGeneration) return;
      _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      _errorMessage = 'Não foi possível autorizar o acesso ao Google Drive.';
    } finally {
      if (gen == _sessionGeneration) {
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> verifyDriveAccess() async {
    if (_isBusy || _user == null) return;
    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    _verificationStatus = DriveVerificationStatus.verifying;
    notifyListeners();

    final gen = _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: false,
      );
      if (gen != _sessionGeneration) return;

      if (token == null || token.isEmpty) {
        _verificationStatus = DriveVerificationStatus.failure;
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        _errorMessage =
            'Token do Drive não encontrado. Autorize o Drive primeiro.';
        return;
      }

      final result = await driveAccessService.verifyAccess(accessToken: token);
      if (gen != _sessionGeneration) return;

      if (result.isSuccess) {
        _verificationStatus = DriveVerificationStatus.success;
        _statusMessage = result.message;
      } else {
        _verificationStatus = DriveVerificationStatus.failure;
        _errorMessage = result.message;
        if (result.status == DriveAccessStatus.unauthorized ||
            result.status == DriveAccessStatus.forbidden) {
          _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        }
      }
    } catch (e) {
      if (gen != _sessionGeneration) return;
      _verificationStatus = DriveVerificationStatus.failure;
      _errorMessage = 'Falha ao verificar acesso à Drive API.';
    } finally {
      if (gen == _sessionGeneration) {
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> backup(BookmarkLibrary library) async {
    if (_isBusy ||
        _user == null ||
        _driveAuthStatus != DriveAuthorizationStatus.granted) {
      return false;
    }

    if (library.state.links.isEmpty) {
      _errorMessage = 'Nenhum link disponível para backup.';
      notifyListeners();
      return false;
    }

    _isBusy = true;
    _isBackingUp = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    final gen = _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: false,
      );
      if (gen != _sessionGeneration) return false;

      if (token == null || token.isEmpty) {
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        _errorMessage = 'Sessão do Drive expirada. Autorize o Drive novamente.';
        return false;
      }

      final csv = library.exportCsv();
      final result = await driveAccessService.uploadBackup(
        accessToken: token,
        csvContent: csv,
      );

      if (gen != _sessionGeneration) return false;

      if (result.isSuccess) {
        _backupInfo = result.backupInfo;
        _statusMessage = 'Backup realizado com sucesso no Google Drive.';
        return true;
      } else {
        _errorMessage = result.message;
        if (result.status == DriveAccessStatus.unauthorized ||
            result.status == DriveAccessStatus.forbidden) {
          _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        }
        return false;
      }
    } catch (e) {
      if (gen != _sessionGeneration) return false;
      _errorMessage = 'Falha ao enviar backup para o Google Drive.';
      return false;
    } finally {
      if (gen == _sessionGeneration) {
        _isBusy = false;
        _isBackingUp = false;
        notifyListeners();
      }
    }
  }

  Future<bool> restore(BookmarkLibrary library) async {
    if (_isBusy ||
        _user == null ||
        _driveAuthStatus != DriveAuthorizationStatus.granted) {
      return false;
    }

    _isBusy = true;
    _isRestoring = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    final gen = _sessionGeneration;
    try {
      final token = await connection.getDriveAccessToken(
        requestIfNotGranted: false,
      );
      if (gen != _sessionGeneration) return false;

      if (token == null || token.isEmpty) {
        _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        _errorMessage = 'Sessão do Drive expirada. Autorize o Drive novamente.';
        return false;
      }

      final result = await driveAccessService.downloadBackup(
        accessToken: token,
      );
      if (gen != _sessionGeneration) return false;

      if (result.isSuccess && result.csvContent != null) {
        try {
          await library.importCsv(result.csvContent!);
          if (result.backupInfo != null) {
            _backupInfo = result.backupInfo;
          }
          _statusMessage = 'Backup restaurado com sucesso!';
          return true;
        } on FormatException {
          _errorMessage =
              'Arquivo de backup no Google Drive possui formato inválido.';
          return false;
        }
      } else {
        _errorMessage = result.message;
        if (result.status == DriveAccessStatus.unauthorized ||
            result.status == DriveAccessStatus.forbidden) {
          _driveAuthStatus = DriveAuthorizationStatus.notGranted;
        }
        return false;
      }
    } catch (e) {
      if (gen != _sessionGeneration) return false;
      _errorMessage = 'Falha ao restaurar backup do Google Drive.';
      return false;
    } finally {
      if (gen == _sessionGeneration) {
        _isBusy = false;
        _isRestoring = false;
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    _sessionGeneration++;
    notifyListeners();

    try {
      await connection.signOut();
      _user = null;
      _backupInfo = null;
      _authStatus = AuthStatus.disconnected;
      _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      _verificationStatus = DriveVerificationStatus.idle;
      _statusMessage = 'Sessão encerrada com sucesso.';
    } catch (e) {
      _errorMessage = 'Falha ao desconectar conta Google.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    _sessionGeneration++;
    notifyListeners();

    try {
      await connection.disconnect();
      _user = null;
      _backupInfo = null;
      _authStatus = AuthStatus.disconnected;
      _driveAuthStatus = DriveAuthorizationStatus.notGranted;
      _verificationStatus = DriveVerificationStatus.idle;
      _statusMessage = 'Acesso do aplicativo à conta Google revogado.';
    } catch (e) {
      _errorMessage = 'Falha ao revogar acesso da conta Google.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
