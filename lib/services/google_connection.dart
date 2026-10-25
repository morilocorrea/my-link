import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_oauth_config.dart';

@immutable
class GoogleUser {
  const GoogleUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);

  @override
  String toString() => 'GoogleUser(id: $id, email: $email, name: $displayName)';
}

abstract interface class GoogleConnection {
  Future<void> initialize();
  Stream<GoogleUser?> get userStream;
  GoogleUser? get currentUser;
  bool get isConfigured;
  Future<GoogleUser?> signIn();
  Future<void> signOut();
  Future<void> disconnect();
  Future<String?> getDriveAccessToken({bool requestIfNotGranted = false});
  void dispose();
}

class DefaultGoogleConnection implements GoogleConnection {
  DefaultGoogleConnection({required this.config, GoogleSignIn? signInInstance})
    : _signIn = signInInstance ?? GoogleSignIn.instance;

  final GoogleOAuthConfig config;
  final GoogleSignIn _signIn;

  static const String driveFileScope =
      'https://www.googleapis.com/auth/drive.file';

  final _userController = StreamController<GoogleUser?>.broadcast();
  GoogleUser? _currentUser;
  GoogleSignInAccount? _currentAccount;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventSubscription;
  bool _initialized = false;

  @override
  bool get isConfigured => config.hasServerClientId;

  @override
  GoogleUser? get currentUser => _currentUser;

  @override
  Stream<GoogleUser?> get userStream => _userController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final serverClientId = config.hasServerClientId
          ? config.serverClientId
          : null;
      await _signIn.initialize(serverClientId: serverClientId);

      _eventSubscription = _signIn.authenticationEvents.listen(
        _onAuthenticationEvent,
        onError: (Object error) {
          if (kDebugMode) {
            debugPrint('Google connection event error: $error');
          }
        },
      );

      await _signIn.attemptLightweightAuthentication();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google connection initialization error: $e');
      }
    }
  }

  void _onAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        _currentAccount = user;
        _currentUser = _mapUser(user);
        _userController.add(_currentUser);
      case GoogleSignInAuthenticationEventSignOut():
        _currentAccount = null;
        _currentUser = null;
        _userController.add(null);
    }
  }

  GoogleUser _mapUser(GoogleSignInAccount account) => GoogleUser(
    id: account.id,
    email: account.email,
    displayName: account.displayName,
    photoUrl: account.photoUrl,
  );

  @override
  Future<GoogleUser?> signIn() async {
    try {
      if (!isConfigured) {
        throw StateError(
          'Configuração ausente: defina GOOGLE_SERVER_CLIENT_ID no arquivo .env.',
        );
      }
      final account = await _signIn.authenticate();
      _currentAccount = account;
      _currentUser = _mapUser(account);
      _userController.add(_currentUser);
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google sign-in error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _signIn.signOut();
      _currentAccount = null;
      _currentUser = null;
      _userController.add(null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google sign-out error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _signIn.disconnect();
      _currentAccount = null;
      _currentUser = null;
      _userController.add(null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google disconnect error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<String?> getDriveAccessToken({
    bool requestIfNotGranted = false,
  }) async {
    final account = _currentAccount;
    if (account == null) return null;

    final authClient = account.authorizationClient;
    final scopes = [config.driveScope];

    try {
      final existingAuth = await authClient.authorizationForScopes(scopes);
      if (existingAuth != null) {
        return existingAuth.accessToken;
      }

      if (requestIfNotGranted) {
        final newAuth = await authClient.authorizeScopes(scopes);
        return newAuth.accessToken;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Drive access token error: $e');
      }
      rethrow;
    }

    return null;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _userController.close();
  }
}
