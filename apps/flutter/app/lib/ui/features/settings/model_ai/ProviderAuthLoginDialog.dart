// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ProviderLoginCallback.dart';

/// Starts and completes one account authorization for a provider.
///
/// This is a full page rather than a modal: the flow can stay open for browser
/// or device authorization without covering the app with a translucent dialog.
Future<core.ProviderAuthResult?> showProviderAuthLoginDialog({
  required BuildContext context,
  required GeneratedCoreProxyClients clients,
  required core.ProviderAuthProviderView provider,
}) {
  return Navigator.of(context).push<core.ProviderAuthResult>(
    MaterialPageRoute<core.ProviderAuthResult>(
      fullscreenDialog: true,
      builder: (context) =>
          _ProviderAuthLoginDialog(clients: clients, provider: provider),
    ),
  );
}

class _ProviderAuthLoginDialog extends StatefulWidget {
  const _ProviderAuthLoginDialog({
    required this.clients,
    required this.provider,
  });

  final GeneratedCoreProxyClients clients;
  final core.ProviderAuthProviderView provider;

  @override
  State<_ProviderAuthLoginDialog> createState() =>
      _ProviderAuthLoginDialogState();
}

class _ProviderAuthLoginDialogState extends State<_ProviderAuthLoginDialog> {
  bool _busy = true;
  String? _error;
  String? _hint;
  String? _userCode;
  String? _verificationUrl;
  String? _authorizationUrl;
  bool _approved = false;
  bool _manualSubmitting = false;
  core.ProviderBrowserAuthorization? _manualStart;
  final TextEditingController _manualController = TextEditingController();

  ProviderLoginCallbackListener? _listener;
  bool _cancelled = false;
  String? _activeProviderTypeId;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _cancelled = true;
    unawaited(_listener?.close());
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _approved = false;
      _manualSubmitting = false;
      _manualStart = null;
      _authorizationUrl = null;
      _manualController.clear();
    });
    try {
      if (widget.provider.loginStyle == 'device_code') {
        await _startDeviceLogin();
      } else if (widget.provider.loginStyle == 'manual_code') {
        await _startManualLogin();
      } else {
        await _startBrowserLogin();
      }
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _error = '$error';
        _busy = false;
      });
    }
  }

  Future<void> _startBrowserLogin() async {
    _listener = await ProviderLoginCallbackListener.bind();
    _activeProviderTypeId = widget.provider.providerTypeId;
    final start = await widget.clients.servicesProviderAuthService
        .startBrowserLogin(
          providerTypeId: widget.provider.providerTypeId,
          redirectUri: _listener!.redirectUri,
        );
    _authorizationUrl = start.authorizationUrl;
    final launched = await launchUrl(
      Uri.parse(start.authorizationUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('无法打开浏览器，请手动复制授权链接');
    }
    if (mounted) {
      setState(() {
        _busy = true;
        _hint = '已在浏览器中打开授权页，完成授权后会自动返回。';
        _error = null;
      });
    }
    final callback = await _listener!.completion.timeout(
      const Duration(minutes: 10),
      onTimeout: () => null,
    );
    if (callback == null || !mounted || _cancelled) {
      return;
    }
    final result = await widget.clients.servicesProviderAuthService
        .completeBrowserLogin(
          providerTypeId: widget.provider.providerTypeId,
          code: callback.code,
          state: callback.state,
          expectedState: start.state,
          codeVerifier: start.codeVerifier,
          redirectUri: start.redirectUri,
        );
    if (!mounted || _cancelled) {
      return;
    }
    setState(() {
      _busy = false;
      _approved = true;
    });
    Navigator.of(context).pop(result);
  }

  Future<void> _startManualLogin() async {
    final start = await widget.clients.servicesProviderAuthService
        .startManualLogin(providerTypeId: widget.provider.providerTypeId);
    if (!mounted || _cancelled) {
      return;
    }
    _manualStart = start;
    _authorizationUrl = start.authorizationUrl;
    final launched = await launchUrl(
      Uri.parse(start.authorizationUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || _cancelled) {
      return;
    }
    setState(() {
      _busy = false;
      _hint = launched
          ? '在浏览器完成授权，复制页面显示的授权码，粘贴到下方。'
          : '无法打开浏览器，请复制授权链接手动打开，再粘贴页面显示的授权码。';
      _error = null;
    });
  }

  Future<void> _submitManualCode() async {
    final start = _manualStart;
    final pasted = _manualController.text.trim();
    if (start == null) {
      return;
    }
    if (pasted.isEmpty) {
      setState(() => _error = '请粘贴授权码');
      return;
    }
    setState(() {
      _manualSubmitting = true;
      _error = null;
    });
    try {
      final result = await widget.clients.servicesProviderAuthService
          .completeManualLogin(
            providerTypeId: widget.provider.providerTypeId,
            pastedCode: pasted,
            expectedState: start.state,
            codeVerifier: start.codeVerifier,
            redirectUri: start.redirectUri,
          );
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _manualSubmitting = false;
        _approved = true;
      });
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _cancelled) {
        return;
      }
      setState(() {
        _manualSubmitting = false;
        _error = '$error';
      });
    }
  }

  Future<void> _startDeviceLogin() async {
    final start = await widget.clients.servicesProviderAuthService
        .startDeviceLogin(providerTypeId: widget.provider.providerTypeId);
    if (!mounted || _cancelled) {
      return;
    }
    _activeProviderTypeId = widget.provider.providerTypeId;
    setState(() {
      _userCode = start.userCode;
      _verificationUrl = start.verificationUrl;
      _hint = '在浏览器中输入验证码完成授权，此页会自动检查结果。';
      _error = null;
    });
    unawaited(
      launchUrl(
        Uri.parse(start.verificationUrl),
        mode: LaunchMode.externalApplication,
      ),
    );
    await _pollDevice(start);
  }

  Future<void> _pollDevice(core.ProviderDeviceAuthorization start) async {
    var interval = start.intervalSeconds < 1 ? 5 : start.intervalSeconds;
    final deadline = DateTime.fromMillisecondsSinceEpoch(start.expiresAtMillis);
    while (mounted && !_cancelled) {
      if (DateTime.now().isAfter(deadline)) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = '验证码已过期，请重新登录';
          });
        }
        return;
      }
      await Future<void>.delayed(Duration(seconds: interval));
      if (!mounted || _cancelled) {
        return;
      }
      final poll = await widget.clients.servicesProviderAuthService
          .pollDeviceLogin(
            providerTypeId:
                _activeProviderTypeId ?? widget.provider.providerTypeId,
            deviceCode: start.deviceCode,
          );
      if (poll.status == 'approved' && poll.account != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _approved = true;
        });
        Navigator.of(context).pop(poll.account);
        return;
      }
      if (poll.status == 'pending') {
        continue;
      }
      if (poll.status == 'slow_down') {
        interval += poll.nextIntervalSeconds > 0 ? poll.nextIntervalSeconds : 5;
        continue;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = poll.message.isEmpty ? '授权未完成，请重试' : poll.message;
        });
      }
      return;
    }
  }

  Future<void> _copyLink() async {
    final value = _authorizationUrl ?? _verificationUrl;
    if (value == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      setState(() => _hint = '链接已复制');
    }
  }

  Future<void> _reopen() async {
    final value = _authorizationUrl ?? _verificationUrl;
    if (value == null) {
      return;
    }
    await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUserCode() async {
    final value = _userCode;
    if (value == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      setState(() => _hint = '验证码已复制');
    }
  }

  bool get _isManual => widget.provider.loginStyle == 'manual_code';

  bool get _isDevice => widget.provider.loginStyle == 'device_code';

  String get _modeLabel {
    if (_isManual) {
      return '手动授权码';
    }
    if (_isDevice) {
      return '设备码登录';
    }
    return '浏览器授权';
  }

  IconData get _modeIcon {
    if (_isManual) {
      return ModelAiIcons.paste;
    }
    if (_isDevice) {
      return ModelAiIcons.deviceCode;
    }
    return ModelAiIcons.externalLink;
  }

  String get _defaultSubtitle {
    if (_isManual) {
      return '在授权页复制 code#state 或 code，粘贴到下方。';
    }
    if (_isDevice) {
      return '在浏览器输入验证码，完成后此页会自动检查结果。';
    }
    return '已在浏览器打开授权页，完成后会自动返回。';
  }

  String get _statusSubtitle {
    final hint = _hint;
    if (hint == null || hint.isEmpty) {
      return _defaultSubtitle;
    }
    if (hint.startsWith('在浏览器完成授权') ||
        hint.startsWith('已在浏览器中打开授权页') ||
        hint.startsWith('在浏览器中输入验证码')) {
      return _defaultSubtitle;
    }
    return hint;
  }

  String? get _authorizationHost {
    final value = _authorizationUrl ?? _verificationUrl;
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    final host = uri?.host ?? '';
    return host.isEmpty ? value : host;
  }

  int get _currentStep {
    if (_approved) {
      return 2;
    }
    if (_error != null) {
      return 1;
    }
    if (_busy && _hint == null) {
      return 0;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '取消授权',
          icon: const Icon(ModelAiIcons.close),
        ),
        title: const Text('账号授权'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: <Widget>[
                _buildHeader(context, scheme),
                const SizedBox(height: 22),
                _buildSteps(context, scheme),
                const SizedBox(height: 18),
                _buildStatusCard(context, scheme),
                if (_isManual &&
                    _manualStart != null &&
                    !_approved) ...<Widget>[
                  const SizedBox(height: 14),
                  _buildManualWarning(context, scheme),
                ],
                if (_isDevice || _isManual) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    '同一账号同时只能有一处授权在进行，切换会作废上一个代码。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  '授权过程在系统浏览器完成，应用只接收授权结果；凭据仅保存在本机。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.58),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _buildActions(context, scheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProviderLogo(
            providerTypeId: widget.provider.providerTypeId,
            fallbackName: widget.provider.displayName,
            size: 54,
            preserveBrandColor: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '账号授权',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.provider.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_modeLabel · 凭据只保存在本机',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context, ColorScheme scheme) {
    const labels = <String>['打开授权页', '完成授权', '已连接'];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 6,
                ),
                child: _stepChip(
                  context,
                  scheme,
                  index: index,
                  label: labels[index],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepChip(
    BuildContext context,
    ColorScheme scheme, {
    required int index,
    required String label,
  }) {
    final complete = index < _currentStep || _approved;
    final active = index == _currentStep && !_approved;
    final failed = active && _error != null;
    final background = active
        ? (failed
              ? scheme.errorContainer.withValues(alpha: 0.7)
              : scheme.primaryContainer.withValues(alpha: 0.55))
        : Colors.transparent;
    final foreground = complete || active
        ? (failed ? scheme.error : scheme.primary)
        : scheme.onSurfaceVariant;
    final fill = complete
        ? scheme.primary
        : active
        ? (failed ? scheme.error : scheme.primary)
        : scheme.surfaceContainerHighest;
    final onFill = complete
        ? scheme.onPrimary
        : (failed ? scheme.onError : scheme.onPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Center(
              child: complete
                  ? Icon(ModelAiIcons.check, size: 13, color: onFill)
                  : Text(
                      failed ? '!' : '${index + 1}',
                      style: TextStyle(
                        color: complete || active
                            ? onFill
                            : scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: active || complete
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _approved
        ? scheme.primary
        : (_error != null ? scheme.error : scheme.primary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_modeIcon, size: 20, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _statusTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _statusSubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusIndicator(scheme),
            ],
          ),
          if (_isDevice && _userCode != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '一次性验证码',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _userCode!,
                          style: textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _copyUserCode,
                    tooltip: '复制验证码',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      ModelAiIcons.copy,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isManual && _manualStart != null && !_approved) ...<Widget>[
            const SizedBox(height: 14),
            TextField(
              controller: _manualController,
              enabled: !_manualSubmitting,
              minLines: 1,
              maxLines: 3,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: scheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                labelText: '授权码',
                hintText: '粘贴 code#state 或 code',
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
                suffixIcon: _manualSubmitting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: '粘贴',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _manualController.text = data!.text!;
                          }
                        },
                        icon: Icon(
                          ModelAiIcons.paste,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
              onSubmitted: (_) => _submitManualCode(),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(ModelAiIcons.error, size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_authorizationHost != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  ModelAiIcons.endpoint,
                  size: 14,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '授权页：${_authorizationHost!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIndicator(ColorScheme scheme) {
    if (_approved) {
      return Icon(ModelAiIcons.success, size: 20, color: scheme.primary);
    }
    if (_error != null) {
      return Icon(ModelAiIcons.error, size: 20, color: scheme.error);
    }
    if (_busy) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      );
    }
    return Icon(ModelAiIcons.waiting, size: 18, color: scheme.onSurfaceVariant);
  }

  Widget _buildManualWarning(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ModelAiIcons.warning, size: 18, color: scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Claude Code 账号授权可能受 Anthropic 服务条款限制；如登录失败或账号受限，请改用 API Key。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme scheme) {
    final hasLink = _authorizationUrl != null || _verificationUrl != null;
    final manualReady = _isManual && _manualStart != null && !_approved;
    if (manualReady) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _manualSubmitting ? null : _submitManualCode,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          child: Text(_manualSubmitting ? '正在验证…' : '完成登录'),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: _start,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          child: const Text('重新开始'),
        ),
      );
    }
    if (!hasLink) {
      return const SizedBox.shrink();
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyLink,
            icon: const Icon(ModelAiIcons.copy, size: 16),
            label: const Text('复制链接'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _reopen,
            icon: const Icon(ModelAiIcons.externalLink, size: 16),
            label: const Text('重新打开'),
          ),
        ),
      ],
    );
  }

  String get _statusTitle {
    if (_approved) {
      return '授权完成';
    }
    if (_error != null) {
      return '授权未完成';
    }
    if (_isManual) {
      return '粘贴授权码';
    }
    if (_isDevice) {
      return '输入验证码';
    }
    return '等待浏览器授权';
  }
}
