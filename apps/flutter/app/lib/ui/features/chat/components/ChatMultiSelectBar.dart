// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';

class ChatMultiSelectBar extends StatelessWidget {
  const ChatMultiSelectBar({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.onClose,
    required this.onToggleSelectAll,
    required this.onCopy,
    required this.onShareImage,
    required this.onDelete,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onToggleSelectAll;
  final VoidCallback? onCopy;
  final VoidCallback? onShareImage;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0.98),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(OperitIcons.close_rounded),
                    tooltip: '退出多选',
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      selectedCount == 0 ? '多选' : '已选 $selectedCount 条',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleSelectAll,
                    icon: Icon(
                      allSelected
                          ? OperitIcons.deselect_rounded
                          : OperitIcons.select_all_rounded,
                    ),
                    tooltip: allSelected ? '清空选择' : '全选',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onCopy,
                    icon: const Icon(OperitIcons.content_copy_outlined),
                    tooltip: '复制所选',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton.filledTonal(
                    onPressed: onShareImage,
                    icon: const Icon(OperitIcons.ios_share_rounded),
                    tooltip: '生成长图',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton.filledTonal(
                    onPressed: onDelete,
                    icon: const Icon(OperitIcons.delete_outline_rounded),
                    tooltip: '删除所选',
                    color: colorScheme.onErrorContainer,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
