import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/my_link_logo.dart';

/// Tela Sobre do MyLink.
/// Apresenta a identidade da aplicação, detalhes técnicos de versão,
/// desenvolvedor e links institucionais como Política de Privacidade.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String version = '0.1.0';
  static const String buildNumber = '1';
  static const String developer = 'SisCORR Desenvolvimento';
  static const String privacyPolicyUrl = 'https://morilocorrea.github.io/';

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(privacyPolicyUrl);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a política de privacidade.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a política de privacidade.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = AppColors.primaryOf(context);
    final secondaryColor = AppColors.secondaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final dividerColor = AppColors.dividerOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                const SizedBox(height: 8),
                // Logotipo e Identificação
                Center(
                  child: Column(
                    children: [
                      const MyLinkLogoBadge(
                        size: 88,
                        iconSize: 52,
                        borderRadius: 22,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MyLink',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seus links, sempre à mão',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Seção Detalhes Técnicos
                _buildSectionHeader(
                  context,
                  title: 'Detalhes Técnicos',
                  icon: Icons.settings_suggest_outlined,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildInfoTile(
                        context,
                        label: 'Versão',
                        value: version,
                        icon: Icons.info_outline,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: dividerColor,
                      ),
                      _buildInfoTile(
                        context,
                        label: 'Build',
                        value: buildNumber,
                        icon: Icons.build_circle_outlined,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: dividerColor,
                      ),
                      _buildInfoTile(
                        context,
                        label: 'Desenvolvedor',
                        value: developer,
                        icon: Icons.code_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Seção Links Úteis
                _buildSectionHeader(
                  context,
                  title: 'Links Úteis',
                  icon: Icons.link_rounded,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),
                _buildCard(
                  context,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () => _launchPrivacyPolicy(context),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Política de Privacidade',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Rodapé Institucional
                Center(
                  child: Text(
                    developer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
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

  Widget _buildCard(BuildContext context, {required Widget child}) {
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

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primaryColor = AppColors.primaryOf(context);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: primaryColor, size: 20),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }
}
