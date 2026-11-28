// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'ModelAiIcons.dart';
import 'ModelAiSurfaces.dart';

/// Three-or-more stage progress strip used by account authorization pages.
///
/// `current` is zero-based: steps before it are complete, the step at `current`
/// is active, and later steps are pending. Set `failedAt` to mark one step as
/// failed without losing the completed steps before it.
class ModelAiSteps extends StatelessWidget {
  const ModelAiSteps({
    super.key,
    required this.labels,
    required this.current,
    this.failedAt,
  }) : assert(labels.length > 1, 'Use at least two steps');

  final List<String> labels;
  final int current;
  final int? failedAt;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var index = 0; index < labels.length; index++) ...<Widget>[
              if (index > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 1,
                    color: index <= current
                        ? palette.success.withValues(alpha: 0.55)
                        : palette.border,
                  ),
                ),
              _dot(context, index),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: index == current
                        ? palette.text
                        : index < current
                        ? palette.success
                        : palette.textTertiary,
                    fontWeight: index == current
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dot(BuildContext context, int index) {
    final palette = ModelAiPalette.of(context);
    final failed = failedAt == index;
    final done = !failed && index < current;
    final active = !failed && index == current;
    final background = failed
        ? palette.danger.withValues(alpha: 0.14)
        : done
        ? palette.success.withValues(alpha: 0.14)
        : active
        ? palette.accent
        : palette.inset;
    final foreground = failed
        ? palette.danger
        : done
        ? palette.success
        : active
        ? Theme.of(context).colorScheme.onPrimary
        : palette.textTertiary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: active
            ? Border.all(
                color: palette.accent.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: failed
          ? Icon(ModelAiIcons.close, size: 12, color: foreground)
          : done
          ? Icon(ModelAiIcons.check, size: 12, color: foreground)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    );
  }
}
