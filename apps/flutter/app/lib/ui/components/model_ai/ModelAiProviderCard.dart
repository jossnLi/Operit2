// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:operit2/ui/features/settings/model/ProviderLogo.dart';

import 'ModelAiIcons.dart';
import 'ModelAiSurfaces.dart';

/// Summary row for one configured provider.
class ModelAiProviderCard extends StatelessWidget {
  const ModelAiProviderCard({
    super.key,
    required this.providerTypeId,
    required this.name,
    required this.modelCount,
    this.accountEmail,
    this.planEnabled = false,
    this.needsReauthentication = false,
    this.isDefault = false,
    this.onTap,
  });

  final String providerTypeId;
  final String name;
  final int modelCount;
  final String? accountEmail;
  final bool planEnabled;
  final bool needsReauthentication;
  final bool isDefault;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModelAiPalette.of(context);
    final hasAccount = accountEmail != null && accountEmail!.isNotEmpty;
    final status = needsReauthentication
        ? const ModelAiStatusPill(
            label: '需重新登录',
            tone: ModelAiStatusTone.danger,
            compact: true,
          )
        : hasAccount
        ? ModelAiStatusPill(
            label: planEnabled ? '订阅已启用' : '账号已连接',
            tone: planEnabled
                ? ModelAiStatusTone.success
                : ModelAiStatusTone.accent,
            compact: true,
          )
        : const ModelAiStatusPill(
            label: 'API Key',
            tone: ModelAiStatusTone.neutral,
            compact: true,
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: <Widget>[
            ProviderLogo(
              providerTypeId: providerTypeId,
              fallbackName: name,
              size: 42,
              showBackdrop: true,
              preserveBrandColor: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (isDefault) ...<Widget>[
                        const SizedBox(width: 6),
                        const ModelAiStatusPill(
                          label: '默认',
                          tone: ModelAiStatusTone.accent,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      status,
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasAccount
                              ? (accountEmail!.isEmpty
                                    ? '$modelCount 个模型'
                                    : accountEmail!)
                              : '$modelCount 个模型',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(ModelAiIcons.chevron, size: 18, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}
