import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/bookmarks.dart';
import 'package:mylink/l10n/app_localizations.dart';
import 'package:mylink/screens/library_screen.dart';
import 'package:mylink/theme/app_theme.dart';
import 'package:mylink/widgets/banner_ad_widget.dart';

import 'bookmarks_test.dart' show MemoryStorage;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BannerAdWidget — Unidade e Configuração de IDs', () {
    testWidgets(
      'resolve o ID oficial de teste da Google para Android em debug',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: BannerAdWidget(key: key)),
            ),
          );

          final state = tester.state(find.byKey(key));
          // Acesso ao getter resolvedAdUnitId
          final dynamic dynamicState = state;
          expect(
            dynamicState.resolvedAdUnitId,
            'ca-app-pub-3940256099942544/6300978111',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('resolve o ID oficial de teste da Google para iOS em debug', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: BannerAdWidget(key: key)),
          ),
        );

        final state = tester.state(find.byKey(key));
        final dynamic dynamicState = state;
        expect(
          dynamicState.resolvedAdUnitId,
          'ca-app-pub-3940256099942544/2934735716',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('respeita o adUnitId explícito quando informado', (
      tester,
    ) async {
      const customId = 'ca-app-pub-1478542054095233/6685912904';
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(key: key, adUnitId: customId),
          ),
        ),
      );

      final state = tester.state(find.byKey(key));
      final dynamic dynamicState = state;
      expect(dynamicState.resolvedAdUnitId, customId);
    });

    testWidgets(
      'chama onAdFailedToLoad com segurança em plataformas sem canal nativo (Linux/CI)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        var failedCalled = false;

        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BannerAdWidget(
                  onAdFailedToLoad: () {
                    failedCalled = true;
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(failedCalled, isTrue);
          expect(find.byType(SizedBox), findsWidgets);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'retorna SizedBox.shrink quando o teclado virtual está aberto (viewInsets.bottom > 0)',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
            child: MaterialApp(home: Scaffold(body: BannerAdWidget())),
          ),
        );
        await tester.pumpAndSettle();

        final bannerFinder = find.byType(BannerAdWidget);
        expect(bannerFinder, findsOneWidget);
        final size = tester.getSize(bannerFinder);
        expect(size, Size.zero);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('LibraryScreen — Rodapé: Barra de Gestos vs. 3 Botões [ |||  o  < ]', () {
    late BookmarkLibrary library;

    setUp(() async {
      library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
      await library.load();
      await library.finishOnboarding();
    });

    tearDown(() => library.dispose());

    Widget createSubject({
      required double bottomViewPadding,
      Widget Function(BuildContext)? bannerAdBuilder,
    }) {
      return MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            padding: EdgeInsets.only(bottom: bottomViewPadding),
            viewPadding: EdgeInsets.only(bottom: bottomViewPadding),
          ),
          child: LibraryScreen(
            library: library,
            bannerAdBuilder: bannerAdBuilder,
          ),
        ),
      );
    }

    testWidgets(
      'Cenário 1 (Barra de Gestos ~24dp): rodapé protege a base sem anúncio ativo',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createSubject(
            bottomViewPadding: 24.0,
            bannerAdBuilder: (_) => const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();

        final bottomNavFinder = find.byType(NavigationBar);
        expect(bottomNavFinder, findsOneWidget);
        final navBarSize = tester.getSize(bottomNavFinder);
        expect(navBarSize.height, 64.0);

        final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
        final navBarBottom = tester.getBottomLeft(bottomNavFinder).dy;
        expect(scaffoldHeight - navBarBottom, 24.0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cenário 2 (Barra de Gestos ~24dp): rodapé empilha NavigationBar + Banner sem duplicar os 24dp',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createSubject(
            bottomViewPadding: 24.0,
            bannerAdBuilder: (_) =>
                const SizedBox(key: Key('mock-banner'), width: 320, height: 50),
          ),
        );
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        final bannerFinder = find.byKey(const Key('mock-banner'));

        expect(navBarFinder, findsOneWidget);
        expect(bannerFinder, findsOneWidget);

        final navBarBottom = tester.getBottomLeft(navBarFinder).dy;
        final bannerTop = tester.getTopLeft(bannerFinder).dy;
        final bannerBottom = tester.getBottomLeft(bannerFinder).dy;

        // Banner fica imediatamente abaixo do NavigationBar sem buracos
        expect(bannerTop, equals(navBarBottom));

        // Abaixo do banner, sobra exatamente os 24dp da barra de gestos
        final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
        expect(scaffoldHeight - bannerBottom, 24.0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cenário 3 (Barra de 3 Botões [ |||  o  < ] ~48dp): menu fica 48dp acima do fim da tela (sem sobreposição)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createSubject(
            bottomViewPadding: 48.0,
            bannerAdBuilder: (_) => const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
        final navBarBottom = tester.getBottomLeft(navBarFinder).dy;
        // O menu fica exatamente 48dp acima da borda física da tela
        expect(scaffoldHeight - navBarBottom, 48.0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cenário 4 (Barra de 3 Botões [ |||  o  < ] ~48dp): com banner de 50dp ativo, o banner fica 48dp acima da borda e o menu logo acima',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createSubject(
            bottomViewPadding: 48.0,
            bannerAdBuilder: (_) => const SizedBox(
              key: Key('mock-banner-3-buttons'),
              width: 320,
              height: 50,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        final bannerFinder = find.byKey(const Key('mock-banner-3-buttons'));

        expect(navBarFinder, findsOneWidget);
        expect(bannerFinder, findsOneWidget);

        final navBarBottom = tester.getBottomLeft(navBarFinder).dy;
        final bannerTop = tester.getTopLeft(bannerFinder).dy;
        final bannerBottom = tester.getBottomLeft(bannerFinder).dy;

        // O topo do banner encosta diretamente na base do NavigationBar (sem duplicação de 48dp)
        expect(bannerTop, equals(navBarBottom));

        // A base do banner fica 48dp acima da borda inferior da tela, garantindo zero sobreposição com [ |||  o  < ]
        final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
        expect(scaffoldHeight - bannerBottom, 48.0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cenário 5 (Modo clássico sem Edge-to-Edge: 0dp): rodapé encosta perfeitamente na borda sem gap',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createSubject(
            bottomViewPadding: 0.0,
            bannerAdBuilder: (_) => const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
        final navBarBottom = tester.getBottomLeft(navBarFinder).dy;
        expect(scaffoldHeight - navBarBottom, 0.0);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
