// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/preferences/UserPreferencesManager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../main/layout/NavigationLayoutMetrics.dart';
import '../../../theme/OperitGlassSurface.dart';
import '../components/SettingsControlStyles.dart';

class GlobalBehaviorSettingsPanel extends StatelessWidget {
  const GlobalBehaviorSettingsPanel({super.key});

  /// Builds global chat input behavior settings.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        _GlobalBehaviorSectionCard(
          title: l10n.settingsGlobalBehaviorChatInputSection,
          description: '调整聊天界面的键盘回车与文本输入交互',
          children: const <Widget>[
            _EnterSendsMessageControl(),
            Divider(height: 20, thickness: 0.6),
            _LongPastedTextBehaviorControl(),
          ],
        ),
      ],
    );
  }
}

class _GlobalBehaviorSectionCard extends StatelessWidget {
  const _GlobalBehaviorSectionCard({
    required this.title,
    this.description,
    required this.children,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  /// Builds a grouped settings card for this page in ChatGPT layout style.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(16);
    return OperitGlassSurface(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: radius,
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        width: 0.8,
      ),
      material: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: 3),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EnterSendsMessageControl extends StatelessWidget {
  const _EnterSendsMessageControl();

  /// Builds the shared Enter switch using the existing layout default if unset.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool?>(
      valueListenable: UserPreferencesManager.enterSendsMessage,
      builder: (context, enabled, _) => SettingsSwitchRow(
        key: const ValueKey('settings.enterSendsMessage'),
        title: l10n.settingsGlobalBehaviorEnterSendsMessage,
        subtitle: l10n.settingsGlobalBehaviorEnterSendsMessageDescription,
        value: enabled ?? useTabletLayoutForContext(context),
        onChanged: (value) => unawaited(
          const UserPreferencesManager().saveEnterSendsMessage(value),
        ),
      ),
    );
  }
}

class _LongPastedTextBehaviorControl extends StatefulWidget {
  const _LongPastedTextBehaviorControl();

  /// Creates the mutable state for the long-paste preference controls.
  @override
  State<_LongPastedTextBehaviorControl> createState() =>
      _LongPastedTextBehaviorControlState();
}

class _LongPastedTextBehaviorControlState
    extends State<_LongPastedTextBehaviorControl> {
  final UserPreferencesManager _preferences = const UserPreferencesManager();

  /// Starts loading persisted long-paste preferences for the settings controls.
  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  /// Loads the persisted long-paste preferences into the shared settings value.
  Future<void> _loadSettings() async {
    try {
      await _preferences.loadLongPastedTextInputSettings();
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load long pasted text preferences: $error\n$stackTrace',
      );
    }
  }

  /// Persists one complete long-paste preference value.
  Future<void> _saveSettings({
    required bool enabled,
    required int threshold,
  }) async {
    try {
      await _preferences.saveLongPastedTextInputSettings(
        enabled: enabled,
        threshold: threshold,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to save long pasted text preferences: $error\n$stackTrace',
      );
    }
  }

  /// Builds the switch and threshold slider for long pasted text conversion.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<LongPastedTextInputSettings>(
      valueListenable: UserPreferencesManager.longPastedTextInputSettings,
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SettingsSwitchRow(
              title: l10n.settingsGlobalBehaviorLongPastedTextAsAttachment,
              subtitle: '输入大段内容时自动封装为文件胶囊附件，保持对话流轻盈',
              value: settings.enabled,
              onChanged: (enabled) {
                UserPreferencesManager.longPastedTextInputSettings.value =
                    LongPastedTextInputSettings(
                      enabled: enabled,
                      threshold: settings.threshold,
                    );
                unawaited(
                  _saveSettings(
                    enabled: enabled,
                    threshold: settings.threshold,
                  ),
                );
              },
            ),
            if (settings.enabled) ...<Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SettingsSliderRow(
                  label: l10n.settingsGlobalBehaviorLongPastedTextThreshold,
                  value: settings.threshold.toDouble(),
                  min: UserPreferencesManager.longPastedTextInputMinimumThreshold
                      .toDouble(),
                  max: UserPreferencesManager.longPastedTextInputMaximumThreshold
                      .toDouble(),
                  divisions:
                      (UserPreferencesManager.longPastedTextInputMaximumThreshold -
                          UserPreferencesManager
                              .longPastedTextInputMinimumThreshold) ~/
                      UserPreferencesManager.longPastedTextInputThresholdStep,
                  valueText: l10n
                      .settingsGlobalBehaviorLongPastedTextThresholdValue(
                        settings.threshold,
                      ),
                  onChanged: (value) {
                    final threshold = value.round();
                    UserPreferencesManager.longPastedTextInputSettings.value =
                        LongPastedTextInputSettings(
                          enabled: settings.enabled,
                          threshold: threshold,
                        );
                  },
                  onChangeEnd: (value) {
                    final threshold = value.round();
                    unawaited(
                      _saveSettings(
                        enabled: settings.enabled,
                        threshold: threshold,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
