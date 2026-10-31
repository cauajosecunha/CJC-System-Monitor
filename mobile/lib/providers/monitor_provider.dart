import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/app_constants.dart';
import '../core/services/discovery_service.dart';
import '../core/services/monitor_service.dart';
import '../core/services/storage_service.dart';
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

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _host = AppConstants.defaultHost;
  int _port = AppConstants.defaultPort;
  String? _token;
  String? _errorMessage;

  String? _clientIpv4;
  bool _isDiscovering = false;

  SystemStatsModel? _currentStats;
  SystemSpecsModel? _specs;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;

  // Buffers de histórico para gráficos em tempo real (últimos 40 pontos)
  final List<FlSpot> _cpuHistory = [];
  final List<FlSpot> _ramHistory = [];
  final List<FlSpot> _downloadHistory = []; // KB/s
  final List<FlSpot> _uploadHistory = []; // KB/s
  double _timeIndex = 0;

  // Getters
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isConnecting =>
      _status == ConnectionStatus.connecting ||
      _status == ConnectionStatus.reconnecting;
  bool get isDiscovering => _isDiscovering;
  String get host => _host;
  int get port => _port;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  String? get clientIpv4 => _clientIpv4;
  SystemStatsModel? get currentStats => _currentStats;
  SystemSpecsModel? get specs => _specs;

  List<FlSpot> get cpuHistory => List.unmodifiable(_cpuHistory);
  List<FlSpot> get ramHistory => List.unmodifiable(_ramHistory);
  List<FlSpot> get downloadHistory => List.unmodifiable(_downloadHistory);
  List<FlSpot> get uploadHistory => List.unmodifiable(_uploadHistory);

  MonitorProvider() {
    _initFromStorage();
  }

  Future<void> _initFromStorage() async {
    _clientIpv4 = await _discovery.getLocalDeviceIpv4();

    final savedHost = await _storage.getHost();
    final savedPort = await _storage.getPort();
    final savedToken = await _storage.getToken();

    if (savedHost != null && savedHost.isNotEmpty) {
      _host = savedHost;
    }
    _port = savedPort;
    _token = savedToken;
    notifyListeners();
  }

  /// Descobre automaticamente o servidor IPv4 na LAN e conecta
  Future<bool> autoDiscoverIpv4() async {
    _isDiscovering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clientIpv4 = await _discovery.getLocalDeviceIpv4();

      // 1. Tenta descoberta rápida via UDP Broadcast
      DiscoveredServer? found = await _discovery.discoverViaUdpBroadcast(port: _port);

      // 2. Se não respondeu por UDP (firewall/roteador), faz varredura na sub-rede IPv4
      found ??= await _discovery.scanSubnetForServer(port: _port, preferredHost: _host);

      if (found != null) {
        _host = found.ipv4;
        _port = found.port;
        _isDiscovering = false;
        notifyListeners();

        await connect(_host, _port, targetToken: _token);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MonitorProvider] Erro no auto-discovery IPv4: $e');
      }
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }

    return false;
  }

  /// Testa a conectividade HTTP REST sem abrir WebSocket
  Future<bool> testConnection(String targetHost, int targetPort, {String? targetToken}) async {
    return await _service.checkHealth(targetHost, targetPort, token: targetToken);
  }

  /// Conecta ao servidor e inicia streaming WebSocket
  Future<void> connect(String targetHost, int targetPort, {String? targetToken}) async {
    _manualDisconnect = false;
    _cancelReconnectTimer();
    _closeWebSocket();

    _host = targetHost.trim();
    _port = targetPort;
    _token = targetToken?.trim();
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    // Salva configuração segura no dispositivo
    await _storage.saveConnectionConfig(host: _host, port: _port, token: _token);

    // Atualiza o IPv4 local da interface
    _clientIpv4 = await _discovery.getLocalDeviceIpv4();

    // 1. Carrega especificações estáticas do hardware
    _specs = await _service.fetchSpecs(_host, _port, token: _token);

    // 2. Estabelece canal WebSocket
    try {
      _wsChannel = _service.connectWebSocket(_host, _port, token: _token);
      _wsSubscription = _wsChannel!.stream.listen(
        _onMessageReceived,
        onError: _onWebSocketError,
        onDone: _onWebSocketDone,
        cancelOnError: false,
      );

      _status = ConnectionStatus.connected;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha ao estabelecer conexão WebSocket: $e';
      _status = ConnectionStatus.error;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _onMessageReceived(dynamic rawData) {
    try {
      if (rawData is String && rawData == 'pong') return;

      final Map<String, dynamic> json = jsonDecode(rawData as String);
      final stats = SystemStatsModel.fromJson(json);

      _currentStats = stats;
      _status = ConnectionStatus.connected;
      _errorMessage = null;

      // Atualiza buffers deslizantes de histórico para gráficos
      _timeIndex += 1;

      _addPoint(_cpuHistory, _timeIndex, stats.cpu.usage);
      _addPoint(_ramHistory, _timeIndex, stats.memory.usagePercent);

      // Converte bytes/sec para KB/sec para legibilidade gráfica
      final dlKb = (stats.network.rxSec / 1024.0);
      final ulKb = (stats.network.txSec / 1024.0);
      _addPoint(_downloadHistory, _timeIndex, dlKb);
      _addPoint(_uploadHistory, _timeIndex, ulKb);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MonitorProvider] Erro ao decodificar telemetria: $e');
      }
    }
  }

  void _addPoint(List<FlSpot> list, double x, double y) {
    list.add(FlSpot(x, y));
    if (list.length > AppConstants.maxHistoryPoints) {
      list.removeAt(0);
    }
  }

  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      debugPrint('[MonitorProvider] Erro no canal WebSocket: $error');
    }
    _status = ConnectionStatus.error;
    _errorMessage = 'Conexão interrompida';
    notifyListeners();
    _scheduleReconnect();
  }

  void _onWebSocketDone() {
    if (!_manualDisconnect) {
      _status = ConnectionStatus.reconnecting;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    _cancelReconnectTimer();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!_manualDisconnect && _status != ConnectionStatus.connected) {
        connect(_host, _port, targetToken: _token);
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _closeWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  /// Desconecta intencionalmente e limpa os estados em memória
  void disconnect() {
    _manualDisconnect = true;
    _cancelReconnectTimer();
    _closeWebSocket();
    _status = ConnectionStatus.disconnected;
    _currentStats = null;
    _cpuHistory.clear();
    _ramHistory.clear();
    _downloadHistory.clear();
    _uploadHistory.clear();
    _timeIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _service.dispose();
    _discovery.dispose();
    super.dispose();
  }
}
