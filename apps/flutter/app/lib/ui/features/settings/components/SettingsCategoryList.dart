// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit_ui/operit_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../theme/OperitGlassSurface.dart';
import '../models/SettingsModels.dart';
import '../profile/UserProfileSummaryTile.dart';

class SettingsCategoryList extends StatelessWidget {
  const SettingsCategoryList({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final SettingsCategory? selectedCategory;
  final ValueChanged<SettingsCategory> onCategorySelected;

  /// Shares one control blur across the non-overlapping category tiles.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = <_SettingsCategoryGroup>[
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupAssistant,
        categories: const <SettingsCategory>[
          SettingsCategory.model,
          SettingsCategory.characters,
          SettingsCategory.memory,
          SettingsCategory.localModels,
          SettingsCategory.usage,
          SettingsCategory.tts,
        ],
      ),
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupExperience,
        categories: const <SettingsCategory>[
          SettingsCategory.globalBehavior,
          SettingsCategory.appearance,
          SettingsCategory.tools,
          SettingsCategory.workspace,
        ],
      ),
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupSystem,
        categories: const <SettingsCategory>[
          SettingsCategory.data,
          SettingsCategory.accessLinks,
          SettingsCategory.about,
        ],
      ),
    ];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ThemeGlassSurfaceGroup(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          UserProfileSummaryTile(
            selected: selectedCategory == SettingsCategory.profile,
            revision: 0,
            onTap: () => onCategorySelected(SettingsCategory.profile),
          ),
          for (final groupEntry in groups.asMap().entries) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: Text(
                groupEntry.value.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
            ),
            OperitGlassSurface(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              layer: OperitGlassSurfaceLayer.control,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                width: 0.8,
              ),
              material: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < groupEntry.value.categories.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.6,
                          indent: 44,
                          endIndent: 12,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      SettingsCategoryTile(
                        spec: SettingsCategorySpec.of(groupEntry.value.categories[i], l10n),
                        selected: selectedCategory == groupEntry.value.categories[i],
                        onTap: () => onCategorySelected(groupEntry.value.categories[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsCategoryGroup {
  const _SettingsCategoryGroup({required this.title, required this.categories});

  final String title;
  final List<SettingsCategory> categories;
}

class SettingsCategoryTile extends StatelessWidget {
  const SettingsCategoryTile({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
    this.prominent = false,
  });

  final SettingsCategorySpec spec;
  final bool selected;
  final VoidCallback onTap;
  final bool prominent;

  /// Builds a selectable tile for one settings category.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = selected
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
        : Colors.transparent;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurface;
    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(
                spec.icon,
                size: 20,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected || prominent
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                OperitIcons.chevron_right_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
