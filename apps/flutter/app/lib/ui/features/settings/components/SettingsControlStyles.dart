// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
abstract final class SettingsControlStyles {
  static const Size activePillSize = Size(78, 28);
  static const Size sectionIconButtonSize = Size(32, 32);
  static const Size entityIconButtonSize = Size(32, 32);

  static TextStyle sectionTitleTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700);
  }

  static ButtonStyle sectionTextButton() {
    return TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  static ButtonStyle sectionFilledButton() {
    return FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    );
  }

  static ButtonStyle activeTextButton() {
    return TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: activePillSize,
      fixedSize: activePillSize,
      padding: EdgeInsets.zero,
    );
  }

  static TextStyle activeTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700);
  }

  static ButtonStyle entityIconButton() {
    return IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: entityIconButtonSize,
      fixedSize: entityIconButtonSize,
      padding: EdgeInsets.zero,
      iconSize: 20,
    );
  }
}

class SettingsActivePill extends StatelessWidget {
  const SettingsActivePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: SettingsControlStyles.activePillSize.width,
      height: SettingsControlStyles.activePillSize.height,
      decoration: ShapeDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
          colorScheme.surfaceContainerHigh,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.30 : 0.32),
            width: 0.8,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: SettingsControlStyles.activeTextStyle(context).copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSetActiveButton extends StatelessWidget {
  const SettingsSetActiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: SettingsControlStyles.activePillSize.width,
      height: SettingsControlStyles.activePillSize.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.28 : 0.45,
            ),
            width: 0.8,
          ),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SettingsControlStyles.activeTextStyle(context).copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class SettingsEntityIconButton extends StatelessWidget {
  const SettingsEntityIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tight(
        SettingsControlStyles.entityIconButtonSize,
      ),
      padding: EdgeInsets.zero,
      iconSize: 20,
      style: SettingsControlStyles.entityIconButton(),
      icon: Icon(icon),
    );
  }
}

class SettingsEntityPopupIconButton<T> extends StatelessWidget {
  const SettingsEntityPopupIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onSelected,
    required this.itemBuilder,
  });

  final String tooltip;
  final IconData icon;
  final PopupMenuItemSelected<T> onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      icon: Icon(icon),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tight(
        SettingsControlStyles.entityIconButtonSize,
      ),
      style: SettingsControlStyles.entityIconButton(),
    );
  }
}

class SettingsSectionAddButton extends StatelessWidget {
  const SettingsSectionAddButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.label = '添加',
    this.icon = OperitIcons.add_rounded,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.35 : 0.45,
            ),
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Container(
            height: 26,
            padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 13,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsInfoBadge extends StatelessWidget {
  const SettingsInfoBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: dense ? 4 : 8,
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.82,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueText,
    required this.onChanged,
    this.onChangeEnd,
    this.icon,
    this.compact = false,
    this.activeColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueText;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final IconData? icon;
  final bool compact;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              SettingsInfoBadge(label: valueText),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: activeColor ?? colorScheme.primary,
              thumbColor: activeColor ?? colorScheme.primary,
              inactiveTrackColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsToggleChip extends StatelessWidget {
  const SettingsToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chipColor = selected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.10)
        : (isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
              : colorScheme.surfaceContainerHigh.withValues(alpha: 0.55));
    final chipBorderColor = selected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.60 : 0.40)
        : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.36);
    final chipForeground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final child = Material(
      color: chipColor,
      shape: StadiumBorder(
        side: BorderSide(color: chipBorderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelected(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: chipForeground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: chipForeground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}


class SettingsSegmentedSelector<T> extends StatelessWidget {
  const SettingsSegmentedSelector({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.hasSelection = true,
    this.dense = false,
    this.expand = false,
  });

  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool hasSelection;

  /// Tightens type and icon sizes so the control fits a crowded action row.
  final bool dense;

  /// Stretches the track to the full available width so the thumb can slide.
  /// Leave it false inside toolbars and aligned rows, where the control keeps
  /// its intrinsic width and animates the fill colour instead.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!expand ||
            !constraints.hasBoundedWidth ||
            constraints.maxWidth < _minTrackWidth) {
          return _SettingsSegmentedFallback<T>(
            value: value,
            segments: segments,
            onChanged: onChanged,
            hasSelection: hasSelection,
            dense: dense,
          );
        }
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final trackHeight = dense ? 32.0 : 36.0;
        final padding = dense ? 2.5 : 3.0;
        final count = segments.length;
        final selectedIndex = hasSelection
            ? segments.indexWhere((segment) => segment.value == value)
            : -1;
        final segmentWidth = (constraints.maxWidth - padding * 2) / count;

        return Container(
          height: trackHeight,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.34)
                : colorScheme.onSurface.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.24 : 0.34,
              ),
              width: 1,
            ),
          ),
          child: Stack(
            children: <Widget>[
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: padding + segmentWidth * selectedIndex,
                  top: padding,
                  width: segmentWidth,
                  height: trackHeight - padding * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.42 : 0.24,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < count; i++)
                      Expanded(
                        child: _SettingsSegmentButton<T>(
                          segment: segments[i],
                          selected: i == selectedIndex,
                          dense: dense,
                          onTap: () => onChanged(segments[i].value),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const double _minTrackWidth = 120;

/// One tap target of [SettingsSegmentedSelector], rendered on top of the
/// sliding thumb so the thumb never intercepts pointer events.
class _SettingsSegmentButton<T> extends StatelessWidget {
  const _SettingsSegmentButton({
    required this.segment,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final ButtonSegment<T> segment;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final label = segment.label ?? Text(segment.value.toString());
    final icon = segment.icon;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: segment.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: dense ? 13 : 14),
              child: DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: dense ? 11.5 : 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      ExcludeSemantics(child: icon),
                      SizedBox(width: dense ? 4 : 6),
                    ],
                    Flexible(child: label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Intrinsic-width variant used where the parent gives no measurable width
/// (toolbars, [Wrap] rows), where a sliding thumb cannot be positioned.
class _SettingsSegmentedFallback<T> extends StatelessWidget {
  const _SettingsSegmentedFallback({
    required this.value,
    required this.segments,
    required this.onChanged,
    required this.hasSelection,
    required this.dense,
  });

  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool hasSelection;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastIndex = segments.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < segments.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == lastIndex ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: hasSelection && segments[i].value == value
                    ? colorScheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.11,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: hasSelection && segments[i].value == value
                      ? colorScheme.primary.withValues(alpha: 0.24)
                      : Colors.transparent,
                ),
              ),
              child: _SettingsSegmentButton<T>(
                segment: segments[i],
                selected: hasSelection && segments[i].value == value,
                dense: dense,
                onTap: () => onChanged(segments[i].value),
              ),
            ),
          ),
      ],
    );
  }
}
