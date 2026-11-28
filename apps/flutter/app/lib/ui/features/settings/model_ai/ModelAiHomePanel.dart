// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/bridge/ProxyCoreRuntimeBridge.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiProviderCard.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model/CodexLoginDialog.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiDiagnosticsPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiFunctionMappingPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiModelLibraryPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiPreferencesPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiProviderDetailPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ProviderAuthLoginDialog.dart';

/// High-fidelity home for the model and AI settings module.
class ModelAiHomePanel extends StatefulWidget {
  const ModelAiHomePanel({
    super.key,
    required this.onOpenLegacy,
    required this.useV2,
    required this.onUseV2Changed,
    GeneratedCoreProxyClients? clients,
  }) : clients =
           clients ?? const GeneratedCoreProxyClients(ProxyCoreRuntimeBridge());

  final VoidCallback onOpenLegacy;
  final bool useV2;
  final ValueChanged<bool> onUseV2Changed;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiHomePanel> createState() => _ModelAiHomePanelState();
}

class _ModelAiHomePanelState extends State<ModelAiHomePanel> {
  Future<ModelAiHomeData>? _future;

  @override
  void initState() {
    super.initState();
    _future = loadModelAiHomeData(widget.clients);
  }

  void _reload() {
    setState(() {
      _future = loadModelAiHomeData(widget.clients);
    });
  }

  Future<void> _openAccountLogin(core.ProviderAuthProviderView provider) async {
    if (provider.providerTypeId == 'OPENAI_CODEX') {
      final result = await showCodexLoginDialog(
        context: context,
        clients: widget.clients,
      );
      if (result != null && mounted) {
        _reload();
      }
      return;
    }
    final result = await showProviderAuthLoginDialog(
      context: context,
      clients: widget.clients,
      provider: provider,
    );
    if (result != null && mounted) {
      _reload();
    }
  }

  Future<void> _openModelLibrary(ModelAiHomeData data) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiModelLibraryPage(
          models: data.summaries,
          onOpenLegacy: widget.onOpenLegacy,
        ),
      ),
    );
  }

  Future<void> _openFunctionMapping(ModelAiHomeData data) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiFunctionMappingPage(
          clients: widget.clients,
          summaries: data.summaries,
          initialBindings: data.functionBindings,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  Future<void> _openPreferences(ModelAiHomeData data) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiPreferencesPage(
          data: data,
          clients: widget.clients,
          onOpenLegacy: widget.onOpenLegacy,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  Future<void> _openDiagnostics(ModelAiHomeData data) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiDiagnosticsPage(
          data: data,
          clients: widget.clients,
          onOpenLegacy: widget.onOpenLegacy,
        ),
      ),
    );
  }

  Future<void> _openProvider(core.ProviderProfile provider) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiProviderDetailPage(
          providerId: provider.id,
          clients: widget.clients,
          onOpenLegacy: widget.onOpenLegacy,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ModelAiHomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
            child: ModelAiInlineError(
              message: '无法读取模型配置：${snapshot.error}',
              onRetry: _reload,
            ),
          );
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildContent(BuildContext context, ModelAiHomeData data) {
    final palette = ModelAiPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '总览',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onOpenLegacy,
                      icon: const Icon(OperitIcons.tune_outlined, size: 16),
                      label: const Text('高级设置'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CurrentModelSection(
                  data: data,
                  onOpenLegacy: widget.onOpenLegacy,
                ),
                const SizedBox(height: 22),
                ModelAiSection(
                  title: '供应商',
                  subtitle: '已配置的模型来源与账号状态',
                  action: TextButton(
                    onPressed: widget.onOpenLegacy,
                    child: const Text('管理'),
                  ),
                  padding: EdgeInsets.zero,
                  child: _buildProviderList(context, data),
                ),
                const SizedBox(height: 22),
                if (data.authProviders.isNotEmpty) ...<Widget>[
                  ModelAiSection(
                    title: '账号授权',
                    subtitle: '使用订阅账号登录，无需手动填写 API Key',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < data.authProviders.length;
                          index++
                        ) ...<Widget>[
                          if (index > 0) _divider(context),
                          _buildAccountRow(
                            context,
                            data.authProviders[index],
                            data.accounts[data
                                .authProviders[index]
                                .providerTypeId
                                .toUpperCase()],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                ModelAiSection(
                  title: '模型工具',
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      ModelAiRow(
                        icon: OperitIcons.inventory_2_outlined,
                        title: '模型库',
                        subtitle: '浏览可用模型、能力与价格',
                        tone: ModelAiIconTone.blue,
                        onTap: () => _openModelLibrary(data),
                      ),
                      _divider(context),
                      ModelAiRow(
                        icon: OperitIcons.tune_outlined,
                        title: 'AI 参数',
                        subtitle: '温度、思考等级与历史轮数',
                        onTap: () => _openPreferences(data),
                      ),
                      _divider(context),
                      ModelAiRow(
                        icon: OperitIcons.route_outlined,
                        title: '功能映射',
                        subtitle: '为每个功能指定独立模型',
                        tone: ModelAiIconTone.amber,
                        onTap: () => _openFunctionMapping(data),
                      ),
                      _divider(context),
                      ModelAiRow(
                        icon: OperitIcons.build_outlined,
                        title: '连接诊断',
                        subtitle: '检查端点、凭据与最近错误',
                        tone: ModelAiIconTone.green,
                        onTap: () => _openDiagnostics(data),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ModelAiSection(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        title: Text(
                          '使用新版界面',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: palette.text),
                        ),
                        subtitle: Text(
                          '关闭后回到原有模型设置页',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                        value: widget.useV2,
                        onChanged: widget.onUseV2Changed,
                      ),
                      _divider(context),
                      ModelAiNavRow(
                        label: '高级设置（旧版）：逐项编辑供应商、Key 与参数',
                        icon: OperitIcons.settings_outlined,
                        onTap: widget.onOpenLegacy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderList(BuildContext context, ModelAiHomeData data) {
    if (data.providers.isEmpty) {
      return ModelAiRow(
        icon: OperitIcons.add_rounded,
        title: '添加第一个供应商',
        subtitle: '连接 OpenAI、Claude、Gemini 或兼容端点',
        tone: ModelAiIconTone.blue,
        onTap: widget.onOpenLegacy,
      );
    }
    final chatProviderId = data.chatBinding.providerId;
    return Column(
      children: <Widget>[
        for (var index = 0; index < data.providers.length; index++) ...<Widget>[
          if (index > 0) _divider(context),
          _providerCard(context, data, data.providers[index], chatProviderId),
        ],
        _divider(context),
        ModelAiRow(
          icon: OperitIcons.add_rounded,
          title: '添加供应商',
          subtitle: '账号授权或 API Key 接入',
          tone: ModelAiIconTone.blue,
          onTap: widget.onOpenLegacy,
        ),
      ],
    );
  }

  Widget _providerCard(
    BuildContext context,
    ModelAiHomeData data,
    core.ProviderProfile provider,
    String chatProviderId,
  ) {
    final account = data.accounts[provider.providerTypeId.toUpperCase()];
    return ModelAiProviderCard(
      providerTypeId: provider.providerTypeId,
      name: provider.name,
      modelCount: data.modelCountFor(provider.id),
      accountEmail: account?.email,
      planEnabled: account?.planEnabled ?? false,
      needsReauthentication: account?.needsReauthentication ?? false,
      isDefault: provider.id == chatProviderId,
      onTap: () => _openProvider(provider),
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    core.ProviderAuthProviderView provider,
    core.ProviderAuthStatus? status,
  ) {
    final signedIn = status?.signedIn ?? false;
    final name = provider.displayName;
    final detail = signedIn
        ? (status!.email.isNotEmpty ? status.email : '账号已连接')
        : provider.loginStyle == 'device_code'
        ? '设备码登录'
        : provider.loginStyle == 'manual_code'
        ? '手动授权码'
        : '浏览器授权';
    return ModelAiRow(
      icon: OperitIcons.key_outlined,
      title: name,
      subtitle: detail,
      tone: signedIn ? ModelAiIconTone.green : ModelAiIconTone.blue,
      showChevron: false,
      trailing: signedIn
          ? ModelAiStatusPill(
              label: status!.planEnabled ? '订阅已启用' : '已连接',
              tone: status.planEnabled
                  ? ModelAiStatusTone.success
                  : ModelAiStatusTone.neutral,
              compact: true,
            )
          : TextButton(
              onPressed: () => _openAccountLogin(provider),
              child: const Text('登录'),
            ),
      onTap: signedIn ? null : () => _openAccountLogin(provider),
    );
  }

  Widget _divider(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: palette.border.withValues(alpha: 0.6),
    );
  }
}

class _CurrentModelSection extends StatelessWidget {
  const _CurrentModelSection({required this.data, required this.onOpenLegacy});

  final ModelAiHomeData data;
  final VoidCallback onOpenLegacy;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final config = data.currentConfig;
    final summary = data.currentSummary;
    final modelName = config?.modelId ?? data.chatBinding.modelId;
    final providerName = config?.providerName ?? '未选择供应商';
    final providerTypeId = config?.apiProviderTypeId ?? '';
    return ModelAiSection(
      title: '当前使用',
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpenLegacy,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProviderLogo(
                providerTypeId: providerTypeId,
                fallbackName: providerName,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      modelName.isEmpty ? '尚未设置对话模型' : modelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        if (summary != null) ...<Widget>[
                          if (summary.capabilities.directImage)
                            const ModelAiStatusPill(
                              label: '视觉',
                              tone: ModelAiStatusTone.accent,
                              compact: true,
                            ),
                          if (summary.capabilities.toolCall)
                            const ModelAiStatusPill(label: '工具', compact: true),
                          if (summary.capabilities.directAudio)
                            const ModelAiStatusPill(label: '语音', compact: true),
                        ] else
                          const ModelAiStatusPill(
                            label: '需要配置',
                            tone: ModelAiStatusTone.warning,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onOpenLegacy,
                child: Text(modelName.isEmpty ? '设置' : '更换'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
