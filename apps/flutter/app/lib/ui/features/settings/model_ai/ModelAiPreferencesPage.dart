// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiFunctionMappingPage.dart';
import 'package:operit2/ui/features/settings/model_ai/ModelAiHomeData.dart';

/// Model-independent generation and history preferences.
class ModelAiPreferencesPage extends StatefulWidget {
  const ModelAiPreferencesPage({
    super.key,
    required this.data,
    required this.clients,
  });

  final ModelAiHomeData data;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiPreferencesPage> createState() => _ModelAiPreferencesPageState();
}

class _ModelAiPreferencesPageState extends State<ModelAiPreferencesPage> {
  int? _imageTurns;
  int? _mediaTurns;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = widget.clients.preferencesApiPreferences;
      final image = await preferences.maxImageHistoryUserTurnsFlow().first;
      final media = await preferences.maxMediaHistoryUserTurnsFlow().first;
      if (mounted) {
        setState(() {
          _imageTurns = image;
          _mediaTurns = media;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageTurns = 3;
          _mediaTurns = 1;
        });
      }
    }
  }

  Future<void> _saveHistory({int? image, int? media}) async {
    final nextImage = image ?? _imageTurns;
    final nextMedia = media ?? _mediaTurns;
    if (nextImage == null || nextMedia == null || _saving) {
      return;
    }
    setState(() {
      _imageTurns = nextImage;
      _mediaTurns = nextMedia;
      _saving = true;
    });
    try {
      await widget.clients.preferencesApiPreferences.updateMediaHistorySettings(
        maxImageHistoryUserTurns: nextImage,
        maxMediaHistoryUserTurns: nextMedia,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openFunctionMapping() async {
    final bindings = await widget.clients.preferencesFunctionalConfigManager
        .functionModelBindingFlow()
        .first;
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ModelAiFunctionMappingPage(
          clients: widget.clients,
          summaries: widget.data.summaries,
          initialBindings: bindings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final config = widget.data.currentConfig;
    return ModelAiPageScaffold(
      title: 'AI 参数',
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
                    title: '对话模型',
                    subtitle: '参数按模型保存',
                    padding: EdgeInsets.zero,
                    child: ModelAiRow(
                      icon: ModelAiIcons.model,
                      leading: ProviderLogo(
                        providerTypeId: config?.apiProviderTypeId ?? '',
                        fallbackName: config?.providerName ?? '未设置',
                        size: 40,
                        preserveBrandColor: true,
                      ),
                      title: config?.modelId ?? widget.data.chatBinding.modelId,
                      subtitle: config?.providerName ?? '尚未设置',
                      tone: ModelAiIconTone.blue,
                      onTap: _openFunctionMapping,
                    ),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '历史上下文',
                    subtitle: '限制图片和多模态消息回放到当前对话中的轮数',
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: <Widget>[
                        _historySlider(
                          context,
                          label: '图片历史',
                          value: _imageTurns,
                          min: 0,
                          max: 20,
                          onChanged: (value) => _saveHistory(image: value),
                        ),
                        const SizedBox(height: 6),
                        _historySlider(
                          context,
                          label: '媒体历史',
                          value: _mediaTurns,
                          min: 0,
                          max: 10,
                          onChanged: (value) => _saveHistory(media: value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '模型行为',
                    padding: EdgeInsets.zero,
                    child: ModelAiRow(
                      icon: ModelAiIcons.functionMapping,
                      title: '功能映射',
                      subtitle: '为标题、翻译、压缩等任务指定模型',
                      tone: ModelAiIconTone.amber,
                      onTap: _openFunctionMapping,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '参数按模型保存，切换模型不会覆盖其他模型的设置。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.4,
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

  Widget _historySlider(
    BuildContext context, {
    required String label,
    required int? value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final palette = ModelAiPalette.of(context);
    final current = (value ?? min).clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.text),
              ),
            ),
            Text(
              current == 0 ? '关闭' : '$current 轮',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
        Slider(
          value: current.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: _saving
              ? null
              : (next) => setState(() {
                  if (label == '图片历史') {
                    _imageTurns = next.round();
                  } else {
                    _mediaTurns = next.round();
                  }
                }),
          onChangeEnd: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
