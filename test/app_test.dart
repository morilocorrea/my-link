import 'package:mylink/bookmarks.dart';
import 'package:mylink/main.dart';
import 'package:mylink/services/google_oauth_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bookmarks_test.dart' show MemoryStorage;

void main() {
  late BookmarkLibrary library;
  final platform = TargetPlatformVariant.only(TargetPlatform.linux);
  setUp(() async {
    library = BookmarkLibrary(MemoryStorage(simulateLatency: false));
    await library.load();
  });
  tearDown(() => library.dispose());

  for (final config in [
    const GoogleOAuthConfig(),
    const GoogleOAuthConfig(
      serverClientId: '1234567890-fixture.apps.googleusercontent.com',
    ),
  ]) {
    testWidgets(
      'local app starts with OAuth configuration present=${config.hasServerClientId}',
      (tester) async {
        final app = MyLinkApp(library: library, googleOAuthConfig: config);
        await tester.pumpWidget(app);
        expect(app.googleOAuthConfig, same(config));
        expect(find.text('Seus links, organizados'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: platform,
    );
  }

  testWidgets('onboarding opens an empty library', (tester) async {
    await tester.pumpWidget(MyLinkApp(library: library));
    expect(find.text('Seus links, organizados'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('Começar')));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Você ainda não adicionou URLs aqui.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: platform);

  testWidgets(
    'editor saves, favorite filters and category navigation work',
    (tester) async {
      await tester.runAsync(() => library.finishOnboarding());
      await tester.pumpWidget(MyLinkApp(library: library));
      await tester.tap(find.byTooltip('Adicionar URL'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Flutter docs');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://flutter.dev',
      );
      await tester.runAsync(() => tester.tap(find.text('Salvar')));
      await tester.pumpAndSettle();
      expect(find.text('Flutter docs'), findsOneWidget);
      await tester.runAsync(
        () => tester.tap(find.byTooltip('Marcar favorito')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorite').last);
      await tester.pumpAndSettle();
      expect(find.text('Flutter docs'), findsOneWidget);
      await tester.runAsync(
        () => tester.tap(find.byTooltip('Remover dos favoritos')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum link favorito.'), findsOneWidget);
      await tester.tap(find.text('Category').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Articles'));
      await tester.pumpAndSettle();
      expect(find.text('Flutter docs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: platform,
  );

  testWidgets('narrow phone renders all tabs without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => library.finishOnboarding());
    await tester.pumpWidget(MyLinkApp(library: library));
    for (final name in ['Category', 'TimeLine', 'Favorite', 'Home']) {
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }, variant: platform);

  testWidgets(
    'startup failure blocks editing without destroying saved data',
    (tester) async {
      await tester.pumpWidget(
        MyLinkApp(library: library, startupError: StateError('Corrupt')),
      );
      expect(
        find.textContaining('Nenhum dado foi sobrescrito.'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    },
    variant: platform,
  );
}
