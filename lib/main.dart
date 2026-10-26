import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bookmarks.dart';
import 'controllers/google_drive_controller.dart';
import 'screens/library_screen.dart';
import 'services/drive_access_service.dart';
import 'services/google_connection.dart';
import 'services/google_oauth_config.dart';
import 'theme/app_theme.dart';
import 'widgets/my_link_logo.dart';

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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.library});
  final BookmarkLibrary library;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MyLinkLogoBadge(
                    size: 96,
                    iconSize: 56,
                    borderRadius: 24,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Seus links, organizados',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Salve URLs, crie categorias, marque favoritos e leve seu backup CSV com você.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
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
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reimplementação independente em Flutter. Dados locais; sem anúncios.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
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
}
