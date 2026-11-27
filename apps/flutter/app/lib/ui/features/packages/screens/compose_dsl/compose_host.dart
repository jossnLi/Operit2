// ignore_for_file: file_names

part of '../ToolPkgUiLauncherScreen.dart';

class _ComposeHost extends StatefulWidget {
  /// Creates the compose host instance.
  const _ComposeHost({
    super.key,
    required this.loading,
    required this.error,
    required this.renderResult,
    required this.showLoadingIndicator,
    required this.contentBuilder,
    required this.onAction,
    required this.onTextInput,
    required this.webViewHostContext,
    required this.splitMarkdownContent,
    this.dialogTitle,
    this.onRetry,
  });

  final bool loading;
  final String? error;
  final _ComposeDslRenderResult? renderResult;
  final bool showLoadingIndicator;
  final ToolPkgUiContentBuilder contentBuilder;
  final String? dialogTitle;

  /// Resolves function for the Compose DSL renderer.
  final Future<Object?> Function(String actionId, [Object? payload]) onAction;

  /// Dispatches text edits through the page-wide ordered text queue.
  final Future<Object?> Function(String actionId, String text) onTextInput;
  final ComposeDslWebViewHostContext webViewHostContext;
  final MarkdownContentSplitter splitMarkdownContent;

  /// Re-runs the route load after a runtime failure, when the host can retry.
  final VoidCallback? onRetry;

  /// Creates persistent state for this DSL widget.
  @override
  State<_ComposeHost> createState() => _ComposeHostState();
}

class _ComposeHostState extends State<_ComposeHost> {
  bool _hasDispatchedInitialOnLoad = false;
  bool _initialOnLoadScheduled = false;

  /// Synchronizes widget state with the latest DSL node.
  @override
  void didUpdateWidget(covariant _ComposeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderResult?.tree != widget.renderResult?.tree) {
      _dispatchRootOnLoad();
    }
  }

  /// Builds the widget for the current DSL state.
  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final title = widget.dialogTitle;
    final tree = widget.renderResult?.tree;
    final rootIsDialog = tree?.type == 'Dialog' || tree?.type == 'AlertDialog';
    if (title == null || (!widget.loading && rootIsDialog)) {
      return content;
    }
    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: 620, height: 420, child: content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  /// Builds loading, error, and rendered content within the selected surface.
  Widget _buildContent(BuildContext context) {
    final tree = widget.renderResult?.tree;
    if (!widget.loading && widget.error == null && tree != null) {
      _dispatchRootOnLoad();
    }
    if (widget.loading && widget.showLoadingIndicator) {
      return _presentBox(context, const M3LoadingPane());
    }
    if (widget.loading) {
      return _presentBox(context, const SizedBox.shrink());
    }
    final error = widget.error;
    final errorView = error == null
        ? null
        : _PluginRuntimeNotice(message: error, onRetry: widget.onRetry);
    if (tree == null) {
      return _presentBox(
        context,
        errorView == null ? const _NoUiView() : Center(child: errorView),
      );
    }
    // Keep the mounted renderer in a stable slot while reporting action failures.
    // Removing it would fire disposal callbacks, whose commits can mount it again.
    final renderer = _ComposeProgramExecutor(
      node: tree,
      onLoadHandledByHost: true,
      onAction: widget.onAction,
      onTextInput: widget.onTextInput,
      webViewHostContext: widget.webViewHostContext,
      splitMarkdownContent: widget.splitMarkdownContent,
      embedDialog: widget.dialogTitle != null,
    );
    return widget.contentBuilder(
      context,
      ToolPkgUiContent._compose(renderer, errorView),
    );
  }

  /// Presents loading and error boxes through the same embedding contract.
  Widget _presentBox(BuildContext context, Widget body) =>
      widget.contentBuilder(context, ToolPkgUiContent._box(body));

  /// Runs initial loading once and measures its first subsequent content frame.
  void _dispatchRootOnLoad() {
    if (_hasDispatchedInitialOnLoad ||
        _initialOnLoadScheduled ||
        widget.loading ||
        widget.error != null) {
      return;
    }
    final rootNode = widget.renderResult?.tree;
    if (rootNode == null) {
      return;
    }
    final rootOnLoadActionId = _actionId(rootNode.props['onLoad']);
    if (rootOnLoadActionId == null) {
      return;
    }
    _initialOnLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initialOnLoadScheduled = false;
      if (!mounted ||
          _hasDispatchedInitialOnLoad ||
          widget.loading ||
          widget.error != null) {
        return;
      }
      final currentRootNode = widget.renderResult?.tree;
      if (currentRootNode == null) {
        return;
      }
      final currentRootOnLoadActionId = _actionId(
        currentRootNode.props['onLoad'],
      );
      if (currentRootOnLoadActionId == null) {
        return;
      }
      _hasDispatchedInitialOnLoad = true;
      final watch = const bool.fromEnvironment('OPERIT_PROFILE_PLUGIN_UI')
          ? (Stopwatch()..start())
          : null;
      final owner = widget.webViewHostContext;
      await widget.onAction(currentRootOnLoadActionId, null);
      if (!mounted || widget.error != null) return;
      WidgetsBinding.instance.ensureVisualUpdate();
      if (watch == null) return;
      final actionMicros = watch.elapsedMicroseconds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.error != null ||
            widget.webViewHostContext.executionContextKey !=
                owner.executionContextKey) {
          return;
        }
        watch.stop();
        ClientLogger.v(
          'event=compose_onload_frame package=${owner.packageName} '
          'context=${owner.executionContextKey} elapsedMs=${watch.elapsedMilliseconds} '
          'actionMs=${(actionMicros / 1000).toStringAsFixed(3)} '
          'frameWaitMs=${((watch.elapsedMicroseconds - actionMicros) / 1000).toStringAsFixed(3)}',
          tag: 'ToolPkgUiLauncher',
          verboseLevel: VerboseLevel.level4,
        );
      });
    });
  }
}

/// Presents a plugin runtime failure as a quiet inline notice instead of a
/// full-bleed error container, so a transient runtime restart no longer
/// dominates the page.
class _PluginRuntimeNotice extends StatelessWidget {
  const _PluginRuntimeNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  /// Collapses engine-level failure strings into a readable one-liner.
  static String _summary(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('javascript runtime') ||
        lower.contains('runtime was destroyed')) {
      return '插件界面运行时已停止，重新加载即可恢复。';
    }
    if (lower.contains('session')) {
      return '插件界面会话已中断，重新加载即可恢复。';
    }
    return message.split('\n').first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                OperitIcons.warning_amber_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '界面加载中断',
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summary(message),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('重新加载'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
Widget buildComposeDslHostForTest({
  required Map<String, Object?> node,
  required ComposeDslWebViewHostContext hostContext,
  String? error,
  ToolPkgUiContentBuilder contentBuilder = _buildToolPkgUiBody,
}) {
  final tree = _composeProgramFixture(node);
  return _ComposeHost(
    loading: false,
    error: error,
    renderResult: _ComposeDslRenderResult(tree: tree, actionResult: null),
    showLoadingIndicator: false,
    contentBuilder: contentBuilder,
    onAction: hostContext.dispatchAction,
    onTextInput: (id, text) => hostContext.dispatchAction(id, text),
    webViewHostContext: hostContext,
    splitMarkdownContent: (_) async => [],
  );
}
