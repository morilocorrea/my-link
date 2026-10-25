import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const String kBackupFileName = 'mylink_backup.csv';

enum DriveAccessStatus {
  verified,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  networkError,
  timedOut,
  unknownError,
}

@immutable
class DriveAccessResult {
  const DriveAccessResult({
    required this.status,
    required this.message,
    this.rawStatusCode,
    this.reason,
  });

  final DriveAccessStatus status;
  final String message;
  final int? rawStatusCode;
  final String? reason;

  bool get isSuccess => status == DriveAccessStatus.verified;

  @override
  String toString() =>
      'DriveAccessResult(status: $status, code: $rawStatusCode, reason: $reason, message: $message)';
}

@immutable
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.fileId,
    required this.name,
    this.modifiedTime,
    this.sizeBytes,
  });

  final String fileId;
  final String name;
  final DateTime? modifiedTime;
  final int? sizeBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriveBackupInfo &&
          runtimeType == other.runtimeType &&
          fileId == other.fileId &&
          name == other.name &&
          modifiedTime == other.modifiedTime &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(fileId, name, modifiedTime, sizeBytes);

  @override
  String toString() =>
      'DriveBackupInfo(id: $fileId, name: $name, modifiedTime: $modifiedTime, size: $sizeBytes)';
}

@immutable
class DriveBackupInfoResult {
  const DriveBackupInfoResult({
    required this.status,
    required this.message,
    this.backupInfo,
    this.rawStatusCode,
    this.reason,
  });

  final DriveAccessStatus status;
  final String message;
  final DriveBackupInfo? backupInfo;
  final int? rawStatusCode;
  final String? reason;

  bool get isSuccess => status == DriveAccessStatus.verified;
}

@immutable
class DriveOperationResult {
  const DriveOperationResult({
    required this.status,
    required this.message,
    this.backupInfo,
    this.rawStatusCode,
    this.reason,
  });

  final DriveAccessStatus status;
  final String message;
  final DriveBackupInfo? backupInfo;
  final int? rawStatusCode;
  final String? reason;

  bool get isSuccess => status == DriveAccessStatus.verified;
}

@immutable
class DriveDownloadResult {
  const DriveDownloadResult({
    required this.status,
    required this.message,
    this.csvContent,
    this.backupInfo,
    this.modifiedTime,
    this.rawStatusCode,
    this.reason,
  });

  final DriveAccessStatus status;
  final String message;
  final String? csvContent;
  final DriveBackupInfo? backupInfo;
  final DateTime? modifiedTime;
  final int? rawStatusCode;
  final String? reason;

  bool get isSuccess =>
      status == DriveAccessStatus.verified && csvContent != null;
}

abstract interface class DriveAccessService {
  Future<DriveAccessResult> verifyAccess({required String accessToken});
  Future<DriveBackupInfoResult> getBackupInfo({required String accessToken});
  Future<DriveOperationResult> uploadBackup({
    required String accessToken,
    required String csvContent,
  });
  Future<DriveDownloadResult> downloadBackup({required String accessToken});
}

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient(this._token, this._inner);
  final String _token;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class DefaultDriveAccessService implements DriveAccessService {
  DefaultDriveAccessService({
    http.Client Function()? clientFactory,
    this.requestTimeout = const Duration(seconds: 15),
    this.retryDelay = const Duration(seconds: 1),
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;
  final Duration requestTimeout;
  final Duration retryDelay;

  Future<T> _executeApi<T>({
    required String token,
    required Future<T> Function(drive.DriveApi driveApi) action,
    required T Function(DriveAccessResult mappedError) onMappedError,
    required T Function(
      DriveAccessStatus status,
      String message, {
      String? reason,
    })
    onError,
    int retriesLeft = 1,
  }) async {
    if (token.trim().isEmpty) {
      return onError(
        DriveAccessStatus.unauthorized,
        'Token de acesso não fornecido ou vazio.',
      );
    }

    final baseClient = _clientFactory();
    final authClient = AuthenticatedHttpClient(token, baseClient);

    try {
      final driveApi = drive.DriveApi(authClient);
      return await action(driveApi).timeout(requestTimeout);
    } on drive.DetailedApiRequestError catch (e) {
      final statusCode = e.status ?? 0;
      final reason = e.errors.isNotEmpty ? e.errors.first.reason : null;

      if ((statusCode == 429 || statusCode >= 500) && retriesLeft > 0) {
        if (kDebugMode) {
          debugPrint('Drive API error $statusCode, retrying once...');
        }
        await Future<void>.delayed(retryDelay);
        return _executeApi(
          token: token,
          action: action,
          onMappedError: onMappedError,
          onError: onError,
          retriesLeft: retriesLeft - 1,
        );
      }

      return onMappedError(_mapApiError(statusCode, reason, e.message));
    } on TimeoutException {
      return onError(
        DriveAccessStatus.timedOut,
        'Tempo limite esgotado ao consultar a Drive API. Verifique sua conexão.',
      );
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Drive API socket error: ${e.osError?.message ?? e.message}',
        );
      }
      return onError(
        DriveAccessStatus.networkError,
        'Falha de rede ao consultar o Google Drive. Verifique sua conexão.',
      );
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Drive API client error: ${e.message}');
      }
      return onError(
        DriveAccessStatus.networkError,
        'Erro de comunicação HTTP ao consultar o Google Drive. Verifique sua conexão.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Drive API unexpected error: $e');
      }
      return onError(
        DriveAccessStatus.unknownError,
        'Não foi possível verificar a Drive API. Tente novamente.',
        reason: e.runtimeType.toString(),
      );
    } finally {
      authClient.close();
    }
  }

  @override
  Future<DriveAccessResult> verifyAccess({required String accessToken}) =>
      _executeApi(
        token: accessToken,
        action: (driveApi) async {
          await driveApi.files.list(
            spaces: 'drive',
            pageSize: 1,
            q: 'trashed = false',
            $fields: 'files(id)',
          );

          return const DriveAccessResult(
            status: DriveAccessStatus.verified,
            rawStatusCode: 200,
            message:
                'Conexão e autorização da Drive API verificadas com sucesso.',
          );
        },
        onMappedError: (m) => m,
        onError: (s, msg, {reason}) =>
            DriveAccessResult(status: s, message: msg, reason: reason),
      );

  @override
  Future<DriveBackupInfoResult> getBackupInfo({required String accessToken}) =>
      _executeApi(
        token: accessToken,
        action: (driveApi) async {
          final list = await driveApi.files.list(
            spaces: 'drive',
            pageSize: 1,
            q: "name = '$kBackupFileName' and trashed = false",
            $fields: 'files(id, name, modifiedTime, size)',
          );

          final files = list.files;
          if (files == null || files.isEmpty) {
            return const DriveBackupInfoResult(
              status: DriveAccessStatus.verified,
              rawStatusCode: 200,
              message: 'Nenhum backup encontrado no Google Drive.',
            );
          }

          final f = files.first;
          final info = DriveBackupInfo(
            fileId: f.id ?? '',
            name: f.name ?? kBackupFileName,
            modifiedTime: f.modifiedTime,
            sizeBytes: int.tryParse(f.size ?? ''),
          );

          return DriveBackupInfoResult(
            status: DriveAccessStatus.verified,
            rawStatusCode: 200,
            message: 'Backup encontrado no Google Drive.',
            backupInfo: info,
          );
        },
        onMappedError: (m) => DriveBackupInfoResult(
          status: m.status,
          message: m.message,
          rawStatusCode: m.rawStatusCode,
          reason: m.reason,
        ),
        onError: (s, msg, {reason}) =>
            DriveBackupInfoResult(status: s, message: msg, reason: reason),
      );

  @override
  Future<DriveOperationResult> uploadBackup({
    required String accessToken,
    required String csvContent,
  }) => _executeApi(
    token: accessToken,
    action: (driveApi) async {
      final bytes = utf8.encode(csvContent);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'text/csv',
      );

      final list = await driveApi.files.list(
        spaces: 'drive',
        pageSize: 1,
        q: "name = '$kBackupFileName' and trashed = false",
        $fields: 'files(id)',
      );

      final files = list.files;
      drive.File resultFile;

      if (files != null && files.isNotEmpty && files.first.id != null) {
        resultFile = await driveApi.files.update(
          drive.File(),
          files.first.id!,
          uploadMedia: media,
          $fields: 'id, name, modifiedTime, size',
        );
      } else {
        resultFile = await driveApi.files.create(
          drive.File(
            name: kBackupFileName,
            description: 'Backup de links do MyLink',
          ),
          uploadMedia: media,
          $fields: 'id, name, modifiedTime, size',
        );
      }

      final info = DriveBackupInfo(
        fileId: resultFile.id ?? '',
        name: resultFile.name ?? kBackupFileName,
        modifiedTime: resultFile.modifiedTime,
        sizeBytes: int.tryParse(resultFile.size ?? '') ?? bytes.length,
      );

      return DriveOperationResult(
        status: DriveAccessStatus.verified,
        rawStatusCode: 200,
        message: 'Backup enviado com sucesso para o Google Drive.',
        backupInfo: info,
      );
    },
    onMappedError: (m) => DriveOperationResult(
      status: m.status,
      message: m.message,
      rawStatusCode: m.rawStatusCode,
      reason: m.reason,
    ),
    onError: (s, msg, {reason}) =>
        DriveOperationResult(status: s, message: msg, reason: reason),
  );

  @override
  Future<DriveDownloadResult> downloadBackup({required String accessToken}) =>
      _executeApi(
        token: accessToken,
        action: (driveApi) async {
          final list = await driveApi.files.list(
            spaces: 'drive',
            pageSize: 1,
            q: "name = '$kBackupFileName' and trashed = false",
            $fields: 'files(id, name, modifiedTime, size)',
          );

          final files = list.files;
          if (files == null || files.isEmpty || files.first.id == null) {
            return const DriveDownloadResult(
              status: DriveAccessStatus.notFound,
              rawStatusCode: 404,
              message: 'Nenhum backup encontrado no Google Drive.',
            );
          }

          final f = files.first;
          final res = await driveApi.files.get(
            f.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          );

          if (res is! drive.Media) {
            return const DriveDownloadResult(
              status: DriveAccessStatus.unknownError,
              message: 'Falha ao baixar conteúdo do arquivo de backup.',
            );
          }

          final content = await utf8.decodeStream(res.stream);
          final info = DriveBackupInfo(
            fileId: f.id ?? '',
            name: f.name ?? kBackupFileName,
            modifiedTime: f.modifiedTime,
            sizeBytes: int.tryParse(f.size ?? ''),
          );

          return DriveDownloadResult(
            status: DriveAccessStatus.verified,
            rawStatusCode: 200,
            message: 'Backup baixado com sucesso.',
            csvContent: content,
            backupInfo: info,
            modifiedTime: f.modifiedTime,
          );
        },
        onMappedError: (m) => DriveDownloadResult(
          status: m.status,
          message: m.message,
          rawStatusCode: m.rawStatusCode,
          reason: m.reason,
        ),
        onError: (s, msg, {reason}) =>
            DriveDownloadResult(status: s, message: msg, reason: reason),
      );

  DriveAccessResult _mapApiError(
    int statusCode,
    String? reason,
    String? apiMessage,
  ) {
    switch (statusCode) {
      case 401:
        return const DriveAccessResult(
          status: DriveAccessStatus.unauthorized,
          rawStatusCode: 401,
          message:
              'Sessão expirada ou não autorizada. Conecte-se novamente ou autorize o acesso.',
        );
      case 403:
        String message;
        if (reason == 'insufficientPermissions' ||
            reason == 'insufficientFilePermissions') {
          message =
              'Permissão insuficiente no Google Drive. Conceda autorização para o escopo drive.file.';
        } else if (reason == 'accessNotConfigured' ||
            reason == 'apiNotActivated' ||
            (apiMessage?.toLowerCase().contains('api has not been used') ??
                false)) {
          message =
              'A Google Drive API não está habilitada no projeto Google Cloud.';
        } else if (reason == 'rateLimitExceeded' ||
            reason == 'userRateLimitExceeded' ||
            reason == 'quotaExceeded') {
          message =
              'Limite de quota ou taxa da Drive API atingido. Aguarde alguns instantes.';
        } else {
          message =
              'Acesso ao Google Drive recusado (HTTP 403). Verifique restrições da conta ou do projeto.';
        }
        return DriveAccessResult(
          status: DriveAccessStatus.forbidden,
          rawStatusCode: 403,
          reason: reason,
          message: message,
        );
      case 404:
        return const DriveAccessResult(
          status: DriveAccessStatus.notFound,
          rawStatusCode: 404,
          message: 'Recurso da Drive API não encontrado (HTTP 404).',
        );
      case 429:
        return const DriveAccessResult(
          status: DriveAccessStatus.rateLimited,
          rawStatusCode: 429,
          message:
              'Muitas requisições em curto intervalo. Aguarde alguns instantes.',
        );
      default:
        if (statusCode >= 500 && statusCode < 600) {
          return DriveAccessResult(
            status: DriveAccessStatus.serverError,
            rawStatusCode: statusCode,
            message:
                'Serviço do Google Drive temporariamente indisponível (HTTP $statusCode).',
          );
        }
        return DriveAccessResult(
          status: DriveAccessStatus.unknownError,
          rawStatusCode: statusCode,
          reason: reason,
          message:
              'Resposta inesperada da Drive API (HTTP $statusCode). Tente novamente.',
        );
    }
  }
}
