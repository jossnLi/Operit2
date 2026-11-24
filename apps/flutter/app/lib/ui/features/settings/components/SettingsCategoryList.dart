// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit_ui/operit_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../models/SettingsModels.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';

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
          SettingsCategory.localModels,
          SettingsCategory.usage,
        ],
      ),
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupWorkspace,
        categories: const <SettingsCategory>[
          SettingsCategory.tools,
          SettingsCategory.workspace,
        ],
      ),
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupExperience,
        categories: const <SettingsCategory>[
          SettingsCategory.globalBehavior,
          SettingsCategory.appearance,
        ],
      ),
      _SettingsCategoryGroup(
        title: l10n.settingsCategoryGroupSystem,
        categories: const <SettingsCategory>[
          SettingsCategory.data,
          SettingsCategory.about,
        ],
      ),
    ];
    final theme = Theme.of(context);
    return ThemeGlassSurfaceGroup(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
            child: Text(
              l10n.settings,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          SettingsCategoryTile(
            spec: SettingsCategorySpec.of(SettingsCategory.accessLinks, l10n),
            selected: selectedCategory == SettingsCategory.accessLinks,
            onTap: () => onCategorySelected(SettingsCategory.accessLinks),
            prominent: true,
          ),
          for (final groupEntry in groups.asMap().entries) ...<Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                groupEntry.key == 0 ? 10 : 20,
                10,
                8,
              ),
              child: Text(
                groupEntry.value.title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
            ),
            for (final category in groupEntry.value.categories)
              SettingsCategoryTile(
                spec: SettingsCategorySpec.of(category, l10n),
                selected: selectedCategory == category,
                onTap: () => onCategorySelected(category),
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
        ? colorScheme.surfaceContainerHigh
        : Colors.transparent;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: <Widget>[
                Icon(spec.icon, size: 18, color: foreground),
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
                if (selected)
                  Icon(
                    OperitIcons.check_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
