import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget de exibição de anúncio em Banner do Google AdMob.
///
/// Segue o mesmo padrão arquitetural, de resiliência e UX do aplicativo
/// Private Tasks:
/// - Em [kDebugMode], utiliza automaticamente os IDs de teste oficiais do Google,
///   prevenindo infrações por cliques inválidos durante o desenvolvimento.
/// - Em modo de produção / Release, utiliza o Ad Unit ID oficial da conta AdMob.
/// - Oculta-se automaticamente ([SizedBox.shrink]) quando o teclado virtual é aberto
///   para evitar sobreposições e quebras de layout.
/// - Trata falhas de conectividade, ausência de Google Play Services ou plataformas
///   sem suporte nativo através de blocos `try/catch` síncronos e assíncronos.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adUnitId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  /// Permite especificar explicitamente um ID de bloco de anúncio.
  /// Caso não seja informado, resolve automaticamente entre o ID de teste
  /// (em [kDebugMode]) e o ID de produção configurado.
  final String? adUnitId;

  /// Callback acionado quando o anúncio for carregado e renderizado com sucesso.
  final VoidCallback? onAdLoaded;

  /// Callback acionado caso o carregamento falhe.
  final VoidCallback? onAdFailedToLoad;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // IDs de Teste Oficiais do Google (https://developers.google.com/admob/android/test-ads)
  static const String _testAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testAdUnitIdiOS =
      'ca-app-pub-3940256099942544/2934735716';

  // ID de Produção do bloco de banner do MyLink
  static const String _defaultProdAdUnitId =
      'ca-app-pub-1478542054095233/6685912904';

  /// Resolve o identificador do bloco de anúncios adequado para o ambiente.
  String get resolvedAdUnitId {
    if (widget.adUnitId != null && widget.adUnitId!.isNotEmpty) {
      return widget.adUnitId!;
    }
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? _testAdUnitIdiOS
          : _testAdUnitIdAndroid;
    }
    return const String.fromEnvironment(
      'ADMOB_BANNER_AD_UNIT_ID',
      defaultValue: _defaultProdAdUnitId,
    );
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!_isSupportedPlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onAdFailedToLoad?.call();
        }
      });
      return;
    }

    try {
      final ad = BannerAd(
        adUnitId: resolvedAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoaded = true;
                });
                widget.onAdLoaded?.call();
              }
            });
          },
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoaded = false;
                  _bannerAd = null;
                });
                widget.onAdFailedToLoad?.call();
              }
            });
          },
        ),
      );

      _bannerAd = ad;
      await ad.load();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar o BannerAd (AdMob): $e\n$stack');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoaded = false;
            _bannerAd = null;
          });
          widget.onAdFailedToLoad?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Esconde o banner quando o teclado virtual está aberto para evitar sobreposições
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_isLoaded && _bannerAd != null && !keyboardOpen) {
      return SafeArea(
        top: false,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
