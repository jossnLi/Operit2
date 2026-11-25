import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The title treatment used by the main app bar and the Studio fixture.
class ThemeTopBarTitle extends StatelessWidget {
  const ThemeTopBarTitle({
    super.key,
    required this.primaryText,
    required this.contentColor,
    this.secondaryText = '',
  });

  final String primaryText;
  final String secondaryText;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (primaryText.isNotEmpty)
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                primaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          if (primaryText.isNotEmpty && secondaryText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '·',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: contentColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (secondaryText.isNotEmpty)
            Flexible(
              child: Text(
                secondaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: contentColor.withValues(alpha: 0.78),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared visual frame for the main client bar. Routing and action creation
/// remain with the host; this widget owns only the fixed paint geometry.
class ThemeTopBarChrome extends StatelessWidget {
  const ThemeTopBarChrome({
    super.key,
    required this.title,
    this.navigationIcon,
    this.navigationTooltip,
    this.onNavigationPressed,
    required this.contentColor,
    required this.contentForeground,
    this.topPadding = 0,
    this.flipNavigationIcon = false,
    this.actions = const <Widget>[],
  });

  /// Shared vertical geometry for the app bar and desktop sidebar headers.
  static const double toolbarHeight = 52;

  final Widget title;
  final IconData? navigationIcon;
  final String? navigationTooltip;
  final VoidCallback? onNavigationPressed;
  final Color contentColor;
  final Color contentForeground;
  final double topPadding;
  final bool flipNavigationIcon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final navIcon = navigationIcon;
    final navigationIconWidget = navIcon != null
        ? Icon(navIcon, size: 22, color: contentForeground)
        : null;
    final leadingExtent = navIcon != null ? 52.0 : 8.0;
    final trailingExtent = actions.length * 44.0 + 8.0;
    // Without trailing actions, equal side margins keep the title exactly
    // centered; pages with actions keep their title beside the leading icon.
    final centered = actions.isEmpty;
    return ColoredBox(
      color: contentColor,
      child: SizedBox(
        height: topPadding + toolbarHeight,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: leadingExtent,
                    end: centered ? leadingExtent : trailingExtent,
                  ),
                  child: Align(
                    alignment: centered
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: title,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (navIcon != null && navigationIconWidget != null) ...<Widget>[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onNavigationPressed,
                        icon: flipNavigationIcon
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
                                child: navigationIconWidget,
                              )
                            : navigationIconWidget,
                        tooltip: navigationTooltip,
                      ),
                    ),
                  ] else ...<Widget>[
                    SizedBox(width: actions.isNotEmpty ? 46 : 16),
                  ],
                  const Spacer(),
                  ...actions,
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared workspace toggle used as a top-bar action.
class ThemeWorkspaceTopBarButton extends StatelessWidget {
  const ThemeWorkspaceTopBarButton({
    super.key,
    required this.open,
    required this.hasBoundWorkspace,
    required this.onPressed,
  });

  final bool open;
  final bool hasBoundWorkspace;
  final VoidCallback onPressed;

  static const String _workspaceClosedSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/>
  <path d="M2 10h20"/>
</svg>''';

  static const String _workspaceOpenSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/>
  <path d="M2 10h20"/>
  <circle cx="17" cy="15" r="2" fill="currentColor"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = open ? scheme.primary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: onPressed,
          icon: SvgPicture.string(
            open ? _workspaceOpenSvg : _workspaceClosedSvg,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          tooltip: open ? 'Close workspace' : 'Workspace',
        ),
      ),
    );
  }
}
