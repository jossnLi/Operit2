// ignore_for_file: file_names

/// 记录每次工具调用从「上屏」到「拿到结果」的耗时。
///
/// 消息流本身不携带逐次调用时间戳（整组耗时是靠组标题的 Stopwatch 量的），
/// 所以单行耗时只能在渲染层测：调用节点第一次上屏记 t0，对应 result 节点
/// 第一次上屏记 t1。历史回放时两个节点在同一帧里一起出现，差值接近 0，
/// 视为「未知」——行尾留空，而不是给用户一个假的 0.0s。
class ToolCallTimingRegistry {
  ToolCallTimingRegistry._();

  static final ToolCallTimingRegistry instance = ToolCallTimingRegistry._();

  /// 同一帧内先后上屏会被视为同一次回放，低于该阈值不当作真实耗时。
  static const Duration _sameFrameThreshold = Duration(milliseconds: 16);

  static const int _maxTrackedEntries = 600;

  final Map<String, DateTime> _startedAt = <String, DateTime>{};
  final Map<String, DateTime> _finishedAt = <String, DateTime>{};
  final Map<String, Duration> _elapsed = <String, Duration>{};
  final List<String> _trackedOrder = <String>[];

  /// 有 call_id 就用它；否则用节点自身的 stableKey（同一块在重建时不变）；
  /// 都没有时才退回「渲染实例 + 序号 + 工具名」。
  static String keyFor({
    String? callId,
    String nodeKey = '',
    required String renderInstanceKey,
    required int index,
    required String toolName,
  }) {
    final id = callId?.trim();
    if (id != null && id.isNotEmpty) {
      return 'call:$id';
    }
    if (nodeKey.isNotEmpty) {
      return 'node:$nodeKey|$toolName';
    }
    return 'seq:$renderInstanceKey:$index:$toolName';
  }

  /// 调用节点上屏；只记第一次，后续重建不会重置起点。
  void noteCall(String key) {
    if (_startedAt.containsKey(key)) {
      return;
    }
    _track(key);
    _startedAt[key] = DateTime.now();
  }

  /// result 节点上屏；没有起点或已经结算过就跳过。
  void noteResult(String key) {
    final startedAt = _startedAt[key];
    if (startedAt == null || _finishedAt.containsKey(key)) {
      return;
    }
    final finishedAt = DateTime.now();
    _finishedAt[key] = finishedAt;
    final delta = finishedAt.difference(startedAt);
    if (delta > _sameFrameThreshold) {
      _elapsed[key] = delta;
    }
  }

  DateTime? startedAt(String key) => _startedAt[key];

  Duration? elapsedFor(String key) => _elapsed[key];

  bool hasResult(String key) => _finishedAt.containsKey(key);

  void _track(String key) {
    _trackedOrder.add(key);
    if (_trackedOrder.length <= _maxTrackedEntries) {
      return;
    }
    final evicted = _trackedOrder.removeAt(0);
    _startedAt.remove(evicted);
    _finishedAt.remove(evicted);
    _elapsed.remove(evicted);
  }
}

/// 行尾耗时文案：短的一律保留一位小数，长的收成整数，超过一分钟换成 m/s。
///
/// 目标是在 34dp 的固定列里不换行、不抖动，同时不给用户毫秒级噪声。
String formatToolCallDuration(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds < 100) {
    return '<0.1s';
  }
  if (milliseconds < 10000) {
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  }
  final seconds = duration.inSeconds;
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = duration.inMinutes;
  final restSeconds = seconds % 60;
  return '${minutes}m${restSeconds.toString().padLeft(2, '0')}s';
}
