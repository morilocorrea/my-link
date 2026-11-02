import 'package:flutter/material.dart';

import '../bookmarks.dart';
import '../controllers/google_drive_controller.dart';
import '../l10n/app_localizations.dart';
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

  String _formatDateTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final locale = Localizations.localeOf(context).toString();
    final isPt = locale.toLowerCase().startsWith('pt');
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final hr = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    if (isPt) {
      return '$d/$m/$y às $hr:$min';
    }
    return '$m/$d/$y at $hr:$min';
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
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.googleDriveTitle)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!controller.isConfigured) ...[
                    _buildConfigWarningCard(context, l10n),
                    const SizedBox(height: 16),
                  ],
                  if (controller.errorMessage != null) ...[
                    _buildErrorBanner(context, l10n, controller.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (controller.statusMessage != null) ...[
                    _buildSuccessBanner(
                      context,
                      l10n,
                      controller.statusMessage!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (controller.user == null)
                    _buildDisconnectedView(context, l10n)
                  else
                    _buildConnectedView(context, l10n, controller.user!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigWarningCard(BuildContext context, AppLocalizations l10n) =>
      Card(
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
                      l10n.driveConfigMissingTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.driveConfigMissingMessage,
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

  Widget _buildErrorBanner(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) => Card(
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
            tooltip: l10n.closeMessageTooltip,
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

  Widget _buildSuccessBanner(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) => Card(
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
            tooltip: l10n.closeMessageTooltip,
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

  Widget _buildDisconnectedView(BuildContext context, AppLocalizations l10n) =>
      Card(
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
                l10n.connectDriveTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(l10n.connectDriveMessage, textAlign: TextAlign.center),
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
                  controller.isBusy
                      ? l10n.connecting
                      : l10n.connectGoogleAccount,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildConnectedView(
    BuildContext context,
    AppLocalizations l10n,
    GoogleUser user,
  ) {
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
                              ? l10n.driveAuthorized
                              : l10n.driveNotAuthorized,
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
                  l10n.sectionAuthAndAccess,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  driveGranted
                      ? l10n.driveAuthorizedScopeInfo
                      : l10n.driveNotAuthorizedScopeInfo,
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
                            isAuthorizing
                                ? l10n.authorizing
                                : l10n.authorizeDrive,
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
                            isVerifying ? l10n.verifying : l10n.verifyApiAccess,
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
                        l10n.sectionDriveBackup,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: l10n.refreshInfoTooltip,
                        onPressed: controller.isBusy
                            ? null
                            : () => controller.refreshBackupInfo(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.backupDescription),
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
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.checkingBackup),
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
                                    Text(
                                      l10n.backupAvailableCloud,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l10n.lastUploaded(backup.modifiedTime != null ? _formatDateTime(context, backup.modifiedTime!) : 'N/A')}'
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
                        : Row(
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(l10n.noBackupFound)),
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
                                      SnackBar(
                                        content: Text(l10n.noLinksToBackup),
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
                            isBackingUp ? l10n.backingUp : l10n.backupNow,
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
                                    title: l10n.restoreBackupConfirmTitle,
                                    message: l10n.restoreBackupConfirmMessage,
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
                            isRestoring ? l10n.restoring : l10n.restoreBackup,
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
                  title: Text(l10n.signOut),
                  subtitle: Text(l10n.signOutSubtitle),
                  onTap: controller.isBusy
                      ? null
                      : () async {
                          if (await _confirm(
                            title: l10n.signOutConfirmTitle,
                            message: l10n.signOutConfirmMessage,
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
                    l10n.revokeAccess,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: Text(l10n.revokeAccessSubtitle),
                  onTap: controller.isBusy
                      ? null
                      : () async {
                          if (await _confirm(
                            title: l10n.revokeAccessConfirmTitle,
                            message: l10n.revokeAccessConfirmMessage,
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
