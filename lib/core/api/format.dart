/// Formatting helpers for Jellyfin tick values and durations.
/// 1 second = 10,000,000 ticks.
library;

Duration ticksToDuration(int? ticks) =>
    Duration(microseconds: ((ticks ?? 0) / 10).round());

int durationToTicks(Duration d) => d.inMicroseconds * 10;

String formatRuntime(int? ticks) {
  final d = ticksToDuration(ticks);
  if (d <= Duration.zero) return '';
  final minutes = d.inMinutes;
  if (minutes < 60) return '${minutes}m';
  return '${d.inHours}h ${minutes % 60}m';
}

String formatDuration(Duration d) {
  final neg = d.isNegative;
  d = d.abs();
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final out = h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
  return neg ? '-$out' : out;
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final str = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$str ${units[unit]}';
}
