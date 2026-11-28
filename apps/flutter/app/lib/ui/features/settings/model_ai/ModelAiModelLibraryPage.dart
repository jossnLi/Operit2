// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';

/// Searchable model catalog grouped by provider.
///
/// Details expand inside the list instead of opening a bottom sheet, so the user
/// can compare models without losing their scroll position.
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
  String? _expandedKey;

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
          icon: const Icon(ModelAiIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ModelAiMetrics.pagePadding,
              12,
              ModelAiMetrics.pagePadding,
              8,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '搜索模型或供应商',
                prefixIcon: Icon(
                  ModelAiIcons.search,
                  size: 18,
                  color: palette.textTertiary,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(ModelAiIcons.close, size: 16),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: palette.inset.withValues(alpha: 0.72),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: palette.border.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.accent, width: 1.2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: ModelAiMetrics.pagePadding,
              ),
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
                    padding: const EdgeInsets.fromLTRB(
                      ModelAiMetrics.pagePadding,
                      8,
                      ModelAiMetrics.pagePadding,
                      32,
                    ),
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
                              padding: EdgeInsets.fromLTRB(
                                2,
                                index == 0 ? 2 : 18,
                                2,
                                8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  ProviderLogo(
                                    providerTypeId: model.providerTypeId,
                                    fallbackName: model.providerName,
                                    size: 26,
                                    preserveBrandColor: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    model.providerName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: palette.textTertiary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ModelAiSection(
                              padding: EdgeInsets.zero,
                              child: _modelItem(context, model),
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

  Widget _modelItem(BuildContext context, core.ProviderModelSummary model) {
    final palette = ModelAiPalette.of(context);
    final key = '${model.providerId}:${model.modelId}';
    final expanded = _expandedKey == key;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ModelAiRow(
          icon: ModelAiIcons.model,
          leading: ProviderLogo(
            providerTypeId: model.providerTypeId,
            fallbackName: model.providerName,
            size: 38,
            preserveBrandColor: true,
          ),
          title: model.modelId,
          subtitle: _modelSubtitle(model),
          showChevron: false,
          onTap: () => setState(() {
            _expandedKey = expanded ? null : key;
          }),
          trailing: Icon(
            expanded ? ModelAiIcons.expandLess : ModelAiIcons.expandMore,
            size: 18,
            color: palette.textTertiary,
          ),
        ),
        if (expanded) ...<Widget>[
          Divider(
            height: 1,
            indent: 64,
            endIndent: 14,
            color: palette.border.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ModelAiMeta(
                        label: '上下文',
                        value: _formatContext(model.context.maxContextLength),
                        icon: ModelAiIcons.context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModelAiMeta(
                        label: '能力',
                        value: _capabilityText(model),
                        icon: ModelAiIcons.spark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ModelAiMeta(
                  label: '接口地址',
                  value: model.endpoint.isEmpty ? '使用供应商默认端点' : model.endpoint,
                  icon: ModelAiIcons.endpoint,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onOpenLegacy,
                    icon: const Icon(ModelAiIcons.settings, size: 16),
                    label: const Text('在高级设置中配置'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _filterChip(BuildContext context, String label, String? provider) {
    final palette = ModelAiPalette.of(context);
    final selected = _providerFilter == provider;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected ? palette.accent : palette.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: palette.inset.withValues(alpha: 0.55),
        selectedColor: palette.accentTint,
        side: BorderSide(
          color: selected
              ? palette.accent.withValues(alpha: 0.35)
              : palette.border.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        onSelected: (_) => setState(() {
          _providerFilter = provider;
          _expandedKey = null;
        }),
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

  String _capabilityText(core.ProviderModelSummary model) {
    final capabilities = <String>[
      if (model.capabilities.directImage) '视觉',
      if (model.capabilities.directAudio) '语音',
      if (model.capabilities.directVideo) '视频',
      if (model.capabilities.toolCall) '工具调用',
    ];
    return capabilities.isEmpty ? '文本' : capabilities.join(' · ');
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
}
