import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bookmarks.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _completed = false;
  final _controller = MobileScannerController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ler QR Code')),
    body: MobileScanner(
      controller: _controller,
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error.errorCode == MobileScannerErrorCode.permissionDenied
                ? 'Permita o acesso à câmera nas configurações do dispositivo e tente novamente.'
                : 'Câmera indisponível. Você pode adicionar o link manualmente.',
          ),
        ),
      ),
      onDetect: (capture) {
        if (_completed) return;
        for (final barcode in capture.barcodes) {
          if (barcode.rawValue != null) {
            _completed = true;
            Navigator.pop(context, barcode.rawValue);
            break;
          }
        }
      },
    ),
  );
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.url, required this.title});
  final String url, title;
  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // No app-to-JavaScript bridge; saved URLs are untrusted remote content.
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame != false) {
              setState(() => _error = 'Não foi possível carregar a página.');
            }
          },
          onNavigationRequest: (request) {
            try {
              normalizeUrl(request.url);
              return NavigationDecision.navigate;
            } on FormatException {
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(normalizeUrl(widget.url)));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await _controller.canGoBack()) {
        await _controller.goBack();
      } else if (context.mounted) {
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Abrir externamente',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              try {
                final current = normalizeUrl(
                  await _controller.currentUrl() ?? widget.url,
                );
                if (!await launchUrl(
                  Uri.parse(current),
                  mode: LaunchMode.externalApplication,
                )) {
                  throw StateError('Launch failed');
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível abrir o navegador.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => _controller.reload(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    ),
  );
}
