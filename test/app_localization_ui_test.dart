import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/l10n/app_localizations.dart';
import 'package:mylink/screens/about_screen.dart';
import 'package:mylink/screens/library_screen.dart';
import 'package:mylink/screens/settings_screen.dart';
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

  Widget buildSubject(Widget child, {Locale locale = const Locale('pt', 'BR')}) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: library.state.themeMode,
        home: child,
      ),
    );
  }

  group('UI Localization verification (pt_BR and en_US)', () {
    testWidgets('SettingsScreen in pt_BR displays Portuguese strings', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          SettingsScreen(library: library),
          locale: const Locale('pt', 'BR'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('APARÊNCIA'), findsOneWidget);
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
      expect(find.text('Sistema'), findsWidgets);
      expect(find.text('INFORMAÇÕES'), findsOneWidget);
      expect(find.text('Sobre o Aplicativo'), findsOneWidget);
      expect(find.text('Seus links, sempre à mão'), findsOneWidget);
    });

    testWidgets('SettingsScreen in en_US displays English strings', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          SettingsScreen(library: library),
          locale: const Locale('en', 'US'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('System'), findsWidgets);
      expect(find.text('INFORMATION'), findsOneWidget);
      expect(find.text('About the App'), findsOneWidget);
      expect(find.text('Your links, always at hand'), findsOneWidget);
    });

    testWidgets('AboutScreen in pt_BR displays Portuguese details', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          const AboutScreen(),
          locale: const Locale('pt', 'BR'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('DETALHES TÉCNICOS'), findsOneWidget);
      expect(find.text('Versão'), findsOneWidget);
      expect(find.text('Desenvolvedor'), findsOneWidget);
      expect(find.text('LINKS ÚTEIS'), findsOneWidget);
      expect(find.text('Política de Privacidade'), findsOneWidget);
    });

    testWidgets('AboutScreen in en_US displays English details', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          const AboutScreen(),
          locale: const Locale('en', 'US'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('TECHNICAL DETAILS'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('USEFUL LINKS'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets(
      'LibraryScreen displays original category names in both pt_BR and en_US',
      (tester) async {
        // Test in pt_BR
        await tester.pumpWidget(
          buildSubject(
            LibraryScreen(library: library),
            locale: const Locale('pt', 'BR'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Buscar título, URL ou categoria…'), findsOneWidget);

        // Switch to Category tab
        await tester.tap(find.text('Category').last);
        await tester.pumpAndSettle();

        // Standard categories are preserved in their registered names
        expect(find.text('Audio'), findsOneWidget);
        expect(find.text('Blog'), findsOneWidget);
        expect(find.text('Video'), findsOneWidget);
        expect(find.text('Youtube'), findsOneWidget);

        // Test in en_US
        await tester.pumpWidget(
          buildSubject(
            LibraryScreen(library: library),
            locale: const Locale('en', 'US'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Search title, URL, or category…'), findsOneWidget);
        expect(find.text('Audio'), findsOneWidget);
        expect(find.text('Blog'), findsOneWidget);
        expect(find.text('Video'), findsOneWidget);
        expect(find.text('Youtube'), findsOneWidget);
      },
    );
  });
}
