// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';

/// Diagnostics for the active model binding and provider accounts.
class ModelAiDiagnosticsPage extends StatefulWidget {
  const ModelAiDiagnosticsPage({
    super.key,
    required this.data,
    required this.clients,
    required this.onOpenLegacy,
  });

  final ModelAiHomeData data;
  final GeneratedCoreProxyClients clients;
  final VoidCallback onOpenLegacy;

  @override
  State<ModelAiDiagnosticsPage> createState() => _ModelAiDiagnosticsPageState();
}

class _ModelAiDiagnosticsPageState extends State<ModelAiDiagnosticsPage> {
  bool _testing = false;
  core.ModelConnectionTestReport? _report;
  String? _error;

  Future<void> _test() async {
    final binding = widget.data.chatBinding;
    if (binding.providerId.isEmpty || binding.modelId.isEmpty) {
      setState(() => _error = '尚未设置对话模型');
      return;
    }
    setState(() {
      _testing = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await widget.clients.application.testModelConnection(
        providerId: binding.providerId,
        modelId: binding.modelId,
      );
      if (mounted) {
        setState(() => _report = report);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final config = widget.data.currentConfig;
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接诊断'),
        leading: IconButton(
          icon: const Icon(OperitIcons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(onPressed: widget.onOpenLegacy, child: const Text('高级设置')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ModelAiSection(
                    title: '当前配置',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        _infoRow(
                          context,
                          '供应商',
                          config?.providerName ??
                              (widget.data.chatBinding.providerId.isEmpty
                                  ? '未设置'
                                  : widget.data.chatBinding.providerId),
                        ),
                        _line(context),
                        _infoRow(
                          context,
                          '模型',
                          config?.modelId ?? widget.data.chatBinding.modelId,
                        ),
                        _line(context),
                        _infoRow(context, '端点', config?.apiEndpoint ?? '未提供'),
                        _line(context),
                        _infoRow(
                          context,
                          '已配置供应商',
                          '${widget.data.providers.length} 个 · ${widget.data.summaries.length} 个模型',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '连接测试',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: palette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _testing ? null : _test,
                        icon: _testing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                OperitIcons.play_arrow_rounded,
                                size: 16,
                              ),
                        label: Text(_testing ? '测试中' : '运行测试'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    ModelAiInlineError(message: _error!, onRetry: _test),
                  if (_report != null) _reportCard(context, _report!),
                  if (_report == null && _error == null)
                    ModelAiSection(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '测试会使用当前模型发送一次最小请求，检查网络、凭据和响应格式。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  ModelAiSection(
                    title: '账号',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (final provider
                            in widget.data.authProviders) ...<Widget>[
                          _accountLine(context, provider),
                          _line(context),
                        ],
                        ModelAiNavRow(
                          label: '管理供应商与凭据',
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
      ),
    );
  }

  Widget _reportCard(
    BuildContext context,
    core.ModelConnectionTestReport report,
  ) {
    final palette = ModelAiPalette.of(context);
    return ModelAiSection(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: <Widget>[
                Icon(
                  report.success
                      ? OperitIcons.check_circle_outline_rounded
                      : OperitIcons.error_outline_rounded,
                  color: report.success ? palette.success : palette.danger,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.success ? '连接成功' : '连接失败',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: report.success ? palette.success : palette.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final item in report.items)
            ListTile(
              dense: true,
              leading: Icon(
                item.success
                    ? OperitIcons.check_rounded
                    : OperitIcons.close_rounded,
                size: 16,
                color: item.success ? palette.success : palette.danger,
              ),
              title: Text('${item.type}'),
              subtitle: (item.error ?? '').isEmpty ? null : Text(item.error!),
            ),
        ],
      ),
    );
  }

  Widget _accountLine(
    BuildContext context,
    core.ProviderAuthProviderView provider,
  ) {
    final palette = ModelAiPalette.of(context);
    final account = widget.data.accounts[provider.providerTypeId.toUpperCase()];
    final signedIn = account?.signedIn ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              provider.displayName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.text),
            ),
          ),
          ModelAiStatusPill(
            label: signedIn
                ? (account!.email.isEmpty ? '已连接' : account.email)
                : '未连接',
            tone: signedIn
                ? ModelAiStatusTone.success
                : ModelAiStatusTone.neutral,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final palette = ModelAiPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '未提供' : value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.text, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: ModelAiPalette.of(context).border.withValues(alpha: 0.6),
    );
  }
}
