// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit_ui/operit_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../appearance/AppearanceSettingsPanel.dart';
import '../access_links/AccessLinksSettingsPanel.dart';
import '../about/AboutOperitScreen.dart';
import '../data/DataSettingsPanel.dart';
import '../data/UsageStatisticsDetailScreen.dart';
import '../global_behavior/GlobalBehaviorSettingsPanel.dart';
import '../model_ai/ModelAiSettingsEntry.dart';
import '../local_models/LocalModelSettingsPanel.dart';
import '../models/SettingsModels.dart';
import '../profile/UserProfileSettingsPanel.dart';
import '../tools/ToolSettingsPanel.dart';
import '../tts/TtsSettingsPanel.dart';
import '../workspace/WorkspaceSettingsPanel.dart';
import '../../../main/screens/OperitScreens.dart';

class SettingsDetailView extends StatelessWidget {
  const SettingsDetailView({
    super.key,
    required this.category,
    required this.onOpenProfile,
    this.showHeader = true,
    this.onProfileChanged,
  });

  final SettingsCategory category;
  final VoidCallback onOpenProfile;
  final bool showHeader;
  final VoidCallback? onProfileChanged;

  /// Shares matching panel blurs within this page, including during transitions.
  @override
  Widget build(BuildContext context) {
    final content = switch (category) {
      SettingsCategory.profile => UserProfileSettingsPanel(
        onProfileChanged: onProfileChanged,
      ),
      SettingsCategory.model => const ModelAiSettingsEntry(),
      SettingsCategory.characters => const ToolPkgComposeDslScreenRoute(
        containerPackageName: 'com.operit.character_cards',
        uiModuleId: 'main',
      ).build(context),
      SettingsCategory.memory => const ToolPkgComposeDslScreenRoute(
        containerPackageName: 'com.operit.character_cards',
        uiModuleId: 'memory',
      ).build(context),
      SettingsCategory.localModels => const LocalModelSettingsPanel(),
      SettingsCategory.usage => const UsageStatisticsDetailScreen(),
      SettingsCategory.tts => const TtsSettingsPanel(),
      SettingsCategory.tools => const ToolSettingsPanel(),
      SettingsCategory.workspace => const WorkspaceSettingsPanel(),
      SettingsCategory.globalBehavior => const GlobalBehaviorSettingsPanel(),
      SettingsCategory.appearance => const AppearanceSettingsPanel(),
      SettingsCategory.data => const DataSettingsPanel(),
      SettingsCategory.accessLinks => AccessLinksSettingsPanel(
        onOpenProfile: onOpenProfile,
      ),
      SettingsCategory.about => const AboutOperitScreen(),
    };

    if (!showHeader) {
      return ThemeGlassSurfaceGroup(child: content);
    }

    final spec = SettingsCategorySpec.of(
      category,
      AppLocalizations.of(context)!,
    );
    return ThemeGlassSurfaceGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.45,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      spec.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
