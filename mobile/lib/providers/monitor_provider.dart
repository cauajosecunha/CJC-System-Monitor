import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/services/discovery_service.dart';
import '../core/services/monitor_service.dart';
import '../core/services/storage_service.dart';
import '../models/server_connection_state.dart';
import '../models/system_specs_model.dart';
import '../models/system_stats_model.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class MonitorProvider extends ChangeNotifier {
  final MonitorService _service = MonitorService();
  final StorageService _storage = StorageService();
  final DiscoveryService _discovery = DiscoveryService();

  late final ServerConnectionState devPc;
  late final ServerConnectionState ubuntuServer;

  int _selectedScreenIndex = 0; // 0 = Dev PC, 1 = Ubuntu Server
  bool _autoCycle = false;
  Timer? _autoCycleTimer;
  Timer? _watchdogTimer;
  String? _clientIpv4;

  void Function(int index)? onPageChangeRequested;

  ServerConnectionState get selectedServer =>
      _selectedScreenIndex == 0 ? devPc : ubuntuServer;

  int get selectedScreenIndex => _selectedScreenIndex;
  bool get autoCycle => _autoCycle;
  String? get clientIpv4 => _clientIpv4;

  // Getters delegados para compatibilidade reversa
  ConnectionStatus get status => selectedServer.status;
  bool get isConnected => selectedServer.isConnected;
  bool get isConnecting => selectedServer.isConnecting;
  bool get isDiscovering => selectedServer.isDiscovering;
  String get host => selectedServer.host;
  int get port => selectedServer.port;
  String? get token => selectedServer.token;
  String? get errorMessage => selectedServer.errorMessage;
  SystemStatsModel? get currentStats => selectedServer.currentStats;
  SystemSpecsModel? get specs => selectedServer.specs;
  List<FlSpot> get cpuHistory => List.unmodifiable(selectedServer.cpuHistory);
  List<FlSpot> get ramHistory => List.unmodifiable(selectedServer.ramHistory);
  List<FlSpot> get downloadHistory => List.unmodifiable(selectedServer.downloadHistory);
  List<FlSpot> get uploadHistory => List.unmodifiable(selectedServer.uploadHistory);

  MonitorProvider() {
    devPc = ServerConnectionState(
      id: 'dev',
      defaultName: 'Meu-PC (Dev)',
      osIcon: 'windows',
      host: AppConstants.defaultDevHost,
      port: AppConstants.defaultDevPort,
    );

    ubuntuServer = ServerConnectionState(
      id: 'ubuntu',
      defaultName: 'Ubuntu Server 24.04',
      osIcon: 'linux',
      host: AppConstants.defaultUbuntuHost,
      port: AppConstants.defaultUbuntuPort,
    );

    _bootstrap();
    _startWatchdogTimer();
  }

  Future<void> _bootstrap() async {
    _clientIpv4 = await _discovery.getLocalDeviceIpv4();

    // Carrega configurações persistidas de ambos os servidores
    final savedDevHost = await _storage.getServerHost('dev', defaultVal: AppConstants.defaultDevHost);
    final savedDevPort = await _storage.getServerPort('dev', defaultVal: AppConstants.defaultDevPort);
    final savedDevToken = await _storage.getServerToken('dev');

    final savedUbuntuHost = await _storage.getServerHost('ubuntu', defaultVal: AppConstants.defaultUbuntuHost);
    final savedUbuntuPort = await _storage.getServerPort('ubuntu', defaultVal: AppConstants.defaultUbuntuPort);
    final savedUbuntuToken = await _storage.getServerToken('ubuntu');

    if (savedDevHost != null && savedDevHost.isNotEmpty) devPc.host = savedDevHost;
    devPc.port = savedDevPort;
    devPc.token = savedDevToken;

    if (savedUbuntuHost != null && savedUbuntuHost.isNotEmpty) ubuntuServer.host = savedUbuntuHost;
    ubuntuServer.port = savedUbuntuPort;
    ubuntuServer.token = savedUbuntuToken;

    _autoCycle = await _storage.getAutoCycleEnabled();
    if (_autoCycle) {
      _startAutoCycleTimer();
    }

    notifyListeners();

    // Conecta aos dois servidores em paralelo
    connectServer(devPc);
    connectServer(ubuntuServer);
  }

  void setSelectedScreenIndex(int index) {
    if (_selectedScreenIndex != index && (index == 0 || index == 1)) {
      _selectedScreenIndex = index;
      notifyListeners();
    }
  }

  void switchToScreen(int index) {
    setSelectedScreenIndex(index);
    onPageChangeRequested?.call(index);
  }

  void toggleAutoCycle() {
    _autoCycle = !_autoCycle;
    _storage.setAutoCycleEnabled(_autoCycle);
    if (_autoCycle) {
      _startAutoCycleTimer();
    } else {
      _autoCycleTimer?.cancel();
      _autoCycleTimer = null;
    }
    notifyListeners();
  }

  void _startAutoCycleTimer() {
    _autoCycleTimer?.cancel();
    _autoCycleTimer = Timer.periodic(AppConstants.autoCycleDefaultDuration, (_) {
      final nextIndex = (_selectedScreenIndex == 0) ? 1 : 0;
      switchToScreen(nextIndex);
    });
  }

  /// Watchdog ativo a cada 1s: detecta congelamento ou desligamento abrupto do servidor
  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkServerWatchdog(devPc);
      _checkServerWatchdog(ubuntuServer);
    });
  }

  void _checkServerWatchdog(ServerConnectionState server) {
    if (server.manualDisconnect) return;

    final now = DateTime.now();

    // Se estiver no estado 'connecting', mas passaram mais de 7s sem resposta, trata como timeout
    if (server.isConnecting || server.status == ConnectionStatus.connecting) {
      if (server.connectStartTime != null &&
          now.difference(server.connectStartTime!).inSeconds >= 7) {
        if (kDebugMode) {
          debugPrint('[Watchdog] Servidor ${server.displayName} timeout ao conectar (7s). Marcando erro.');
        }
        server.closeWebSocket();
        server.isConnecting = false;
        server.status = ConnectionStatus.error;
        server.errorMessage = 'Tempo limite de conexão esgotado';
        server.currentStats = null;
        notifyListeners();
        _scheduleReconnect(server);
      }
      return;
    }

    // Se marcado como conectado, mas o último dado recebido foi há mais de 5 segundos
    if (server.isConnected) {
      if (server.lastMessageTime != null &&
          now.difference(server.lastMessageTime!).inSeconds >= 5) {
        if (kDebugMode) {
          debugPrint('[Watchdog] Servidor ${server.displayName} inativo há 5s. Marcando OFFLINE.');
        }
        server.closeWebSocket();
        server.isConnecting = false;
        server.status = ConnectionStatus.error;
        server.errorMessage = 'Sem telemetria do servidor (Timeout)';
        server.currentStats = null;
        notifyListeners();
        _scheduleReconnect(server);
      }
    }
  }

  Future<void> connectServer(
    ServerConnectionState server, {
    String? targetHost,
    int? targetPort,
    String? targetToken,
  }) async {
    server.manualDisconnect = false;
    server.reconnectTimer?.cancel();
    server.reconnectTimer = null;
    server.closeWebSocket();

    if (targetHost != null) server.host = targetHost.trim();
    if (targetPort != null) server.port = targetPort;
    if (targetToken != null) server.token = targetToken.trim().isEmpty ? null : targetToken.trim();

    server.status = ConnectionStatus.connecting;
    server.errorMessage = null;
    server.isConnecting = true;
    server.connectStartTime = DateTime.now();
    server.lastMessageTime = null;
    notifyListeners();

    // Salva configuração isolada do servidor
    await _storage.saveServerConfig(
      prefix: server.id,
      host: server.host,
      port: server.port,
      token: server.token,
    );

    // Busca especificações estáticas em segundo plano para não bloquear a conexão WebSocket
    _service.fetchSpecs(server.host, server.port, token: server.token).then((specs) {
      if (specs != null) {
        server.specs = specs;
        notifyListeners();
      }
    }).catchError((_) {});

    // Conecta ao WebSocket imediatamente
    try {
      server.wsChannel = _service.connectWebSocket(server.host, server.port, token: server.token);
      server.wsSubscription = server.wsChannel!.stream.listen(
        (rawData) => _onMessageReceived(server, rawData),
        onError: (err) => _onWebSocketError(server, err),
        onDone: () => _onWebSocketDone(server),
        cancelOnError: false,
      );
      // Mantém o status como 'connecting' até a chegada do 1º pacote de telemetria em _onMessageReceived
    } catch (e) {
      server.isConnecting = false;
      server.errorMessage = 'Falha ao conectar: $e';
      server.status = ConnectionStatus.error;
      server.currentStats = null;
      notifyListeners();
      _scheduleReconnect(server);
    }
  }

  void _onMessageReceived(ServerConnectionState server, dynamic rawData) {
    try {
      if (rawData is String && rawData == 'pong') return;

      final Map<String, dynamic> json = jsonDecode(rawData as String);
      final stats = SystemStatsModel.fromJson(json);

      server.connectStartTime = null;
      server.lastMessageTime = DateTime.now();
      server.currentStats = stats;
      server.isConnecting = false;
      server.status = ConnectionStatus.connected;
      server.errorMessage = null;

      final dlKb = (stats.network.rxSec / 1024.0);
      final ulKb = (stats.network.txSec / 1024.0);
      server.addHistoryPoint(stats.cpu.usage, stats.memory.usagePercent, dlKb, ulKb);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MonitorProvider] Erro ao decodificar telemetria (${server.id}): $e');
      }
    }
  }

  void _onWebSocketError(ServerConnectionState server, dynamic error) {
    if (kDebugMode) {
      debugPrint('[MonitorProvider] WebSocket error (${server.id}): $error');
    }
    server.closeWebSocket();
    server.isConnecting = false;
    server.status = ConnectionStatus.error;
    server.currentStats = null;
    server.errorMessage = 'Conexão interrompida com ${server.displayName}';
    notifyListeners();
    _scheduleReconnect(server);
  }

  void _onWebSocketDone(ServerConnectionState server) {
    if (kDebugMode) {
      debugPrint('[MonitorProvider] WebSocket encerrado (${server.id})');
    }
    if (!server.manualDisconnect) {
      server.closeWebSocket();
      server.isConnecting = false;
      server.status = ConnectionStatus.reconnecting;
      server.currentStats = null;
      server.errorMessage = 'Conexão encerrada pelo servidor';
      notifyListeners();
      _scheduleReconnect(server);
    }
  }

  void _scheduleReconnect(ServerConnectionState server) {
    if (server.manualDisconnect) return;
    server.reconnectTimer?.cancel();
    server.reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!server.isConnected && !server.manualDisconnect) {
        connectServer(server);
      }
    });
  }

  Future<void> disconnectServer(ServerConnectionState server) async {
    server.manualDisconnect = true;
    server.closeWebSocket();
    server.status = ConnectionStatus.disconnected;
    server.currentStats = null;
    notifyListeners();
  }

  Future<bool> autoDiscoverServer(ServerConnectionState server) async {
    server.isDiscovering = true;
    notifyListeners();

    try {
      DiscoveredServer? found = await _discovery.discoverViaUdpBroadcast(port: server.port);
      found ??= await _discovery.scanSubnetForServer(port: server.port, preferredHost: server.host);

      if (found != null) {
        server.host = found.ipv4;
        server.port = found.port;
        server.isDiscovering = false;
        notifyListeners();
        await connectServer(server);
        return true;
      }
    } catch (_) {}

    server.isDiscovering = false;
    notifyListeners();
    return false;
  }

  // Compatibilidade legada
  Future<bool> testConnection(String targetHost, int targetPort, {String? targetToken}) async {
    return await _service.checkHealth(targetHost, targetPort, token: targetToken);
  }

  Future<void> connect(String targetHost, int targetPort, {String? targetToken}) async {
    await connectServer(selectedServer, targetHost: targetHost, targetPort: targetPort, targetToken: targetToken);
  }

  Future<bool> autoDiscoverIpv4() async {
    return await autoDiscoverServer(selectedServer);
  }

  @override
  void dispose() {
    _autoCycleTimer?.cancel();
    _watchdogTimer?.cancel();
    devPc.closeWebSocket();
    ubuntuServer.closeWebSocket();
    super.dispose();
  }
}
