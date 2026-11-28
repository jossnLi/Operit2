// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';

import 'ModelAiAccountDetailPage.dart';
import 'ModelAiHomeData.dart';
import 'ModelAiProviderDetailPage.dart';

/// Dedicated account-authorization surface.
///
/// Keeping this out of the overview avoids a five-row block on the home page and
/// gives browser/device authorization a full page instead of a modal.
class ModelAiAccountsPage extends StatefulWidget {
  const ModelAiAccountsPage({
    super.key,
    required this.data,
    required this.clients,
  });

  final ModelAiHomeData data;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiAccountsPage> createState() => _ModelAiAccountsPageState();
}

class _ModelAiAccountsPageState extends State<ModelAiAccountsPage> {
  late ModelAiHomeData _data = widget.data;

  Future<void> _reload() async {
    final next = await loadModelAiHomeData(widget.clients);
    if (mounted) {
      setState(() => _data = next);
    }
  }

  core.ProviderProfile? _configuredProvider(
    core.ProviderAuthProviderView provider,
  ) {
    for (final item in _data.providers) {
      if (item.providerTypeId.toUpperCase() ==
          provider.providerTypeId.toUpperCase()) {
        return item;
      }
    }
    return null;
  }

  Future<void> _openAccount(core.ProviderAuthProviderView provider) async {
    final configured = _configuredProvider(provider);
    if (configured != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ModelAiProviderDetailPage(
            providerId: configured.id,
            clients: widget.clients,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ModelAiAccountDetailPage(
            provider: provider,
            clients: widget.clients,
          ),
        ),
      );
    }
    if (mounted) {
      await _reload();
    }
  }

  int get _connectedCount => _data.authProviders
      .where(
        (provider) =>
            _data.accounts[provider.providerTypeId.toUpperCase()]?.signedIn ==
            true,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final total = _data.authProviders.length;
    return ModelAiPageScaffold(
      title: '账号授权',
      body: ListView(
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
                  ModelAiSection(
                    title: '可授权供应商',
                    subtitle: total == 0
                        ? '授权后在对话里直接使用订阅账号'
                        : '$_connectedCount / $total 已连接 · 授权后可直接在对话里使用',
                    padding: EdgeInsets.zero,
                    child: _data.authProviders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              '当前没有可用的账号授权供应商。',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          )
                        : Column(
                            children: <Widget>[
                              for (
                                var index = 0;
                                index < _data.authProviders.length;
                                index++
                              ) ...<Widget>[
                                if (index > 0)
                                  Divider(
                                    height: 1,
                                    indent: 70,
                                    color: palette.border.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                _accountRow(
                                  context,
                                  _data.authProviders[index],
                                  _data.accounts[_data
                                      .authProviders[index]
                                      .providerTypeId
                                      .toUpperCase()],
                                ),
                              ],
                            ],
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
                        const SizedBox(height: 12),
                        _note(
                          context,
                          ModelAiIcons.apiKey,
                          '账号受限时可继续使用 API Key，两种凭据可以并存。',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountRow(
    BuildContext context,
    core.ProviderAuthProviderView provider,
    core.ProviderAuthStatus? status,
  ) {
    final signedIn = status?.signedIn ?? false;
    final planEnabled = status?.planEnabled ?? false;
    final detail = signedIn
        ? (status!.email.isNotEmpty ? status.email : '账号已连接')
        : provider.loginStyle == 'device_code'
        ? '设备码登录'
        : provider.loginStyle == 'manual_code'
        ? '手动授权码'
        : '浏览器授权';
    return ModelAiRow(
      icon: ModelAiIcons.account,
      leading: ProviderLogo(
        providerTypeId: provider.providerTypeId,
        fallbackName: provider.displayName,
        size: 40,
        preserveBrandColor: true,
      ),
      title: provider.displayName,
      subtitle: detail,
      showChevron: true,
      onTap: () => _openAccount(provider),
      trailing: signedIn
          ? ModelAiStatusPill(
              label: planEnabled ? '订阅已启用' : '已连接',
              tone: planEnabled
                  ? ModelAiStatusTone.success
                  : ModelAiStatusTone.neutral,
              compact: true,
            )
          : const ModelAiStatusPill(
              label: '未连接',
              tone: ModelAiStatusTone.neutral,
              compact: true,
            ),
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
}
