class FormatUtils {
  /// Formata bytes para B, KB, MB, GB, TB
  static String formatBytes(num? bytes, {int decimals = 1}) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Formata taxa de transferência de rede por segundo (ex: 2.4 MB/s)
  static String formatSpeed(num? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec <= 0) return '0 KB/s';
    return '${formatBytes(bytesPerSec)}/s';
  }

  /// Formata segundos de uptime em formato legível (ex: "2d 4h 12m" ou "3h 45m")
  static String formatUptime(int? seconds) {
    if (seconds == null || seconds <= 0) return '0s';
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    final parts = <String>[];
    if (d > 0) parts.add('${d}d');
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (parts.isEmpty) parts.add('${s}s');

    return parts.join(' ');
  }

  /// Formata porcentagem com 1 casa decimal
  static String formatPercent(num? value) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(1)}%';
  }
}

