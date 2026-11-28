// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/bridge/ProxyCoreRuntimeBridge.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/data/preferences/UserPreferencesManager.dart';
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ModelSettingsPanel.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomePanel.dart';

/// Chooses between the redesigned shell and the legacy panel.
///
/// The rollout flag keeps both entries alive: turning the switch off renders the
/// original panel in place, and the new shell links to the legacy editor without
/// deleting it.
class ModelAiSettingsEntry extends StatefulWidget {
  const ModelAiSettingsEntry({super.key, GeneratedCoreProxyClients? clients})
    : clients =
          clients ?? const GeneratedCoreProxyClients(ProxyCoreRuntimeBridge());

  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiSettingsEntry> createState() => _ModelAiSettingsEntryState();
}

class _ModelAiSettingsEntryState extends State<ModelAiSettingsEntry> {
  static const UserPreferencesManager _preferences = UserPreferencesManager();
  bool? _useV2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _preferences.loadModelAiV2Enabled();
      if (mounted) {
        setState(() => _useV2 = enabled);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _useV2 = true);
      }
    }
  }

  Future<void> _setUseV2(bool enabled) async {
    setState(() => _useV2 = enabled);
    try {
      await _preferences.saveModelAiV2Enabled(enabled);
    } catch (_) {
      // The in-memory switch still reflects the user's choice for this session.
    }
  }

  void _openLegacy() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('高级设置（旧版）'),
            leading: IconButton(
              icon: const Icon(OperitIcons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(child: ModelSettingsPanel(clients: widget.clients)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useV2 == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_useV2 == false) {
      return _LegacyPanelHost(
        clients: widget.clients,
        onOpenNew: () => _setUseV2(true),
      );
    }
    return ModelAiHomePanel(
      clients: widget.clients,
      useV2: true,
      onUseV2Changed: _setUseV2,
      onOpenLegacy: _openLegacy,
    );
  }
}

/// Keeps the legacy editor reachable with a single migration hint.
class _LegacyPanelHost extends StatelessWidget {
  const _LegacyPanelHost({required this.clients, required this.onOpenNew});

  final GeneratedCoreProxyClients clients;
  final VoidCallback onOpenNew;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Column(
      children: <Widget>[
        Material(
          color: palette.accentTint,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: <Widget>[
                Icon(
                  OperitIcons.info_outline_rounded,
                  size: 17,
                  color: palette.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '正在使用旧版模型设置。新版界面提供总览、账号登录与诊断，可随时切回。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.accent,
                      height: 1.35,
                    ),
                  ),
                ),
                TextButton(onPressed: onOpenNew, child: const Text('试用新版')),
              ],
            ),
          ),
        ),
        Expanded(child: ModelSettingsPanel(clients: clients)),
      ],
    );
  }
}
