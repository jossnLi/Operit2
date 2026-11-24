// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
/// Defines host-owned settings; plugin editors register their own navigation.
enum SettingsCategory {
  profile,
  model,
  localModels,
  usage,
  tts,
  tools,
  workspace,
  globalBehavior,
  appearance,
  data,
  accessLinks,
  about,
}

class SettingsCategorySpec {
  const SettingsCategorySpec({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  /// Resolves the localized presentation specification for a category.
  static SettingsCategorySpec of(
    SettingsCategory category,
    AppLocalizations l10n,
  ) {
    return switch (category) {
      SettingsCategory.profile => SettingsCategorySpec(
        title: l10n.settingsUserProfileTitle,
        subtitle: l10n.settingsUserProfileSubtitle,
        description: l10n.settingsUserProfileDescription,
        icon: OperitIcons.account_circle_outlined,
      ),
      SettingsCategory.model => SettingsCategorySpec(
        title: l10n.settingsCategoryModelTitle,
        subtitle: l10n.settingsCategoryModelSubtitle,
        description: l10n.settingsCategoryModelDescription,
        icon: OperitIcons.auto_awesome_rounded,
      ),
      SettingsCategory.localModels => SettingsCategorySpec(
        title: l10n.settingsCategoryLocalModelsTitle,
        subtitle: l10n.settingsCategoryLocalModelsSubtitle,
        description: l10n.settingsCategoryLocalModelsDescription,
        icon: OperitIcons.memory_outlined,
      ),
      SettingsCategory.usage => SettingsCategorySpec(
        title: l10n.settingsUsageReportTitle,
        subtitle: l10n.settingsUsageReportSubtitle,
        description: l10n.settingsDataDetailedStatsDescription,
        icon: OperitIcons.analytics_outlined,
      ),
      SettingsCategory.tts => const SettingsCategorySpec(
        title: '语音与识别',
        subtitle: 'TTS 与 STT 供应商',
        description: '管理语音合成与语音识别供应商，并分别选择当前配置。',
        icon: OperitIcons.volume_up_outlined,
      ),
      SettingsCategory.tools => SettingsCategorySpec(
        title: l10n.settingsCategoryToolsTitle,
        subtitle: l10n.settingsCategoryToolsSubtitle,
        description: l10n.settingsCategoryToolsDescription,
        icon: OperitIcons.build_outlined,
      ),
      SettingsCategory.workspace => SettingsCategorySpec(
        title: l10n.settingsCategoryWorkspaceTitle,
        subtitle: l10n.settingsCategoryWorkspaceSubtitle,
        description: l10n.settingsCategoryWorkspaceDescription,
        icon: OperitIcons.folder_outlined,
      ),
      SettingsCategory.globalBehavior => SettingsCategorySpec(
        title: l10n.settingsCategoryGlobalBehaviorTitle,
        subtitle: l10n.settingsCategoryGlobalBehaviorSubtitle,
        description: l10n.settingsCategoryGlobalBehaviorDescription,
        icon: OperitIcons.tune_rounded,
      ),
      SettingsCategory.appearance => SettingsCategorySpec(
        title: l10n.settingsCategoryAppearanceTitle,
        subtitle: l10n.settingsCategoryAppearanceSubtitle,
        description: l10n.settingsCategoryAppearanceDescription,
        icon: OperitIcons.palette_outlined,
      ),
      SettingsCategory.data => SettingsCategorySpec(
        title: l10n.settingsCategoryDataTitle,
        subtitle: l10n.settingsCategoryDataSubtitle,
        description: l10n.settingsCategoryDataDescription,
        icon: OperitIcons.inventory_2_outlined,
      ),
      SettingsCategory.accessLinks => SettingsCategorySpec(
        title: l10n.settingsCategoryAccessLinksTitle,
        subtitle: l10n.settingsCategoryAccessLinksSubtitle,
        description: l10n.settingsCategoryAccessLinksDescription,
        icon: OperitIcons.devices_outlined,
      ),
      SettingsCategory.about => const SettingsCategorySpec(
        title: '关于 Operit2',
        subtitle: '版本、项目与许可',
        description: '查看 Operit2 的版本信息、项目链接和开源许可证。',
        icon: OperitIcons.info_outline_rounded,
      ),
    };
  }
}
