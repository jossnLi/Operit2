part of 'TtsSettingsPanel.dart';

class _SttProviderManager extends StatelessWidget {
  const _SttProviderManager({
    required this.configs,
    required this.currentConfigId,
    required this.onEdit,
    required this.onDelete,
    required this.onSetCurrent,
  });

  final List<core_proxy.SttConfig> configs;
  final String? currentConfigId;
  final Future<void> Function(core_proxy.SttConfig config) onEdit;
  final Future<void> Function(core_proxy.SttConfig config) onDelete;
  final Future<void> Function(String id) onSetCurrent;

  @override
  Widget build(BuildContext context) {
    if (configs.isEmpty) {
      return const _VoiceEmptyState(
        icon: OperitIcons.mic_none_rounded,
        title: '还没有识别供应商',
        message: '添加后即可把语音转成文字，用于对话输入与会议记录。',
      );
    }
    return Column(
      children: <Widget>[
        for (var index = 0; index < configs.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 7),
          _SttProviderTile(
            config: configs[index],
            current: configs[index].id == currentConfigId,
            onEdit: () => onEdit(configs[index]),
            onDelete: () => onDelete(configs[index]),
            onSetCurrent: () => onSetCurrent(configs[index].id),
          ),
        ],
      ],
    );
  }
}

class _SttProviderTile extends StatelessWidget {
  const _SttProviderTile({
    required this.config,
    required this.current,
    required this.onEdit,
    required this.onDelete,
    required this.onSetCurrent,
  });

  final core_proxy.SttConfig config;
  final bool current;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final endpoint = config.endpoint.trim();
    final subtitle = <String>[
      config.providerType,
      if (config.model.trim().isNotEmpty) config.model.trim(),
      if (endpoint.isNotEmpty) endpoint,
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: current
            ? scheme.primaryContainer.withValues(alpha: 0.16)
            : scheme.surface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: current
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 9, 5, 9),
          child: Row(
            children: <Widget>[
              _SelectionMark(
                selected: current,
                tooltip: current ? '当前使用的识别配置' : '设为当前识别配置',
                onPressed: current ? null : onSetCurrent,
              ),
              const SizedBox(width: 8),
              _VoiceAvatar(label: config.name, size: 34),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            config.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '更多操作',
                icon: Icon(
                  OperitIcons.more_horiz_rounded,
                  size: 19,
                  color: scheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('编辑配置'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    enabled: !current,
                    child: const Text('删除配置'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
