// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/bridge/ProxyCoreRuntimeBridge.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiProviderCard.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiAccountsPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiDiagnosticsPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiFunctionMappingPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiModelLibraryPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiPreferencesPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiProviderDetailPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiProviderEditorPage.dart';

/// High-fidelity overview for the model and AI settings module.
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

  Future<void> _openAccounts(ModelAiHomeData data) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            ModelAiAccountsPage(data: data, clients: widget.clients),
      ),
    );
    if (mounted) {
      _reload();
    }
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

  Future<void> _createProvider(ModelAiHomeData data) async {
    final catalog = await widget.clients.preferencesModelConfigManager
        .getProviderCatalogEntries();
    if (!mounted) {
      return;
    }
    final result = await ModelAiProviderEditorPage.show(
      context: context,
      catalogEntries: catalog,
      occupiedProviderNames: <String>{
        for (final provider in data.providers) provider.name,
      },
      clients: widget.clients,
    );
    if (result == null || !mounted) {
      return;
    }
    try {
      final providerId = await widget.clients.preferencesModelConfigManager
          .createProvider(
            name: result.name,
            providerTypeId: result.providerTypeId,
            endpoint: result.endpoint,
          );
      final provider = await widget.clients.preferencesModelConfigManager
          .getProviderProfile(providerId: providerId);
      await widget.clients.preferencesModelConfigManager.updateProviderProfile(
        provider: core.ProviderProfile(
          id: provider.id,
          name: result.name,
          providerTypeId: result.providerTypeId,
          providerType: core.ApiProviderType.fromJson(result.providerTypeId),
          endpoint: result.endpoint,
          apiKey: result.apiKey,
          useMultipleApiKeys: result.useMultipleApiKeys,
          apiKeyPool: result.apiKeyPool,
          currentKeyIndex: 0,
          keyRotationMode: provider.keyRotationMode,
          customHeaders: result.customHeaders,
          requestLimitPerMinute: result.requestLimitPerMinute,
          maxConcurrentRequests: result.maxConcurrentRequests,
          models: provider.models,
        ),
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加供应商失败：$error')));
      }
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ModelAiMetrics.pagePadding,
        10,
        ModelAiMetrics.pagePadding,
        32,
      ),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ModelAiMetrics.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _currentModelCard(context, data),
                const SizedBox(height: ModelAiMetrics.sectionGap),
                _toolsGrid(context, data),
                const SizedBox(height: ModelAiMetrics.sectionGap),
                _providersSection(context, data),
                const SizedBox(height: ModelAiMetrics.sectionGap),
                _accountsSection(context, data),
                const SizedBox(height: ModelAiMetrics.sectionGap),
                _interfaceSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _currentModelCard(BuildContext context, ModelAiHomeData data) {
    final palette = ModelAiPalette.of(context);
    final config = data.currentConfig;
    final summary = data.currentSummary;
    final modelName = config?.modelId ?? data.chatBinding.modelId;
    final providerName = config?.providerName ?? '未选择供应商';
    final providerTypeId = config?.apiProviderTypeId ?? '';
    final configured = modelName.isNotEmpty;
    return ModelAiSection(
      title: '当前使用',
      subtitle: '对话默认模型',
      action: TextButton(
        onPressed: widget.onOpenLegacy,
        child: Text(configured ? '更换' : '设置'),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProviderLogo(
            providerTypeId: providerTypeId,
            fallbackName: providerName,
            size: 56,
            preserveBrandColor: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  configured ? modelName : '尚未设置对话模型',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  configured ? providerName : '选择一个供应商和模型开始使用',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 11),
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
        ],
      ),
    );
  }

  Widget _toolsGrid(BuildContext context, ModelAiHomeData data) {
    final tools = <Widget>[
      ModelAiToolTile(
        icon: ModelAiIcons.modelLibrary,
        title: '模型库',
        subtitle: '浏览模型、能力与上下文',
        tone: ModelAiIconTone.blue,
        onTap: () => _openModelLibrary(data),
      ),
      ModelAiToolTile(
        icon: ModelAiIcons.preferences,
        title: 'AI 参数',
        subtitle: '历史轮数与模型行为',
        onTap: () => _openPreferences(data),
      ),
      ModelAiToolTile(
        icon: ModelAiIcons.functionMapping,
        title: '功能映射',
        subtitle: '为每个功能指定模型',
        tone: ModelAiIconTone.amber,
        onTap: () => _openFunctionMapping(data),
      ),
      ModelAiToolTile(
        icon: ModelAiIcons.diagnostics,
        title: '连接诊断',
        subtitle: '端点、凭据与最近错误',
        tone: ModelAiIconTone.green,
        onTap: () => _openDiagnostics(data),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
          child: Text(
            '模型工具',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ModelAiPalette.of(context).textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 4 : 2;
            const gap = 12.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: <Widget>[
                for (final tool in tools)
                  SizedBox(
                    width: itemWidth,
                    height: columns == 4 ? 116 : 118,
                    child: tool,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _providersSection(BuildContext context, ModelAiHomeData data) {
    final palette = ModelAiPalette.of(context);
    if (data.providers.isEmpty) {
      return ModelAiSection(
        title: '供应商',
        subtitle: '还没有配置模型来源',
        child: ModelAiRow(
          icon: ModelAiIcons.add,
          title: '添加第一个供应商',
          subtitle: '连接 OpenAI、Claude、Gemini 或兼容端点',
          tone: ModelAiIconTone.blue,
          onTap: () => _createProvider(data),
        ),
      );
    }
    final chatProviderId = data.chatBinding.providerId;
    return ModelAiSection(
      title: '供应商',
      subtitle: '${data.providers.length} 个来源 · ${data.summaries.length} 个模型',
      action: TextButton(
        onPressed: () => _createProvider(data),
        child: const Text('添加'),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (
            var index = 0;
            index < data.providers.length;
            index++
          ) ...<Widget>[
            if (index > 0)
              Divider(
                height: 1,
                indent: 66,
                endIndent: 16,
                color: palette.border.withValues(alpha: 0.5),
              ),
            _providerCard(context, data, data.providers[index], chatProviderId),
          ],
        ],
      ),
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

  Widget _accountsSection(BuildContext context, ModelAiHomeData data) {
    final total = data.authProviders.length;
    final connected = data.authProviders
        .where(
          (provider) =>
              data.accounts[provider.providerTypeId.toUpperCase()]?.signedIn ==
              true,
        )
        .length;
    return ModelAiSection(
      title: '账号授权',
      subtitle: total == 0 ? '使用订阅账号登录' : '$connected / $total 已连接',
      action: TextButton(
        onPressed: () => _openAccounts(data),
        child: const Text('管理'),
      ),
      padding: EdgeInsets.zero,
      child: ModelAiRow(
        icon: ModelAiIcons.account,
        leading: _accountStack(context, data),
        title: '订阅账号',
        subtitle: total == 0 ? '暂无可授权供应商' : '凭据只保存在本机',
        onTap: () => _openAccounts(data),
      ),
    );
  }

  Widget _accountStack(BuildContext context, ModelAiHomeData data) {
    final providers = data.authProviders.take(3).toList(growable: false);
    if (providers.isEmpty) {
      return const ModelAiIconTile(
        icon: ModelAiIcons.account,
        tone: ModelAiIconTone.blue,
      );
    }
    final palette = ModelAiPalette.of(context);
    return SizedBox(
      width: 34 + (providers.length - 1) * 16,
      height: 36,
      child: Stack(
        children: <Widget>[
          for (var index = 0; index < providers.length; index++)
            Positioned(
              left: index * 16,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.center,
                child: ProviderLogo(
                  providerTypeId: providers[index].providerTypeId,
                  fallbackName: providers[index].displayName,
                  size: 28,
                  preserveBrandColor: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _interfaceSection(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return ModelAiSection(
      title: '界面与高级',
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
            title: Text(
              '使用新版界面',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '关闭后回到原始模型设置页',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
            ),
            value: widget.useV2,
            onChanged: widget.onUseV2Changed,
          ),
        ],
      ),
    );
  }
}
