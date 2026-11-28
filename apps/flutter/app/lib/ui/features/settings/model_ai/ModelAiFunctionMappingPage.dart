// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';

/// Assigns each runtime function to the chat model or a dedicated model.
class ModelAiFunctionMappingPage extends StatefulWidget {
  const ModelAiFunctionMappingPage({
    super.key,
    required this.clients,
    required this.summaries,
    required this.initialBindings,
  });

  final GeneratedCoreProxyClients clients;
  final List<core.ProviderModelSummary> summaries;
  final Map<core.FunctionType, core.FunctionModelBinding> initialBindings;

  @override
  State<ModelAiFunctionMappingPage> createState() =>
      _ModelAiFunctionMappingPageState();
}

class _ModelAiFunctionMappingPageState
    extends State<ModelAiFunctionMappingPage> {
  late Map<core.FunctionType, core.FunctionModelBinding> _bindings;
  bool _busy = false;
  core.FunctionType? _expanded;

  static const List<core.FunctionType> _textFunctions = <core.FunctionType>[
    core.FunctionType.chat,
    core.FunctionType.summary,
    core.FunctionType.titleGeneration,
    core.FunctionType.memory,
    core.FunctionType.translation,
    core.FunctionType.grep,
  ];

  static const List<core.FunctionType> _interactionFunctions =
      <core.FunctionType>[
        core.FunctionType.uiController,
        core.FunctionType.roleResponsePlanner,
      ];

  static const List<core.FunctionType> _multimodalFunctions =
      <core.FunctionType>[
        core.FunctionType.imageRecognition,
        core.FunctionType.audioRecognition,
        core.FunctionType.videoRecognition,
      ];

  @override
  void initState() {
    super.initState();
    _bindings = Map<core.FunctionType, core.FunctionModelBinding>.from(
      widget.initialBindings,
    );
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final bindings = await widget.clients.preferencesFunctionalConfigManager
          .functionModelBindingFlow()
          .first;
      if (mounted) {
        setState(() => _bindings = bindings);
      }
    } catch (_) {
      // Keep the snapshot passed by the caller.
    }
  }

  String _label(core.FunctionType type) {
    return switch (type) {
      core.FunctionType.chat => '对话',
      core.FunctionType.summary => '摘要',
      core.FunctionType.titleGeneration => '标题生成',
      core.FunctionType.memory => '记忆',
      core.FunctionType.uiController => '界面控制',
      core.FunctionType.translation => '翻译',
      core.FunctionType.grep => '内容检索',
      core.FunctionType.roleResponsePlanner => '角色回复规划',
      core.FunctionType.imageRecognition => '图片识别',
      core.FunctionType.audioRecognition => '音频识别',
      core.FunctionType.videoRecognition => '视频识别',
    };
  }

  Future<void> _followChat(core.FunctionType type) async {
    setState(() {
      _busy = true;
      _expanded = null;
    });
    try {
      await widget.clients.preferencesFunctionalConfigManager
          .setFunctionFollowChat(functionType: type);
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _assign(
    core.FunctionType type,
    core.ProviderModelSummary model,
  ) async {
    setState(() {
      _busy = true;
      _expanded = null;
    });
    try {
      await widget.clients.preferencesFunctionalConfigManager
          .setModelForFunction(
            functionType: type,
            providerId: model.providerId,
            modelId: model.modelId,
          );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _followAll() async {
    setState(() => _busy = true);
    try {
      await widget.clients.preferencesFunctionalConfigManager
          .setAllFunctionsFollowChat();
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final following = _bindings.values
        .where((binding) => binding.followsChat)
        .length;
    return ModelAiPageScaffold(
      title: '功能映射',
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : _followAll,
          child: const Text('全部跟随'),
        ),
      ],
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        const ModelAiIconTile(
                          icon: ModelAiIcons.functionMapping,
                          tone: ModelAiIconTone.blue,
                          size: 42,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '按功能分配模型',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '未单独指定时，全部跟随当前对话模型。',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: palette.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        ModelAiStatusPill(
                          label: '$following 项跟随',
                          tone: ModelAiStatusTone.neutral,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  _functionGroup(context, '对话与文本', _textFunctions),
                  const SizedBox(height: 16),
                  _functionGroup(context, '交互与角色', _interactionFunctions),
                  const SizedBox(height: 16),
                  _functionGroup(context, '多模态', _multimodalFunctions),
                  const SizedBox(height: 18),
                  Text(
                    '跟随对话的项会自动使用当前对话模型；单独指定后，切换对话模型不会影响该功能。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.45,
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

  Widget _functionGroup(
    BuildContext context,
    String title,
    List<core.FunctionType> functions,
  ) {
    final palette = ModelAiPalette.of(context);
    return ModelAiSection(
      title: title,
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var index = 0; index < functions.length; index++) ...<Widget>[
            if (index > 0)
              Divider(
                height: 1,
                indent: 64,
                color: palette.border.withValues(alpha: 0.5),
              ),
            _functionRow(context, functions[index]),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(core.FunctionType type) {
    return switch (type) {
      core.FunctionType.chat => ModelAiIcons.chatFunction,
      core.FunctionType.summary => ModelAiIcons.summaryFunction,
      core.FunctionType.titleGeneration => ModelAiIcons.titleFunction,
      core.FunctionType.memory => ModelAiIcons.memoryFunction,
      core.FunctionType.uiController => ModelAiIcons.uiControlFunction,
      core.FunctionType.translation => ModelAiIcons.translationFunction,
      core.FunctionType.grep => ModelAiIcons.retrievalFunction,
      core.FunctionType.roleResponsePlanner => ModelAiIcons.rolePlannerFunction,
      core.FunctionType.imageRecognition => ModelAiIcons.imageFunction,
      core.FunctionType.audioRecognition => ModelAiIcons.audioFunction,
      core.FunctionType.videoRecognition => ModelAiIcons.videoFunction,
    };
  }

  Widget _functionRow(BuildContext context, core.FunctionType type) {
    final binding = _bindings[type];
    final follows = binding?.followsChat ?? true;
    final model = binding == null
        ? null
        : _findModel(binding.providerId, binding.modelId);
    final detail = follows
        ? '跟随对话模型'
        : (model == null
              ? binding?.modelId ?? '未设置'
              : '${model.providerName} · ${model.modelId}');
    final expanded = _expanded == type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ModelAiRow(
          icon: _iconFor(type),
          title: _label(type),
          subtitle: detail,
          tone: follows ? ModelAiIconTone.neutral : ModelAiIconTone.blue,
          showChevron: false,
          trailing: Icon(
            expanded ? ModelAiIcons.expandLess : ModelAiIcons.expandMore,
            size: 18,
            color: ModelAiPalette.of(context).textTertiary,
          ),
          onTap: _busy
              ? null
              : () => setState(() => _expanded = expanded ? null : type),
        ),
        if (expanded) _inlinePicker(context, type, follows, binding),
      ],
    );
  }

  Widget _inlinePicker(
    BuildContext context,
    core.FunctionType type,
    bool follows,
    core.FunctionModelBinding? binding,
  ) {
    final palette = ModelAiPalette.of(context);
    return Container(
      color: palette.inset.withValues(alpha: 0.32),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _pickerRow(
            context,
            icon: ModelAiIcons.refresh,
            title: '跟随对话模型',
            subtitle: '自动复用当前对话绑定',
            selected: follows,
            onTap: _busy ? null : () => _followChat(type),
          ),
          if (widget.summaries.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
              child: Text(
                '指定模型',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final model in widget.summaries)
              _pickerRow(
                context,
                leading: ProviderLogo(
                  providerTypeId: model.providerTypeId,
                  fallbackName: model.providerName,
                  size: 28,
                  preserveBrandColor: true,
                ),
                icon: ModelAiIcons.model,
                title: model.modelId,
                subtitle: model.providerName,
                selected:
                    !follows &&
                    binding?.providerId == model.providerId &&
                    binding?.modelId == model.modelId,
                onTap: _busy ? null : () => _assign(type, model),
              ),
            if (!follows && binding == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '当前绑定不在模型库中，请到高级设置中检查。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.warning,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pickerRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
    Widget? leading,
  }) {
    final palette = ModelAiPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: <Widget>[
            leading ??
                Icon(
                  icon,
                  size: 20,
                  color: selected ? palette.accent : palette.textTertiary,
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? palette.accent : palette.text,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(ModelAiIcons.selection, size: 18, color: palette.accent),
          ],
        ),
      ),
    );
  }

  core.ProviderModelSummary? _findModel(String providerId, String modelId) {
    for (final model in widget.summaries) {
      if (model.providerId == providerId && model.modelId == modelId) {
        return model;
      }
    }
    return null;
  }
}
