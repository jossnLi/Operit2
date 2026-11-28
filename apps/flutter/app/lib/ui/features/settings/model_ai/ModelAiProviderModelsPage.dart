// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';

/// Dedicated provider-model management surface.
///
/// Replaces the old settings modal: configured models can be removed and
/// catalog models can be added without leaving the redesigned module.
class ModelAiProviderModelsPage extends StatefulWidget {
  const ModelAiProviderModelsPage({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.clients,
  });

  final String providerId;
  final String providerName;
  final GeneratedCoreProxyClients clients;

  @override
  State<ModelAiProviderModelsPage> createState() =>
      _ModelAiProviderModelsPageState();
}

class _ModelAiProviderModelsPageState extends State<ModelAiProviderModelsPage> {
  final TextEditingController _search = TextEditingController();
  core.ProviderProfile? _profile;
  List<core.AvailableProviderModel> _available = const [];
  String _query = '';
  String? _pendingDelete;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await widget.clients.preferencesModelConfigManager
          .getProviderProfile(providerId: widget.providerId);
      final available = await widget.clients.preferencesModelConfigManager
          .getAvailableProviderModels(providerId: widget.providerId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _available = available;
          _pendingDelete = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _add(core.AvailableProviderModel model) async {
    setState(() => _busy = true);
    try {
      await widget.clients.preferencesModelConfigManager.createProviderModel(
        providerId: widget.providerId,
        modelId: model.modelId,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete(String modelId) async {
    setState(() => _busy = true);
    try {
      await widget.clients.preferencesModelConfigManager.deleteModel(
        providerId: widget.providerId,
        modelId: modelId,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  List<core.AvailableProviderModel> get _visibleAvailable {
    final existing = <String>{
      for (final model in _profile?.models ?? const <core.ModelProfile>[])
        model.id,
    };
    final query = _query.trim().toLowerCase();
    return _available
        .where((model) => !existing.contains(model.modelId))
        .where(
          (model) =>
              query.isEmpty || model.modelId.toLowerCase().contains(query),
        )
        .take(80)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final models = _profile?.models ?? const <core.ModelProfile>[];
    final available = _visibleAvailable;
    return ModelAiPageScaffold(
      title: widget.providerName,
      body: ListView(
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
                  if (_error != null)
                    ModelAiInlineError(message: _error!, onRetry: _reload),
                  if (_error != null) const SizedBox(height: 16),
                  ModelAiSection(
                    title: '已配置模型',
                    subtitle: '${models.length} 个 · 点击移除后可重新添加',
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        if (_pendingDelete != null) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: ModelAiInlineConfirm(
                              title: '移除 $_pendingDelete？',
                              message: '只会删除本机模型配置，不影响供应商账号。',
                              confirmLabel: '移除',
                              onCancel: () =>
                                  setState(() => _pendingDelete = null),
                              onConfirm: () {
                                final id = _pendingDelete;
                                if (id != null) {
                                  _delete(id);
                                }
                              },
                            ),
                          ),
                          _line(context),
                        ],
                        if (models.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '还没有配置模型。可从下方目录添加。',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                          )
                        else
                          for (
                            var index = 0;
                            index < models.length;
                            index++
                          ) ...<Widget>[
                            if (index > 0) _line(context),
                            ModelAiRow(
                              icon: ModelAiIcons.model,
                              title: models[index].id,
                              subtitle: '本机模型配置',
                              showChevron: false,
                              trailing: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _pendingDelete = models[index].id,
                                      ),
                                child: const Text('移除'),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '添加模型',
                    subtitle: '来自供应商目录，未配置的模型才会出现',
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: '搜索模型 ID',
                            prefixIcon: Icon(
                              ModelAiIcons.search,
                              size: 18,
                              color: palette.textTertiary,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: palette.inset.withValues(alpha: 0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (available.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              _available.isEmpty
                                  ? '供应商目录为空，请先在供应商详情里刷新目录。'
                                  : '没有可添加的模型。',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                          )
                        else
                          for (
                            var index = 0;
                            index < available.length;
                            index++
                          ) ...<Widget>[
                            if (index > 0) _line(context),
                            ModelAiRow(
                              icon: ModelAiIcons.add,
                              title: available[index].modelId,
                              subtitle: _modelDetail(available[index]),
                              showChevron: false,
                              trailing: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _add(available[index]),
                                child: const Text('添加'),
                              ),
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

  String _modelDetail(core.AvailableProviderModel model) {
    final parts = <String>[
      if (model.context != null && model.context!.maxContextLength > 0)
        '上下文 ${_formatContext(model.context!.maxContextLength)}',
      if (model.capabilities?.toolCall == true) '工具',
      if (model.capabilities?.directImage == true) '视觉',
      if (model.capabilities?.directAudio == true) '语音',
    ];
    return parts.isEmpty ? '文本模型' : parts.join(' · ');
  }

  String _formatContext(double value) {
    if (value >= 1_000_000) {
      return '${(value / 1_000_000).toStringAsFixed(1)}M';
    }
    if (value >= 1_000) {
      return '${(value / 1_000).round()}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _line(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: ModelAiPalette.of(context).border.withValues(alpha: 0.55),
    );
  }
}
