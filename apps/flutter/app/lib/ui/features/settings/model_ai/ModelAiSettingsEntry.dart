// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/bridge/ProxyCoreRuntimeBridge.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomePanel.dart';

/// Entry point for the model and AI settings module.
///
/// There is no rollout switch and no legacy fallback anymore: every surface in
/// this module is the redesigned one.
class ModelAiSettingsEntry extends StatelessWidget {
  const ModelAiSettingsEntry({super.key, GeneratedCoreProxyClients? clients})
    : clients =
          clients ?? const GeneratedCoreProxyClients(ProxyCoreRuntimeBridge());

  final GeneratedCoreProxyClients clients;

  @override
  Widget build(BuildContext context) {
    return ModelAiHomePanel(clients: clients);
  }
}
