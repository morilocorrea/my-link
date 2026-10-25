import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bookmarks.dart';
import 'controllers/google_drive_controller.dart';
import 'screens/library_screen.dart';
import 'services/drive_access_service.dart';
import 'services/google_connection.dart';
import 'services/google_oauth_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = BookmarkLibrary(PreferenceStorage());
  const config = GoogleOAuthConfig.fromEnvironment();
  final googleConnection = DefaultGoogleConnection(config: config);
  final driveAccessService = DefaultDriveAccessService(
    requestTimeout: Duration(seconds: config.driveTimeoutSeconds),
  );
  final driveController = GoogleDriveController(
    connection: googleConnection,
    driveAccessService: driveAccessService,
  );
  Object? error;
  try {
    await library.load();
  } catch (e, stack) {
    error = e;
    if (kDebugMode) debugPrint('Library initialization failed: $e\n$stack');
  }
  runApp(
    MyLinkApp(
      library: library,
      startupError: error,
      googleOAuthConfig: config,
      googleDriveController: driveController,
    ),
  );
}

class MyLinkApp extends StatelessWidget {
  const MyLinkApp({
    super.key,
    required this.library,
    this.startupError,
    this.googleOAuthConfig = const GoogleOAuthConfig.fromEnvironment(),
    this.googleDriveController,
  });
  final BookmarkLibrary library;
  final Object? startupError;
  final GoogleOAuthConfig googleOAuthConfig;
  final GoogleDriveController? googleDriveController;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => MaterialApp(
      title: 'MyLink',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: library.state.dark ? ThemeMode.dark : ThemeMode.light,
      home: startupError != null
          ? const Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Não foi possível ler os dados salvos. Nenhum dado foi sobrescrito. '
                      'Feche o app e verifique o armazenamento antes de tentar novamente.',
                    ),
                  ),
                ),
              ),
            )
          : library.state.onboarded
          ? LibraryScreen(
              library: library,
              googleDriveController: googleDriveController,
            )
          : _Welcome(library: library),
    ),
  );

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff0095ff),
        brightness: brightness,
        primary: const Color(0xff0095ff),
      ),
      scaffoldBackgroundColor: dark ? const Color(0xff141820) : Colors.white,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: dark ? const Color(0xff141820) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff202733) : const Color(0xfff4f6f9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.library});
  final BookmarkLibrary library;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bookmarks_rounded,
                  size: 100,
                  color: Color(0xff0095ff),
                ),
                const SizedBox(height: 32),
                Text(
                  'Seus links, organizados',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Salve URLs, crie categorias, marque favoritos e leve seu backup CSV com você.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    try {
                      await library.finishOnboarding();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível salvar. Tente novamente.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Começar'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reimplementação independente em Flutter. Dados locais; sem anúncios.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
