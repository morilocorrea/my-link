import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mylink/services/drive_access_service.dart';

class MockTransportClient extends http.BaseClient {
  MockTransportClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}

http.StreamedResponse _jsonResponse(int statusCode, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream.value(bytes),
    statusCode,
    headers: {
      'content-type': 'application/json; charset=UTF-8',
      'content-length': bytes.length.toString(),
    },
  );
}

void main() {
  group('DefaultDriveAccessService', () {
    test(
      'empty or whitespace token returns unauthorized without HTTP call',
      () async {
        var httpCalls = 0;
        final service = DefaultDriveAccessService(
          clientFactory: () => MockTransportClient((_) async {
            httpCalls++;
            return _jsonResponse(200, {});
          }),
        );

        final resultEmpty = await service.verifyAccess(accessToken: '');
        expect(resultEmpty.status, DriveAccessStatus.unauthorized);
        expect(resultEmpty.isSuccess, isFalse);
        expect(resultEmpty.message, contains('não fornecido ou vazio'));

        final resultWhitespace = await service.verifyAccess(accessToken: '   ');
        expect(resultWhitespace.status, DriveAccessStatus.unauthorized);
        expect(httpCalls, 0);
      },
    );

    test(
      'HTTP 200 with empty files verifies authorization and sends bearer token',
      () async {
        http.BaseRequest? capturedRequest;
        final service = DefaultDriveAccessService(
          clientFactory: () => MockTransportClient((request) async {
            capturedRequest = request;
            return _jsonResponse(200, {'files': []});
          }),
        );

        final result = await service.verifyAccess(
          accessToken: 'test-token-123',
        );

        expect(result.status, DriveAccessStatus.verified);
        expect(result.isSuccess, isTrue);
        expect(result.rawStatusCode, 200);
        expect(result.message, contains('verificadas com sucesso'));

        expect(capturedRequest, isNotNull);
        expect(
          capturedRequest!.headers['Authorization'],
          'Bearer test-token-123',
        );
        final query = capturedRequest!.url.queryParameters;
        expect(query['spaces'], 'drive');
        expect(query['pageSize'], '1');
        expect(query['q'], 'trashed = false');
        expect(query['fields'], 'files(id)');
      },
    );

    test('HTTP 200 with files returns verified', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(200, {
            'files': [
              {'id': 'file-abc'},
            ],
          });
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.verified);
      expect(result.isSuccess, isTrue);
    });

    test(
      'HTTP 401 returns unauthorized status with re-auth guidance',
      () async {
        final service = DefaultDriveAccessService(
          clientFactory: () => MockTransportClient((_) async {
            return _jsonResponse(401, {
              'error': {
                'code': 401,
                'message': 'Invalid Credentials',
                'status': 'UNAUTHENTICATED',
              },
            });
          }),
        );

        final result = await service.verifyAccess(accessToken: 'expired-token');
        expect(result.status, DriveAccessStatus.unauthorized);
        expect(result.rawStatusCode, 401);
        expect(result.message, contains('Sessão expirada ou não autorizada'));
      },
    );

    test('HTTP 403 insufficientPermissions explains scope need', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(403, {
            'error': {
              'code': 403,
              'message': 'The user has not granted scope drive.file',
              'errors': [
                {'reason': 'insufficientPermissions'},
              ],
            },
          });
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.forbidden);
      expect(result.rawStatusCode, 403);
      expect(result.reason, 'insufficientPermissions');
      expect(result.message, contains('drive.file'));
    });

    test(
      'HTTP 403 accessNotConfigured explains API disabled in Console',
      () async {
        final service = DefaultDriveAccessService(
          clientFactory: () => MockTransportClient((_) async {
            return _jsonResponse(403, {
              'error': {
                'code': 403,
                'message': 'Google Drive API has not been used in project',
                'errors': [
                  {'reason': 'accessNotConfigured'},
                ],
              },
            });
          }),
        );

        final result = await service.verifyAccess(accessToken: 'token');
        expect(result.status, DriveAccessStatus.forbidden);
        expect(result.message, contains('não está habilitada'));
      },
    );

    test('HTTP 403 quotaExceeded explains rate/quota limit', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(403, {
            'error': {
              'code': 403,
              'message': 'User rate limit exceeded',
              'errors': [
                {'reason': 'userRateLimitExceeded'},
              ],
            },
          });
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.forbidden);
      expect(result.message, contains('quota'));
    });

    test('HTTP 404 returns notFound status', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(404, {
            'error': {'code': 404, 'message': 'Not Found'},
          });
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.notFound);
      expect(result.rawStatusCode, 404);
      expect(result.message, contains('HTTP 404'));
    });

    test(
      'HTTP 429 retries once and returns rateLimited if exhausted',
      () async {
        var callCount = 0;
        final service = DefaultDriveAccessService(
          retryDelay: Duration.zero,
          clientFactory: () => MockTransportClient((_) async {
            callCount++;
            return _jsonResponse(429, {
              'error': {'code': 429, 'message': 'Too Many Requests'},
            });
          }),
        );

        final result = await service.verifyAccess(accessToken: 'token');
        expect(result.status, DriveAccessStatus.rateLimited);
        expect(result.rawStatusCode, 429);
        expect(callCount, 2); // Initial + 1 retry
      },
    );

    test(
      'HTTP 500 recovers on retry when second attempt returns 200',
      () async {
        var callCount = 0;
        final service = DefaultDriveAccessService(
          retryDelay: Duration.zero,
          clientFactory: () => MockTransportClient((_) async {
            callCount++;
            if (callCount == 1) {
              return _jsonResponse(500, {
                'error': {'code': 500, 'message': 'Internal Server Error'},
              });
            }
            return _jsonResponse(200, {'files': []});
          }),
        );

        final result = await service.verifyAccess(accessToken: 'token');
        expect(result.status, DriveAccessStatus.verified);
        expect(result.isSuccess, isTrue);
        expect(callCount, 2);
      },
    );

    test('HTTP 503 returns serverError when retries fail', () async {
      var callCount = 0;
      final service = DefaultDriveAccessService(
        retryDelay: Duration.zero,
        clientFactory: () => MockTransportClient((_) async {
          callCount++;
          return _jsonResponse(503, {
            'error': {'code': 503, 'message': 'Service Unavailable'},
          });
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.serverError);
      expect(result.rawStatusCode, 503);
      expect(callCount, 2);
    });

    test('TimeoutException returns timedOut status', () async {
      final service = DefaultDriveAccessService(
        requestTimeout: const Duration(milliseconds: 10),
        clientFactory: () => MockTransportClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _jsonResponse(200, {});
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.timedOut);
      expect(result.message, contains('Tempo limite esgotado'));
    });

    test('SocketException returns networkError status', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          throw const SocketException('Failed host lookup');
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.networkError);
      expect(result.message, contains('Falha de rede'));
    });

    test('ClientException returns networkError status', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          throw http.ClientException(
            'Connection closed before full header was received',
          );
        }),
      );

      final result = await service.verifyAccess(accessToken: 'token');
      expect(result.status, DriveAccessStatus.networkError);
      expect(result.message, contains('Erro de comunicação HTTP'));
    });

    test('getBackupInfo returns empty when no backup file exists', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(200, {'files': []});
        }),
      );

      final result = await service.getBackupInfo(accessToken: 'token');
      expect(result.status, DriveAccessStatus.verified);
      expect(result.backupInfo, isNull);
      expect(result.message, contains('Nenhum backup encontrado'));
    });

    test('getBackupInfo returns DriveBackupInfo when file exists', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(200, {
            'files': [
              {
                'id': 'file-123',
                'name': 'mylink_backup.csv',
                'modifiedTime': '2026-10-25T14:30:00.000Z',
                'size': '4096',
              },
            ],
          });
        }),
      );

      final result = await service.getBackupInfo(accessToken: 'token');
      expect(result.status, DriveAccessStatus.verified);
      expect(result.backupInfo, isNotNull);
      expect(result.backupInfo!.fileId, 'file-123');
      expect(result.backupInfo!.name, 'mylink_backup.csv');
      expect(result.backupInfo!.sizeBytes, 4096);
      expect(result.backupInfo!.modifiedTime, isNotNull);
    });

    test('uploadBackup creates new file when no prior backup exists', () async {
      var callIndex = 0;
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((request) async {
          callIndex++;
          if (callIndex == 1) {
            // First call: list files -> empty
            return _jsonResponse(200, {'files': []});
          } else {
            // Second call: create file
            return _jsonResponse(200, {
              'id': 'created-file-id',
              'name': 'mylink_backup.csv',
              'modifiedTime': '2026-10-25T15:00:00.000Z',
              'size': '128',
            });
          }
        }),
      );

      final result = await service.uploadBackup(
        accessToken: 'token',
        csvContent:
            'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n',
      );

      expect(result.status, DriveAccessStatus.verified);
      expect(result.backupInfo, isNotNull);
      expect(result.backupInfo!.fileId, 'created-file-id');
      expect(callIndex, 2);
    });

    test('uploadBackup updates file when backup already exists', () async {
      var callIndex = 0;
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((request) async {
          callIndex++;
          if (callIndex == 1) {
            // First call: list files -> found existing
            return _jsonResponse(200, {
              'files': [
                {'id': 'existing-file-id'},
              ],
            });
          } else {
            // Second call: update file
            return _jsonResponse(200, {
              'id': 'existing-file-id',
              'name': 'mylink_backup.csv',
              'modifiedTime': '2026-10-25T16:00:00.000Z',
              'size': '256',
            });
          }
        }),
      );

      final result = await service.uploadBackup(
        accessToken: 'token',
        csvContent:
            'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n',
      );

      expect(result.status, DriveAccessStatus.verified);
      expect(result.backupInfo, isNotNull);
      expect(result.backupInfo!.fileId, 'existing-file-id');
      expect(callIndex, 2);
    });

    test('downloadBackup returns notFound when no backup exists', () async {
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((_) async {
          return _jsonResponse(200, {'files': []});
        }),
      );

      final result = await service.downloadBackup(accessToken: 'token');
      expect(result.status, DriveAccessStatus.notFound);
      expect(result.csvContent, isNull);
    });

    test('downloadBackup downloads CSV content when file exists', () async {
      var callIndex = 0;
      const fakeCsv =
          'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\nTest,https://test.com,News,0,,TRUE\n';
      final service = DefaultDriveAccessService(
        clientFactory: () => MockTransportClient((request) async {
          callIndex++;
          if (callIndex == 1) {
            // List files -> found
            return _jsonResponse(200, {
              'files': [
                {
                  'id': 'file-to-download',
                  'name': 'mylink_backup.csv',
                  'modifiedTime': '2026-10-25T14:00:00.000Z',
                  'size': fakeCsv.length.toString(),
                },
              ],
            });
          } else {
            // Get file media
            final bytes = utf8.encode(fakeCsv);
            return http.StreamedResponse(
              Stream.value(bytes),
              200,
              headers: {
                'content-type': 'text/csv; charset=UTF-8',
                'content-length': bytes.length.toString(),
              },
            );
          }
        }),
      );

      final result = await service.downloadBackup(accessToken: 'token');
      expect(result.status, DriveAccessStatus.verified);
      expect(result.csvContent, fakeCsv);
      expect(result.backupInfo, isNotNull);
      expect(result.backupInfo!.fileId, 'file-to-download');
      expect(callIndex, 2);
    });
  });
}
