// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';

/// Diagnostics for the active model binding and provider accounts.
class ModelAiDiagnosticsPage extends StatefulWidget {
  const ModelAiDiagnosticsPage({
    super.key,
    required this.data,
    required this.clients,
  });

  final ModelAiHomeData data;
  final GeneratedCoreProxyClients clients;

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
    return ModelAiPageScaffold(
      title: '连接诊断',
      body: ListView(
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
                  ModelAiSection(
                    title: '当前配置',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        ModelAiRow(
                          icon: ModelAiIcons.model,
                          leading: ProviderLogo(
                            providerTypeId: config?.apiProviderTypeId ?? '',
                            fallbackName: config?.providerName ?? '未设置',
                            size: 40,
                            preserveBrandColor: true,
                          ),
                          title:
                              config?.modelId ??
                              (widget.data.chatBinding.modelId.isEmpty
                                  ? '尚未设置模型'
                                  : widget.data.chatBinding.modelId),
                          subtitle:
                              config?.providerName ??
                              (widget.data.chatBinding.providerId.isEmpty
                                  ? '未设置供应商'
                                  : widget.data.chatBinding.providerId),
                          showChevron: false,
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
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '连接测试',
                    subtitle: '使用当前模型发送一次最小请求',
                    action: FilledButton.tonalIcon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(ModelAiIcons.runTest, size: 16),
                      label: Text(_testing ? '测试中' : '运行测试'),
                    ),
                    padding: EdgeInsets.zero,
                    child: _report == null && _error == null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '检查网络、凭据和响应格式。测试不会修改模型配置。',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: palette.textTertiary,
                                    height: 1.45,
                                  ),
                            ),
                          )
                        : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: ModelAiInlineError(
                              message: _error!,
                              onRetry: _test,
                            ),
                          )
                        : _reportCard(context, _report!),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '账号',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < widget.data.authProviders.length;
                          index++
                        ) ...<Widget>[
                          if (index > 0) _line(context),
                          _accountLine(
                            context,
                            widget.data.authProviders[index],
                          ),
                        ],
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
    final passed = report.items.where((item) => item.success).length;
    final allPassed = report.success && passed == report.items.length;
    final tone = allPassed ? palette.success : palette.danger;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _statusDot(tone, size: 9),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      allPassed
                          ? '全部检查通过'
                          : '$passed / ${report.items.length} 项通过',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${report.providerName} · ${report.modelId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                allPassed ? '通过' : '未通过',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: palette.border.withValues(alpha: 0.55)),
          for (var index = 0; index < report.items.length; index++) ...<Widget>[
            if (index > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 17),
                color: palette.border.withValues(alpha: 0.4),
              ),
            _testRow(context, report.items[index]),
          ],
        ],
      ),
    );
  }

  Widget _testRow(
    BuildContext context,
    core.CoreOperitProvidersChatLlmproviderModelConfigConnectionTesterModelConnectionTestItem
    item,
  ) {
    final palette = ModelAiPalette.of(context);
    final tone = item.success ? palette.success : palette.danger;
    final error = item.error?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _statusDot(tone, size: 7),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _testLabel(item.type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.success ? '通过' : '失败',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, {required double size}) {
    return Padding(
      padding: EdgeInsets.only(top: size == 9 ? 2 : 3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  String _testLabel(core.ModelConnectionTestType type) {
    return switch (type) {
      core.ModelConnectionTestType.chat => '基础对话',
      core.ModelConnectionTestType.toolCall => '工具调用',
      core.ModelConnectionTestType.image => '图像输入',
      core.ModelConnectionTestType.audio => '音频输入',
      core.ModelConnectionTestType.video => '视频输入',
    };
  }

  Widget _accountLine(
    BuildContext context,
    core.ProviderAuthProviderView provider,
  ) {
    final account = widget.data.accounts[provider.providerTypeId.toUpperCase()];
    final signedIn = account?.signedIn ?? false;
    final email = account?.email.trim() ?? '';
    return ModelAiRow(
      icon: ModelAiIcons.account,
      leading: ProviderLogo(
        providerTypeId: provider.providerTypeId,
        fallbackName: provider.displayName,
        size: 34,
        preserveBrandColor: true,
      ),
      title: provider.displayName,
      subtitle: signedIn ? (email.isEmpty ? '账号已连接' : email) : '尚未连接账号',
      showChevron: false,
      trailing: ModelAiStatusPill(
        label: signedIn ? '已连接' : '未连接',
        tone: signedIn ? ModelAiStatusTone.success : ModelAiStatusTone.neutral,
        compact: true,
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
