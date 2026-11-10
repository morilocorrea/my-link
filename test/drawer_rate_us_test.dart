import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/l10n/app_localizations.dart';
import 'package:mylink/screens/library_screen.dart';
import 'package:mylink/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
    Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncher,
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
          urlLauncher: urlLauncher,
        ),
      ),
    );
  }

  group('Drawer "Avalie-nos" menu tests', () {
    test('LibraryScreen.playStoreUrl obeys normalization rules', () {
      expect(
        LibraryScreen.playStoreUrl,
        'https://play.google.com/store/apps/details?id=com.siscorr.mylink',
      );
      final normalized = normalizeUrl(LibraryScreen.playStoreUrl);
      expect(
        normalized,
        'https://play.google.com/store/apps/details?id=com.siscorr.mylink',
      );
    });

    testWidgets(
      'renders "Avalie-nos" directly below "Configurações" in pt_BR',
      (tester) async {
        await tester.pumpWidget(buildSubject(locale: const Locale('pt', 'BR')));
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final settingsFinder = find.text('Configurações');
        final rateUsFinder = find.text('Avalie-nos');

        await tester.scrollUntilVisible(
          rateUsFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );

        expect(settingsFinder, findsOneWidget);
        expect(rateUsFinder, findsOneWidget);

        // Verify that rateUs tile appears below settings tile in the layout
        final settingsTop = tester.getTopLeft(settingsFinder).dy;
        final rateUsTop = tester.getTopLeft(rateUsFinder).dy;
        expect(rateUsTop, greaterThan(settingsTop));

        // Verify star icon
        expect(find.byIcon(Icons.star_rate_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'renders "Rate us" in en_US',
      (tester) async {
        await tester.pumpWidget(buildSubject(locale: const Locale('en', 'US')));
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final rateUsFinder = find.text('Rate us');
        await tester.scrollUntilVisible(
          rateUsFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );

        expect(rateUsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Avalie-nos" closes drawer and launches normalized Play Store URL',
      (tester) async {
        Uri? launchedUri;
        LaunchMode? launchedMode;

        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            urlLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
              launchedUri = uri;
              launchedMode = mode;
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final rateUsFinder = find.text('Avalie-nos');
        await tester.scrollUntilVisible(
          rateUsFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );

        await tester.tap(rateUsFinder);
        await tester.pumpAndSettle();

        // Drawer should be closed
        expect(scaffoldState.isDrawerOpen, isFalse);

        // Verify URL launched
        expect(launchedUri, isNotNull);
        expect(
          launchedUri.toString(),
          'https://play.google.com/store/apps/details?id=com.siscorr.mylink',
        );
        expect(launchedMode, LaunchMode.externalApplication);
      },
    );

    testWidgets(
      'shows openBrowserError snackbar if launchUrl fails',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            locale: const Locale('pt', 'BR'),
            urlLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
              return false;
            },
          ),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final rateUsFinder = find.text('Avalie-nos');
        await tester.scrollUntilVisible(
          rateUsFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );

        await tester.tap(rateUsFinder);
        await tester.pumpAndSettle();

        expect(find.text('Não foi possível abrir o navegador.'), findsOneWidget);
      },
    );
  });
}
