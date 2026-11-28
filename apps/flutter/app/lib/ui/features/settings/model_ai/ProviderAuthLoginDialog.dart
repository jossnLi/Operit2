// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ProviderLoginCallback.dart';

/// Starts and completes one account authorization for a provider.
Future<core.ProviderAuthResult?> showProviderAuthLoginDialog({
  required BuildContext context,
  required GeneratedCoreProxyClients clients,
  required core.ProviderAuthProviderView provider,
}) {
  return showDialog<core.ProviderAuthResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _ProviderAuthLoginDialog(clients: clients, provider: provider),
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

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      title: Row(
        children: <Widget>[
          Icon(
            widget.provider.loginStyle == 'device_code' ||
                    widget.provider.loginStyle == 'manual_code'
                ? OperitIcons.key_outlined
                : OperitIcons.open_in_new_rounded,
            size: 20,
            color: palette.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.provider.displayName} 账号授权',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_approved)
              Row(
                children: <Widget>[
                  Icon(
                    OperitIcons.check_rounded,
                    color: palette.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('授权完成'),
                ],
              )
            else if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_userCode != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '验证码',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userCode!,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (_manualStart != null && !_approved) ...<Widget>[
              const SizedBox(height: 14),
              TextField(
                controller: _manualController,
                enabled: !_manualSubmitting,
                minLines: 1,
                maxLines: 3,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: '授权码',
                  hintText: '粘贴 code#state 或 code',
                  border: const OutlineInputBorder(),
                  suffixIcon: _manualSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: '粘贴',
                          icon: const Icon(
                            OperitIcons.content_paste_outlined,
                            size: 18,
                          ),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _manualController.text = data!.text!;
                            }
                          },
                        ),
                ),
                onSubmitted: (_) => _submitManualCode(),
              ),
            ],
            if (_hint != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _hint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            if (_manualStart != null && !_approved) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Claude Code 账号授权可能受 Anthropic 服务条款限制；如登录失败或账号受限，请改用 API Key。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.error,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        if (_authorizationUrl != null || _verificationUrl != null)
          TextButton.icon(
            onPressed: _copyLink,
            icon: const Icon(OperitIcons.content_copy_rounded, size: 16),
            label: const Text('复制链接'),
          ),
        if (_authorizationUrl != null || _verificationUrl != null)
          TextButton.icon(
            onPressed: _reopen,
            icon: const Icon(OperitIcons.open_in_new_rounded, size: 16),
            label: const Text('重新打开'),
          ),
        if (_manualStart != null && !_approved)
          FilledButton(
            onPressed: _manualSubmitting ? null : _submitManualCode,
            child: Text(_manualSubmitting ? '正在验证…' : '完成登录'),
          ),
        if (_error != null)
          TextButton(onPressed: _start, child: const Text('重试')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
