class ApiRoutes {
  static String status(String host, int port) => 'http://$host:$port/api/status';
  static String specs(String host, int port) => 'http://$host:$port/api/specs';
  static String stats(String host, int port) => 'http://$host:$port/api/stats';
  static String ws(String host, int port, {String? token}) {
    final base = 'ws://$host:$port/ws';
    if (token != null && token.trim().isNotEmpty) {
      return '$base?token=${Uri.encodeComponent(token.trim())}';
    }
    return base;
  }
}

