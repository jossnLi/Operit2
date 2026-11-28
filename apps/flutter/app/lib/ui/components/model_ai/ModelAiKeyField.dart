// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/ui/common/icons/operit_icons.dart';

import 'ModelAiSurfaces.dart';

/// A masked credential field with the model-AI key treatment: key prefix,
/// monospace value, focus ring and an explicit reveal control.
///
/// The widget owns a controller when the caller does not supply one, so short
/// forms can use it without wiring lifecycle state themselves.
class ModelAiKeyField extends StatefulWidget {
  const ModelAiKeyField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = '粘贴 API Key',
    this.obscureByDefault = true,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helperText,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool obscureByDefault;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? helperText;

  @override
  State<ModelAiKeyField> createState() => _ModelAiKeyFieldState();
}

class _ModelAiKeyFieldState extends State<ModelAiKeyField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late bool _obscured = widget.obscureByDefault;
  late final bool _ownsController = widget.controller == null;
  late final bool _ownsFocusNode = widget.focusNode == null;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? palette.danger
        : _focused
        ? palette.accent
        : palette.border;
    final fillColor = _focused ? palette.group : palette.inset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.16),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                OperitIcons.key_outlined,
                size: 16,
                color: _focused ? palette.accent : palette.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  obscureText: _obscured,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.done,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.enabled
                        ? palette.textSecondary
                        : palette.textTertiary,
                    fontFamily: 'Cascadia Mono',
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      fontFamily: 'Cascadia Mono',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: _obscured ? '显示 Key' : '隐藏 Key',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
                icon: Icon(
                  OperitIcons.visibility_outlined,
                  size: 17,
                  color: _obscured ? palette.textTertiary : palette.accent,
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.danger, height: 1.3),
          ),
        ] else if (widget.helperText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textTertiary,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
