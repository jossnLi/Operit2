// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model/CodexLoginDialog.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';
import 'package:operit2/ui/features/settings/model_ai/ProviderAuthLoginDialog.dart';

/// Detail for one configured provider with read-only configuration and account
/// actions. Editing still routes to the legacy editor until the edit sheets land.
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

  @override
  void initState() {
    super.initState();
    _future = loadModelAiHomeData(widget.clients);
  }

  void _reload() {
    setState(() => _future = loadModelAiHomeData(widget.clients));
  }

  core.ProviderProfile? _provider(ModelAiHomeData data) {
    for (final provider in data.providers) {
      if (provider.id == widget.providerId) {
        return provider;
      }
    }
    return null;
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

  Future<void> _logout(core.ProviderProfile provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出账号'),
        content: Text('将从本机移除 ${provider.name} 的账号凭据，模型配置仍会保留。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
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
          icon: const Icon(OperitIcons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(onPressed: widget.onOpenLegacy, child: const Text('编辑')),
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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _hero(context, provider, account, accountProvider),
                      const SizedBox(height: 22),
                      ModelAiSection(
                        title: '连接',
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            ModelAiRow(
                              icon: OperitIcons.link_rounded,
                              title: '接口地址',
                              subtitle: provider.endpoint.isEmpty
                                  ? '使用供应商默认端点'
                                  : provider.endpoint,
                              showChevron: false,
                            ),
                            const Divider(height: 1, indent: 50),
                            ModelAiRow(
                              icon: OperitIcons.key_outlined,
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
                            const Divider(height: 1, indent: 50),
                            ModelAiRow(
                              icon: OperitIcons.speed_rounded,
                              title: '请求限制',
                              subtitle:
                                  '${provider.requestLimitPerMinute} 次/分钟 · 并发 ${provider.maxConcurrentRequests}',
                              showChevron: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      ModelAiSection(
                        title: '模型',
                        subtitle: '${models.length} 个可用模型',
                        action: TextButton(
                          onPressed: widget.onOpenLegacy,
                          child: const Text('管理模型'),
                        ),
                        padding: EdgeInsets.zero,
                        child: models.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('尚未配置模型'),
                              )
                            : Column(
                                children: <Widget>[
                                  for (
                                    var index = 0;
                                    index < models.length;
                                    index++
                                  ) ...<Widget>[
                                    if (index > 0)
                                      const Divider(height: 1, indent: 50),
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
    return ModelAiSection(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProviderLogo(
            providerTypeId: provider.providerTypeId,
            fallbackName: provider.name,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.providerTypeId,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 8),
                if (account?.signedIn == true)
                  ModelAiStatusPill(
                    label: account!.email.isEmpty ? '账号已连接' : account.email,
                    tone: account.planEnabled
                        ? ModelAiStatusTone.success
                        : ModelAiStatusTone.accent,
                    icon: OperitIcons.check_rounded,
                  )
                else
                  const ModelAiStatusPill(
                    label: 'API Key 模式',
                    tone: ModelAiStatusTone.neutral,
                    icon: OperitIcons.key_outlined,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (accountProvider != null && account?.signedIn != true)
                FilledButton.tonal(
                  onPressed: () => _login(accountProvider),
                  child: const Text('登录'),
                ),
              if (account?.signedIn == true)
                TextButton(
                  onPressed: () => _logout(provider),
                  child: const Text('退出账号'),
                ),
              TextButton(
                onPressed: widget.onOpenLegacy,
                child: const Text('编辑配置'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modelRow(BuildContext context, core.ProviderModelSummary model) {
    return ModelAiRow(
      icon: OperitIcons.psychology_outlined,
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
