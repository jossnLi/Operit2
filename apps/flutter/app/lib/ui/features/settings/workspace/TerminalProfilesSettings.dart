// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/proxy/generated/CoreProxyClients.g.dart';
import '../../../../core/proxy/generated/CoreProxyModels.g.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../common/TerminalLabels.dart';
import '../../../common/components/M3LoadingIndicator.dart';
import '../../../theme/OperitGlassSurface.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'WorkspaceSettingsPanel.dart';
/// Edits device-owned profiles using fields registered by the active Core host.
class TerminalProfilesSettings extends StatefulWidget {
  /// Creates a terminal settings section backed by the selected Core connection.
  const TerminalProfilesSettings({super.key, required this.clients});

  final GeneratedCoreProxyClients clients;

  /// Creates the profile editor state.
  @override
  State<TerminalProfilesSettings> createState() =>
      _TerminalProfilesSettingsState();
}

class _TerminalProfilesSettingsState extends State<TerminalProfilesSettings> {
  TerminalProfileSettings? _settings;
  List<TerminalProfileSupport> _support = [];
  List<TerminalDistribution> _distributions = [];
  List<RuntimeTerminalInstall> _installs = [];
  Timer? _pollTimer;
  bool _polling = false;
  Object? _error;
  bool _saving = false;

  /// Loads the saved profiles and host-registered editing capabilities together.
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Replaces the visible snapshot only after both Core reads complete.
  Future<void> _load() async {
    try {
      final api = widget.clients.servicesRuntimeTerminalService;
      final (settings, support, distributions, installs) = await (
        api.terminalProfileSettings(),
        api.terminalProfileSupport(),
        api.terminalDistributions(),
        api.terminalDistributionInstalls(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _support = support;
        _distributions = distributions;
        _installs = installs;
        _error = null;
      });
      _schedulePoll();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Stops UI observation while Core-owned installation workers retain their lifetime.
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Recognizes terminal job states from the shared installation protocol.
  bool _finished(RuntimeTerminalInstall job) =>
      const {'completed', 'failed', 'cancelled'}.contains(job.state);

  /// Polls only while a Core-owned job is active, including jobs started before reconnecting.
  void _schedulePoll() {
    _pollTimer?.cancel();
    if (_installs.any((job) => !_finished(job))) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_pollInstalls()),
      );
    }
  }

  /// Refreshes completed profiles without issuing overlapping polling requests.
  Future<void> _pollInstalls() async {
    if (_polling) return;
    _polling = true;
    try {
      final api = widget.clients.servicesRuntimeTerminalService;
      final installs = await api.terminalDistributionInstalls();
      final completed = installs.any(
        (job) =>
            job.state == 'completed' &&
            !_installs.any(
              (old) =>
                  old.installId == job.installId && old.state == 'completed',
            ),
      );
      final settings = completed ? await api.terminalProfileSettings() : null;
      if (!mounted) return;
      setState(() {
        _installs = installs;
        if (settings != null) _settings = settings;
        _error = null;
      });
      _schedulePoll();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _polling = false;
    }
  }

  /// Names a fresh instance so the same distribution can be installed more than once.
  Future<void> _download(TerminalDistribution distribution) async {
    final l10n = AppLocalizations.of(context)!;
    var instanceName = distribution.name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.terminalDistributionDownload),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${distribution.name} · ${distribution.architecture}'),
            if (distribution.notice.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(distribution.notice),
            ],
            const SizedBox(height: 16),
            TextFormField(
              initialValue: distribution.name,
              onChanged: (value) => instanceName = value,
              decoration: InputDecoration(labelText: l10n.terminalProfileName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, instanceName.trim()),
            child: Text(l10n.terminalDistributionDownload),
          ),
        ],
      ),
    );
    if (!mounted || name == null) return;
    try {
      final job = await widget.clients.servicesRuntimeTerminalService
          .startTerminalDistributionInstall(
            distributionId: distribution.id,
            name: name,
          );
      if (!mounted) return;
      setState(() => _installs = [..._installs, job]);
      _schedulePoll();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Requests cancellation and lets Core finish cleaning its private staging files.
  Future<void> _cancelInstall(RuntimeTerminalInstall job) async {
    try {
      await widget.clients.servicesRuntimeTerminalService
          .cancelTerminalDistributionInstall(installId: job.installId);
      await _pollInstalls();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Translates installation protocol phases into localized user-facing text.
  String _installState(AppLocalizations l10n, String state) => switch (state) {
    'queued' => l10n.terminalInstallQueued,
    'downloading' => l10n.terminalInstallDownloading,
    'verifying' => l10n.terminalInstallVerifying,
    'extracting' => l10n.terminalInstallExtracting,
    'completed' => l10n.terminalInstallCompleted,
    'cancelled' => l10n.terminalInstallCancelled,
    'failed' => l10n.terminalInstallFailed,
    _ => state,
  };

  /// Publishes a complete validated registry and retains the last saved UI state on failure.
  Future<void> _save(TerminalProfileSettings settings) async {
    setState(() => _saving = true);
    try {
      final saved = await widget.clients.servicesRuntimeTerminalService
          .saveTerminalProfileSettings(settings: settings);
      if (mounted) {
        setState(() {
          _settings = saved;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Opens the standalone profile editor page without changing the default implicitly.
  Future<void> _edit([TerminalProfile? existing]) async {
    final profile = await Navigator.of(context).push<TerminalProfile>(
      MaterialPageRoute<TerminalProfile>(
        fullscreenDialog: true,
        builder: (context) => _TerminalProfileEditorPage(
          profile: existing,
          support: _support,
        ),
      ),
    );
    if (!mounted || profile == null) return;
    final settings = _settings!;
    final profiles = [...settings.profiles];
    final index = profiles.indexWhere((entry) => entry.id == profile.id);
    if (index == -1) {
      profiles.add(profile);
    } else {
      profiles[index] = profile;
    }
    await _save(
      TerminalProfileSettings(
        schemaVersion: settings.schemaVersion,
        revision: settings.revision,
        defaultProfileId: settings.defaultProfileId,
        profiles: profiles,
      ),
    );
  }

  /// Deletes a non-default profile after explaining that its running sessions stay open.
  Future<void> _delete(TerminalProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.terminalProfileDelete),
        content: Text(l10n.terminalProfileDeleteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final settings = _settings!;
    await _save(
      TerminalProfileSettings(
        schemaVersion: settings.schemaVersion,
        revision: settings.revision,
        defaultProfileId: settings.defaultProfileId,
        profiles: settings.profiles
            .where((entry) => entry.id != profile.id)
            .toList(),
      ),
    );
  }

  /// Shows saved profiles, download options, and running installs as one
  /// themed surface that matches the surrounding settings cards.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = _settings;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 卡片区块 1：终端配置
        WorkspaceSectionCard(
          title: l10n.terminalProfilesTitle,
          icon: OperitIcons.terminal_outlined,
          children: [
            Text(
              l10n.terminalProfilesDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              SelectableText(
                '$_error',
                style: TextStyle(color: scheme.error),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _load, child: Text(l10n.retry)),
              ),
            ],
            if (settings == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: M3LoadingIndicator(),
              ),
            if (settings != null) ...[
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: settings.defaultProfileId,
                onChanged: (id) {
                  if (id != null && !_saving) {
                    unawaited(
                      _save(
                        TerminalProfileSettings(
                          schemaVersion: settings.schemaVersion,
                          revision: settings.revision,
                          defaultProfileId: id,
                          profiles: settings.profiles,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    for (final profile in settings.profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TerminalProfileCard(
                          profile: profile,
                          selected: settings.defaultProfileId == profile.id,
                          saving: _saving,
                          onSelect: () => _save(
                            TerminalProfileSettings(
                              schemaVersion: settings.schemaVersion,
                              revision: settings.revision,
                              defaultProfileId: profile.id,
                              profiles: settings.profiles,
                            ),
                          ),
                          onEdit: () => _edit(profile),
                          onDelete: settings.defaultProfileId == profile.id
                              ? null
                              : () => _delete(profile),
                        ),
                      ),
                  ],
                ),
              ),
              if (_saving)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(minHeight: 3),
                  ),
                ),
              _TerminalAddTile(
                enabled: !_saving && _support.isNotEmpty,
                label: l10n.terminalProfileAdd,
                onTap: _edit,
              ),
            ],
          ],
        ),

        // 卡片区块 2：下载 Linux 发行版
        if (_distributions.isNotEmpty || _installs.isNotEmpty)
          WorkspaceSectionCard(
            title: l10n.terminalDistributionsTitle,
            icon: OperitIcons.download_for_offline_outlined,
            children: [
              Text(
                l10n.terminalDistributionsDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final distribution in _distributions)
                _TerminalDistributionTile(
                  distribution: distribution,
                  enabled: !_saving,
                  onDownload: () => _download(distribution),
                ),
              for (final job in _installs)
                _TerminalInstallTile(
                  job: job,
                  stateLabel: _installState(l10n, job.state),
                  finished: _finished(job),
                  onCancel: () => _cancelInstall(job),
                ),
            ],
          ),
      ],
    );
  }
}

/// Section title block shared by the terminal settings surfaces.
class _TerminalSectionHeader extends StatelessWidget {
  const _TerminalSectionHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Smaller heading used for the Linux distribution catalog.
class _TerminalSubHeader extends StatelessWidget {
  const _TerminalSubHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Rounded tile that opens the standalone profile editor page.
class _TerminalAddTile extends StatelessWidget {
  const _TerminalAddTile({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OperitGlassSurface(
      color: enabled
          ? scheme.primary.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: enabled
            ? scheme.primary.withValues(alpha: 0.34)
            : scheme.outlineVariant.withValues(alpha: 0.22),
        width: 0.8,
      ),
      layer: OperitGlassSurfaceLayer.control,
      material: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                OperitIcons.add_rounded,
                size: 18,
                color: enabled ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                OperitIcons.chevron_right_rounded,
                size: 18,
                color: (enabled ? scheme.primary : scheme.onSurfaceVariant)
                    .withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Download option for one Linux distribution.
class _TerminalDistributionTile extends StatelessWidget {
  const _TerminalDistributionTile({
    required this.distribution,
    required this.enabled,
    required this.onDownload,
  });

  final TerminalDistribution distribution;
  final bool enabled;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = (distribution.downloadBytes / 1048576).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OperitGlassSurface(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.22),
          width: 0.8,
        ),
        layer: OperitGlassSurfaceLayer.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distribution.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${distribution.architecture} · $size MB',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (distribution.notice.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        distribution.notice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '下载并安装',
                onPressed: enabled ? onDownload : null,
                icon: const Icon(OperitIcons.download_outlined, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  maximumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress row for one running or finished install job.
class _TerminalInstallTile extends StatelessWidget {
  const _TerminalInstallTile({
    required this.job,
    required this.stateLabel,
    required this.finished,
    required this.onCancel,
  });

  final RuntimeTerminalInstall job;
  final String stateLabel;
  final bool finished;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = job.state == 'downloading' && job.totalBytes > 0
        ? (job.downloadedBytes / job.totalBytes).clamp(0.0, 1.0)
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OperitGlassSurface(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.22),
          width: 0.8,
        ),
        layer: OperitGlassSurfaceLayer.control,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (!finished) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                        ),
                      ),
                    ],
                    if (job.error != null) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        job.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!finished)
                IconButton(
                  tooltip: '取消',
                  onPressed: onCancel,
                  icon: const Icon(OperitIcons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// One saved terminal profile as a selectable card with inline actions.
class _TerminalProfileCard extends StatelessWidget {
  const _TerminalProfileCard({
    required this.profile,
    required this.selected,
    required this.saving,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final TerminalProfile profile;
  final bool selected;
  final bool saving;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(14);
    return OperitGlassSurface(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: radius,
      border: Border.all(
        color: selected
            ? scheme.primary.withValues(alpha: 0.50)
            : scheme.outlineVariant.withValues(alpha: 0.24),
        width: selected ? 1.0 : 0.8,
      ),
      layer: OperitGlassSurfaceLayer.control,
      material: true,
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        onTap: saving || selected ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.16)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                ),
                child: Icon(
                  OperitIcons.terminal_outlined,
                  size: 18,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TerminalLabels.profileName(l10n, profile),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      TerminalLabels.implementation(
                        l10n,
                        profile.terminal,
                        profile.terminalType,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 4),
                      Text(
                        '默认配置',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? OperitIcons.radio_button_checked_rounded
                    : OperitIcons.radio_button_unchecked_rounded,
                size: 20,
                color: selected
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.42),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: l10n.edit,
                visualDensity: VisualDensity.compact,
                onPressed: saving ? null : onEdit,
                icon: const Icon(OperitIcons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                onPressed: saving || onDelete == null ? null : onDelete,
                icon: Icon(
                  OperitIcons.delete_outline_rounded,
                  size: 18,
                  color: onDelete == null
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edits a host-declared implementation on its own themed page.
class _TerminalProfileEditorPage extends StatefulWidget {
  /// Creates an editor page for a new profile or an existing saved profile.
  const _TerminalProfileEditorPage({this.profile, required this.support});
  final TerminalProfile? profile;
  final List<TerminalProfileSupport> support;

  /// Creates the form state.
  @override
  State<_TerminalProfileEditorPage> createState() =>
      _TerminalProfileEditorPageState();
}

class _TerminalProfileEditorPageState extends State<_TerminalProfileEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _initialDisplayName;
  final Map<String, TextEditingController> _options = {};
  late TerminalProfileSupport _implementation;

  /// Initializes the saved implementation and its registered fields.
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '');
    _implementation = widget.profile == null
        ? widget.support.first
        : widget.support.firstWhere(
            (entry) =>
                entry.terminal == widget.profile!.terminal &&
                entry.terminalType == widget.profile!.terminalType,
          );
    for (final field
        in widget.support.expand((entry) => entry.fields).toSet()) {
      _options[field] = TextEditingController(
        text: widget.profile?.options[field] ?? '',
      );
    }
  }

  /// Shows the translated default while retaining its stored name on an unchanged save.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDisplayName != null) return;
    final profile = widget.profile;
    _initialDisplayName = profile == null
        ? ''
        : TerminalLabels.profileName(AppLocalizations.of(context)!, profile);
    _name.text = _initialDisplayName!;
  }

  /// Releases all text controllers when the dialog closes.
  @override
  void dispose() {
    _name.dispose();
    for (final controller in _options.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Validates structured arguments before returning the edited profile.
  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      TerminalProfile(
        id:
            widget.profile?.id ??
            'user_${DateTime.now().microsecondsSinceEpoch}',
        name: widget.profile != null && _name.text == _initialDisplayName
            ? widget.profile!.name
            : _name.text.trim(),
        nameKey: _name.text == _initialDisplayName
            ? widget.profile?.nameKey
            : null,
        terminal: _implementation.terminal,
        terminalType: _implementation.terminalType,
        options: {
          for (final field in _implementation.fields)
            if (_options[field]!.text.trim().isNotEmpty)
              field: _options[field]!.text.trim(),
        },
      ),
    );
  }

  /// Labels the protocol field registered by the host.
  String _label(AppLocalizations l10n, String field) => switch (field) {
    'rootfs' => l10n.terminalProfileRootfs,
    'executable' => l10n.terminalProfileExecutable,
    'arguments' => l10n.terminalProfileArguments,
    'wslDistribution' => l10n.terminalProfileWslDistribution,
    _ => field,
  };

  /// Validates the JSON argument array without interpreting shell text.
  String? _validateOption(String field, String? text) {
    if (field != 'arguments' || text == null || text.trim().isEmpty) {
      return null;
    }
    try {
      final value = jsonDecode(text);
      if (value is List &&
          value.every(
            (entry) => entry is String && !entry.contains('\u0000'),
          )) {
        return null;
      }
    } on FormatException {
      /* Report malformed structured arguments below. */
    }
    return AppLocalizations.of(context)!.terminalProfileArgumentsError;
  }

  /// Builds a themed editor page from the host's supported configuration fields.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEditing = widget.profile != null;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 44,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(OperitIcons.chevron_left_rounded),
        ),
        title: Text(
          isEditing ? l10n.terminalProfileEdit : l10n.terminalProfileAdd,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _submit,
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            OperitGlassSurface(
              borderRadius: BorderRadius.circular(16),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
                width: 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                child: Form(
                  key: _form,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.terminalProfileName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.terminalProfileNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue:
                          '${_implementation.terminal}/${_implementation.terminalType}',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.terminalProfileImplementation,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final entry in widget.support)
                          DropdownMenuItem(
                            value: '${entry.terminal}/${entry.terminalType}',
                            child: Text(
                              TerminalLabels.implementation(
                                l10n,
                                entry.terminal,
                                entry.terminalType,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _implementation = widget.support.firstWhere(
                          (entry) =>
                              '${entry.terminal}/${entry.terminalType}' == value,
                        );
                      }),
                    ),
                    if (_implementation.fields.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          l10n.terminalProfileNoOptions,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    for (final field in _implementation.fields)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: _options[field],
                          minLines: 1,
                          maxLines: field == 'arguments' ? 4 : 2,
                          decoration: InputDecoration(
                            labelText: _label(l10n, field),
                            border: const OutlineInputBorder(),
                            helperText: switch (field) {
                              'rootfs' => l10n.terminalProfileRootfsHelp,
                              'arguments' => l10n.terminalProfileArgumentsHelp,
                              'wslDistribution' => l10n.terminalProfileWslHelp,
                              _ => null,
                            },
                            helperMaxLines: 5,
                          ),
                          validator: (value) => _validateOption(field, value),
                        ),
                      ),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
