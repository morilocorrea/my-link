import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Exibe o logotipo vetorial SVG do MyLink com tintura adaptável ao tema.
class MyLinkLogo extends StatelessWidget {
  const MyLinkLogo({
    super.key,
    this.size = 48,
    this.color,
    this.semanticsLabel = 'MyLink Logo',
  });

  final double size;
  final Color? color;
  final String semanticsLabel;

  static const String assetPath = 'assets/icons/logo-mylink.svg';

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryOf(context);
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      semanticsLabel: semanticsLabel,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}

/// Contêiner com fundo secundário e logotipo centralizado do MyLink,
/// usado na tela de boas-vindas, cabeçalho da gaveta e diálogo "Sobre".
class MyLinkLogoBadge extends StatelessWidget {
  const MyLinkLogoBadge({
    super.key,
    this.size = 48,
    this.iconSize,
    this.borderRadius = 14,
  });

  final double size;
  final double? iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondary = isDark ? AppColors.secondaryDark : AppColors.secondary;
    final resolvedIconSize = iconSize ?? (size * 0.58);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: MyLinkLogo(
        size: resolvedIconSize,
        color: primary,
      ),
    );
  }
}
