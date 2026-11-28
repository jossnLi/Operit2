// ignore_for_file: file_names

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core;
import '../../../../l10n/generated/app_localizations.dart';
import '../components/ApiKeyTextField.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';

/// Edits a provider's draft key pool without writing application preferences.
class ApiKeyPoolEditor extends StatefulWidget {
  /// Creates the pool controls and an optional explicit credential probe.
  const ApiKeyPoolEditor({
    super.key,
    required this.enabled,
    required this.entries,
    required this.onEnabledChanged,
    required this.onChanged,
    this.onTestEntry,
    this.onTestingChanged,
    this.singleKey = '',
    this.onResetHealth,
  });
  final bool enabled;
  final List<core.ApiKeyInfo> entries;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<List<core.ApiKeyInfo>> onChanged;
  final Future<core.ApiKeyInfo> Function(core.ApiKeyInfo)? onTestEntry;
  final ValueChanged<bool>? onTestingChanged;
  final String singleKey;
  final Future<void> Function()? onResetHealth;

  /// Creates state for draft dialogs and sequential availability probes.
  @override
  State<ApiKeyPoolEditor> createState() => _ApiKeyPoolEditorState();
}

class _ApiKeyPoolEditorState extends State<ApiKeyPoolEditor> {
  bool _testing = false;
  bool _pause = false;
  int _tested = 0;
  int _total = 0;

  /// Copies an entry while preserving imported identity and usage metadata.
  core.ApiKeyInfo _copy(core.ApiKeyInfo entry, Map<String, Object?> changes) =>
      core.ApiKeyInfo.fromJson({...entry.toJson(), ...changes});

  /// Replaces one draft entry by stable identity.
  void _replace(core.ApiKeyInfo entry) => widget.onChanged([
    for (final current in widget.entries)
      current.id == entry.id ? entry : current,
  ]);

  /// Creates an opaque identifier without including the credential in metadata.
  String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Adds one or several newline-separated keys, or edits an existing entry.
  Future<void> _edit([core.ApiKeyInfo? entry]) async {
    final l10n = AppLocalizations.of(context)!;
    final name = TextEditingController(text: entry?.name ?? '');
    final keyText = TextEditingController(text: entry?.key ?? '');
    final form = GlobalKey<FormState>();
    final route = DialogRoute<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          entry == null
              ? l10n.settingsModelAddApiKey
              : l10n.settingsModelEditApiKey,
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: l10n.settingsModelApiKeyName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ApiKeyTextField(
                    key: const ValueKey('pool-key-input'),
                    controller: keyText,
                    labelText: l10n.settingsModelApiKey,
                    minLines: entry == null ? 3 : 1,
                    maxLines: entry == null ? 6 : 1,
                    helperText: entry == null
                        ? l10n.settingsModelPoolPaste
                        : null,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.settingsModelApiKey
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final saved = await Navigator.of(context).push(route);
    if (saved == true && mounted) {
      if (entry != null) {
        final changed = keyText.text.trim() != entry.key;
        _replace(
          _copy(entry, {
            'name': name.text.trim(),
            'key': keyText.text.trim(),
            if (changed) ...{
              'availabilityStatus': 'UNTESTED',
              'usageCount': 0,
              'lastUsed': 0,
              'errorCount': 0,
            },
          }),
        );
      } else {
        final seen = widget.entries.map((entry) => entry.key.trim()).toSet();
        final keys = keyText.text
            .split(RegExp(r'\r?\n'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty && seen.add(value))
            .toList();
        widget.onChanged([
          ...widget.entries,
          for (var i = 0; i < keys.length; i++)
            core.ApiKeyInfo(
              id: _newId(),
              key: keys[i],
              name: keys.length == 1
                  ? name.text.trim()
                  : '${name.text.trim()} ${i + 1}'.trim(),
              isEnabled: true,
              availabilityStatus: core.ApiKeyAvailabilityStatus.untested,
              usageCount: 0,
              lastUsed: 0,
              errorCount: 0,
            ),
        ]);
      }
    }
    await route.completed;
    name.dispose();
    keyText.dispose();
  }

  /// Tests enabled, untested entries and pauses after any in-flight probe finishes.
  Future<void> _test() async {
    final pending = widget.entries
        .where(
          (entry) =>
              entry.isEnabled &&
              entry.availabilityStatus ==
                  core.ApiKeyAvailabilityStatus.untested,
        )
        .toList();
    setState(() {
      _testing = true;
      _pause = false;
      _tested = 0;
      _total = pending.length;
    });
    widget.onTestingChanged?.call(true);
    var workingPool = List.of(widget.entries);
    try {
      for (final entry in pending) {
        if (_pause || !mounted) break;
        final result = await widget.onTestEntry!(entry);
        if (!mounted) break;
        workingPool = [
          for (final current in workingPool)
            current.id == result.id ? result : current,
        ];
        widget.onChanged(workingPool);
        setState(() => _tested++);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
        widget.onTestingChanged?.call(false);
      }
    }
  }

  /// Clears explicit test marks and the runtime's temporary credential fault state.
  Future<void> _resetHealth() async {
    try {
      await widget.onResetHealth?.call();
      if (!mounted) return;
      widget.onChanged([
        for (final entry in widget.entries)
          _copy(entry, {'availabilityStatus': 'UNTESTED'}),
      ]);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  /// Maps persisted availability values to localized labels.
  String _status(
    AppLocalizations l10n,
    core.ApiKeyAvailabilityStatus status,
  ) => switch (status) {
    core.ApiKeyAvailabilityStatus.untested => l10n.settingsModelPoolUntested,
    core.ApiKeyAvailabilityStatus.available => l10n.settingsModelPoolAvailable,
    core.ApiKeyAvailabilityStatus.unavailable =>
      l10n.settingsModelPoolUnavailable,
  };

  /// Builds the pool controls with a centered empty state and a compact key list.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEmpty = widget.entries.isEmpty;

    final actions = <Widget>[
      if (widget.singleKey.trim().isNotEmpty &&
          !widget.entries.any(
            (entry) => entry.key.trim() == widget.singleKey.trim(),
          ))
        TextButton(
          onPressed: _testing
              ? null
              : () => widget.onChanged([
                  ...widget.entries,
                  core.ApiKeyInfo(
                    id: _newId(),
                    key: widget.singleKey.trim(),
                    name: l10n.settingsModelApiKey,
                    isEnabled: true,
                    availabilityStatus: core.ApiKeyAvailabilityStatus.untested,
                    usageCount: 0,
                    lastUsed: 0,
                    errorCount: 0,
                  ),
                ]),
          child: Text(l10n.settingsModelPoolAddSingle),
        ),
      FilledButton.tonalIcon(
        onPressed: _testing ? null : _edit,
        icon: const Icon(OperitIcons.add_rounded, size: 18),
        label: Text(l10n.settingsModelAddApiKey),
      ),
      if (!isEmpty)
        TextButton(
          onPressed: _testing ? null : _resetHealth,
          child: Text(l10n.settingsModelPoolClearMarks),
        ),
      if (!isEmpty && widget.onTestEntry != null)
        TextButton(
          onPressed: _testing ? () => setState(() => _pause = true) : _test,
          child: Text(_testing ? l10n.pause : l10n.settingsModelPoolTest),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    OperitIcons.playlist_add_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.settingsModelApiKeyPool,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.settingsModelApiKeyPoolDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.88,
                  child: Switch(
                    key: const ValueKey('api-key-pool-toggle'),
                    value: widget.enabled,
                    onChanged: _testing ? null : widget.onEnabledChanged,
                  ),
                ),
              ],
            ),
            if (widget.enabled) ...<Widget>[
              const SizedBox(height: 12),
              FormField<bool>(
                validator: (_) {
                  final enabled = widget.entries.where(
                    (entry) => entry.isEnabled && entry.key.trim().isNotEmpty,
                  );
                  return !enabled.any(
                        (entry) =>
                            entry.availabilityStatus !=
                            core.ApiKeyAvailabilityStatus.unavailable,
                      )
                      ? l10n.settingsModelPoolNoEligible
                      : null;
                },
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                OperitIcons.playlist_add_rounded,
                                size: 22,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '还没有备用 Key',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '添加多个 Key 后，失败时自动切换，单个 Key 出错不会影响整体。',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final entry in widget.entries)
                        _keyPoolRow(context, entry, l10n),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          field.errorText!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actions,
                    ),
                  ],
                ),
              ),
              if (_testing) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(minHeight: 3),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.settingsModelTestProgress(_tested, _total),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.onTestEntry == null && !isEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  l10n.settingsModelPoolNeedsModel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _keyPoolRow(
    BuildContext context,
    core.ApiKeyInfo entry,
    AppLocalizations l10n,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: entry.isEnabled,
              onChanged: _testing
                  ? null
                  : (value) => _replace(_copy(entry, {'isEnabled': value})),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _testing ? null : () => _edit(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.name.isEmpty
                          ? l10n.settingsModelApiKey
                          : entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '•••••••• · ${_status(l10n, entry.availabilityStatus)} · ${entry.usageCount} 次使用',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.settingsModelEditApiKey,
            onPressed: _testing ? null : () => _edit(entry),
            visualDensity: VisualDensity.compact,
            icon: const Icon(OperitIcons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: _testing
                ? null
                : () => widget.onChanged(
                    widget.entries
                        .where((item) => item.id != entry.id)
                        .toList(),
                  ),
            visualDensity: VisualDensity.compact,
            icon: const Icon(OperitIcons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
