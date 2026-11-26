// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operit2/ui/common/icons/operit_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Supported provider configuration for account-based login/authorization.
class ProviderAccountConfig {
  const ProviderAccountConfig({
    required this.providerTypeId,
    required this.providerName,
    required this.authUrl,
    required this.description,
    this.keyPrefix = '',
  });

  final String providerTypeId;
  final String providerName;
  final String authUrl;
  final String description;
  final String keyPrefix;
}

/// Registry of OAuth and console account authorization configurations for popular providers.
final Map<String, ProviderAccountConfig> kAccountSupportedProviders = <String, ProviderAccountConfig>{
  'OPENROUTER': const ProviderAccountConfig(
    providerTypeId: 'OPENROUTER',
    providerName: 'OpenRouter',
    authUrl: 'https://openrouter.ai/settings/keys',
    description: '通过 OpenRouter 官方账号一键登录并生成调用密钥。',
    keyPrefix: 'sk-or-',
  ),
  'ANTHROPIC': const ProviderAccountConfig(
    providerTypeId: 'ANTHROPIC',
    providerName: 'Claude (Anthropic)',
    authUrl: 'https://console.anthropic.com/settings/keys',
    description: '登录 Anthropic 官方控制台授权并获取 Claude 访问密钥。',
    keyPrefix: 'sk-ant-',
  ),
  'ANTHROPIC_GENERIC': const ProviderAccountConfig(
    providerTypeId: 'ANTHROPIC_GENERIC',
    providerName: 'Claude (Anthropic)',
    authUrl: 'https://console.anthropic.com/settings/keys',
    description: '登录 Anthropic 官方控制台授权并获取 Claude 访问密钥。',
    keyPrefix: 'sk-ant-',
  ),
  'MOONSHOT': const ProviderAccountConfig(
    providerTypeId: 'MOONSHOT',
    providerName: 'Kimi (Moonshot)',
    authUrl: 'https://platform.moonshot.cn/console/api-keys',
    description: '登录 Kimi 开放平台账号授权并获取服务密钥。',
    keyPrefix: 'sk-',
  ),
  'XAI': const ProviderAccountConfig(
    providerTypeId: 'XAI',
    providerName: 'xAI (Grok)',
    authUrl: 'https://console.x.ai/',
    description: '登录 xAI 官方账号并获取 API 授权密钥。',
    keyPrefix: 'xai-',
  ),
};

/// Displays an account sign-in/authorization dialog for the given provider type.
Future<String?> showProviderAccountLoginDialog({
  required BuildContext context,
  required String providerTypeId,
}) {
  final config = kAccountSupportedProviders[providerTypeId];
  if (config == null) {
    return Future<String?>.value(null);
  }
  return showDialog<String>(
    context: context,
    builder: (context) => _ProviderAccountLoginDialog(config: config),
  );
}

class _ProviderAccountLoginDialog extends StatefulWidget {
  const _ProviderAccountLoginDialog({required this.config});

  final ProviderAccountConfig config;

  @override
  State<_ProviderAccountLoginDialog> createState() =>
      _ProviderAccountLoginDialogState();
}

class _ProviderAccountLoginDialogState extends State<_ProviderAccountLoginDialog>
    with WidgetsBindingObserver {
  late final TextEditingController _keyController;
  bool _browserOpened = false;
  String? _detectedClipboardKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keyController = TextEditingController();
    unawaited(_checkClipboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkClipboard());
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      if (widget.config.keyPrefix.isNotEmpty) {
        if (text.startsWith(widget.config.keyPrefix) || text.length > 20) {
          if (mounted) {
            setState(() {
              _detectedClipboardKey = text;
              if (_keyController.text.isEmpty) {
                _keyController.text = text;
              }
            });
          }
          return;
        }
      } else if (text.length > 15 && mounted) {
        setState(() {
          _detectedClipboardKey = text;
          if (_keyController.text.isEmpty) {
            _keyController.text = text;
          }
        });
      }
    }
  }

  Future<void> _openOfficialLogin() async {
    final uri = Uri.parse(widget.config.authUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched && mounted) {
      setState(() {
        _browserOpened = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已在浏览器打开 ${widget.config.providerName} 授权页面，授权后复制密钥返回即可自动填入。'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(OperitIcons.verified_user_outlined, size: 22),
          const SizedBox(width: 8),
          Text('${widget.config.providerName} 获取授权密钥'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _openOfficialLogin,
              icon: const Icon(OperitIcons.open_in_new_rounded, size: 18),
              label: Text('前往 ${widget.config.providerName} 登录授权'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_browserOpened || _detectedClipboardKey != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      OperitIcons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _detectedClipboardKey != null
                            ? '已检测到剪贴板中的授权凭据！'
                            : '已打开授权页面，完成授权后复制 Key 回到此处即可完成登录。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: '授权密钥 (API Key)',
                hintText: '可在授权页面生成后填入或自动粘贴',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: '读取剪贴板',
                  icon: const Icon(Icons.content_paste_rounded),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text?.trim();
                    if (text != null && text.isNotEmpty && mounted) {
                      setState(() {
                        _keyController.text = text;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final key = _keyController.text.trim();
            if (key.isNotEmpty) {
              Navigator.of(context).pop(key);
            }
          },
          child: const Text('完成登录'),
        ),
      ],
    );
  }
}
