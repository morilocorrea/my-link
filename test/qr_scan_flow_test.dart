import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/l10n/app_localizations.dart';
import 'package:mylink/screens/library_screen.dart';
import 'package:mylink/screens/web_tools.dart';
import 'package:mylink/services/camera_permission_service.dart';
import 'package:mylink/theme/app_theme.dart';

import 'bookmarks_test.dart' show MemoryStorage;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late BookmarkLibrary library;

  setUp(() async {
    library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
    await library.load();
    await library.finishOnboarding();
  });

  tearDown(() => library.dispose());

  Widget buildSubject({
    Locale locale = const Locale('pt', 'BR'),
    CameraPermissionService? cameraPermissionService,
  }) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: library.state.themeMode,
        home: LibraryScreen(
          library: library,
          cameraPermissionService:
              cameraPermissionService ??
              FakeCameraPermissionService(granted: false),
        ),
      ),
    );
  }

  group('QR Scan camera permission rationale dialog flow', () {
    testWidgets(
      'tapping QR scan when permission is pending shows camera rationale dialog in pt-BR',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            cameraPermissionService: FakeCameraPermissionService(
              granted: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the QR scanner icon on AppBar
        await tester.tap(find.byTooltip('Ler QR Code'));
        await tester.pumpAndSettle();

        // Verify rationale dialog content
        expect(find.text('Acesso à Câmera'), findsOneWidget);
        expect(
          find.text(
            'Para escanear códigos QR e adicionar links automaticamente à sua biblioteca, o MyLink precisa de acesso à câmera do seu dispositivo.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // Verify dialog is closed and ScanScreen is NOT opened
        expect(find.text('Acesso à Câmera'), findsNothing);
        expect(find.byType(ScanScreen), findsNothing);
      },
    );

    testWidgets(
      'tapping QR scan when permission is pending shows English rationale dialog in en-US',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('en', 'US'),
            cameraPermissionService: FakeCameraPermissionService(
              granted: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the QR scanner icon on AppBar
        await tester.tap(find.byTooltip('Scan QR Code'));
        await tester.pumpAndSettle();

        // Verify rationale dialog content in English
        expect(find.text('Camera Access'), findsOneWidget);
        expect(
          find.text(
            'To scan QR codes and automatically add links to your library, MyLink needs access to your device camera.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is closed and ScanScreen is NOT opened
        expect(find.text('Camera Access'), findsNothing);
        expect(find.byType(ScanScreen), findsNothing);
      },
    );

    testWidgets(
      'tapping QR scan in Drawer when permission is pending shows dialog and canceling keeps on LibraryScreen',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            cameraPermissionService: FakeCameraPermissionService(
              granted: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Tap "Ler QR Code" in drawer
        await tester.tap(find.text('Ler QR Code'));
        await tester.pumpAndSettle();

        // Verify dialog appears
        expect(find.text('Acesso à Câmera'), findsOneWidget);

        // Dismiss by tapping Cancel
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('Acesso à Câmera'), findsNothing);
        expect(find.byType(ScanScreen), findsNothing);
        expect(find.byType(LibraryScreen), findsOneWidget);
      },
    );

    testWidgets('confirming with OK in dialog proceeds to ScanScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          locale: const Locale('pt', 'BR'),
          cameraPermissionService: FakeCameraPermissionService(granted: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ler QR Code'));
      await tester.pumpAndSettle();

      expect(find.text('Acesso à Câmera'), findsOneWidget);

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be gone, and ScanScreen should now be in tree
      expect(find.text('Acesso à Câmera'), findsNothing);
      expect(find.byType(ScanScreen), findsOneWidget);
    });

    testWidgets(
      'tapping QR scan when permission is ALREADY granted opens ScanScreen directly without dialog',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            cameraPermissionService: FakeCameraPermissionService(granted: true),
          ),
        );
        await tester.pumpAndSettle();

        // Tap QR scanner icon on AppBar
        await tester.tap(find.byTooltip('Ler QR Code'));
        await tester.pumpAndSettle();

        // Rationale dialog must NOT be displayed
        expect(find.text('Acesso à Câmera'), findsNothing);
        // ScanScreen must be opened immediately
        expect(find.byType(ScanScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping QR scan in Drawer when permission is ALREADY granted opens ScanScreen directly',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            cameraPermissionService: FakeCameraPermissionService(granted: true),
          ),
        );
        await tester.pumpAndSettle();

        // Open Drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Tap "Ler QR Code" in drawer
        await tester.tap(find.text('Ler QR Code'));
        await tester.pumpAndSettle();

        // Rationale dialog must NOT be displayed
        expect(find.text('Acesso à Câmera'), findsNothing);
        // ScanScreen must be opened immediately
        expect(find.byType(ScanScreen), findsOneWidget);
      },
    );
  });
}
