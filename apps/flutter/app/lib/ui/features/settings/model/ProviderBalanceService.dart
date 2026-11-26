// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result representing provider balance and subscription usage details.
class ProviderBalanceInfo {
  const ProviderBalanceInfo({
    required this.success,
    this.balanceText,
    this.usageText,
    this.details,
    this.error,
    this.title,
    this.planLabel,
    this.windows = const <ProviderUsageWindow>[],
    this.usageDetails = const <ProviderUsageDetail>[],
  });

  final bool success;
  final String? balanceText;
  final String? usageText;
  final String? details;
  final String? error;

  /// Card heading; switching between subscription usage and account balance.
  final String? title;
  final String? planLabel;

  /// Measured quota windows rendered as labelled progress bars.
  final List<ProviderUsageWindow> windows;

  /// Raw subscription values such as credits or reset coupons.
  final List<ProviderUsageDetail> usageDetails;
}

/// One quota window of a subscription plan.
class ProviderUsageWindow {
  const ProviderUsageWindow({
    required this.label,
    required this.usedPercent,
    this.resetAt,
  });

  final String label;
  final int usedPercent;
  final DateTime? resetAt;
}

/// One raw subscription value row.
class ProviderUsageDetail {
  const ProviderUsageDetail({required this.label, required this.value});

  final String label;
  final String value;
}

/// Service that queries live account balance, credits, or subscription quota
/// from various AI model providers.
class ProviderBalanceService {
  ProviderBalanceService._();
  static final ProviderBalanceService instance = ProviderBalanceService._();

  final http.Client _client = http.Client();

  /// Queries the balance or subscription usage for the given provider type and credential.
  Future<ProviderBalanceInfo> fetchBalance({
    required String providerTypeId,
    required String apiKey,
    String? endpoint,
    bool isCodexSignedIn = false,
    String? codexAccount,
  }) async {
    final cleanType = providerTypeId.trim().toUpperCase();
    final cleanKey = apiKey.trim();

    // 1. OpenAI Codex reports live subscription usage from the signed-in
    // ChatGPT session, which is queried through the core service instead of
    // an API-key balance endpoint.
    if (cleanType == 'OPENAI_CODEX') {
      return const ProviderBalanceInfo(
        success: false,
        error: '订阅用量需登录 ChatGPT Codex 账号后查询',
      );
    }

    if (cleanKey.isEmpty) {
      return const ProviderBalanceInfo(
        success: false,
        error: '未配置 API Key',
      );
    }

    try {
      // 2. OpenRouter Credits & Usage
      if (cleanType == 'OPENROUTER') {
        return await _fetchOpenRouterBalance(cleanKey);
      }

      // 3. DeepSeek Balance
      if (cleanType == 'DEEPSEEK') {
        return await _fetchDeepSeekBalance(cleanKey);
      }

      // 4. SiliconFlow (硅基流动)
      if (cleanType == 'SILICONFLOW') {
        return await _fetchSiliconFlowBalance(cleanKey);
      }

      // 5. Moonshot (Kimi)
      if (cleanType == 'MOONSHOT') {
        return await _fetchMoonshotBalance(cleanKey);
      }

      // 6. Providers without a public balance endpoint.
      return const ProviderBalanceInfo(
        success: false,
        error: '该供应商暂不支持自动查询余额与订阅用量',
      );
    } catch (e) {
      return ProviderBalanceInfo(
        success: false,
        error: '获取余额失败: $e',
      );
    }
  }

  /// OpenRouter: GET https://openrouter.ai/api/v1/credits
  Future<ProviderBalanceInfo> _fetchOpenRouterBalance(String apiKey) async {
    final response = await _client.get(
      Uri.parse('https://openrouter.ai/api/v1/credits'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://operit.app',
        'X-Title': 'Operit2',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        final totalCredits = (data['total_credits'] as num?)?.toDouble() ?? 0.0;
        final totalUsage = (data['total_usage'] as num?)?.toDouble() ?? 0.0;
        final remaining = totalCredits - totalUsage;
        return ProviderBalanceInfo(
          success: true,
          balanceText: 'USD \$${remaining.toStringAsFixed(3)}',
          usageText: '已消耗: USD \$${totalUsage.toStringAsFixed(3)}',
          details: '总额度: \$${totalCredits.toStringAsFixed(3)}',
        );
      }
    }
    return ProviderBalanceInfo(
      success: false,
      error: '查询失败 (${response.statusCode})',
    );
  }

  /// DeepSeek: GET https://api.deepseek.com/user/balance
  Future<ProviderBalanceInfo> _fetchDeepSeekBalance(String apiKey) async {
    final response = await _client.get(
      Uri.parse('https://api.deepseek.com/user/balance'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final infos = json['balance_infos'] as List<dynamic>?;
      if (infos != null && infos.isNotEmpty) {
        final first = infos.first as Map<String, dynamic>;
        final currency = first['currency']?.toString() ?? 'CNY';
        final total = first['total_balance']?.toString() ?? '0.00';
        final granted = first['granted_balance']?.toString() ?? '0.00';
        final toppedUp = first['topped_up_balance']?.toString() ?? '0.00';
        final symbol = currency == 'CNY' ? '¥' : '\$';
        return ProviderBalanceInfo(
          success: true,
          balanceText: '$symbol$total',
          details: '充值: $symbol$toppedUp · 赠送: $symbol$granted',
        );
      }
    }
    return ProviderBalanceInfo(
      success: false,
      error: '查询失败 (${response.statusCode})',
    );
  }

  /// SiliconFlow: GET https://api.siliconflow.cn/v1/user/info
  Future<ProviderBalanceInfo> _fetchSiliconFlowBalance(String apiKey) async {
    final response = await _client.get(
      Uri.parse('https://api.siliconflow.cn/v1/user/info'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        final balance = data['balance']?.toString() ?? '0.00';
        final totalBalance = data['totalBalance']?.toString();
        return ProviderBalanceInfo(
          success: true,
          balanceText: '¥$balance',
          details: totalBalance != null ? '总额度: ¥$totalBalance' : null,
        );
      }
    }
    return ProviderBalanceInfo(
      success: false,
      error: '查询失败 (${response.statusCode})',
    );
  }

  /// Moonshot (Kimi): GET https://api.moonshot.cn/v1/users/me/balance
  Future<ProviderBalanceInfo> _fetchMoonshotBalance(String apiKey) async {
    final response = await _client.get(
      Uri.parse('https://api.moonshot.cn/v1/users/me/balance'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        final available = (data['available_balance'] as num?)?.toDouble() ?? 0.0;
        final cash = (data['cash_balance'] as num?)?.toDouble() ?? 0.0;
        final voucher = (data['voucher_balance'] as num?)?.toDouble() ?? 0.0;
        return ProviderBalanceInfo(
          success: true,
          balanceText: '¥${available.toStringAsFixed(2)}',
          details: '充值: ¥${cash.toStringAsFixed(2)} · 赠券: ¥${voucher.toStringAsFixed(2)}',
        );
      }
    }
    return ProviderBalanceInfo(
      success: false,
      error: '查询失败 (${response.statusCode})',
    );
  }
}
