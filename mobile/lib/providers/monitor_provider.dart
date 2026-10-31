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
    notifyListeners();

    // Salva configuração isolada do servidor
    await _storage.saveServerConfig(
      prefix: server.id,
      host: server.host,
      port: server.port,
      token: server.token,
    );

    // Busca especificações estáticas
    try {
      server.specs = await _service.fetchSpecs(server.host, server.port, token: server.token);
    } catch (_) {}

    // Conecta ao WebSocket
    try {
      server.wsChannel = _service.connectWebSocket(server.host, server.port, token: server.token);
      server.wsSubscription = server.wsChannel!.stream.listen(
        (rawData) => _onMessageReceived(server, rawData),
        onError: (err) => _onWebSocketError(server, err),
        onDone: () => _onWebSocketDone(server),
        cancelOnError: false,
      );

      server.isConnecting = false;
      server.status = ConnectionStatus.connected;
      notifyListeners();
    } catch (e) {
      server.isConnecting = false;
      server.errorMessage = 'Falha ao conectar: $e';
      server.status = ConnectionStatus.error;
      notifyListeners();
      _scheduleReconnect(server);
    }
  }

  void _onMessageReceived(ServerConnectionState server, dynamic rawData) {
    try {
      if (rawData is String && rawData == 'pong') return;

      final Map<String, dynamic> json = jsonDecode(rawData as String);
      final stats = SystemStatsModel.fromJson(json);

      server.currentStats = stats;
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
    server.status = ConnectionStatus.error;
    server.errorMessage = 'Conexão interrompida com ${server.displayName}';
    notifyListeners();
    _scheduleReconnect(server);
  }

  void _onWebSocketDone(ServerConnectionState server) {
    if (!server.manualDisconnect) {
      server.status = ConnectionStatus.reconnecting;
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
    devPc.closeWebSocket();
    ubuntuServer.closeWebSocket();
    super.dispose();
  }
}
