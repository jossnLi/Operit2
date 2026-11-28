// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model/CodexLoginDialog.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiProviderEditorPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ProviderAuthLoginDialog.dart';

/// Detail for one configured provider with read-only configuration and account
/// actions. Editing opens the dedicated full-screen provider editor.
class ModelAiProviderDetailPage extends StatefulWidget {
  const ModelAiProviderDetailPage({
    super.key,
    required this.providerId,
    required this.onOpenLegacy,
    required this.clients,
  });

  final String providerId;
  final VoidCallback onOpenLegacy;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiProviderDetailPage> createState() =>
      _ModelAiProviderDetailPageState();
}

class _ModelAiProviderDetailPageState extends State<ModelAiProviderDetailPage> {
  Future<ModelAiHomeData>? _future;
  ModelAiHomeData? _currentData;
  bool _confirmLogout = false;

  @override
  void initState() {
    super.initState();
    _future = loadModelAiHomeData(widget.clients);
  }

  void _reload() {
    setState(() {
      _confirmLogout = false;
      _future = loadModelAiHomeData(widget.clients);
    });
  }

  core.ProviderProfile? _provider(ModelAiHomeData data) {
    for (final provider in data.providers) {
      if (provider.id == widget.providerId) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _openEditor(core.ProviderProfile provider) async {
    final catalog = await widget.clients.preferencesModelConfigManager
        .getProviderCatalogEntries();
    final current = await loadModelAiHomeData(widget.clients);
    if (!mounted) {
      return;
    }
    final result = await ModelAiProviderEditorPage.show(
      context: context,
      catalogEntries: catalog,
      occupiedProviderNames: <String>{
        for (final item in current.providers)
          if (item.id != provider.id) item.name,
      },
      clients: widget.clients,
      provider: provider,
    );
    if (result == null || !mounted) {
      return;
    }
    try {
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
          currentKeyIndex: provider.currentKeyIndex,
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
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    }
  }

  core.ProviderAuthProviderView? _accountProvider(
    ModelAiHomeData data,
    String providerTypeId,
  ) {
    for (final provider in data.authProviders) {
      if (provider.providerTypeId.toUpperCase() ==
          providerTypeId.toUpperCase()) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _login(core.ProviderAuthProviderView account) async {
    if (account.providerTypeId == 'OPENAI_CODEX') {
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
      provider: account,
    );
    if (result != null && mounted) {
      _reload();
    }
  }

  Future<void> _performLogout(core.ProviderProfile provider) async {
    await widget.clients.servicesProviderAuthService.logout(
      providerTypeId: provider.providerTypeId,
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('供应商详情'),
        leading: IconButton(
          icon: const Icon(ModelAiIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final data = _currentData;
              final provider = data == null ? null : _provider(data);
              if (provider != null) {
                _openEditor(provider);
              }
            },
            child: const Text('编辑'),
          ),
        ],
      ),
      body: FutureBuilder<ModelAiHomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ModelAiInlineError(
                message: '无法读取供应商配置：${snapshot.error}',
                onRetry: _reload,
              ),
            );
          }
          final data = snapshot.data!;
          _currentData = data;
          final provider = _provider(data);
          if (provider == null) {
            return const Center(child: Text('供应商已被删除'));
          }
          final account = data.accounts[provider.providerTypeId.toUpperCase()];
          final accountProvider = _accountProvider(
            data,
            provider.providerTypeId,
          );
          final models = data.summaries
              .where((summary) => summary.providerId == provider.id)
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              ModelAiMetrics.pagePadding,
              8,
              ModelAiMetrics.pagePadding,
              30,
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
                      _hero(context, provider, account, accountProvider),
                      const SizedBox(height: 12),
                      _actionBar(context, provider, account, accountProvider),
                      if (_confirmLogout) ...<Widget>[
                        const SizedBox(height: 12),
                        ModelAiInlineConfirm(
                          title: '退出 ${provider.name} 账号',
                          message: '会从本机移除账号凭据，供应商与模型配置仍会保留。',
                          confirmLabel: '退出账号',
                          onCancel: () =>
                              setState(() => _confirmLogout = false),
                          onConfirm: () => _performLogout(provider),
                        ),
                      ],
                      const SizedBox(height: ModelAiMetrics.sectionGap),
                      ModelAiSection(
                        title: '连接',
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            ModelAiRow(
                              icon: ModelAiIcons.endpoint,
                              title: '接口地址',
                              subtitle: provider.endpoint.isEmpty
                                  ? '使用供应商默认端点'
                                  : provider.endpoint,
                              showChevron: false,
                            ),
                            Divider(
                              height: 1,
                              indent: 64,
                              color: ModelAiPalette.of(
                                context,
                              ).border.withValues(alpha: 0.5),
                            ),
                            ModelAiRow(
                              icon: ModelAiIcons.apiKey,
                              title: '凭据',
                              subtitle: provider.useMultipleApiKeys
                                  ? 'API Key 池 · ${provider.apiKeyPool.length} 个 Key'
                                  : (account?.signedIn == true
                                        ? '账号授权'
                                        : '单个 API Key'),
                              tone: account?.signedIn == true
                                  ? ModelAiIconTone.green
                                  : ModelAiIconTone.blue,
                              showChevron: false,
                            ),
                            Divider(
                              height: 1,
                              indent: 64,
                              color: ModelAiPalette.of(
                                context,
                              ).border.withValues(alpha: 0.5),
                            ),
                            ModelAiRow(
                              icon: ModelAiIcons.rateLimit,
                              title: '请求限制',
                              subtitle:
                                  '${provider.requestLimitPerMinute} 次/分钟 · 并发 ${provider.maxConcurrentRequests}',
                              showChevron: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ModelAiMetrics.sectionGap),
                      ModelAiSection(
                        title: '模型',
                        subtitle: '${models.length} 个可用模型',
                        action: TextButton(
                          onPressed: widget.onOpenLegacy,
                          child: const Text('管理模型'),
                        ),
                        padding: EdgeInsets.zero,
                        child: models.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  '尚未配置模型',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ModelAiPalette.of(
                                          context,
                                        ).textTertiary,
                                      ),
                                ),
                              )
                            : Column(
                                children: <Widget>[
                                  for (
                                    var index = 0;
                                    index < models.length;
                                    index++
                                  ) ...<Widget>[
                                    if (index > 0)
                                      Divider(
                                        height: 1,
                                        indent: 64,
                                        color: ModelAiPalette.of(
                                          context,
                                        ).border.withValues(alpha: 0.5),
                                      ),
                                    _modelRow(context, models[index]),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    core.ProviderProfile provider,
    core.ProviderAuthStatus? account,
    core.ProviderAuthProviderView? accountProvider,
  ) {
    final palette = ModelAiPalette.of(context);
    final signedIn = account?.signedIn == true;
    return ModelAiSection(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProviderLogo(
            providerTypeId: provider.providerTypeId,
            fallbackName: provider.name,
            size: 56,
            preserveBrandColor: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.providerTypeId,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    if (signedIn)
                      ModelAiStatusPill(
                        label: account!.email.isEmpty ? '账号已连接' : account.email,
                        tone: account.planEnabled
                            ? ModelAiStatusTone.success
                            : ModelAiStatusTone.accent,
                        icon: ModelAiIcons.check,
                        compact: true,
                      )
                    else if (accountProvider != null)
                      const ModelAiStatusPill(
                        label: '账号未连接',
                        tone: ModelAiStatusTone.neutral,
                        icon: ModelAiIcons.account,
                        compact: true,
                      )
                    else
                      const ModelAiStatusPill(
                        label: 'API Key 模式',
                        tone: ModelAiStatusTone.neutral,
                        icon: ModelAiIcons.apiKey,
                        compact: true,
                      ),
                    ModelAiStatusPill(
                      label: '${provider.models.length} 个模型',
                      tone: ModelAiStatusTone.neutral,
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

  Widget _actionBar(
    BuildContext context,
    core.ProviderProfile provider,
    core.ProviderAuthStatus? account,
    core.ProviderAuthProviderView? accountProvider,
  ) {
    final signedIn = account?.signedIn == true;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        if (accountProvider != null)
          if (signedIn)
            OutlinedButton.icon(
              onPressed: () => setState(() => _confirmLogout = true),
              icon: const Icon(ModelAiIcons.signOut, size: 17),
              label: const Text('退出账号'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => _login(accountProvider),
              icon: const Icon(ModelAiIcons.signIn, size: 17),
              label: const Text('账号登录'),
            ),
        OutlinedButton.icon(
          onPressed: () => _openEditor(provider),
          icon: const Icon(ModelAiIcons.settings, size: 17),
          label: const Text('编辑配置'),
        ),
      ],
    );
  }

  Widget _modelRow(BuildContext context, core.ProviderModelSummary model) {
    return ModelAiRow(
      icon: ModelAiIcons.model,
      title: model.modelId,
      subtitle: model.capabilities.toolCall ? '支持工具调用' : null,
      showChevron: false,
      onTap: widget.onOpenLegacy,
      trailing: Wrap(
        spacing: 5,
        children: <Widget>[
          if (model.capabilities.directImage)
            const ModelAiStatusPill(
              label: '视觉',
              tone: ModelAiStatusTone.accent,
              compact: true,
            ),
          if (model.capabilities.toolCall)
            const ModelAiStatusPill(label: '工具', compact: true),
        ],
      ),
    );
  }
}
