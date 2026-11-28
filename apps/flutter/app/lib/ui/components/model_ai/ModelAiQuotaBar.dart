// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'ModelAiSurfaces.dart';

/// A compact quota meter with label, value and a six-pixel track.
///
/// The bar turns amber from 75% and red from 90% unless the caller supplies an
/// explicit tone, so plan and rate-limit surfaces share one visual language.
class ModelAiQuotaBar extends StatelessWidget {
  const ModelAiQuotaBar({
    super.key,
    required this.label,
    required this.ratio,
    this.valueText,
    this.tone = ModelAiQuotaTone.auto,
  });

  final String label;

  /// Normalized usage in the 0.0–1.0 range.
  final double ratio;
  final String? valueText;
  final ModelAiQuotaTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final value = ratio.isFinite ? ratio.clamp(0.0, 1.0) : 0.0;
    final resolved = tone == ModelAiQuotaTone.auto
        ? value >= 0.9
              ? ModelAiQuotaTone.danger
              : value >= 0.75
              ? ModelAiQuotaTone.warning
              : ModelAiQuotaTone.normal
        : tone;
    final color = switch (resolved) {
      ModelAiQuotaTone.normal || ModelAiQuotaTone.auto => palette.accent,
      ModelAiQuotaTone.warning => palette.warning,
      ModelAiQuotaTone.danger => palette.danger,
    };
    final secondary = valueText ?? '${(value * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              secondary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: palette.inset),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum ModelAiQuotaTone { auto, normal, warning, danger }
