// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:desktop_widgets/desktop_widgets.dart';

import '../../../../core/proxy/generated/CoreProxyClients.g.dart';
import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import '../../../../l10n/generated/app_localizations.dart';
import 'ToolPkgUiLauncherScreen.dart';

import 'package:operit2/ui/common/icons/operit_icons.dart';

/// Shows a package's registered widget render routes through the shared Flutter host.
class ToolPkgDesktopWidgetsScreen extends StatefulWidget {
  /// Creates the widget gallery for one enabled package.
  const ToolPkgDesktopWidgetsScreen({
    super.key,
    required this.clients,
    required this.plugin,
  });

  final GeneratedCoreProxyClients clients;
  final core_proxy.ToolPkgContainerRuntime plugin;

  /// Creates localized registration loading state.
  @override
  State<ToolPkgDesktopWidgetsScreen> createState() =>
      _ToolPkgDesktopWidgetsScreenState();
}

class _ToolPkgDesktopWidgetsScreenState
    extends State<ToolPkgDesktopWidgetsScreen> {
  Future<List<core_proxy.ToolPkgDesktopWidget>>? _widgets;
  String? _language;

  /// Creates a desktop content window and displays explicit host errors to the user.
  Future<void> _addToDesktop(core_proxy.ToolPkgDesktopWidget definition) async {
    try {
      await DesktopWidgetWindow.open(
        payload: {
          'instanceId': 'desktop:${DateTime.now().microsecondsSinceEpoch}',
          'definition': definition.toJson(),
          'locale': Localizations.localeOf(context).languageCode,
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  /// Loads only registrations exposed by currently enabled packages.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _widgets = widget.clients.application
          .packageManager()
          .getToolPkgDesktopWidgets(useEnglish: language == 'en')
          .then(
            (values) => values
                .where(
                  (item) =>
                      item.containerPackageName == widget.plugin.packageName,
                )
                .toList(),
          );
    }
  }

  /// Opens the registration's application route rather than its widget render route.
  Future<void> _openRoute(String packageName, String routeId) async {
    if (packageName != widget.plugin.packageName) {
      throw StateError('Widget route belongs to another package: $packageName');
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ToolPkgUiLauncherScreen(
          clients: widget.clients,
          plugin: widget.plugin,
          initialRouteId: routeId,
        ),
      ),
    );
  }

  /// Displays independently refreshable widget instances in responsive cards.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.desktopWidgetsCount(widget.plugin.desktopWidgets.length),
        ),
      ),
      body: FutureBuilder<List<core_proxy.ToolPkgDesktopWidget>>(
        future: _widgets,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline_rounded,
                      size: 32,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final definitions = snapshot.data!;
          if (definitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    OperitIcons.widgets_outlined,
                    size: 32,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _language == 'en'
                        ? 'No desktop widgets registered'
                        : '暂无桌面小组件',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 480,
              mainAxisExtent: 320,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: definitions.length,
            itemBuilder: (context, index) {
              final definition = definitions[index];
              return Card.filled(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        definition.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _addToDesktop(definition),
                          icon: const Icon(
                            OperitIcons.add_to_home_screen_outlined,
                          ),
                          label: Text(
                            _language == 'en' ? 'Add to desktop' : '添加到桌面',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ToolPkgDesktopWidgetView(
                          key: ValueKey(definition.widgetId),
                          clients: widget.clients,
                          definition: definition,
                          instanceId:
                              'preview:${definition.containerPackageName}:${definition.widgetId}',
                          onOpenRoute: _openRoute,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
