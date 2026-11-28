// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';

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

  static const List<core.FunctionType> _functions = <core.FunctionType>[
    core.FunctionType.chat,
    core.FunctionType.summary,
    core.FunctionType.titleGeneration,
    core.FunctionType.memory,
    core.FunctionType.uiController,
    core.FunctionType.translation,
    core.FunctionType.grep,
    core.FunctionType.roleResponsePlanner,
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
    setState(() => _busy = true);
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
    setState(() => _busy = true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能映射'),
        leading: IconButton(
          icon: const Icon(OperitIcons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _busy ? null : _followAll,
            child: const Text('全部跟随'),
          ),
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
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < _functions.length;
                          index++
                        ) ...<Widget>[
                          if (index > 0)
                            Divider(
                              height: 1,
                              indent: 50,
                              color: palette.border,
                            ),
                          _functionRow(context, _functions[index]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
    return ModelAiRow(
      icon: type == core.FunctionType.chat
          ? OperitIcons.chat_bubble_outline_rounded
          : OperitIcons.route_outlined,
      title: _label(type),
      subtitle: detail,
      tone: follows ? ModelAiIconTone.neutral : ModelAiIconTone.blue,
      showChevron: true,
      onTap: _busy ? null : () => _pick(type, follows),
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

  Future<void> _pick(core.FunctionType type, bool follows) async {
    final choice = await showModalBottomSheet<_FunctionChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: <Widget>[
          ListTile(
            leading: const Icon(OperitIcons.refresh_rounded, size: 20),
            title: const Text('跟随对话模型'),
            subtitle: const Text('自动复用当前对话绑定'),
            selected: follows,
            onTap: () =>
                Navigator.of(context).pop(const _FunctionChoice.followChat()),
          ),
          const Divider(),
          for (final model in widget.summaries)
            ListTile(
              leading: const Icon(OperitIcons.psychology_outlined, size: 20),
              title: Text(model.modelId),
              subtitle: Text(model.providerName),
              onTap: () =>
                  Navigator.of(context).pop(_FunctionChoice.model(model)),
            ),
        ],
      ),
    );
    if (choice == null) {
      return;
    }
    if (choice.followChat) {
      await _followChat(type);
    } else if (choice.model != null) {
      await _assign(type, choice.model!);
    }
  }
}

class _FunctionChoice {
  const _FunctionChoice.followChat() : followChat = true, model = null;
  const _FunctionChoice.model(this.model) : followChat = false;

  final bool followChat;
  final core.ProviderModelSummary? model;
}
