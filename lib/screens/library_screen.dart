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
import 'google_drive_screen.dart';
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
        title: const Text('QR Code'),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: Colors.white,
                child: QrImageView(
                  data: url,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(url, maxLines: 4),
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
  });

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: ListView(
        children: [
          const DrawerHeader(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bookmarks_rounded,
                    size: 40,
                    color: Color(0xff0095ff),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'MyLink',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text('Seus links, sempre à mão'),
                ],
              ),
            ),
          ),
          for (var i = 0; i < _titles.length; i++)
            ListTile(
              title: Text(_titles[i]),
              onTap: () {
                Navigator.pop(context);
                _selectTab(i);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_link),
            title: const Text('Adicionar link'),
            onTap: () {
              Navigator.pop(context);
              _edit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Ler QR Code'),
            onTap: () {
              Navigator.pop(context);
              _scan();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Gerar QR Code'),
            onTap: () {
              Navigator.pop(context);
              _generateQr();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo escuro'),
            value: library.state.dark,
            onChanged: (v) => _run(() => library.setDark(v)),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Exportar CSV'),
            onTap: () {
              Navigator.pop(context);
              _export();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(_importing ? 'Importando…' : 'Importar CSV'),
            enabled: !_importing,
            onTap: () {
              Navigator.pop(context);
              _import();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Google Drive'),
            subtitle: const Text('Backup e restauração no Google Drive'),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'MyLink',
                applicationVersion: '0.1.0',
                children: [
                  const Text(
                    'Reimplementação independente. Não afiliada ao app original. '
                    'Dados locais; a abertura de URLs e a conexão opcional com o Google Drive utilizam a rede.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 128,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = library.state.links
            .where((e) => e.category == category)
            .length;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() {
              _category = category;
              _search = '';
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        color: Color(0xff0095ff),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Excluir categoria',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          if (await _confirm(
                            'Excluir $category?',
                            '$count links desta categoria também serão excluídos.',
                          )) {
                            await _run(() => library.deleteCategory(category));
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$count links',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty(
    String text, {
    VoidCallback? action,
    String label = 'Adicionar URL',
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: Color(0xff0095ff),
          ),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: action ?? () => _edit(),
            icon: const Icon(Icons.add),
            label: Text(label),
          ),
        ],
      ),
    ),
  );

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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        onTap: () => _open(link),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xffe7f4ff),
                          child: Icon(Icons.link, color: Color(0xff0095ff)),
                        ),
                        title: Text(
                          link.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${link.category} · $day',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: link.favorite
                          ? 'Remover dos favoritos'
                          : 'Marcar favorito',
                      icon: Icon(
                        link.favorite ? Icons.favorite : Icons.favorite_border,
                        color: link.favorite ? Colors.red : null,
                      ),
                      onPressed: () =>
                          _run(() => library.toggleFavorite(link.id)),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opções do link',
                      onSelected: (a) => _action(a, link),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'copy', child: Text('Copiar URL')),
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
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ],
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
              onPressed: () => setState(() => _category = null),
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
                child: TextField(
                  key: ValueKey('search-$_tab-$_category'),
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar título, URL ou categoria…',
                    prefixIcon: Icon(Icons.search),
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
    floatingActionButton: FloatingActionButton(
      tooltip: _tab == 1 && _category == null
          ? 'Nova categoria'
          : 'Adicionar URL',
      onPressed: _tab == 1 && _category == null ? _addCategory : () => _edit(),
      child: const Icon(Icons.add),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (tab) {
        _selectTab(tab);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          label: 'Category',
        ),
        NavigationDestination(icon: Icon(Icons.access_time), label: 'TimeLine'),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favorite',
        ),
      ],
    ),
  );
}
