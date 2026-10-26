import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bookmarks.dart';
import '../controllers/google_drive_controller.dart';
import '../services/drive_access_service.dart';
import '../services/google_connection.dart';
import '../services/google_oauth_config.dart';
import '../theme/app_theme.dart';
import '../widgets/my_link_logo.dart';
import 'google_drive_screen.dart';
import 'settings_screen.dart';
import 'web_tools.dart';

const _sortLabels = ['New First', 'Old First', 'A to Z', 'Z to A'];
const _titles = ['Home', 'Category', 'TimeLine', 'Favorite'];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.library,
    this.googleDriveController,
  });
  final BookmarkLibrary library;
  final GoogleDriveController? googleDriveController;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  BookmarkLibrary get library => widget.library;
  int _tab = 0;
  String _search = '';
  String? _category;
  bool _importing = false;
  final _searchController = TextEditingController();
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final receiver = ReceiveSharingIntent.instance;
      _subscription = receiver.getMediaStream().listen(
        _receive,
        onError: (Object e) =>
            _message('Não foi possível receber o compartilhamento.'),
      );
      receiver
          .getInitialMedia()
          .then((items) {
            if (mounted) _receive(items);
            return receiver.reset();
          })
          .catchError((Object e) {
            _message('Não foi possível ler o link recebido.');
          });
    }
  }

  void _receive(List<SharedMediaFile> items) {
    if (!mounted || items.isEmpty) return;
    final url = extractSharedUrl(items.map((e) => e.path).join(' '));
    if (url == null) {
      _message('Nenhuma URL HTTP/HTTPS encontrada.');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _edit(initialUrl: url);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, stack) {
      if (kDebugMode) debugPrint('Bookmark action failed: $e\n$stack');
      _message(
        e is FormatException
            ? e.message
            : 'Não foi possível concluir. Tente novamente.',
      );
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _edit({Bookmark? link, String? initialUrl}) async {
    final title = TextEditingController(text: link?.title);
    final url = TextEditingController(text: link?.url ?? initialUrl);
    var selected =
        link?.category ??
        (_category != null && library.state.categories.contains(_category)
            ? _category
            : library.state.categories.firstOrNull);
    final form = GlobalKey<FormState>();
    var busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(link == null ? 'Adicionar URL' : 'Editar link'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: url,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'URL',
                        suffixIcon: IconButton(
                          tooltip: 'Colar link',
                          onPressed: () async {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (dialogContext.mounted && data?.text != null) {
                              url.text = data!.text!;
                            }
                          },
                          icon: const Icon(Icons.content_paste),
                        ),
                      ),
                      validator: (value) {
                        try {
                          normalizeUrl(value ?? '');
                          return null;
                        } on FormatException catch (e) {
                          return e.message;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: library.state.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => selected = value,
                      validator: (value) => value == null
                          ? 'Crie ou selecione uma categoria.'
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await _addCategory();
                        if (dialogContext.mounted) update(() {});
                      },
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Nova categoria'),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await library.save(
                          id: link?.id,
                          title: title.text,
                          url: url.text,
                          category: selected!,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          update(() {
                            busy = false;
                            error = e is FormatException
                                ? e.message
                                : 'Falha ao salvar os dados.';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
    // Wait for the reverse route animation before disposing field controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    url.dispose();
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    String? error;
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Nova categoria'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(labelText: 'Nome', errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() => busy = true);
                      try {
                        await library.addCategory(controller.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          update(() {
                            busy = false;
                            error = e is FormatException
                                ? e.message
                                : 'Não foi possível salvar.';
                          });
                        }
                      }
                    },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  Future<void> _scan() async {
    final value = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (value != null && mounted) {
      final url = extractSharedUrl(value);
      if (url == null) {
        _message('O QR Code não contém uma URL HTTP/HTTPS.');
        return;
      }
      await _edit(initialUrl: url);
    }
  }

  Future<void> _qr(String url) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('QR Code'),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: url,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                maxLines: 4,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQr() async {
    final controller = TextEditingController();
    String? error;
    final url = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Gerar QR Code'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'URL', errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  Navigator.pop(context, normalizeUrl(controller.text));
                } on FormatException catch (e) {
                  update(() => error = e.message);
                }
              },
              child: const Text('Gerar'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (url != null && mounted) await _qr(url);
  }

  Future<void> _export() => _run(() async {
    if (library.state.links.isEmpty) {
      _message('Nenhum link disponível para exportar.');
      return;
    }
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar links',
      fileName: 'links.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Uint8List.fromList(utf8.encode(library.exportCsv())),
    );
    if (result != null) _message('CSV exportado.');
  });

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.size > library.csvConfig.maxCsvSizeBytes) {
        throw FormatException(
          'O CSV deve ter no máximo ${library.csvConfig.maxCsvSizeMb} MB.',
        );
      }
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('Não foi possível ler o arquivo.');
      }
      if (await _confirm(
        'Importar CSV?',
        'Os links serão adicionados à biblioteca. '
            'Importar o mesmo arquivo novamente pode criar duplicatas.',
      )) {
        await library.importCsv(utf8.decode(bytes));
        _message('Importação concluída.');
      }
    });
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _open(Bookmark link, {bool external = false}) => _run(() async {
    if (!external && defaultTargetPlatform == TargetPlatform.android) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BrowserScreen(url: link.url, title: link.title),
        ),
      );
    } else if (!await launchUrl(
      Uri.parse(link.url),
      mode: LaunchMode.externalApplication,
    )) {
      throw const FormatException('Não foi possível abrir o navegador.');
    }
  });

  Future<void> _action(String action, Bookmark link) async {
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link.url));
        _message('Link copiado.');
      case 'edit':
        await _edit(link: link);
      case 'qr':
        await _qr(link.url);
      case 'browser':
        await _open(link, external: true);
      case 'share':
        await _run(() async {
          final box = context.findRenderObject() as RenderBox?;
          await SharePlus.instance.share(
            ShareParams(
              text: link.url,
              title: link.title,
              sharePositionOrigin: box == null
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        });
      case 'delete':
        if (await _confirm(
          'Excluir link?',
          'Esta ação não pode ser desfeita.',
        )) {
          await _run(() => library.delete(link.id));
        }
    }
  }

  void _selectTab(int tab) => setState(() {
    _tab = tab;
    _category = null;
    _search = '';
    _searchController.clear();
  });

  Widget _drawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: subtitle == null ? 48 : 56,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          enabled: enabled,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.textSecondaryOf(context)
                : AppColors.iconMutedOf(context),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: enabled
                  ? AppColors.textPrimaryOf(context)
                  : AppColors.iconMutedOf(context),
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }

  Widget _drawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: AppColors.surfaceElevatedOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MyLinkLogoBadge(
                    size: 48,
                    iconSize: 28,
                    borderRadius: 14,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MyLink',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Seus links, sempre à mão',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.dividerOf(context), height: 1),
            const SizedBox(height: 8),
            for (var i = 0; i < _titles.length; i++)
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: _tab == i
                      ? (isDark ? AppColors.secondaryDark : AppColors.secondary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(
                      horizontal: 0,
                      vertical: -2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _titles[i],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: _tab == i
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _tab == i
                            ? (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primary)
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectTab(i);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Divider(color: AppColors.dividerOf(context), height: 1),
            const SizedBox(height: 8),
            _drawerTile(
              icon: Icons.add_link,
              title: 'Adicionar link',
              onTap: () {
                Navigator.pop(context);
                _edit();
              },
            ),
            _drawerTile(
              icon: Icons.qr_code_scanner,
              title: 'Ler QR Code',
              onTap: () {
                Navigator.pop(context);
                _scan();
              },
            ),
            _drawerTile(
              icon: Icons.qr_code,
              title: 'Gerar QR Code',
              onTap: () {
                Navigator.pop(context);
                _generateQr();
              },
            ),
            _drawerTile(
              icon: Icons.file_upload_outlined,
              title: 'Exportar CSV',
              onTap: () {
                Navigator.pop(context);
                _export();
              },
            ),
            _drawerTile(
              icon: Icons.file_download_outlined,
              title: _importing ? 'Importando…' : 'Importar CSV',
              enabled: !_importing,
              onTap: () {
                Navigator.pop(context);
                _import();
              },
            ),
            _drawerTile(
              icon: Icons.cloud_outlined,
              title: 'Google Drive',
              subtitle: 'Backup e restauração no Google Drive',
              onTap: () {
                Navigator.pop(context);
                final controller =
                    widget.googleDriveController ??
                    GoogleDriveController(
                      connection: DefaultGoogleConnection(
                        config: const GoogleOAuthConfig.fromEnvironment(),
                      ),
                      driveAccessService: DefaultDriveAccessService(),
                    );
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => GoogleDriveScreen(
                      controller: controller,
                      library: library,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.dividerOf(context), height: 1),
            const SizedBox(height: 8),
            _drawerTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(library: library),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _categories() {
    final categories =
        library.state.categories
            .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (categories.isEmpty) {
      return _empty(
        'Nenhuma categoria encontrada.',
        action: _addCategory,
        label: 'Criar categoria',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600
            ? (constraints.maxWidth ~/ 220).clamp(2, 6)
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 130,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = library.state.links
                .where((e) => e.category == category)
                .length;

            return Material(
              color: AppColors.surfaceSubtleOf(context),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() {
                  _category = category;
                  _search = '';
                  _searchController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderHairlineOf(context),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 24,
                            color: AppColors.primaryOf(context),
                          ),
                          IconButton(
                            tooltip: 'Excluir categoria',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.iconMutedOf(context),
                            ),
                            onPressed: () async {
                              if (await _confirm(
                                'Excluir $category?',
                                '$count links desta categoria também serão excluídos.',
                              )) {
                                await _run(
                                  () => library.deleteCategory(category),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count links',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.iconMutedOf(context),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _empty(
    String text, {
    VoidCallback? action,
    String label = 'Adicionar URL',
  }) {
    final theme = Theme.of(context);
    final primaryColor = AppColors.primaryOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyLinkLogo(size: 64, color: primaryColor),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: action ?? () => _edit(),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: Icon(Icons.add_rounded, size: 20, color: primaryColor),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _links() {
    final links = library.query(
      text: _search,
      category: _category,
      favorites: _tab == 3,
      timeline: _tab == 2,
    );
    if (links.isEmpty) {
      return _empty(
        _search.isNotEmpty
            ? 'Nenhum resultado para a busca.'
            : _tab == 3
            ? 'Nenhum link favorito.'
            : 'Você ainda não adicionou URLs aqui.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        final day =
            '${link.createdAt.day.toString().padLeft(2, '0')}/${link.createdAt.month.toString().padLeft(2, '0')}/${link.createdAt.year}';
        final previous = index == 0 ? null : links[index - 1].createdAt;
        final heading =
            _tab == 2 &&
            (previous == null ||
                DateUtils.dateOnly(previous) !=
                    DateUtils.dateOnly(link.createdAt));
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  day,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtleOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderHairlineOf(context),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          onTap: () => _open(link),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.secondaryDark
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.link_rounded,
                              size: 22,
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            link.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  link.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${link.category} · $day',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.iconMutedOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: link.favorite
                            ? 'Remover dos favoritos'
                            : 'Marcar favorito',
                        icon: Icon(
                          link.favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: link.favorite
                              ? Colors.red
                              : AppColors.iconMutedOf(context),
                        ),
                        onPressed: () =>
                            _run(() => library.toggleFavorite(link.id)),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Opções do link',
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.iconMutedOf(context),
                        ),
                        onSelected: (a) => _action(a, link),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'copy',
                            child: Text('Copiar URL'),
                          ),
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'share',
                            child: Text('Compartilhar URL'),
                          ),
                          PopupMenuItem(
                            value: 'qr',
                            child: Text('Gerar QR Code'),
                          ),
                          PopupMenuItem(
                            value: 'browser',
                            child: Text('Abrir no navegador externo'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_category ?? _titles[_tab]),
      leading: _category == null
          ? null
          : IconButton(
              tooltip: 'Voltar às categorias',
              onPressed: () => setState(() {
                _category = null;
                _search = '';
                _searchController.clear();
              }),
              icon: const Icon(Icons.arrow_back),
            ),
      actions: [
        PopupMenuButton<LinkSort>(
          tooltip: 'Ordenar links',
          icon: const Icon(Icons.sort),
          onSelected: (v) => _run(() => library.setSort(v)),
          itemBuilder: (_) => [
            for (final sort in LinkSort.values)
              CheckedPopupMenuItem(
                value: sort,
                checked: sort == library.state.sort,
                child: Text(_sortLabels[sort.index]),
              ),
          ],
        ),
        IconButton(
          tooltip: 'Ler QR Code',
          onPressed: _scan,
          icon: const Icon(Icons.qr_code_scanner),
        ),
        const SizedBox(width: 8),
      ],
    ),
    drawer: _drawer(),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    key: ValueKey('search-$_tab-$_category'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceSubtleOf(context),
                      hintText: 'Buscar título, URL ou categoria…',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondaryOf(context)),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 20,
                      ),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              color: AppColors.textSecondaryOf(context),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primaryOf(context),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _tab == 1 && _category == null
                    ? _categories()
                    : _links(),
              ),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : const Color(0xFF1E88E5))
                    .withValues(alpha: 0.22),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        tooltip: _tab == 1 && _category == null
            ? 'Nova categoria'
            : 'Adicionar URL',
        onPressed: _tab == 1 && _category == null
            ? _addCategory
            : () => _edit(),
        backgroundColor: AppColors.secondaryOf(context),
        foregroundColor: AppColors.primaryOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    ),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        border: Border(
          top: BorderSide(color: AppColors.dividerOf(context), width: 1),
        ),
      ),
      child: NavigationBar(
        height: 64,
        selectedIndex: _tab,
        onDestinationSelected: (tab) {
          _selectTab(tab);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Category',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled_rounded),
            label: 'TimeLine',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorite',
          ),
        ],
      ),
    ),
  );
}
