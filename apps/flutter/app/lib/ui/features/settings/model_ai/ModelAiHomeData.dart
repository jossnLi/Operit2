// ignore_for_file: file_names

import 'package:operit2/core/link/CoreLinkProtocol.dart';
import 'package:operit2/core/proxy/generated/CoreProxyClients.g.dart';
import 'package:operit2/core/proxy/generated/CoreProxyModels.g.dart' as core;

/// Read-only snapshot backing every model and AI page.
class ModelAiHomeData {
  const ModelAiHomeData({
    required this.providers,
    required this.summaries,
    required this.chatBinding,
    required this.currentConfig,
    required this.accounts,
    required this.authProviders,
    required this.functionBindings,
  });

  final List<core.ProviderProfile> providers;
  final List<core.ProviderModelSummary> summaries;
  final core.FunctionModelBinding chatBinding;
  final core.ResolvedModelConfig? currentConfig;
  final Map<String, core.ProviderAuthStatus> accounts;
  final List<core.ProviderAuthProviderView> authProviders;
  final Map<core.FunctionType, core.FunctionModelBinding> functionBindings;

  core.ProviderModelSummary? get currentSummary {
    for (final summary in summaries) {
      if (summary.providerId == chatBinding.providerId &&
          summary.modelId == chatBinding.modelId) {
        return summary;
      }
    }
    return null;
  }

  int modelCountFor(String providerId) {
    return summaries
        .where((summary) => summary.providerId == providerId)
        .length;
  }
}

/// Loads the current model binding and provider list without owning edits.
Future<ModelAiHomeData> loadModelAiHomeData(
  GeneratedCoreProxyClients clients,
) async {
  final modelManager = clients.preferencesModelConfigManager;
  final functionManager = clients.preferencesFunctionalConfigManager;
  final chatBinding = await functionManager.getModelBindingForFunction(
    functionType: core.FunctionType.chat,
  );
  final providers = await modelManager.getProviderProfiles();
  final summaries = await modelManager.getAllModelSummaries();
  core.ResolvedModelConfig? currentConfig;
  if (summaries.any(
    (model) =>
        model.providerId == chatBinding.providerId &&
        model.modelId == chatBinding.modelId,
  )) {
    try {
      currentConfig = await modelManager.getResolvedModelConfig(
        providerId: chatBinding.providerId,
        modelId: chatBinding.modelId,
      );
    } on CoreLinkError catch (error) {
      if (error.code != 'COMMAND_ERROR' ||
          !(error.message.startsWith('model not found: ') ||
              error.message.startsWith('provider not found: '))) {
        rethrow;
      }
    }
  }
  Map<String, core.ProviderAuthStatus> accounts =
      const <String, core.ProviderAuthStatus>{};
  List<core.ProviderAuthProviderView> authProviders =
      const <core.ProviderAuthProviderView>[];
  try {
    authProviders = await clients.servicesProviderAuthService.providers();
    final statuses = await clients.servicesProviderAuthService.statuses();
    accounts = <String, core.ProviderAuthStatus>{
      for (final status in statuses)
        if (status.signedIn) status.providerTypeId.toUpperCase(): status,
    };
  } catch (_) {
    // Account status is optional metadata; the page still renders API-key providers.
  }
  return ModelAiHomeData(
    providers: providers,
    summaries: summaries,
    chatBinding: chatBinding,
    currentConfig: currentConfig,
    accounts: accounts,
    authProviders: authProviders,
    functionBindings: await functionManager.functionModelBindingFlow().first,
  );
}
