import 'package:flutter/material.dart';

import '../bookmarks.dart';
import '../controllers/google_drive_controller.dart';
import '../services/google_connection.dart';
import '../theme/app_theme.dart';

class GoogleDriveScreen extends StatefulWidget {
  const GoogleDriveScreen({super.key, required this.controller, this.library});

  final GoogleDriveController controller;
  final BookmarkLibrary? library;

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  GoogleDriveController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.initialize();
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final hr = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $hr:$min';
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Google Drive')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!controller.isConfigured) ...[
                  _buildConfigWarningCard(context),
                  const SizedBox(height: 16),
                ],
                if (controller.errorMessage != null) ...[
                  _buildErrorBanner(context, controller.errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (controller.statusMessage != null) ...[
                  _buildSuccessBanner(context, controller.statusMessage!),
                  const SizedBox(height: 16),
                ],
                if (controller.user == null)
                  _buildDisconnectedView(context)
                else
                  _buildConnectedView(context, controller.user!),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildConfigWarningCard(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração OAuth Ausente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A variável GOOGLE_SERVER_CLIENT_ID não foi informada no arquivo .env. '
                  'Crie o arquivo a partir de .env.example para habilitar a conexão.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorBanner(BuildContext context, String message) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar mensagem',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: controller.clearMessages,
          ),
        ],
      ),
    ),
  );

  Widget _buildSuccessBanner(BuildContext context, String message) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar mensagem',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: controller.clearMessages,
          ),
        ],
      ),
    ),
  );

  Widget _buildDisconnectedView(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppColors.primaryOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Conectar ao Google Drive',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Conecte sua conta Google para autorizar o acesso aos arquivos '
            'do Google Drive gerenciados pelo MyLink. Seus dados locais permanecem salvos no dispositivo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (controller.isBusy || !controller.isConfigured)
                ? null
                : () => controller.signIn(),
            icon: controller.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(
              controller.isBusy ? 'Conectando…' : 'Conectar Conta Google',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildConnectedView(BuildContext context, GoogleUser user) {
    final driveGranted =
        controller.driveAuthStatus == DriveAuthorizationStatus.granted;
    final isAuthorizing =
        controller.driveAuthStatus == DriveAuthorizationStatus.authorizing;
    final isVerifying =
        controller.verificationStatus == DriveVerificationStatus.verifying;
    final isBackingUp = controller.isBackingUp;
    final isRestoring = controller.isRestoring;
    final isLoadingBackupInfo = controller.isLoadingBackupInfo;
    final backup = controller.backupInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.secondaryOf(context),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  onBackgroundImageError: user.photoUrl != null
                      ? (exception, stackTrace) {
                          // Handled gracefully when image cannot be loaded.
                        }
                      : null,
                  child: user.photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primaryOf(context),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.displayName != null &&
                          user.displayName!.isNotEmpty)
                        Text(
                          user.displayName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: Icon(
                          driveGranted
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: driveGranted ? Colors.green : Colors.orange,
                        ),
                        label: Text(
                          driveGranted
                              ? 'Drive Autorizado'
                              : 'Drive Não Autorizado',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autorização e Acesso',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  driveGranted
                      ? 'O aplicativo tem autorização para gerenciar apenas os arquivos criados ou abertos por ele (escopo drive.file).'
                      : 'Para que o aplicativo possa acessar arquivos no Drive, você precisa autorizar a permissão drive.file.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!driveGranted)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: controller.isBusy
                              ? null
                              : () => controller.authorizeDrive(),
                          icon: isAuthorizing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.security),
                          label: Text(
                            isAuthorizing ? 'Autorizando…' : 'Autorizar Drive',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.isBusy
                              ? null
                              : () => controller.verifyDriveAccess(),
                          icon: isVerifying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync_outlined),
                          label: Text(
                            isVerifying
                                ? 'Verificando…'
                                : 'Verificar Acesso à API',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (driveGranted) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Backup no Google Drive',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Atualizar informações',
                        onPressed: controller.isBusy
                            ? null
                            : () => controller.refreshBackupInfo(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Salve todos os seus links e categorias no Google Drive ou restaure seus dados neste aparelho.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isLoadingBackupInfo
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Consultando backup no Google Drive…'),
                            ],
                          )
                        : backup != null
                        ? Row(
                            children: [
                              const Icon(
                                Icons.cloud_done_rounded,
                                color: Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Backup disponível na nuvem',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Último envio: ${backup.modifiedTime != null ? _formatDateTime(backup.modifiedTime!) : 'N/A'}'
                                      '${backup.sizeBytes != null ? ' • ${_formatBytes(backup.sizeBytes)}' : ''}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                color: Colors.grey,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Nenhum backup encontrado no Google Drive.',
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              (controller.isBusy || widget.library == null)
                              ? null
                              : () async {
                                  if (widget.library!.state.links.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Nenhum link disponível para backup.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await controller.backup(widget.library!);
                                },
                          icon: isBackingUp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            isBackingUp ? 'Enviando…' : 'Fazer Backup Agora',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (controller.isBusy || widget.library == null)
                              ? null
                              : () async {
                                  final confirmed = await _confirm(
                                    title: 'Restaurar Backup?',
                                    message:
                                        'Os links e categorias salvos no Google Drive '
                                        'serão adicionados à sua biblioteca neste dispositivo.',
                                  );
                                  if (confirmed && mounted) {
                                    await controller.restore(widget.library!);
                                  }
                                },
                          icon: isRestoring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_download_outlined),
                          label: Text(
                            isRestoring ? 'Restaurando…' : 'Restaurar Backup',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Encerrar sessão'),
                  subtitle: const Text('Desconecta a conta Google deste app.'),
                  onTap: controller.isBusy
                      ? null
                      : () async {
                          if (await _confirm(
                            title: 'Encerrar sessão?',
                            message:
                                'Sua conta Google será desconectada do aplicativo. '
                                'Seus links salvos localmente não serão alterados.',
                          )) {
                            await controller.signOut();
                          }
                        },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.no_accounts_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Revogar acesso Google',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Revoga as permissões concedidas pela sua conta Google a este aplicativo.',
                  ),
                  onTap: controller.isBusy
                      ? null
                      : () async {
                          if (await _confirm(
                            title: 'Revogar acesso?',
                            message:
                                'Esta ação revoga todas as autorizações do aplicativo na sua conta Google. '
                                'Nenhum link local ou arquivo do Drive será apagado.',
                            isDestructive: true,
                          )) {
                            await controller.disconnect();
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
