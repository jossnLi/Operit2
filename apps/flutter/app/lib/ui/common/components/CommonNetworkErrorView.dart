// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import '../ApiErrorText.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';
class CommonNetworkErrorView extends StatelessWidget {
  /// Creates a model configuration error with its original details.
  const CommonNetworkErrorView({
    super.key,
    this.errorDetails,
    this.errorText,
  });

  final core_proxy.CoreProxyErrorDetails? errorDetails;
  final String? errorText;

  /// Builds a readable explanation followed by selectable original error text.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final summary = NetworkErrorSummary.fromDetails(errorDetails, errorText);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                summary.icon,
                size: 20,
                color: colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.message,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        height: 1.35,
                      ),
                    ),
                    if (summary.detail != null) ...<Widget>[
                      const SizedBox(height: 6),
                      SelectableText(
                        '原始错误：\n${summary.detail!}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer.withValues(
                            alpha: 0.74,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NetworkErrorSummary {
  /// Creates an explanation and optional original error details.
  const NetworkErrorSummary({
    required this.title,
    required this.message,
    required this.icon,
    this.detail,
  });

  final String title;
  final String message;
  final String? detail;
  final IconData icon;

  /// Converts structured runtime error details into a visible summary.
  factory NetworkErrorSummary.fromDetails(
    core_proxy.CoreProxyErrorDetails? details,
    String? text,
  ) {
    final original = text ?? details?.message;
    final statusCode = switch (details?.httpStatus) {
      final int status => status,
      null => apiErrorHttpStatus(original ?? ''),
    };
    final httpExplanation = apiErrorExplanation(statusCode);
    final explanation = switch ((
      httpExplanation,
      details?.variant,
      details?.kind,
    )) {
      (final ApiErrorExplanation http, _, _) => (
        title: 'HTTP $statusCode：${http.title}',
        message: http.message,
        category: http.category,
      ),
      (_, 'ModelAlreadyExists', _) => (
        title: '模型已存在',
        message: '模型“${details!.stringField('modelId')!}”'
            '已添加到供应商“${details.stringField('providerName')!}”。',
        category: ApiErrorCategory.info,
      ),
      (_, 'ModelListFetch', _) => (
        title: '模型列表拉取失败',
        message: '没有拿到供应商返回的模型列表，请检查服务地址、访问密钥和网络连接。',
        category: ApiErrorCategory.network,
      ),
      (_, _, 'network') => (
        title: '网络连接失败',
        message: '无法连接到模型供应商，请检查网络连接和服务地址。',
        category: ApiErrorCategory.network,
      ),
      _ => (
        title: '模型配置失败',
        message: '模型配置操作出现异常，请查看原始错误中的具体原因。',
        category: ApiErrorCategory.unknown,
      ),
    };
    return NetworkErrorSummary(
      title: explanation.title,
      message: explanation.message,
      detail: explanation.category == ApiErrorCategory.info ? null : original,
      icon: switch (explanation.category) {
        ApiErrorCategory.request => OperitIcons.tune_rounded,
        ApiErrorCategory.key => OperitIcons.key_off_rounded,
        ApiErrorCategory.billing => OperitIcons.account_balance_wallet_outlined,
        ApiErrorCategory.access => OperitIcons.lock_outline_rounded,
        ApiErrorCategory.address => OperitIcons.link_off_rounded,
        ApiErrorCategory.timeout => OperitIcons.timer_outlined,
        ApiErrorCategory.limit => OperitIcons.hourglass_top_rounded,
        ApiErrorCategory.server => OperitIcons.cloud_off_rounded,
        ApiErrorCategory.network => OperitIcons.wifi_off_rounded,
        ApiErrorCategory.info => OperitIcons.info_outline_rounded,
        ApiErrorCategory.unknown => OperitIcons.error_outline_rounded,
      },
    );
  }
}
