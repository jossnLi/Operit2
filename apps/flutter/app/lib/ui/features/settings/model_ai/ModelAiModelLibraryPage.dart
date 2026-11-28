// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';

/// Searchable model catalog grouped by provider.
class ModelAiModelLibraryPage extends StatefulWidget {
  const ModelAiModelLibraryPage({
    super.key,
    required this.models,
    required this.onOpenLegacy,
  });

  final List<core.ProviderModelSummary> models;
  final VoidCallback onOpenLegacy;

  @override
  State<ModelAiModelLibraryPage> createState() =>
      _ModelAiModelLibraryPageState();
}

class _ModelAiModelLibraryPageState extends State<ModelAiModelLibraryPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _providerFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<core.ProviderModelSummary> get _visibleModels {
    final query = _query.trim().toLowerCase();
    return widget.models
        .where((model) {
          if (_providerFilter != null &&
              model.providerName != _providerFilter) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return model.modelId.toLowerCase().contains(query) ||
              model.providerName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final providers = <String>{
      for (final model in widget.models) model.providerName,
    }.toList(growable: false);
    final models = _visibleModels;
    return Scaffold(
      appBar: AppBar(
        title: Text('模型库 · ${widget.models.length}'),
        leading: IconButton(
          icon: const Icon(OperitIcons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '搜索模型或供应商',
                prefixIcon: const Icon(OperitIcons.search_rounded, size: 18),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(OperitIcons.close_rounded, size: 16),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: <Widget>[
                _filterChip(context, '全部', null),
                for (final provider in providers)
                  _filterChip(context, provider, provider),
              ],
            ),
          ),
          Expanded(
            child: models.isEmpty
                ? Center(
                    child: Text(
                      '没有匹配的模型',
                      style: TextStyle(color: palette.textTertiary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    itemCount: models.length,
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final previousProvider = index == 0
                          ? null
                          : models[index - 1].providerName;
                      final showHeader =
                          _providerFilter == null &&
                          previousProvider != model.providerName;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                              child: Text(
                                model.providerName,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: palette.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: palette.group,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: palette.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: ModelAiRow(
                                icon: OperitIcons.psychology_outlined,
                                title: model.modelId,
                                subtitle: _modelSubtitle(model),
                                tone: ModelAiIconTone.blue,
                                onTap: () => _showModelSheet(context, model),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String? provider) {
    final selected = _providerFilter == provider;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => _providerFilter = provider),
      ),
    );
  }

  String _modelSubtitle(core.ProviderModelSummary model) {
    final parts = <String>[
      if (model.context.maxContextLength > 0)
        '上下文 ${_formatContext(model.context.maxContextLength)}',
      if (model.capabilities.toolCall) '工具',
      if (model.capabilities.directImage) '视觉',
      if (model.capabilities.directAudio) '语音',
    ];
    return parts.join(' · ');
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

  Future<void> _showModelSheet(
    BuildContext context,
    core.ProviderModelSummary model,
  ) {
    final palette = ModelAiPalette.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              model.modelId,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              model.providerName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
            ),
            const SizedBox(height: 18),
            _detailLine(
              context,
              '上下文窗口',
              _formatContext(model.context.maxContextLength),
            ),
            _detailLine(
              context,
              '能力',
              <String>[
                if (model.capabilities.directImage) '视觉',
                if (model.capabilities.directAudio) '语音',
                if (model.capabilities.directVideo) '视频',
                if (model.capabilities.toolCall) '工具调用',
              ].join(' · '),
            ),
            _detailLine(context, '接口地址', model.endpoint),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenLegacy();
              },
              child: const Text('在高级设置中配置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(BuildContext context, String label, String value) {
    final palette = ModelAiPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            child: Text(
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
}
