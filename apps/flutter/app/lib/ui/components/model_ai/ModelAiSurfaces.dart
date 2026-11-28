// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/ui/common/icons/operit_icons.dart';

/// Resolved colors for the model and AI surfaces.
///
/// The page uses the app's color scheme rather than hard-coded design tokens so
/// custom themes keep working, while grouping, insets and status colors stay
/// consistent with the high-fidelity specification.
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
      group: dark ? const Color(0xFF18181A) : scheme.surfaceContainerLow,
      inset: dark ? const Color(0xFF202023) : scheme.surfaceContainerHighest,
      border: dark ? const Color(0xFF2A2B2E) : scheme.outlineVariant,
      text: scheme.onSurface,
      textSecondary: dark ? const Color(0xFFA0A1A7) : scheme.onSurfaceVariant,
      textTertiary: dark ? const Color(0xFF87888F) : scheme.onSurfaceVariant,
      accent: scheme.primary,
      accentTint: dark ? const Color(0xFF182339) : scheme.primaryContainer,
      success: dark ? const Color(0xFF5CC98A) : const Color(0xFF11845B),
      warning: dark ? const Color(0xFFE0A544) : const Color(0xFF9A6700),
      danger: dark ? const Color(0xFFF0808E) : const Color(0xFFC0392B),
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
}

/// A grouped settings card with an optional title and trailing action.
class ModelAiSection extends StatelessWidget {
  const ModelAiSection({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.group,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border.withValues(alpha: 0.7)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}

/// A single settings row with semantic icon tile, subtitle and trailing widget.
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

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: dense ? 10 : 13),
      child: Row(
        children: <Widget>[
          ModelAiIconTile(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled ? palette.text : palette.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.35,
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
            Icon(
              OperitIcons.chevron_right_rounded,
              size: 18,
              color: palette.textTertiary,
            ),
          ],
        ],
      ),
    );
    if (onTap == null || !enabled) {
      return content;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
    this.size = 34,
  });

  final IconData icon;
  final ModelAiIconTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final (background, foreground) = switch (tone) {
      ModelAiIconTone.blue => (palette.accentTint, palette.accent),
      ModelAiIconTone.green => (
        palette.success.withValues(alpha: 0.14),
        palette.success,
      ),
      ModelAiIconTone.amber => (
        palette.warning.withValues(alpha: 0.14),
        palette.warning,
      ),
      ModelAiIconTone.red => (
        palette.danger.withValues(alpha: 0.14),
        palette.danger,
      ),
      ModelAiIconTone.neutral => (palette.inset, palette.textSecondary),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.53, color: foreground),
    );
  }
}

/// Compact status label used for connection, plan and validation results.
class ModelAiStatusPill extends StatelessWidget {
  const ModelAiStatusPill({
    super.key,
    required this.label,
    this.tone = ModelAiStatusTone.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final ModelAiStatusTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final (background, foreground) = switch (tone) {
      ModelAiStatusTone.success => (
        palette.success.withValues(alpha: 0.14),
        palette.success,
      ),
      ModelAiStatusTone.warning => (
        palette.warning.withValues(alpha: 0.14),
        palette.warning,
      ),
      ModelAiStatusTone.danger => (
        palette.danger.withValues(alpha: 0.14),
        palette.danger,
      ),
      ModelAiStatusTone.accent => (palette.accentTint, palette.accent),
      ModelAiStatusTone.neutral => (palette.inset, palette.textSecondary),
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
          if (icon != null) ...<Widget>[
            Icon(icon, size: compact ? 11 : 13, color: foreground),
            const SizedBox(width: 4),
          ],
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
        color: palette.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            OperitIcons.error_outline_rounded,
            color: palette.danger,
            size: 18,
          ),
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

/// Footer action with a trailing chevron, used for the legacy entry.
class ModelAiNavRow extends StatelessWidget {
  const ModelAiNavRow({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.tone = ModelAiIconTone.neutral,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final ModelAiIconTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ModelAiIconTile(icon: icon!, tone: tone, size: 30),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
              ),
            ),
            Icon(
              OperitIcons.chevron_right_rounded,
              color: palette.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
