import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/controllers/google_drive_controller.dart';
import 'package:mylink/main.dart';
import 'package:mylink/screens/google_drive_screen.dart';
import 'package:mylink/services/drive_access_service.dart';
import 'package:mylink/services/google_connection.dart';

import 'bookmarks_test.dart' show MemoryStorage;
import 'google_connection_test.dart'
    show FakeDriveAccessService, FakeGoogleConnection;

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  final platform = TargetPlatformVariant.only(TargetPlatform.linux);

  group('GoogleDriveScreen widgets', () {
    testWidgets(
      'renders warning card when OAuth is not configured and disables button',
      (tester) async {
        final connection = FakeGoogleConnection(configured: false);
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );
        addTearDown(() {
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Configuração OAuth Ausente'), findsOneWidget);
        expect(find.text('Conectar Conta Google'), findsOneWidget);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Conectar Conta Google'),
        );
        expect(button.onPressed, isNull);
      },
      variant: platform,
    );

    testWidgets(
      'disconnected view shows connect button and clicking signs in',
      (tester) async {
        final connection = FakeGoogleConnection(configured: true);
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );
        addTearDown(() {
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Conectar ao Google Drive'), findsOneWidget);
        expect(find.text('Configuração OAuth Ausente'), findsNothing);

        await tester.tap(find.text('Conectar Conta Google'));
        await tester.pumpAndSettle();

        expect(find.text('user@example.com'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('Drive Não Autorizado'), findsOneWidget);
        expect(find.text('Autorizar Drive'), findsOneWidget);
      },
      variant: platform,
    );

    testWidgets(
      'authorizing Drive updates status to Drive Autorizado and shows verify button',
      (tester) async {
        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(
            id: '1',
            email: 'user@example.com',
            displayName: 'Test User',
          ),
          tokenToReturn: 'valid-drive-token',
        );
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );
        addTearDown(() {
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('user@example.com'), findsOneWidget);
        expect(find.text('Drive Autorizado'), findsOneWidget);
        expect(find.text('Verificar Acesso à API'), findsOneWidget);

        await tester.tap(find.text('Verificar Acesso à API'));
        await tester.pumpAndSettle();

        expect(find.text('Verificado'), findsOneWidget);
      },
      variant: platform,
    );

    testWidgets(
      'error banner appears on failure and close button dismisses it',
      (tester) async {
        final connection = FakeGoogleConnection(configured: true);
        connection.throwOnSignIn = true;
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );
        addTearDown(() {
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Conectar Conta Google'));
        await tester.pumpAndSettle();

        expect(
          find.text('Conexão cancelada ou não concluída.'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Fechar mensagem'));
        await tester.pumpAndSettle();

        expect(find.text('Conexão cancelada ou não concluída.'), findsNothing);
      },
      variant: platform,
    );

    testWidgets(
      'signing out with confirmation dialog disconnects the account',
      (tester) async {
        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(id: '1', email: 'test@example.com'),
        );
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );
        addTearDown(() {
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('test@example.com'), findsOneWidget);

        // Tap Encerrar sessão
        await tester.tap(find.text('Encerrar sessão'));
        await tester.pumpAndSettle();

        expect(find.text('Encerrar sessão?'), findsOneWidget);

        // Cancel first
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('test@example.com'), findsOneWidget);

        // Tap again and confirm
        await tester.tap(find.text('Encerrar sessão'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(find.text('Conectar ao Google Drive'), findsOneWidget);
        expect(find.text('Sessão encerrada com sucesso.'), findsOneWidget);
      },
      variant: platform,
    );

    testWidgets('drawer in LibraryScreen navigates to GoogleDriveScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      await library.finishOnboarding();

      final connection = FakeGoogleConnection(configured: true);
      final driveService = FakeDriveAccessService();
      final controller = GoogleDriveController(
        connection: connection,
        driveAccessService: driveService,
      );

      addTearDown(() {
        library.dispose();
        controller.dispose();
        connection.dispose();
      });

      await tester.pumpWidget(
        MyLinkApp(library: library, googleDriveController: controller),
      );
      await tester.pumpAndSettle();

      // Open Drawer
      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final driveItem = find.text('Google Drive');
      expect(driveItem, findsOneWidget);
      await tester.tap(driveItem);
      await tester.pumpAndSettle();

      expect(find.byType(GoogleDriveScreen), findsOneWidget);
      expect(find.text('Conectar ao Google Drive'), findsOneWidget);
    }, variant: platform);

    testWidgets(
      'renders backup card and buttons when Drive is authorized',
      (tester) async {
        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();

        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(
            id: '1',
            email: 'user@example.com',
            displayName: 'Test User',
          ),
          tokenToReturn: 'valid-drive-token',
        );
        final driveService = FakeDriveAccessService();
        driveService.fakeBackupInfo = DriveBackupInfo(
          fileId: 'backup-123',
          name: 'mylink_backup.csv',
          modifiedTime: DateTime(2026, 10, 25, 14, 30),
          sizeBytes: 2048,
        );

        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );

        addTearDown(() {
          library.dispose();
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller, library: library)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Backup no Google Drive'), findsOneWidget);
        expect(find.text('Fazer Backup Agora'), findsOneWidget);
        expect(find.text('Restaurar Backup'), findsOneWidget);
        expect(find.text('Backup disponível na nuvem'), findsOneWidget);
        expect(find.textContaining('25/10/2026 às 14:30'), findsOneWidget);
        expect(find.textContaining('2.0 KB'), findsOneWidget);
      },
      variant: platform,
    );

    testWidgets(
      'clicking Fazer Backup Agora with empty library shows warning',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();

        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(
            id: '1',
            email: 'user@example.com',
            displayName: 'Test User',
          ),
          tokenToReturn: 'valid-drive-token',
        );
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );

        addTearDown(() {
          library.dispose();
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller, library: library)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Fazer Backup Agora'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nenhum link disponível para backup.'),
          findsOneWidget,
        );
      },
      variant: platform,
    );

    testWidgets(
      'clicking Fazer Backup Agora uploads links and updates card',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();
        await library.save(
          url: 'https://dart.dev',
          title: 'Dart',
          category: 'Technology',
        );

        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(
            id: '1',
            email: 'user@example.com',
            displayName: 'Test User',
          ),
          tokenToReturn: 'valid-drive-token',
        );
        final driveService = FakeDriveAccessService();
        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );

        addTearDown(() {
          library.dispose();
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller, library: library)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Fazer Backup Agora'));
        await tester.pumpAndSettle();

        expect(driveService.uploadCount, 1);
        expect(
          find.text('Backup realizado com sucesso no Google Drive.'),
          findsOneWidget,
        );
      },
      variant: platform,
    );

    testWidgets(
      'clicking Restaurar Backup prompts confirmation and restores',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
        await library.load();

        final connection = FakeGoogleConnection(
          configured: true,
          initialUser: const GoogleUser(
            id: '1',
            email: 'user@example.com',
            displayName: 'Test User',
          ),
          tokenToReturn: 'valid-drive-token',
        );
        final driveService = FakeDriveAccessService();
        driveService.fakeRemoteCsv =
            'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n'
            'Google,https://google.com,Technology,0,,FALSE\n';

        final controller = GoogleDriveController(
          connection: connection,
          driveAccessService: driveService,
        );

        addTearDown(() {
          library.dispose();
          controller.dispose();
          connection.dispose();
        });

        await tester.pumpWidget(
          _wrap(GoogleDriveScreen(controller: controller, library: library)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restaurar Backup'));
        await tester.pumpAndSettle();

        expect(find.text('Restaurar Backup?'), findsOneWidget);

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(driveService.downloadCount, 1);
        expect(library.state.links.length, 1);
        expect(library.state.links.first.title, 'Google');
        expect(find.text('Backup restaurado com sucesso!'), findsOneWidget);
      },
      variant: platform,
    );
  });
}
