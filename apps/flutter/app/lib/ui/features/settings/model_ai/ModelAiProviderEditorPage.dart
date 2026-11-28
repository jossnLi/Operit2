// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;
import 'package:operit2/ui/components/model_ai/ModelAiIcons.dart';
import 'package:operit2/ui/components/model_ai/ModelAiSurfaces.dart';
import 'package:operit2/ui/features/settings/components/ApiKeyTextField.dart';
import 'package:operit2/ui/features/settings/model/ApiKeyPoolEditor.dart';
import 'package:operit2/ui/features/settings/model/ProviderBalanceService.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';
import 'package:operit2/ui/features/settings/model/ProviderTypePicker.dart';
import 'package:operit2/ui/features/settings/model_ai/ProviderAuthLoginDialog.dart';

/// Values returned by the provider editor and written by the caller.
class ModelAiProviderEditResult {
  const ModelAiProviderEditResult({
    required this.name,
    required this.providerTypeId,
    required this.endpoint,
    required this.apiKey,
    required this.useMultipleApiKeys,
    required this.apiKeyPool,
    required this.customHeaders,
    required this.requestLimitPerMinute,
    required this.maxConcurrentRequests,
  });

  final String name;
  final String providerTypeId;
  final String endpoint;
  final String apiKey;
  final bool useMultipleApiKeys;
  final List<core.ApiKeyInfo> apiKeyPool;
  final String customHeaders;
  final int requestLimitPerMinute;
  final int maxConcurrentRequests;
}

/// New full-screen provider editor used by the model and AI module.
///
/// It keeps the same core fields as the legacy editor but presents them as a
/// themed document with one primary action and inline endpoint choices.
class ModelAiProviderEditorPage extends StatefulWidget {
  const ModelAiProviderEditorPage({
    super.key,
    required this.catalogEntries,
    required this.occupiedProviderNames,
    required this.clients,
    this.provider,
  });

  final List<core.ProviderCatalogEntry> catalogEntries;
  final Set<String> occupiedProviderNames;
  final GeneratedCoreProxyClients clients;
  final core.ProviderProfile? provider;

  static Future<ModelAiProviderEditResult?> show({
    required BuildContext context,
    required List<core.ProviderCatalogEntry> catalogEntries,
    required Set<String> occupiedProviderNames,
    required GeneratedCoreProxyClients clients,
    core.ProviderProfile? provider,
  }) {
    return Navigator.of(context).push<ModelAiProviderEditResult>(
      MaterialPageRoute<ModelAiProviderEditResult>(
        fullscreenDialog: true,
        builder: (context) => ModelAiProviderEditorPage(
          catalogEntries: catalogEntries,
          occupiedProviderNames: occupiedProviderNames,
          clients: clients,
          provider: provider,
        ),
      ),
    );
  }

  @override
  State<ModelAiProviderEditorPage> createState() =>
      _ModelAiProviderEditorPageState();
}

class _ModelAiProviderEditorPageState extends State<ModelAiProviderEditorPage> {
  static const String _codexEndpoint =
      'https://chatgpt.com/backend-api/codex/responses';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _endpointController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _headersController;
  late final TextEditingController _requestLimitController;
  late final TextEditingController _concurrencyController;
  String? _providerTypeId;
  late bool _useKeyPool;
  late List<core.ApiKeyInfo> _keyPool;
  bool _advancedOpen = false;
  bool _balanceLoading = false;
  ProviderBalanceInfo? _balanceInfo;
  bool _authLoading = false;
  String? _signedInAccount;

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    _nameController = TextEditingController(text: provider?.name ?? '');
    _endpointController = TextEditingController(text: provider?.endpoint ?? '');
    _apiKeyController = TextEditingController(text: provider?.apiKey ?? '');
    _headersController = TextEditingController(
      text: provider?.customHeaders ?? '{}',
    );
    _requestLimitController = TextEditingController(
      text: (provider?.requestLimitPerMinute ?? 0).toString(),
    );
    _concurrencyController = TextEditingController(
      text: (provider?.maxConcurrentRequests ?? 1).toString(),
    );
    _useKeyPool = provider?.useMultipleApiKeys ?? false;
    _keyPool = List<core.ApiKeyInfo>.of(
      provider?.apiKeyPool ?? const <core.ApiKeyInfo>[],
    );
    _providerTypeId = provider?.providerTypeId ?? _fallbackTypeId;
    if (provider == null) {
      final catalog = _catalogFor(_providerTypeId);
      _endpointController.text = catalog?.defaultEndpoint ?? '';
    } else if (_isCodex) {
      _endpointController.text = _codexEndpoint;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _headersController.dispose();
    _requestLimitController.dispose();
    _concurrencyController.dispose();
    super.dispose();
  }

  String? get _fallbackTypeId {
    for (final entry in widget.catalogEntries) {
      if (entry.providerTypeId == 'DEEPSEEK') {
        return entry.providerTypeId;
      }
    }
    return widget.catalogEntries.isEmpty
        ? null
        : widget.catalogEntries.first.providerTypeId;
  }

  core.ProviderCatalogEntry? _catalogFor(String? id) {
    if (id == null) {
      return null;
    }
    for (final entry in widget.catalogEntries) {
      if (entry.providerTypeId == id) {
        return entry;
      }
    }
    return null;
  }

  core.ProviderCatalogEntry? get _catalog => _catalogFor(_providerTypeId);

  bool get _isCodex => _providerTypeId == 'OPENAI_CODEX';
  bool get _isLocal => _providerTypeId == 'LOCAL_MODEL';

  Future<void> _pickProviderType() async {
    final next = await showProviderTypePicker(
      context: context,
      entries: widget.catalogEntries,
      selectedProviderTypeId: _providerTypeId,
    );
    if (next == null || !mounted) {
      return;
    }
    final catalog = _catalogFor(next);
    setState(() {
      _providerTypeId = next;
      _endpointController.text = next == 'OPENAI_CODEX'
          ? _codexEndpoint
          : catalog?.defaultEndpoint ?? '';
      _useKeyPool = false;
    });
  }

  Future<void> _openAccountAuth() async {
    final providerTypeId = _providerTypeId;
    if (providerTypeId == null || _authLoading) {
      return;
    }
    setState(() => _authLoading = true);
    try {
      final providers = await widget.clients.servicesProviderAuthService
          .providers();
      core.ProviderAuthProviderView? account;
      for (final item in providers) {
        if (item.providerTypeId.toUpperCase() == providerTypeId.toUpperCase()) {
          account = item;
          break;
        }
      }
      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('该供应商暂不支持账号授权')));
        }
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _authLoading = false);
      final result = await showProviderAuthLoginDialog(
        context: context,
        clients: widget.clients,
        provider: account,
      );
      if (result != null && mounted) {
        setState(() => _signedInAccount = result.email);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('账号授权失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  Future<void> _fetchBalance() async {
    final providerTypeId = _providerTypeId;
    if (providerTypeId == null || _balanceLoading) {
      return;
    }
    final apiKey = _useKeyPool && _keyPool.isNotEmpty
        ? _keyPool.first.key
        : _apiKeyController.text;
    if (apiKey.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先填写 API Key，再查询余额')));
      return;
    }
    setState(() {
      _balanceLoading = true;
      _balanceInfo = null;
    });
    try {
      final info = await ProviderBalanceService.instance.fetchBalance(
        providerTypeId: providerTypeId,
        apiKey: apiKey,
        endpoint: _endpointController.text.trim().isEmpty
            ? null
            : _endpointController.text.trim(),
      );
      if (mounted) {
        setState(() => _balanceInfo = info);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _balanceInfo = ProviderBalanceInfo(
            success: false,
            error: '$error',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _balanceLoading = false);
      }
    }
  }

  void _save() {
    if (_providerTypeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择供应商类型')));
      return;
    }
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final requestLimit = int.tryParse(_requestLimitController.text.trim()) ?? 0;
    final concurrency = int.tryParse(_concurrencyController.text.trim()) ?? 1;
    Navigator.of(context).pop(
      ModelAiProviderEditResult(
        name: _nameController.text.trim(),
        providerTypeId: _providerTypeId!,
        endpoint: _isCodex
            ? _codexEndpoint
            : _isLocal
            ? ''
            : _endpointController.text.trim(),
        apiKey: _apiKeyController.text,
        useMultipleApiKeys: !_isCodex && !_isLocal && _useKeyPool,
        apiKeyPool: _keyPool,
        customHeaders: _headersController.text.trim().isEmpty
            ? '{}'
            : _headersController.text.trim(),
        requestLimitPerMinute: requestLimit < 0 ? 0 : requestLimit,
        maxConcurrentRequests: concurrency < 1 ? 1 : concurrency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final editing = widget.provider != null;
    return ModelAiPageScaffold(
      title: editing ? '编辑供应商' : '添加供应商',
      leading: IconButton(
        tooltip: '关闭',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(ModelAiIcons.close),
      ),
      actions: <Widget>[TextButton(onPressed: _save, child: const Text('保存'))],
      bottomNavigationBar: ModelAiBottomBar(
        hint: editing ? '保存后会立即应用新的连接参数；模型配置不会丢失。' : '凭据只保存在本机，添加后可继续管理模型。',
        child: FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          child: Text(editing ? '保存修改' : '添加供应商'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  ModelAiMetrics.pagePadding,
                  8,
                  ModelAiMetrics.pagePadding,
                  32,
                ),
                children: <Widget>[
                  _typeCard(context),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  ModelAiSection(
                    title: '基本信息',
                    subtitle: '名称只用于本机区分配置',
                    child: Column(
                      children: <Widget>[
                        _field(
                          context,
                          controller: _nameController,
                          label: '配置名称',
                          hint: '例如：DeepSeek 官方',
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return '请填写配置名称';
                            }
                            if (widget.occupiedProviderNames.contains(name)) {
                              return '该名称已被其他供应商使用';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          context,
                          controller: _endpointController,
                          label: 'API 地址',
                          hint: 'https://api.example.com/v1',
                          keyboardType: TextInputType.url,
                          readOnly: _isCodex || _isLocal,
                          validator: (value) {
                            if (_isLocal) {
                              return null;
                            }
                            final endpoint = value?.trim() ?? '';
                            if (endpoint.isEmpty) {
                              return '请填写 API 地址';
                            }
                            if (!endpoint.startsWith('http://') &&
                                !endpoint.startsWith('https://')) {
                              return '地址需要以 http:// 或 https:// 开头';
                            }
                            return null;
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                        ),
                        if (_catalog != null &&
                            _catalog!.endpointOptions.isNotEmpty &&
                            !_isCodex) ...<Widget>[
                          const SizedBox(height: 10),
                          _endpointChoices(context, _catalog!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  _credentialSection(context),
                  const SizedBox(height: ModelAiMetrics.sectionGap),
                  _advancedSection(context),
                  const SizedBox(height: 18),
                  Text(
                    '凭据只保存在本机；账号授权可在「账号授权」页完成，两者可以并存。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final catalog = _catalog;
    return ModelAiSection(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(ModelAiMetrics.cardRadius),
        onTap: _pickProviderType,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              ProviderLogo(
                providerTypeId: _providerTypeId ?? '',
                fallbackName: catalog?.displayName ?? '供应商',
                size: 54,
                preserveBrandColor: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '供应商类型',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      catalog?.displayName ?? '选择供应商',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _providerTypeId == null
                          ? '选择官方供应商或兼容端点'
                          : '${catalog?.models.length ?? 0} 个模型 · ${_providerTypeId!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ModelAiIcons.expandMore,
                size: 18,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _credentialSection(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final accountSupported =
        _providerTypeId != null &&
        (const <String>{
              'ANTHROPIC',
              'ANTHROPIC_GENERIC',
              'MOONSHOT',
              'XAI',
              'OPENROUTER',
            }.contains(_providerTypeId) ||
            _isCodex);
    return ModelAiSection(
      title: '账号与凭据',
      subtitle: _isLocal ? '本地模型不需要凭据' : 'API Key 或订阅账号',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_isLocal) ...<Widget>[
            _hint(context, ModelAiIcons.model, '本地模型直接连接设备上的推理服务，不需要 API Key。'),
          ] else ...<Widget>[
            if (!_isCodex && !_useKeyPool)
              ApiKeyTextField(
                key: ValueKey<String?>(_providerTypeId),
                controller: _apiKeyController,
                labelText: 'API Key',
              ),
            if (!_isCodex && _useKeyPool)
              _hint(context, ModelAiIcons.apiKey, 'Key 池已启用，可在下方高级设置中管理多个密钥。'),
            if (_isCodex)
              _hint(
                context,
                ModelAiIcons.account,
                'ChatGPT Codex 使用订阅账号授权，不需要单独填写 API Key。',
              ),
            if (accountSupported || !_isCodex) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (accountSupported)
                    OutlinedButton.icon(
                      onPressed: _authLoading ? null : _openAccountAuth,
                      icon: _authLoading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(ModelAiIcons.account, size: 17),
                      label: Text(
                        _signedInAccount == null
                            ? '账号授权'
                            : '已登录 ${_signedInAccount!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!_isCodex)
                    OutlinedButton.icon(
                      onPressed: _balanceLoading ? null : _fetchBalance,
                      icon: _balanceLoading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(ModelAiIcons.refresh, size: 17),
                      label: Text(_balanceLoading ? '查询中…' : '查询余额'),
                    ),
                ],
              ),
            ],
            if (_balanceInfo != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: palette.inset.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _balanceInfo!.success
                          ? _balanceInfo!.title ?? '账户余额'
                          : '查询失败',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _balanceInfo!.success
                            ? palette.text
                            : palette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _balanceInfo!.success
                          ? <String?>[
                                  _balanceInfo!.balanceText,
                                  _balanceInfo!.usageText,
                                  _balanceInfo!.details,
                                ]
                                .whereType<String>()
                                .where((e) => e.trim().isNotEmpty)
                                .join(' · ')
                          : _balanceInfo!.error ?? '未返回余额信息',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (accountSupported) ...<Widget>[
              const SizedBox(height: 8),
              _hint(
                context,
                ModelAiIcons.info,
                '账号授权与 API Key 可同时存在；轮换时优先使用可用凭据。',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _advancedSection(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    return ModelAiSection(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(ModelAiMetrics.cardRadius),
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: <Widget>[
                  ModelAiIconTile(icon: ModelAiIcons.settings, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '高级设置',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '请求头、限流与 API Key 池',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _advancedOpen
                        ? ModelAiIcons.expandLess
                        : ModelAiIcons.expandMore,
                    size: 18,
                    color: palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _advancedOpen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: palette.border.withValues(alpha: 0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _field(
                              context,
                              controller: _headersController,
                              label: '自定义请求头',
                              hint: '{"X-Org": "operit"}',
                              maxLines: 4,
                              validator: _jsonValidator,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _field(
                                    context,
                                    controller: _requestLimitController,
                                    label: '每分钟请求上限',
                                    hint: '0',
                                    keyboardType: TextInputType.number,
                                    validator: _nonNegativeIntValidator,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    context,
                                    controller: _concurrencyController,
                                    label: '最大并发',
                                    hint: '1',
                                    keyboardType: TextInputType.number,
                                    validator: _positiveIntValidator,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!_isCodex && !_isLocal) ...<Widget>[
                              const SizedBox(height: 14),
                              ApiKeyPoolEditor(
                                singleKey: _apiKeyController.text,
                                onResetHealth: widget.provider == null
                                    ? null
                                    : () => widget
                                          .clients
                                          .preferencesModelConfigManager
                                          .clearProviderApiKeyFailures(
                                            providerId: widget.provider!.id,
                                          ),
                                enabled: _useKeyPool,
                                entries: _keyPool,
                                onEnabledChanged: (value) =>
                                    setState(() => _useKeyPool = value),
                                onChanged: (entries) =>
                                    setState(() => _keyPool = entries),
                                onTestingChanged: (_) {},
                                onTestEntry:
                                    widget.provider?.models.isNotEmpty == true
                                    ? (entry) => widget.clients.application
                                          .testProviderApiKey(
                                            provider: core.ProviderProfile(
                                              id: widget.provider!.id,
                                              name: _nameController.text.trim(),
                                              providerTypeId: _providerTypeId!,
                                              providerType:
                                                  core.ApiProviderType.fromJson(
                                                    _providerTypeId!,
                                                  ),
                                              endpoint: _endpointController.text
                                                  .trim(),
                                              apiKey: _apiKeyController.text,
                                              useMultipleApiKeys: _useKeyPool,
                                              apiKeyPool: _keyPool,
                                              currentKeyIndex: widget
                                                  .provider!
                                                  .currentKeyIndex,
                                              keyRotationMode: widget
                                                  .provider!
                                                  .keyRotationMode,
                                              customHeaders:
                                                  _headersController.text,
                                              requestLimitPerMinute:
                                                  int.tryParse(
                                                    _requestLimitController.text
                                                        .trim(),
                                                  ) ??
                                                  0,
                                              maxConcurrentRequests:
                                                  int.tryParse(
                                                    _concurrencyController.text
                                                        .trim(),
                                                  ) ??
                                                  1,
                                              models: widget.provider!.models,
                                            ),
                                            keyId: entry.id,
                                          )
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _endpointChoices(
    BuildContext context,
    core.ProviderCatalogEntry catalog,
  ) {
    final palette = ModelAiPalette.of(context);
    final current = _endpointController.text.trim();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        for (final option in catalog.endpointOptions)
          ChoiceChip(
            selected: option.endpoint == current,
            showCheckmark: false,
            label: Text(
              option.label.isEmpty ? option.endpoint : option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: option.endpoint == current
                  ? palette.accent
                  : palette.textSecondary,
            ),
            backgroundColor: palette.inset.withValues(alpha: 0.55),
            selectedColor: palette.accentTint,
            side: BorderSide(
              color: option.endpoint == current
                  ? palette.accent.withValues(alpha: 0.35)
                  : palette.border.withValues(alpha: 0.5),
            ),
            onSelected: (_) => setState(() {
              _endpointController.text = option.endpoint;
            }),
          ),
      ],
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final palette = ModelAiPalette.of(context);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: palette.text, height: 1.4),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: palette.inset.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.danger, width: 1.2),
        ),
      ),
    );
  }

  Widget _hint(BuildContext context, IconData icon, String text) {
    final palette = ModelAiPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: palette.textTertiary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  String? _jsonValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    try {
      final decoded = text.startsWith('{') ? text : '{$text}';
      if (decoded.contains(':')) {
        return null;
      }
    } catch (_) {
      return '请求头格式不正确';
    }
    return '请求头格式不正确';
  }

  String? _nonNegativeIntValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return '请输入 0 或正整数';
    }
    return null;
  }

  String? _positiveIntValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) {
      return '请输入大于 0 的整数';
    }
    return null;
  }
}
