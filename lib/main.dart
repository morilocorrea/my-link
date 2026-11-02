import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bookmarks.dart';
import 'controllers/google_drive_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/library_screen.dart';
import 'services/drive_access_service.dart';
import 'services/google_connection.dart';
import 'services/google_oauth_config.dart';
import 'theme/app_theme.dart';
import 'widgets/my_link_logo.dart';

/// Regra estrita de resolução de idioma:
/// - Apenas `pt-BR` seleciona Português (Brasil).
/// - Qualquer outro locale (inclusive `pt` sem região ou `pt-PT`) seleciona `en-US`.
Locale resolveAppLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocale != null &&
      deviceLocale.languageCode.toLowerCase() == 'pt' &&
      deviceLocale.countryCode?.toUpperCase() == 'BR') {
    return const Locale('pt', 'BR');
  }
  return const Locale('en', 'US');
}

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
    this.locale,
  });
  final BookmarkLibrary library;
  final Object? startupError;
  final GoogleOAuthConfig googleOAuthConfig;
  final GoogleDriveController? googleDriveController;
  final Locale? locale;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => MaterialApp(
      title: 'MyLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: library.state.themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
      localeResolutionCallback: (deviceLocale, supportedLocales) =>
          resolveAppLocale(deviceLocale, supportedLocales),
      home: startupError != null
          ? Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.startupError),
                      ),
                    ),
                  ),
                );
              },
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.welcomeSubtitle,
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
                              SnackBar(content: Text(l10n.welcomeSaveError)),
                            );
                          }
                        }
                      },
                      child: Text(l10n.welcomeGetStarted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.welcomeFooter,
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
