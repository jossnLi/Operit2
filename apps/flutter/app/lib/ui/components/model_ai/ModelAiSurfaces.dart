// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../theme/OperitGlassSurface.dart';
import 'ModelAiIcons.dart';

/// Shared rhythm for every model and AI surface.
///
/// Keeping these numbers here makes the module read as one product instead of
/// six pages that each picked their own card inset.
abstract final class ModelAiMetrics {
  static const double pagePadding = 20;
  static const double maxContentWidth = 880;
  static const double sectionGap = 24;
  static const double cardRadius = 20;
  static const double cardPadding = 16;
  static const double rowHorizontal = 14;
  static const double rowVertical = 14;
  static const double iconSize = 36;
  static const double iconRadius = 11;
}

/// Resolved colors for the model and AI surfaces.
///
/// Surfaces intentionally come from the live [ColorScheme] so the module
/// follows custom palettes, transparent-surface settings and both brightnesses.
class ModelAiPalette {
  const ModelAiPalette({
    required this.background,
    required this.group,
    required this.inset,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentTint,
    required this.success,
    required this.warning,
    required this.danger,
  });

  factory ModelAiPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ModelAiPalette(
      background: scheme.surface,
      // One step above the page, so grouped cards have a readable edge in both
      // themes without falling back to a hard-coded grey.
      group: scheme.surfaceContainerHigh,
      inset: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant,
      text: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      textTertiary: scheme.onSurfaceVariant.withValues(alpha: 0.68),
      accent: scheme.primary,
      accentTint: scheme.primaryContainer,
      // Material has no semantic success/warning role; these stay functional
      // colors while everything structural follows the configured scheme.
      success: dark ? const Color(0xFF6ED79A) : const Color(0xFF11845B),
      warning: dark ? const Color(0xFFE6B45B) : const Color(0xFF9A6700),
      danger: scheme.error,
    );
  }

  final Color background;
  final Color group;
  final Color inset;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentTint;
  final Color success;
  final Color warning;
  final Color danger;

  double get cardRadius => ModelAiMetrics.cardRadius;
}

/// Shared page frame for every full-screen model and AI surface.
///
/// The app bar is transparent and elevation-free so the wallpaper and the
/// configured surface treatment run edge to edge instead of ending at a flat
/// grey band under the title.
class ModelAiPageScaffold extends StatelessWidget {
  const ModelAiPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.leading,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: palette.border.withValues(alpha: 0.32),
          ),
        ),
        leading:
            leading ??
            IconButton(
              tooltip: '返回',
              icon: const Icon(ModelAiIcons.back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: <Widget>[...actions, const SizedBox(width: 8)],
      ),
      body: body,
    );
  }
}

/// Floating action footer shared by full-screen editors.
///
/// It deliberately uses the same glass surface as the page cards instead of an
/// opaque scaffold colour, so light and transparent-surface themes keep the
/// wallpaper visible and the footer readable.
class ModelAiBottomBar extends StatelessWidget {
  const ModelAiBottomBar({super.key, required this.child, this.hint});

  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: OperitGlassSurface(
          color: palette.group,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border.withValues(alpha: 0.5)),
          layer: OperitGlassSurfaceLayer.card,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (hint != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
                    child: Text(
                      hint!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A grouped settings card with an optional title and trailing action.
///
/// The card is rendered through [OperitGlassSurface] so the wallpaper and the
/// "transparent surface" preference keep working instead of being covered by
/// an opaque panel.
class ModelAiSection extends StatelessWidget {
  const ModelAiSection({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(ModelAiMetrics.cardPadding),
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: palette.textTertiary,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(width: 8),
                  action!,
                ],
              ],
            ),
          ),
        OperitGlassSurface(
          color: palette.group,
          borderRadius: BorderRadius.circular(ModelAiMetrics.cardRadius),
          border: Border.all(color: palette.border.withValues(alpha: 0.52)),
          layer: OperitGlassSurfaceLayer.card,
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}

/// A single settings row with an optional semantic icon tile or custom leading.
class ModelAiRow extends StatelessWidget {
  const ModelAiRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.tone = ModelAiIconTone.neutral,
    this.enabled = true,
    this.dense = false,
    this.leading,
    this.titleTrailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final ModelAiIconTone tone;
  final bool enabled;
  final bool dense;

  /// Replaces the icon tile with an official provider logo or another leading.
  final Widget? leading;

  /// Small widget kept on the title line, such as a "默认" badge.
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ModelAiMetrics.rowHorizontal,
        vertical: dense ? 10 : ModelAiMetrics.rowVertical,
      ),
      child: Row(
        children: <Widget>[
          leading ?? ModelAiIconTile(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: enabled ? palette.text : palette.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...<Widget>[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.38,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 10),
            trailing!,
          ],
          if (showChevron && onTap != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(ModelAiIcons.chevron, size: 18, color: palette.textTertiary),
          ],
        ],
      ),
    );
    if (onTap == null || !enabled) {
      return content;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: content,
    );
  }
}

/// Semantic icon background roles shared by every model and AI page.
enum ModelAiIconTone { neutral, blue, green, amber, red }

class ModelAiIconTile extends StatelessWidget {
  const ModelAiIconTile({
    super.key,
    required this.icon,
    this.tone = ModelAiIconTone.neutral,
    this.size = ModelAiMetrics.iconSize,
  });

  final IconData icon;
  final ModelAiIconTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final foreground = switch (tone) {
      ModelAiIconTone.blue => palette.accent,
      ModelAiIconTone.green => palette.success,
      ModelAiIconTone.amber => palette.warning,
      ModelAiIconTone.red => palette.danger,
      ModelAiIconTone.neutral => palette.textSecondary,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.inset.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(ModelAiMetrics.iconRadius),
        border: Border.all(color: palette.border.withValues(alpha: 0.42)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

/// Compact status label used for connection, plan and validation results.
///
/// Tags and badges are text-only: an icon inside a pill adds noise and makes
/// short states read like buttons.
class ModelAiStatusPill extends StatelessWidget {
  const ModelAiStatusPill({
    super.key,
    required this.label,
    this.tone = ModelAiStatusTone.neutral,
    this.compact = false,
  });

  final String label;
  final ModelAiStatusTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final (background, foreground) = switch (tone) {
      ModelAiStatusTone.success => (
        palette.success.withValues(alpha: 0.13),
        palette.success,
      ),
      ModelAiStatusTone.warning => (
        palette.warning.withValues(alpha: 0.13),
        palette.warning,
      ),
      ModelAiStatusTone.danger => (
        palette.danger.withValues(alpha: 0.12),
        palette.danger,
      ),
      ModelAiStatusTone.accent => (palette.accentTint, palette.accent),
      ModelAiStatusTone.neutral => (
        palette.inset.withValues(alpha: 0.72),
        palette.textSecondary,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum ModelAiStatusTone { neutral, success, warning, danger, accent }

/// Inline error surface for load failures without a modal dialog.
class ModelAiInlineError extends StatelessWidget {
  const ModelAiInlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(ModelAiIcons.error, color: palette.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.danger,
                height: 1.4,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// In-page destructive confirmation; keeps destructive actions out of dialogs.
class ModelAiInlineConfirm extends StatelessWidget {
  const ModelAiInlineConfirm({
    super.key,
    required this.title,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
    this.confirmLabel = '确认',
  });

  final String title;
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.danger.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(ModelAiIcons.warning, size: 18, color: palette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: onCancel, child: const Text('取消')),
              const SizedBox(width: 6),
              FilledButton.tonal(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.danger.withValues(alpha: 0.14),
                  foregroundColor: palette.danger,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact quick-action tile used by the overview grid.
class ModelAiToolTile extends StatelessWidget {
  const ModelAiToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.tone = ModelAiIconTone.neutral,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ModelAiIconTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return OperitGlassSurface(
      color: palette.group,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: palette.border.withValues(alpha: 0.48)),
      layer: OperitGlassSurfaceLayer.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ModelAiIconTile(icon: icon, tone: tone, size: 34),
                  const Spacer(),
                  Icon(
                    ModelAiIcons.chevron,
                    size: 16,
                    color: palette.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small label + value block for metadata inside a page.
class ModelAiMeta extends StatelessWidget {
  const ModelAiMeta({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: palette.textTertiary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.text, height: 1.4),
        ),
      ],
    );
  }
}
