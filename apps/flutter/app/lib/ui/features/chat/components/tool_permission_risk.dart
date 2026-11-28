// ignore_for_file: file_names

import 'package:flutter/widgets.dart';

import '../../../../core/proxy/generated/CoreProxyModels.g.dart' as core_proxy;
import 'package:operit2/ui/common/icons/operit_icons.dart';

/// Risk tier for a single tool invocation.
///
/// The tier — not the tool name — decides how many options the user is
/// offered. High risk never exposes a session-wide approval.
enum ToolPermissionRisk { low, medium, high }

/// Coarse action family, used for the card headline and the object icon.
enum ToolActionKind { read, write, command, network, other }

/// One concrete thing the assistant is about to touch: a path, a command,
/// a URL or a matched pattern.
class ToolPermissionObject {
  const ToolPermissionObject({
    required this.icon,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final String value;
  final String? hint;
}

/// Presentation-ready assessment of one permission request.
class ToolPermissionAssessment {
  const ToolPermissionAssessment({
    required this.kind,
    required this.risk,
    required this.actionLabel,
    required this.icon,
    required this.riskLabel,
    required this.consequence,
    required this.objects,
    required this.hiddenObjectCount,
    required this.sessionAllowed,
    required this.parameterLabel,
  });

  final ToolActionKind kind;
  final ToolPermissionRisk risk;
  final String actionLabel;
  final IconData icon;
  final String riskLabel;
  final String consequence;
  final List<ToolPermissionObject> objects;
  final int hiddenObjectCount;

  /// Whether "allow for this session" may be offered at all.
  final bool sessionAllowed;

  final String parameterLabel;
}

const int _maxVisibleObjects = 3;

const List<String> _commandHints = <String>[
  'command',
  'shell',
  'exec',
  'terminal',
  'bash',
  'script',
  'spawn',
  'process',
];
const List<String> _writeHints = <String>[
  'write',
  'edit',
  'create',
  'delete',
  'remove',
  'move',
  'rename',
  'copy',
  'patch',
  'save',
  'mkdir',
];
const List<String> _networkHints = <String>[
  'http',
  'fetch',
  'browse',
  'web',
  'url',
  'download',
  'upload',
  'request',
];
const List<String> _readHints = <String>[
  'read',
  'list',
  'glob',
  'grep',
  'search',
  'stat',
  'view',
  'cat',
  'find',
  'scan',
];

const List<String> _destructiveHints = <String>[
  'overwrite',
  '--force',
  'rm -',
  'remove ',
  'delete ',
  'sudo',
  'kill ',
  'reset',
  'uninstall',
  'format',
  'push ',
];

const List<String> _objectKeys = <String>[
  'path',
  'file',
  'files',
  'command',
  'cmd',
  'script',
  'url',
  'uri',
  'pattern',
  'query',
  'package',
  'target',
];

/// Maps a request to a risk tier, a headline and the objects worth showing.
ToolPermissionAssessment assessToolPermission(
  core_proxy.RuntimeHostInteractionToolPermissionRequest request,
) {
  final name = request.tool.name.toLowerCase();
  final parameters = request.tool.parameters
      .where((parameter) => !parameter.name.startsWith('__operit_package_'))
      .toList(growable: false);

  final kind = _classify(name);
  final destructive = parameters.any(
    (parameter) =>
        _containsAny(parameter.value.toLowerCase(), _destructiveHints),
  );
  final risk = _riskFor(kind, destructive);

  final objects = _collectObjects(kind, parameters);
  final visible = objects.length > _maxVisibleObjects
      ? objects.sublist(0, _maxVisibleObjects)
      : objects;

  return ToolPermissionAssessment(
    kind: kind,
    risk: risk,
    actionLabel: _actionLabel(kind),
    icon: _kindIcon(kind),
    riskLabel: switch (risk) {
      ToolPermissionRisk.low => '低风险',
      ToolPermissionRisk.medium => '中风险',
      ToolPermissionRisk.high => '高风险',
    },
    consequence: _consequence(kind, risk, destructive),
    objects: visible,
    hiddenObjectCount: objects.length - visible.length,
    sessionAllowed: risk != ToolPermissionRisk.high,
    parameterLabel: '参数',
  );
}

ToolActionKind _classify(String name) {
  if (_nameHits(name, _commandHints)) {
    return ToolActionKind.command;
  }
  if (_nameHits(name, _writeHints)) {
    return ToolActionKind.write;
  }
  if (_nameHits(name, _networkHints)) {
    return ToolActionKind.network;
  }
  if (_nameHits(name, _readHints)) {
    return ToolActionKind.read;
  }
  return ToolActionKind.other;
}

ToolPermissionRisk _riskFor(ToolActionKind kind, bool destructive) {
  if (destructive) {
    return ToolPermissionRisk.high;
  }
  return switch (kind) {
    ToolActionKind.read => ToolPermissionRisk.low,
    ToolActionKind.command => ToolPermissionRisk.high,
    ToolActionKind.write || ToolActionKind.network => ToolPermissionRisk.medium,
    ToolActionKind.other => ToolPermissionRisk.medium,
  };
}

String _actionLabel(ToolActionKind kind) {
  return switch (kind) {
    ToolActionKind.read => '读取文件',
    ToolActionKind.write => '写入文件',
    ToolActionKind.command => '执行命令',
    ToolActionKind.network => '访问网络',
    ToolActionKind.other => '调用工具',
  };
}

IconData _kindIcon(ToolActionKind kind) {
  return switch (kind) {
    ToolActionKind.read => OperitIcons.visibility_outlined,
    ToolActionKind.write => OperitIcons.edit_outlined,
    ToolActionKind.command => OperitIcons.terminal_rounded,
    ToolActionKind.network => OperitIcons.public_rounded,
    ToolActionKind.other => OperitIcons.smart_toy_outlined,
  };
}

String _consequence(
  ToolActionKind kind,
  ToolPermissionRisk risk,
  bool destructive,
) {
  if (destructive) {
    return '会覆盖或删除已存在的文件，旧版本无法恢复。';
  }
  return switch (kind) {
    ToolActionKind.read => '只读取内容，不会修改或上传其他文件。',
    ToolActionKind.write => '会修改或新建文件，原内容可能被覆盖。',
    ToolActionKind.command => '将在本机执行命令，可能启动进程或改写产物。',
    ToolActionKind.network => '请求会发往外部地址，可能携带对话内容。',
    ToolActionKind.other => '助手将调用该工具完成当前任务。',
  };
}

List<ToolPermissionObject> _collectObjects(
  ToolActionKind kind,
  List<core_proxy.RuntimeHostInteractionToolPermissionToolParameter> parameters,
) {
  final result = <ToolPermissionObject>[];
  for (final parameter in parameters) {
    final key = parameter.name.toLowerCase();
    if (!_objectKeys.any(key.contains)) {
      continue;
    }
    final value = parameter.value.trim();
    if (value.isEmpty) {
      continue;
    }
    result.add(
      ToolPermissionObject(
        icon: _objectIcon(kind, key),
        value: value,
        hint: parameter.name,
      ),
    );
  }
  return result;
}

IconData _objectIcon(ToolActionKind kind, String key) {
  if (key.contains('url') || key.contains('uri')) {
    return OperitIcons.link_rounded;
  }
  if (key.contains('command') ||
      key.contains('cmd') ||
      key.contains('script')) {
    return OperitIcons.terminal_rounded;
  }
  if (key.contains('path') || key.contains('file')) {
    return OperitIcons.insert_drive_file_outlined;
  }
  return _kindIcon(kind);
}

bool _nameHits(String name, List<String> hints) => hints.any(name.contains);

bool _containsAny(String value, List<String> hints) =>
    hints.any((hint) => value.contains(hint));
