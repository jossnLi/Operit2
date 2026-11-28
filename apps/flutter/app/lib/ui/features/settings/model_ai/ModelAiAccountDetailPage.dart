// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/CodexLoginDialog.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';

import 'ModelAiHomeData.dart';
import 'ModelAiProviderDetailPage.dart';
import 'ProviderAuthLoginDialog.dart';

/// Account detail for a provider that has no configured provider entry yet.
///
/// The page never launches a browser on open. Authorization starts only after an
/// explicit tap, so a row in the account list cannot drop the user into a blank
/// browser hand-off by accident.
class ModelAiAccountDetailPage extends StatefulWidget {
  const ModelAiAccountDetailPage({
    super.key,
    required this.provider,
    required this.clients,
  });

  final core.ProviderAuthProviderView provider;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiAccountDetailPage> createState() =>
      _ModelAiAccountDetailPageState();
}

class _ModelAiAccountDetailPageState extends State<ModelAiAccountDetailPage> {
  Future<ModelAiHomeData>? _future;
  ModelAiHomeData? _data;
  bool _busy = false;
  bool _confirmLogout = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _confirmLogout = false;
      _future = loadModelAiHomeData(widget.clients);
    });
  }

  core.ProviderAuthStatus? get _status {
    final data = _data;
    if (data == null) {
      return null;
    }
    return data.accounts[widget.provider.providerTypeId.toUpperCase()];
  }

  core.ProviderProfile? get _configuredProvider {
    final data = _data;
    if (data == null) {
      return null;
    }
    for (final provider in data.providers) {
      if (provider.providerTypeId.toUpperCase() ==
          widget.provider.providerTypeId.toUpperCase()) {
        return provider;
      }
    }
    return null;
  }

  String get _loginStyleLabel {
    return switch (widget.provider.loginStyle) {
      'device_code' => '设备码登录',
      'manual_code' => '手动授权码',
      _ => '浏览器授权',
    };
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      if (widget.provider.providerTypeId == 'OPENAI_CODEX') {
        await showCodexLoginDialog(context: context, clients: widget.clients);
      } else {
        await showProviderAuthLoginDialog(
          context: context,
          clients: widget.clients,
          provider: widget.provider,
        );
      }
      _reload();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await widget.clients.servicesProviderAuthService.logout(
        providerTypeId: widget.provider.providerTypeId,
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('退出失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openProviderDetail(core.ProviderProfile provider) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiProviderDetailPage(
          providerId: provider.id,
          clients: widget.clients,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModelAiPageScaffold(
      title: widget.provider.displayName,
      body: FutureBuilder<ModelAiHomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(ModelAiMetrics.pagePadding),
              child: ModelAiInlineError(
                message: '无法读取账号状态：${snapshot.error}',
                onRetry: _reload,
              ),
            );
          }
          final data = snapshot.data!;
          _data = data;
          final status = _status;
          final configured = _configuredProvider;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              ModelAiMetrics.pagePadding,
              8,
              ModelAiMetrics.pagePadding,
              28,
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
                      _hero(context, status),
                      const SizedBox(height: 12),
                      _actions(context, status),
                      if (_confirmLogout) ...<Widget>[
                        const SizedBox(height: 12),
                        ModelAiInlineConfirm(
                          title: '退出 ${widget.provider.displayName} 账号',
                          message: '会从本机移除账号凭据，供应商与模型配置仍会保留。',
                          confirmLabel: '退出账号',
                          onCancel: () =>
                              setState(() => _confirmLogout = false),
                          onConfirm: _logout,
                        ),
                      ],
                      if (configured != null) ...<Widget>[
                        const SizedBox(height: ModelAiMetrics.sectionGap),
                        ModelAiSection(
                          title: '供应商配置',
                          padding: EdgeInsets.zero,
                          child: ModelAiRow(
                            icon: ModelAiIcons.endpoint,
                            title: configured.name,
                            subtitle: configured.endpoint.isEmpty
                                ? '使用供应商默认端点'
                                : configured.endpoint,
                            onTap: () => _openProviderDetail(configured),
                          ),
                        ),
                      ],
                      const SizedBox(height: ModelAiMetrics.sectionGap),
                      ModelAiSection(
                        title: '账号信息',
                        padding: EdgeInsets.zero,
                        child: status?.signedIn == true
                            ? Column(
                                children: <Widget>[
                                  ModelAiRow(
                                    icon: ModelAiIcons.account,
                                    title: '登录邮箱',
                                    subtitle: status!.email.isEmpty
                                        ? '账号已连接'
                                        : status.email,
                                    showChevron: false,
                                  ),
                                  _line(context),
                                  ModelAiRow(
                                    icon: ModelAiIcons.apiKey,
                                    title: '授权方式',
                                    subtitle: _loginStyleLabel,
                                    showChevron: false,
                                  ),
                                  _line(context),
                                  ModelAiRow(
                                    icon: ModelAiIcons.spark,
                                    title: '订阅状态',
                                    subtitle: status.planEnabled
                                        ? '订阅账号可用'
                                        : '未检测到订阅，可能仍可使用 API Key',
                                    showChevron: false,
                                  ),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '尚未连接账号。登录后可在对话中直接使用该供应商的订阅额度。',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ModelAiPalette.of(
                                          context,
                                        ).textSecondary,
                                        height: 1.45,
                                      ),
                                ),
                              ),
                      ),
                      const SizedBox(height: ModelAiMetrics.sectionGap),
                      ModelAiSection(
                        title: '授权说明',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _note(
                              context,
                              ModelAiIcons.info,
                              '授权在系统浏览器完成，应用只接收结果，不会读取浏览器内容。',
                            ),
                            const SizedBox(height: 12),
                            _note(
                              context,
                              ModelAiIcons.deviceCode,
                              '同一账号同时只能有一处授权在进行，新授权会作废旧代码。',
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
        },
      ),
    );
  }

  Widget _hero(BuildContext context, core.ProviderAuthStatus? status) {
    final palette = ModelAiPalette.of(context);
    final signedIn = status?.signedIn == true;
    final needsReauth = status?.needsReauthentication == true;
    final label = needsReauth
        ? '需要重新授权'
        : signedIn
        ? (status!.planEnabled ? '订阅已启用' : '已连接')
        : '未连接';
    final tone = needsReauth
        ? ModelAiStatusTone.danger
        : signedIn
        ? (status!.planEnabled
              ? ModelAiStatusTone.success
              : ModelAiStatusTone.accent)
        : ModelAiStatusTone.neutral;
    return ModelAiSection(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProviderLogo(
            providerTypeId: widget.provider.providerTypeId,
            fallbackName: widget.provider.displayName,
            size: 52,
            preserveBrandColor: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.provider.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.provider.providerTypeId} · $_loginStyleLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 10),
                ModelAiStatusPill(label: label, tone: tone, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, core.ProviderAuthStatus? status) {
    final signedIn = status?.signedIn == true;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _login,
          icon: const Icon(ModelAiIcons.signIn, size: 17),
          label: Text(signedIn ? '重新授权' : '登录账号'),
        ),
        if (signedIn)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() => _confirmLogout = true),
            icon: const Icon(ModelAiIcons.signOut, size: 17),
            label: const Text('退出账号'),
          ),
      ],
    );
  }

  Widget _note(BuildContext context, IconData icon, String text) {
    final palette = ModelAiPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: palette.textTertiary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: ModelAiPalette.of(context).border.withValues(alpha: 0.5),
    );
  }
}
