// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import 'ProviderLogo.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';

/// One provider choice shared by LLM, TTS, and STT configuration pages.
class ProviderCatalogChoice {
  const ProviderCatalogChoice({
    required this.id,
    required this.label,
    required this.logoProviderTypeId,
    this.subtitle = '',
  });

  final String id;
  final String label;
  final String subtitle;
  final String logoProviderTypeId;
}

/// Opens a searchable, ChatGPT-style provider catalog picker.
Future<String?> showProviderTypePicker({
  required BuildContext context,
  required List<core_proxy.ProviderCatalogEntry> entries,
  String? selectedProviderTypeId,
}) {
  return showProviderCatalogChoicePicker(
    context: context,
    selectedId: selectedProviderTypeId,
    choices: entries
        .map(
          (entry) => ProviderCatalogChoice(
            id: entry.providerTypeId,
            label: entry.displayName,
            subtitle: entry.providerTypeId,
            logoProviderTypeId: entry.providerTypeId,
          ),
        )
        .toList(growable: false),
  );
}

/// Opens a searchable provider picker for any provider catalog family.
Future<String?> showProviderCatalogChoicePicker({
  required BuildContext context,
  required List<ProviderCatalogChoice> choices,
  String? selectedId,
  String title = '选择供应商',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (context) => _ProviderCatalogChoiceSheet(
      choices: choices,
      selectedId: selectedId,
      title: title,
    ),
  );
}

/// Displays the current provider and opens the shared catalog picker on tap.
class ProviderTypePickerField extends StatelessWidget {
  const ProviderTypePickerField({
    super.key,
    required this.label,
    required this.entry,
    required this.onTap,
    this.emptyLabel = '选择供应商',
  });

  final String label;
  final core_proxy.ProviderCatalogEntry? entry;
  final VoidCallback onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedEntry = entry;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              if (selectedEntry != null)
                ProviderLogo(
                  providerTypeId: selectedEntry.providerTypeId,
                  fallbackName: selectedEntry.displayName,
                  size: 42,
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: Icon(
                    OperitIcons.dns_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedEntry?.displayName ?? emptyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selectedEntry != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        selectedEntry.providerTypeId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                OperitIcons.expand_more_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a provider choice and opens the shared searchable picker.
class ProviderCatalogChoiceField extends StatelessWidget {
  const ProviderCatalogChoiceField({
    super.key,
    required this.label,
    required this.choice,
    required this.onTap,
    this.emptyLabel = '选择供应商',
  });

  final String label;
  final ProviderCatalogChoice? choice;
  final VoidCallback onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = choice;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              if (selected != null)
                ProviderLogo(
                  providerTypeId: selected.logoProviderTypeId,
                  fallbackName: selected.label,
                  size: 42,
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: Icon(
                    OperitIcons.dns_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected?.label ?? emptyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected != null && selected.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        selected.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                OperitIcons.expand_more_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCatalogChoiceSheet extends StatefulWidget {
  const _ProviderCatalogChoiceSheet({
    required this.choices,
    required this.selectedId,
    required this.title,
  });

  final List<ProviderCatalogChoice> choices;
  final String? selectedId;
  final String title;

  @override
  State<_ProviderCatalogChoiceSheet> createState() =>
      _ProviderCatalogChoiceSheetState();
}

class _ProviderCatalogChoiceSheetState
    extends State<_ProviderCatalogChoiceSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProviderCatalogChoice> get _visibleChoices {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.choices;
    }
    return widget.choices
        .where((choice) {
          return choice.label.toLowerCase().contains(query) ||
              choice.subtitle.toLowerCase().contains(query) ||
              choice.id.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final choices = _visibleChoices;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(OperitIcons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '搜索供应商',
                      prefixIcon: const Icon(OperitIcons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清除',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(OperitIcons.close_rounded),
                            ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.42,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: choices.isEmpty
                      ? Center(
                          child: Text(
                            '没有匹配的供应商',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                          itemCount: choices.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final choice = choices[index];
                            final selected = choice.id == widget.selectedId;
                            return Material(
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    Navigator.of(context).pop(choice.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      ProviderLogo(
                                        providerTypeId:
                                            choice.logoProviderTypeId,
                                        fallbackName: choice.label,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              choice.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (choice.subtitle.isNotEmpty)
                                              Text(
                                                choice.subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? OperitIcons.check_box_rounded
                                            : OperitIcons
                                                  .check_box_outline_blank_rounded,
                                        size: 20,
                                        color: selected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant.withValues(
                                                alpha: 0.5,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
