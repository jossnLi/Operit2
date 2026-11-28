// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:operit_ui/operit_ui.dart';

/// Maps provider type IDs to their bundled brand logo assets.
const Map<String, String> providerLogoAssets = <String, String>{
  'ALIPAY_BAILING': 'assets/model_logos/ALIPAY_BAILING.svg',
  'ALIYUN': 'assets/model_logos/ALIYUN.svg',
  'ANTHROPIC': 'assets/model_logos/ANTHROPIC.svg',
  'ANTHROPIC_CLAUDE': 'assets/model_logos/ANTHROPIC.svg',
  'ANTHROPIC_GENERIC': 'assets/model_logos/ANTHROPIC_GENERIC.svg',
  'BAICHUAN': 'assets/model_logos/BAICHUAN.svg',
  'BAIDU': 'assets/model_logos/BAIDU.svg',
  'DEEPSEEK': 'assets/model_logos/DEEPSEEK.svg',
  'DOUBAO': 'assets/model_logos/DOUBAO.svg',
  'FOUR_ROUTER': 'assets/model_logos/FOUR_ROUTER.svg',
  'GEMINI_GENERIC': 'assets/model_logos/GEMINI_GENERIC.svg',
  'GOOGLE': 'assets/model_logos/GOOGLE.svg',
  'INFINIAI': 'assets/model_logos/INFINIAI.png',
  'LMSTUDIO': 'assets/model_logos/LMSTUDIO.svg',
  'MIMO': 'assets/model_logos/MIMO.svg',
  'MINIMAX': 'assets/model_logos/MINIMAX.svg',
  'MISTRAL': 'assets/model_logos/MISTRAL.svg',
  'MOONSHOT': 'assets/model_logos/MOONSHOT.svg',
  'NOUS_PORTAL': 'assets/model_logos/NOUS_PORTAL.svg',
  'NOVITA': 'assets/model_logos/NOVITA.svg',
  'NVIDIA': 'assets/model_logos/NVIDIA.svg',
  'OLLAMA': 'assets/model_logos/OLLAMA.svg',
  'OPENAI': 'assets/model_logos/OPENAI.svg',
  'OPENAI_CODEX': 'assets/model_logos/OPENAI_CODEX.svg',
  'OPENAI_GENERIC': 'assets/model_logos/OPENAI_GENERIC.svg',
  'OPENAI_LOCAL': 'assets/model_logos/OPENAI_LOCAL.svg',
  'OPENAI_RESPONSES': 'assets/model_logos/OPENAI_RESPONSES.svg',
  'OPENAI_RESPONSES_GENERIC': 'assets/model_logos/OPENAI_RESPONSES_GENERIC.svg',
  'OPENCODE': 'assets/model_logos/OPENCODE.svg',
  'OPENROUTER': 'assets/model_logos/OPENROUTER.svg',
  'PPINFRA': 'assets/model_logos/PPINFRA.svg',
  'SILICONFLOW': 'assets/model_logos/SILICONFLOW.svg',
  'XAI': 'assets/model_logos/XAI.svg',
  'XUNFEI': 'assets/model_logos/XUNFEI.svg',
  'ZHIPU': 'assets/model_logos/ZHIPU.svg',
};

/// Logos that carry brand colors and keep them in both themes.
const Set<String> _coloredLogoProviderTypeIds = <String>{
  'FOUR_ROUTER',
  'INFINIAI',
};

/// Official primary colors for monochrome provider marks.
///
/// The bundled SVGs are single-path files without fills. Model and AI surfaces
/// opt into these brand colors so DeepSeek stays blue and Claude stays orange
/// instead of every logo inheriting `onSurface`.
const Map<String, Color> providerLogoBrandColors = <String, Color>{
  'ALIYUN': Color(0xFFFF6A00),
  'ANTHROPIC': Color(0xFFD97757),
  'ANTHROPIC_CLAUDE': Color(0xFFD97757),
  'ANTHROPIC_GENERIC': Color(0xFFD97757),
  'BAICHUAN': Color(0xFF1F6BFF),
  'BAIDU': Color(0xFF2932E1),
  'DEEPSEEK': Color(0xFF4D6BFE),
  'DOUBAO': Color(0xFF2F6BFF),
  'GEMINI_GENERIC': Color(0xFF4285F4),
  'GOOGLE': Color(0xFF4285F4),
  'MINIMAX': Color(0xFFE7355C),
  'MISTRAL': Color(0xFFFF7000),
  'MOONSHOT': Color(0xFF111111),
  'OPENAI': Color(0xFF10A37F),
  'OPENAI_CODEX': Color(0xFF10A37F),
  'OPENAI_GENERIC': Color(0xFF10A37F),
  'OPENAI_LOCAL': Color(0xFF10A37F),
  'OPENAI_RESPONSES': Color(0xFF10A37F),
  'OPENAI_RESPONSES_GENERIC': Color(0xFF10A37F),
  'OPENROUTER': Color(0xFF6C5CE7),
  'SILICONFLOW': Color(0xFF6C5CE7),
  'XAI': Color(0xFF111111),
  'XUNFEI': Color(0xFF1A6EFF),
  'ZHIPU': Color(0xFF3859FF),
};

/// Renders a provider logo with an optional circular container and initial fallback.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    required this.providerTypeId,
    required this.fallbackName,
    this.size = 42,
    this.contentScale = 0.62,
    this.showBackdrop = true,
    this.preserveBrandColor = false,
  });

  final String providerTypeId;
  final String fallbackName;
  final double size;
  final double contentScale;
  final bool showBackdrop;

  /// Uses the official brand tint when one is declared.
  ///
  /// Off by default so dense lists that rely on a monochrome glyph language
  /// keep their existing appearance.
  final bool preserveBrandColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final asset = providerLogoAssets[providerTypeId];
    final glyphSize = showBackdrop ? size * contentScale : size;
    final brandColor = preserveBrandColor
        ? _resolvedBrandColor(context, providerTypeId)
        : null;
    final child = asset == null
        ? _ProviderLogoInitial(name: fallbackName, size: glyphSize)
        : _ProviderLogoAsset(
            asset: asset,
            providerTypeId: providerTypeId,
            size: glyphSize,
            brandColor: brandColor,
          );
    if (!showBackdrop) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Renders an exact provider brand for message identity without substituting another avatar.
class ProviderIdentityLogo extends StatelessWidget {
  /// Creates a message logo using the configured provider's actual type identifier.
  const ProviderIdentityLogo({
    super.key,
    required this.providerTypeId,
    required this.size,
  });

  final String providerTypeId;
  final double size;

  /// Requires a declared logo and shares the settings renderer's brand color policy.
  @override
  Widget build(BuildContext context) {
    final asset = providerLogoAssets[providerTypeId];
    if (asset == null) {
      throw StateError('Provider logo is not declared: $providerTypeId');
    }
    return Center(
      child: _ProviderLogoAsset(
        asset: asset,
        providerTypeId: providerTypeId,
        size: size * 0.75,
      ),
    );
  }
}

class _ProviderLogoAsset extends StatelessWidget {
  const _ProviderLogoAsset({
    required this.asset,
    required this.providerTypeId,
    required this.size,
    this.brandColor,
  });

  final String asset;
  final String providerTypeId;
  final double size;
  final Color? brandColor;

  @override
  Widget build(BuildContext context) {
    final monochromeTint = _coloredLogoProviderTypeIds.contains(providerTypeId)
        ? null
        : brandColor != null
        ? ColorFilter.mode(brandColor!, BlendMode.srcIn)
        : ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          );
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        colorFilter: monochromeTint,
      );
    }
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
    return monochromeTint == null
        ? image
        : ColorFiltered(colorFilter: monochromeTint, child: image);
  }
}

/// Keeps dark brand marks readable in the dark theme without tinting them white
/// for every surface that has not opted into brand colors.
Color? _resolvedBrandColor(BuildContext context, String providerTypeId) {
  final brand = providerLogoBrandColors[providerTypeId];
  if (brand == null) {
    return null;
  }
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (dark && brand.computeLuminance() < 0.2) {
    return Theme.of(context).colorScheme.onSurface;
  }
  return brand;
}

class _ProviderLogoInitial extends StatelessWidget {
  const _ProviderLogoInitial({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    return ThemeComposerProviderInitial(
      initial: initial.toUpperCase(),
      size: size,
    );
  }
}
