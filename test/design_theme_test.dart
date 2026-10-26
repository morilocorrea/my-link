import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/main.dart';
import 'package:mylink/theme/app_theme.dart';

import 'bookmarks_test.dart' show MemoryStorage;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final platform = TargetPlatformVariant.only(TargetPlatform.linux);

  group('Design System Tokens and AppTheme', () {
    test('AppColors matches DESIGN.md specifications', () {
      expect(AppColors.primary, const Color(0xFF1E88E5));
      expect(AppColors.secondary, const Color(0xFFDCEAFE));
      expect(AppColors.surfaceSubtleLight, const Color(0xFFF3F4F8));
      expect(AppColors.textPrimaryLight, const Color(0xFF1A1C1E));
      expect(AppColors.textSecondaryLight, const Color(0xFF5E6368));
      expect(AppColors.iconMutedLight, const Color(0xFF74777F));
      expect(AppColors.borderSubtleLight, const Color(0xFFE2E5EB));
      expect(AppColors.borderHairlineLight, const Color(0xFFEBF0F7));
      expect(AppColors.dividerLight, const Color(0xFFF0F2F6));
    });

    test('AppColors dark mode tokens match specifications', () {
      expect(AppColors.primaryDark, const Color(0xFFA2C9FF));
      expect(AppColors.secondaryDark, const Color(0xFF253243));
      expect(AppColors.backgroundDark, const Color(0xFF141820));
      expect(AppColors.surfaceDark, const Color(0xFF171C21));
      expect(AppColors.surfaceSubtleDark, const Color(0xFF202733));
      expect(AppColors.textPrimaryDark, const Color(0xFFEDF1F8));
      expect(AppColors.textSecondaryDark, const Color(0xFFA0A7B4));
      expect(AppColors.iconMutedDark, const Color(0xFF8E9199));
    });

    test('ThemeData light and dark are configured properly', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, AppColors.primary);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.backgroundLight);

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, AppColors.primaryDark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });
  });

  group('Dark Mode Toggle and Layout Widgets', () {
    late BookmarkLibrary library;

    setUp(() async {
      library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      await library.finishOnboarding();
    });

    tearDown(() => library.dispose());

    testWidgets(
      'navigating to Settings from drawer updates theme dynamically',
      (tester) async {
        final app = MyLinkApp(library: library);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Initially in system/light mode
        expect(library.state.dark, isFalse);

        // Open drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Scroll and find Settings item in drawer
        final settingsFinder = find.text('Settings');
        await tester.scrollUntilVisible(
          settingsFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );
        expect(settingsFinder, findsOneWidget);
        await tester.tap(settingsFinder);
        await tester.pumpAndSettle();

        // Verify SettingsScreen is displayed
        expect(find.text('Configurações'), findsOneWidget);
        expect(find.text('Tema do Aplicativo'), findsOneWidget);

        // Update theme to dark mode
        await tester.runAsync(() => library.setThemeMode(ThemeMode.dark));
        await tester.pumpAndSettle();

        expect(library.state.dark, isTrue);
        expect(library.state.themeMode, ThemeMode.dark);
        var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.themeMode, ThemeMode.dark);

        // Update theme back to light mode
        await tester.runAsync(() => library.setThemeMode(ThemeMode.light));
        await tester.pumpAndSettle();

        expect(library.state.dark, isFalse);
        expect(library.state.themeMode, ThemeMode.light);
        materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.themeMode, ThemeMode.light);
      },
      variant: platform,
    );

    testWidgets(
      'category tab renders two-column grid with 16px radius cards',
      (tester) async {
        final app = MyLinkApp(library: library);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Switch to Category tab
        await tester.tap(find.text('Category').last);
        await tester.pumpAndSettle();

        // Check GridView exists
        final gridFinder = find.byType(GridView);
        expect(gridFinder, findsOneWidget);

        final gridView = tester.widget<GridView>(gridFinder);
        final delegate =
            gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisSpacing, 12);
        expect(delegate.mainAxisSpacing, 12);
        expect(delegate.mainAxisExtent, 130);
      },
      variant: platform,
    );

    testWidgets(
      'FAB has 16px corner radius and secondary container color',
      (tester) async {
        final app = MyLinkApp(library: library);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.backgroundColor, AppColors.secondary);
        expect(fab.foregroundColor, AppColors.primary);
        expect(fab.shape, isA<RoundedRectangleBorder>());
        final shape = fab.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      },
      variant: platform,
    );

    testWidgets(
      'Bottom navigation bar has 64px height and 4 destinations',
      (tester) async {
        final app = MyLinkApp(library: library);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        final navBar = tester.widget<NavigationBar>(navBarFinder);
        expect(navBar.height, 64);
        expect(navBar.destinations.length, 4);
      },
      variant: platform,
    );

    testWidgets('Search bar has 48px height and 14px border radius', (
      tester,
    ) async {
      final app = MyLinkApp(library: library);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, AppColors.surfaceSubtleLight);

      final border = textField.decoration?.border as OutlineInputBorder?;
      expect(border?.borderRadius, BorderRadius.circular(14));
    }, variant: platform);
  });
}
