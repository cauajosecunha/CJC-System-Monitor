import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/app_constants.dart';
import '../providers/monitor_provider.dart';
import 'system_specs_model.dart';
import 'system_stats_model.dart';

class ServerConnectionState {
  final String id;
  final String defaultName;
  final String osIcon; // 'windows' | 'linux'

  String host;
  int port;
  String? token;

  ConnectionStatus status = ConnectionStatus.disconnected;
  String? errorMessage;
  bool isConnecting = false;
  bool isDiscovering = false;
  bool manualDisconnect = false;

  SystemStatsModel? currentStats;
  SystemSpecsModel? specs;

  WebSocketChannel? wsChannel;
  StreamSubscription? wsSubscription;
  Timer? reconnectTimer;

  // Buffers de histórico para gráficos em tempo real
  final List<FlSpot> cpuHistory = [];
  final List<FlSpot> ramHistory = [];
  final List<FlSpot> downloadHistory = [];
  final List<FlSpot> uploadHistory = [];
  double timeIndex = 0;

  ServerConnectionState({
    required this.id,
    required this.defaultName,
    required this.osIcon,
    required this.host,
    required this.port,
    this.token,
  });

  String get displayName => currentStats?.hostname.isNotEmpty == true
      ? currentStats!.hostname
      : defaultName;

  bool get isConnected => status == ConnectionStatus.connected;

  void addHistoryPoint(double cpu, double ram, double dlKb, double ulKb) {
    timeIndex += 1;
    _addPoint(cpuHistory, timeIndex, cpu);
    _addPoint(ramHistory, timeIndex, ram);
    _addPoint(downloadHistory, timeIndex, dlKb);
    _addPoint(uploadHistory, timeIndex, ulKb);
  }

  void _addPoint(List<FlSpot> list, double x, double y) {
    list.add(FlSpot(x, y));
    if (list.length > AppConstants.maxHistoryPoints) {
      list.removeAt(0);
    }
  }

  void resetHistories() {
    cpuHistory.clear();
    ramHistory.clear();
    downloadHistory.clear();
    uploadHistory.clear();
    timeIndex = 0;
  }

  void closeWebSocket() {
    reconnectTimer?.cancel();
    reconnectTimer = null;
    wsSubscription?.cancel();
    wsSubscription = null;
    wsChannel?.sink.close();
    wsChannel = null;
  }
}

