class AppConstants {
  static const String appName = 'CJC System Monitor';

  // Configurações PC Desenvolvimento (Windows)
  static const String defaultDevHost = '192.168.3.170';
  static const int defaultDevPort = 4080;

  // Configurações Servidor de Produção (Ubuntu Server 24.04 LTS)
  static const String defaultUbuntuHost = '192.168.3.177';
  static const int defaultUbuntuPort = 4080;

  // Compatibilidade com chaves genéricas
  static const String defaultHost = defaultDevHost;
  static const int defaultPort = defaultDevPort;

  // Chaves de armazenamento
  static const String keyDevHost = 'cjc_dev_host';
  static const String keyDevPort = 'cjc_dev_port';
  static const String keyDevToken = 'cjc_dev_token';

  static const String keyUbuntuHost = 'cjc_ubuntu_host';
  static const String keyUbuntuPort = 'cjc_ubuntu_port';
  static const String keyUbuntuToken = 'cjc_ubuntu_token';

  static const String keyAutoCycle = 'cjc_auto_cycle_enabled';
  static const String keyAutoCycleInterval = 'cjc_auto_cycle_interval';

  // Legado
  static const String keyHost = keyDevHost;
  static const String keyPort = keyDevPort;
  static const String keyToken = keyDevToken;

  // Telemetria e Conexão
  static const int maxHistoryPoints = 40;
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration autoCycleDefaultDuration = Duration(seconds: 12);
}
