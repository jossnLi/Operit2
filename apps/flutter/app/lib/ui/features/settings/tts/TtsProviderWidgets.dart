// ignore_for_file: file_names

part of 'TtsSettingsPanel.dart';

class _SectionCard extends StatelessWidget {
  /// Creates one titled settings section with a glass content surface.
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(icon, size: 19, color: scheme.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          OperitGlassSurface(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: radius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.22),
            ),
            layer: OperitGlassSurfaceLayer.card,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TtsProviderManager extends StatelessWidget {
  const _TtsProviderManager({
    required this.groups,
    required this.currentConfigId,
    required this.testingConfigId,
    required this.expandedProviderKeys,
    required this.onToggleProviderExpanded,
    required this.onAddVoice,
    required this.onEditProvider,
    required this.onEditConfig,
    required this.onTestConfig,
    required this.onSetCurrent,
  });

  final List<_TtsProviderGroup> groups;
  final String currentConfigId;
  final String? testingConfigId;
  final Set<String> expandedProviderKeys;
  final ValueChanged<String> onToggleProviderExpanded;
  final void Function(_TtsProviderGroup group) onAddVoice;
  final void Function(_TtsProviderGroup group) onEditProvider;
  final void Function(core_proxy.CoreOperitModelTtsConfigTtsConfig config)
  onEditConfig;
  final Future<void> Function(
    core_proxy.CoreOperitModelTtsConfigTtsConfig config,
  )
  onTestConfig;
  final Future<void> Function(String id) onSetCurrent;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _VoiceEmptyState(
        icon: OperitIcons.record_voice_over_outlined,
        title: '还没有 TTS 供应商',
        message: '点击上方「添加」，接入一个语音合成供应商后即可选择音色。',
      );
    }
    return Column(
      children: <Widget>[
        for (final group in groups)
          _TtsProviderGroupTile(
            group: group,
            currentConfigId: currentConfigId,
            testingConfigId: testingConfigId,
            expanded: expandedProviderKeys.contains(group.key),
            onToggleExpanded: () => onToggleProviderExpanded(group.key),
            onAddVoice: () => onAddVoice(group),
            onEditProvider: () => onEditProvider(group),
            onEditConfig: onEditConfig,
            onTestConfig: onTestConfig,
            onSetCurrent: onSetCurrent,
          ),
      ],
    );
  }
}

class _TtsProviderGroupTile extends StatelessWidget {
  const _TtsProviderGroupTile({
    required this.group,
    required this.currentConfigId,
    required this.testingConfigId,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onAddVoice,
    required this.onEditProvider,
    required this.onEditConfig,
    required this.onTestConfig,
    required this.onSetCurrent,
  });

  final _TtsProviderGroup group;
  final String currentConfigId;
  final String? testingConfigId;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddVoice;
  final VoidCallback onEditProvider;
  final void Function(core_proxy.CoreOperitModelTtsConfigTtsConfig config)
  onEditConfig;
  final Future<void> Function(
    core_proxy.CoreOperitModelTtsConfigTtsConfig config,
  )
  onTestConfig;
  final Future<void> Function(String id) onSetCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentProvider = group.configs.any(
      (config) => config.id == currentConfigId,
    );
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: expanded
              ? scheme.surface.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: expanded
                ? scheme.primary.withValues(alpha: 0.22)
                : scheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              borderRadius: radius,
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 9, 10),
                child: Row(
                  children: <Widget>[
                    _VoiceAvatar(label: group.title, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  group.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (currentProvider) ...<Widget>[
                                const SizedBox(width: 6),
                                const _CurrentBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${group.configs.length} 个音色 · ${group.providerType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        OperitIcons.keyboard_arrow_down_rounded,
                        size: 19,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...<Widget>[
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: scheme.outlineVariant.withValues(alpha: 0.24),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TtsVoiceList(
                      configs: group.configs,
                      currentConfigId: currentConfigId,
                      testingConfigId: testingConfigId,
                      onEditConfig: onEditConfig,
                      onTestConfig: onTestConfig,
                      onSetCurrent: onSetCurrent,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddVoice,
                            icon: const Icon(
                              OperitIcons.playlist_add_rounded,
                              size: 17,
                            ),
                            label: const Text('添加音色'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(38),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onEditProvider,
                          icon: const Icon(OperitIcons.edit_outlined, size: 17),
                          label: const Text('编辑供应商'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TtsVoiceList extends StatelessWidget {
  const _TtsVoiceList({
    required this.configs,
    required this.currentConfigId,
    required this.testingConfigId,
    required this.onEditConfig,
    required this.onTestConfig,
    required this.onSetCurrent,
  });

  final List<core_proxy.CoreOperitModelTtsConfigTtsConfig> configs;
  final String currentConfigId;
  final String? testingConfigId;
  final void Function(core_proxy.CoreOperitModelTtsConfigTtsConfig config)
  onEditConfig;
  final Future<void> Function(
    core_proxy.CoreOperitModelTtsConfigTtsConfig config,
  )
  onTestConfig;
  final Future<void> Function(String id) onSetCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < configs.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 6),
          _TtsVoiceTile(
            config: configs[index],
            current: configs[index].id == currentConfigId,
            testing: configs[index].id == testingConfigId,
            onEdit: () => onEditConfig(configs[index]),
            onTest: () => onTestConfig(configs[index]),
            onSetCurrent: () => onSetCurrent(configs[index].id),
          ),
        ],
      ],
    );
  }
}

class _TtsVoiceTile extends StatelessWidget {
  const _TtsVoiceTile({
    required this.config,
    required this.current,
    required this.testing,
    required this.onSetCurrent,
    required this.onEdit,
    required this.onTest,
  });

  final core_proxy.CoreOperitModelTtsConfigTtsConfig config;
  final bool current;
  final bool testing;
  final VoidCallback onSetCurrent;
  final VoidCallback onEdit;
  final Future<void> Function() onTest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (config.responseFormat.trim().isNotEmpty) config.responseFormat.trim(),
      '${config.speed.toStringAsFixed(2)}×',
      if (config.httpMethod.trim().isNotEmpty) config.httpMethod.trim(),
    ].join(' · ');
    return Material(
      color: current
          ? scheme.primaryContainer.withValues(alpha: 0.18)
          : scheme.surface.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          child: Row(
            children: <Widget>[
              _SelectionMark(
                selected: current,
                tooltip: current ? '当前使用的音色' : '设为当前音色',
                onPressed: current ? null : onSetCurrent,
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  OperitIcons.graphic_eq_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _ttsConfigModelVoiceText(config),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (current) ...<Widget>[
                          const SizedBox(width: 6),
                          const _CurrentBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (testing)
                const SizedBox.square(
                  dimension: 34,
                  child: Center(child: M3LoadingIndicator(size: 22)),
                )
              else
                IconButton(
                  tooltip: '试听',
                  onPressed: () {
                    onTest();
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    OperitIcons.volume_up_outlined,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceEmptyState extends StatelessWidget {
  const _VoiceEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
      child: Column(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceAvatar extends StatelessWidget {
  const _VoiceAvatar({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = label.trim().isEmpty
        ? '?'
        : String.fromCharCode(label.trim().runes.first);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.primary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '当前',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({
    required this.selected,
    required this.tooltip,
    required this.onPressed,
  });

  final bool selected;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 18,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 15, color: scheme.primary)
              : null,
        ),
      ),
    );
  }
}

class _VoiceHero extends StatelessWidget {
  const _VoiceHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OperitGlassSurface(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
        layer: OperitGlassSurfaceLayer.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          scheme.primary.withValues(alpha: 0.22),
                          scheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      OperitIcons.graphic_eq_rounded,
                      size: 23,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '朗读与听写',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '为对话选择更自然的声音，也为语音输入选择更准确的识别。',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: const <Widget>[
                  _VoiceCapability(label: 'TTS · 朗读'),
                  _VoiceCapability(label: 'STT · 听写'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceCapability extends StatelessWidget {
  const _VoiceCapability({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VoiceSectionError extends StatelessWidget {
  const _VoiceSectionError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OperitGlassSurface(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.error.withValues(alpha: 0.18)),
        layer: OperitGlassSurfaceLayer.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: <Widget>[
              Icon(
                OperitIcons.error_outline_rounded,
                size: 24,
                color: scheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(OperitIcons.refresh_rounded, size: 17),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
