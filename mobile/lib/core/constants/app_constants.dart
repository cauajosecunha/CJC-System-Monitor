class AppConstants {
  static const String appName = 'CJC System Monitor';
  static const int defaultPort = 4080;
  static const String defaultHost = '192.168.3.170';

  // Chaves para o Secure Storage
  static const String keyHost = 'cjc_monitor_host';
  static const String keyPort = 'cjc_monitor_port';
  static const String keyToken = 'cjc_monitor_token';
  static const String keyAutoConnect = 'cjc_monitor_auto_connect';

  // Configurações de Telemetria
  static const int maxHistoryPoints = 40; // Pontos no gráfico de linha deslizante
  static const Duration requestTimeout = Duration(seconds: 5);
}

