import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/screens/about_screen.dart';
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

  Widget buildSubject({ThemeMode? themeMode}) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: library.state.themeMode,
        home: SettingsScreen(library: library),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all sections and titles correctly', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('APARÊNCIA'), findsOneWidget);
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
      expect(find.text('INFORMAÇÕES'), findsOneWidget);
      expect(find.text('Sobre o Aplicativo'), findsOneWidget);
      expect(find.text('Versão, desenvolvedor e links úteis.'), findsOneWidget);
      expect(find.text('MyLink'), findsOneWidget);
      expect(find.text('Seus links, sempre à mão'), findsOneWidget);
    });

    testWidgets(
      'shows dropdown with theme options and updates theme on selection',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Initial theme is system
        expect(library.state.themeMode, ThemeMode.system);
        expect(find.text('Padrão do Sistema'), findsWidgets);

        // Open dropdown
        await tester.tap(find.byKey(const Key('theme_mode_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('Escuro'), findsOneWidget);

        // Tap on 'Escuro'
        await tester.tap(find.text('Escuro'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();

        // Theme mode should now be dark
        expect(library.state.themeMode, ThemeMode.dark);
        expect(library.state.dark, isTrue);

        // Open dropdown again and tap 'Claro'
        await tester.tap(find.byKey(const Key('theme_mode_dropdown')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Claro'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();

        expect(library.state.themeMode, ThemeMode.light);
        expect(library.state.dark, isFalse);
      },
    );

    testWidgets('tapping Sobre o Aplicativo navigates to AboutScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final aboutTileFinder = find.text('Sobre o Aplicativo');
      expect(aboutTileFinder, findsOneWidget);
      await tester.tap(aboutTileFinder);
      await tester.pumpAndSettle();

      // Should now be on AboutScreen
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('DETALHES TÉCNICOS'), findsOneWidget);
      expect(find.text('LINKS ÚTEIS'), findsOneWidget);
    });
  });
}
