import 'package:flutter/material.dart';

import '../bookmarks.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

/// Tela de Configurações do MyLink.
/// Segue a organização de informações da tela de Configurações de referência,
/// preservando rigorosamente o design system e tokens de estilo do MyLink.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.library});

  final BookmarkLibrary library;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BookmarkLibrary get library => widget.library;

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Padrão do Sistema';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final theme = Theme.of(context);
        final primaryColor = AppColors.primaryOf(context);
        final secondaryColor = AppColors.secondaryOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final currentThemeMode = library.state.themeMode;

        return Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  children: [
                    _buildSectionHeader(
                      title: 'Aparência',
                      icon: Icons.palette_outlined,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      child: _buildThemeTile(
                        title: 'Tema do Aplicativo',
                        subtitle: _getThemeModeLabel(currentThemeMode),
                        value: currentThemeMode,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            library.setThemeMode(mode);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      title: 'Informações',
                      icon: Icons.info_outline,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.help_outline_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'Sobre o Aplicativo',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Versão, desenvolvedor e links úteis.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'MyLink',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seus links, sempre à mão',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Material(
      color: AppColors.surfaceSubtleOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderHairlineOf(context), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildThemeTile({
    required String title,
    required String subtitle,
    required ThemeMode value,
    required Color primaryColor,
    required Color secondaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<ThemeMode>(
          key: const Key('theme_mode_dropdown'),
          value: value,
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surfaceElevatedOf(context),
          items: [ThemeMode.system, ThemeMode.light, ThemeMode.dark].map((
            ThemeMode mode,
          ) {
            return DropdownMenuItem<ThemeMode>(
              value: mode,
              child: Text(
                _getThemeModeLabel(mode),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
