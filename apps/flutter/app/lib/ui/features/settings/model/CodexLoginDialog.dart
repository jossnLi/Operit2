// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/proxy/generated/CoreProxyClients.g.dart';
import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import '../../../../l10n/generated/app_localizations.dart';
import 'CodexLoginCallback.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
/// Signs in to ChatGPT Codex through the browser callback or a device code.
Future<core_proxy.CodexLoginResult?> showCodexLoginDialog({
  required BuildContext context,
  required GeneratedCoreProxyClients clients,
}) {
  return showDialog<core_proxy.CodexLoginResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CodexLoginDialog(clients: clients),
  );
}

class CodexLoginDialog extends StatefulWidget {
  const CodexLoginDialog({super.key, required this.clients});

  final GeneratedCoreProxyClients clients;

  @override
  State<CodexLoginDialog> createState() => _CodexLoginDialogState();
}

class _CodexLoginDialogState extends State<CodexLoginDialog> {
  core_proxy.CodexSessionStatus? _status;
  core_proxy.CodexDeviceAuthorization? _device;
  String? _error;
  bool _busy = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await widget.clients.servicesCodexOAuthService
          .sessionStatus();
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _status = status;
        _error = null;
      });
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _error = '$error';
      });
    }
  }

  Future<void> _browserLogin() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
      _device = null;
    });
    CodexLoginCallbackListener? listener;
    try {
      listener = await CodexLoginCallbackListener.bind();
      final start = await widget.clients.servicesCodexOAuthService
          .startBrowserLogin();
      final launched = await launchUrl(
        Uri.parse(start.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError(l10n.settingsModelCodexOpenPage);
      }
      final callback = await listener.completion.timeout(
        const Duration(minutes: 5),
      );
      if (callback == null || !mounted || _cancelled) {
        return;
      }
      final result = await widget.clients.servicesCodexOAuthService
          .completeBrowserLogin(
            code: callback.code,
            state: callback.state,
            expectedState: start.state,
            codeVerifier: start.codeVerifier,
          );
      if (!mounted || _cancelled) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _error = '$error';
        _busy = false;
      });
    } finally {
      await listener?.close();
    }
  }

  Future<void> _deviceLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final authorization = await widget.clients.servicesCodexOAuthService
          .startDeviceLogin();
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _device = authorization;
      });
      await launchUrl(
        Uri.parse(authorization.verificationUrl),
        mode: LaunchMode.externalApplication,
      );
      final result = await widget.clients.servicesCodexOAuthService
          .completeDeviceLogin(authorization: authorization);
      if (!mounted || _cancelled) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _error = '$error';
        _busy = false;
        _device = null;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.clients.servicesCodexOAuthService.logout();
      await _loadStatus();
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _error = '$error';
      });
    } finally {
      if (mounted && !_cancelled) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _status;
    final account = status == null
        ? ''
        : (status.email.trim().isEmpty ? status.accountId : status.email);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.settingsModelCodexLoginTitle)),
          IconButton(
            tooltip: l10n.cancel,
            icon: const Icon(OperitIcons.close_rounded, size: 20),
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.settingsModelCodexLoginDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            // 红框内容 1：单行展示账号状态和退出登录
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (status?.signedIn == true)
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    (status?.signedIn == true)
                        ? OperitIcons.verified_user_outlined
                        : OperitIcons.person_outline_rounded,
                    size: 18,
                    color: (status?.signedIn == true)
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == null
                          ? l10n.settingsModelCodexWaiting
                          : status.signedIn
                          ? l10n.settingsModelCodexSignedIn(account)
                          : l10n.settingsModelCodexSignedOut,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status?.signedIn == true)
                    TextButton(
                      onPressed: _busy ? null : _logout,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.settingsModelCodexLogout),
                    ),
                ],
              ),
            ),
            if (_device != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(l10n.settingsModelCodexDeviceInstructions),
              const SizedBox(height: 8),
              SelectableText(
                _device!.userCode,
                style: theme.textTheme.headlineSmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(_device!.verificationUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(OperitIcons.open_in_browser_rounded),
                  label: Text(l10n.settingsModelCodexOpenPage),
                ),
              ),
            ],
            if (_busy) ...<Widget>[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(l10n.settingsModelCodexWaiting),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                l10n.settingsModelCodexLoginFailed(_error!),
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            // 红框内容 2：单行展示设备码登录和浏览器登录
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _deviceLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.settingsModelCodexDevice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _browserLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.settingsModelCodexBrowser,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: const <Widget>[],
    );
  }
}

