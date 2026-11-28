// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import '../../../../l10n/generated/app_localizations.dart';
import '../viewmodel/ChatViewModel.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'tool_permission_risk.dart';

/// Inline approval surface for one pending tool call.
///
/// Layout follows four layers: who is asking, what it touches, what can go
/// wrong, and which decisions are safe to offer. The offered options shrink
/// as the risk grows — a high-risk call never shows a session-wide approval.
class ChatToolPermissionPanel extends StatefulWidget {
  /// Creates the inline permission state surface for one chat.
  const ChatToolPermissionPanel({
    super.key,
    required this.request,
    required this.onRespond,
    this.pendingCount = 1,
  });

  final core_proxy.RuntimeHostInteractionToolPermissionRequest request;
  final Future<void> Function(
    String chatId,
    String requestId,
    ChatToolPermissionResult result,
  )
  onRespond;

  /// Requests queued behind the visible one; only the head is rendered.
  final int pendingCount;

  @override
  State<ChatToolPermissionPanel> createState() =>
      _ChatToolPermissionPanelState();
}

class _ChatToolPermissionPanelState extends State<ChatToolPermissionPanel> {
  bool _submitting = false;
  bool _parametersExpanded = false;

  @override
  void didUpdateWidget(covariant ChatToolPermissionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.requestId != widget.request.requestId ||
        oldWidget.request.chatId != widget.request.chatId) {
      _submitting = false;
      _parametersExpanded = false;
    }
  }

  /// Sends one decision for the request displayed by this chat.
  Future<void> _respond(ChatToolPermissionResult result) async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    final request = widget.request;
    try {
      await widget.onRespond(request.chatId, request.requestId, result);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'chat tool permission panel',
          context: ErrorDescription('responding to chat tool permission'),
        ),
      );
      if (mounted &&
          widget.request.requestId == request.requestId &&
          widget.request.chatId == request.chatId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failed}: $error'),
          ),
        );
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assessment = assessToolPermission(widget.request);
    final accent = _riskColor(colorScheme, assessment.risk);
    final isDark = theme.brightness == Brightness.dark;
    final surface = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.10 : 0.07),
      colorScheme.surface,
    );

    final parameters = widget.request.tool.parameters
        .where(
          (parameter) =>
              parameter.name != '__operit_package_caller_name' &&
              parameter.name != '__operit_package_chat_id' &&
              parameter.name != '__operit_package_caller_card_id',
        )
        .toList(growable: false);

    return Semantics(
      container: true,
      label: '工具权限请求：${assessment.actionLabel}，${assessment.riskLabel}，需要你确认',
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 6, 0, 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.42 : 0.30),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
              child: Row(
                children: <Widget>[
                  Icon(assessment.icon, size: 18, color: accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${l10n.toolApprovalTitle} · ${assessment.actionLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RiskPill(
                    label: assessment.riskLabel,
                    color: accent,
                    risk: assessment.risk,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                widget.request.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (assessment.objects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _ObjectList(
                  objects: assessment.objects,
                  hiddenCount: assessment.hiddenObjectCount,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      assessment.risk == ToolPermissionRisk.low
                          ? OperitIcons.visibility_outlined
                          : OperitIcons.warning_amber_rounded,
                      size: 13,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assessment.consequence,
                      style: theme.textTheme.labelSmall?.copyWith(
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (parameters.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 0),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _parametersExpanded = !_parametersExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                  icon: Icon(
                    _parametersExpanded
                        ? OperitIcons.expand_less_rounded
                        : OperitIcons.expand_more_rounded,
                    size: 15,
                  ),
                  label: Text(
                    '${assessment.parameterLabel} · ${parameters.length}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              if (_parametersExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                  child: _ChatToolPermissionParameters(parameters: parameters),
                ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Divider(height: 1, color: colorScheme.outlineVariant),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _buildActions(context, l10n, assessment, accent),
            ),
            if (widget.pendingCount > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  '另有 ${widget.pendingCount - 1} 个请求排队，处理完这条会自动出现。',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Offers fewer, safer decisions as the risk tier rises.
  Widget _buildActions(
    BuildContext context,
    AppLocalizations l10n,
    ToolPermissionAssessment assessment,
    Color accent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final busy = _submitting;

    final denyButton = _PermissionButton(
      label: l10n.toolApprovalDeny,
      onPressed: busy ? null : () => _respond(ChatToolPermissionResult.deny),
      foreground: assessment.risk == ToolPermissionRisk.high
          ? colorScheme.error
          : colorScheme.onSurface,
      borderColor: colorScheme.outlineVariant,
    );

    final allowOnceButton = _PermissionButton(
      label: l10n.toolApprovalAllowOnce,
      onPressed: busy ? null : () => _respond(ChatToolPermissionResult.allow),
      filled: assessment.sessionAllowed,
      busy: busy,
    );

    final sessionButton = assessment.sessionAllowed
        ? _PermissionButton(
            // The localised full label is too wide for a third of the card.
            label: '本会话允许',
            onPressed: busy
                ? null
                : () => _respond(ChatToolPermissionResult.allowSession),
            filled: assessment.risk == ToolPermissionRisk.low,
            foreground: colorScheme.onSurfaceVariant,
            borderColor: colorScheme.outlineVariant,
          )
        : null;

    final children = <Widget>[
      Expanded(child: denyButton),
      const SizedBox(width: 8),
      Expanded(child: allowOnceButton),
      if (sessionButton != null) ...<Widget>[
        const SizedBox(width: 8),
        Expanded(child: sessionButton),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: children),
        if (assessment.risk == ToolPermissionRisk.high)
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              children: <Widget>[
                Icon(
                  OperitIcons.lock_outline_rounded,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '高风险不提供「本次会话始终允许」，如需放行请逐次确认。',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Color _riskColor(ColorScheme colorScheme, ToolPermissionRisk risk) {
  return switch (risk) {
    ToolPermissionRisk.low => colorScheme.primary,
    ToolPermissionRisk.medium => colorScheme.tertiary,
    ToolPermissionRisk.high => colorScheme.error,
  };
}

/// Risk badge in the card header.
class _RiskPill extends StatelessWidget {
  const _RiskPill({
    required this.label,
    required this.color,
    required this.risk,
  });

  final String label;
  final Color color;
  final ToolPermissionRisk risk;

  @override
  Widget build(BuildContext context) {
    final icon = switch (risk) {
      ToolPermissionRisk.low => OperitIcons.check_circle_rounded,
      ToolPermissionRisk.medium => OperitIcons.warning_amber_rounded,
      ToolPermissionRisk.high => OperitIcons.error_rounded,
    };
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Concrete targets of the call: paths, commands or URLs.
class _ObjectList extends StatelessWidget {
  const _ObjectList({required this.objects, required this.hiddenCount});

  final List<ToolPermissionObject> objects;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final object in objects)
            Container(
              decoration: BoxDecoration(
                border: object == objects.first
                    ? null
                    : Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      object.icon,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: SelectableText(
                      object.value,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        fontFamily: 'OperitTerminalMono',
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hiddenCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Text(
                '还有 $hiddenCount 个对象',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Flat 38px action used across the three decisions.
class _PermissionButton extends StatelessWidget {
  const _PermissionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
    this.foreground,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;
  final Color? foreground;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final content = busy
        ? const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: shape,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Center(child: content),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: shape,
        foregroundColor: foreground ?? colorScheme.onSurface,
        side: BorderSide(
          color: borderColor ?? colorScheme.outlineVariant,
          width: 0.8,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Center(child: content),
    );
  }
}

class _ChatToolPermissionParameters extends StatelessWidget {
  const _ChatToolPermissionParameters({required this.parameters});

  final List<core_proxy.RuntimeHostInteractionToolPermissionToolParameter>
  parameters;

  /// Builds a compact, scrollable summary of requested tool arguments.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final parameter in parameters)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      flex: 2,
                      child: Text(
                        parameter.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        parameter.value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
