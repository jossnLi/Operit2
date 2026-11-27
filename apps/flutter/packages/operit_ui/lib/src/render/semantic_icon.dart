import 'package:flutter/material.dart';

/// 语义强度：调用方只说“这枚图标是主色、辅色、提示色还是中性灰”，
/// 具体色值一律从当前主题配色取，换主题、切深色都不需要改调用点。
enum OperitIconTone {
  /// 主色，用于主操作、当前页主标识。
  accent,

  /// 第二强调色，用于并列的另一类对象。
  secondary,

  /// 提示色，用于第三类对象或次要强调。
  tertiary,

  /// 中性，用于与文字同权的普通图标。
  neutral,

  /// 弱化，用于“成功/已完成”这类只需要被看见、不需要被注意的状态。
  muted,
}

/// 图标尺寸阶梯，避免各页面各写一个魔法数字。
abstract final class OperitIconSizes {
  /// 行内小图标，跟在文字前面。
  static const double inline = 14;

  /// 列表行前缀图标。
  static const double list = 20;

  /// 浮层/卡片里的极小标记。
  static const double marker = 11;

  /// 徽章里的图标。
  static const double badge = 12;

  /// 主题未指定时的兜底尺寸，与 Material 默认一致。
  static const double fallback = 20;
}

/// 主题感知的语义图标。
///
/// 颜色默认由 [OperitIconTone] 映射到 `colorScheme` 的角色色；如果外层
/// `IconTheme` 已经给了颜色（主题配置统一染色时常见），以外层为准，所以在
/// 深色、自定义主题色、透明底主题下都能跟随，而不会写死成某个色值。
/// 尺寸同理：优先吃 `IconTheme.size`，调用方只在确实需要不同档位时才传。
class OperitSemanticIcon extends StatelessWidget {
  const OperitSemanticIcon(
    this.icon, {
    super.key,
    this.tone = OperitIconTone.neutral,
    this.size,
  });

  final IconData icon;
  final OperitIconTone tone;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconTheme = IconTheme.of(context);
    final toneColor = switch (tone) {
      OperitIconTone.accent => scheme.primary,
      OperitIconTone.secondary => scheme.secondary,
      OperitIconTone.tertiary => scheme.tertiary,
      OperitIconTone.neutral => scheme.onSurfaceVariant,
      OperitIconTone.muted => scheme.onSurfaceVariant.withValues(alpha: 0.55),
    };
    return Icon(
      icon,
      size: size ?? iconTheme.size ?? OperitIconSizes.fallback,
      color: iconTheme.color ?? toneColor,
    );
  }
}
