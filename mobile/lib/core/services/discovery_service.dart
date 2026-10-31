import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class DiscoveredServer {
  final String hostname;
  final String ipv4;
  final int port;
  final String version;

  const DiscoveredServer({
    required this.hostname,
    required this.ipv4,
    required this.port,
    required this.version,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredServer &&
          runtimeType == other.runtimeType &&
          ipv4 == other.ipv4 &&
          port == other.port;

  @override
  int get hashCode => ipv4.hashCode ^ port.hashCode;
}

class DiscoveryService {
  final http.Client _client = http.Client();

  /// Obtém o endereço IPv4 local do próprio dispositivo móvel
  Future<String?> getLocalDeviceIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DiscoveryService] Erro ao obter IPv4 local: $e');
      }
    }
    return null;
  }

  /// Descobre o servidor na rede local via UDP Broadcast IPv4 (ultra-rápido)
  Future<DiscoveredServer?> discoverViaUdpBroadcast({
    int port = AppConstants.defaultPort,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final completer = Completer<DiscoveredServer?>();

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            try {
              final text = utf8.decode(datagram.data);
              final json = jsonDecode(text);

              if (json['service'] == 'cjc-system-monitor' || json['name'] == 'CJC System Monitor') {
                final server = DiscoveredServer(
                  hostname: json['hostname'] ?? 'Meu-PC',
                  ipv4: json['ipv4'] ?? datagram.address.address,
                  port: json['port'] ?? port,
                  version: json['version'] ?? '1.0.0',
                );

                if (!completer.isCompleted) {
                  completer.complete(server);
                }
              }
            } catch (_) {}
          }
        }
      });

      // Envia requisição de discovery em broadcast
      final query = utf8.encode('DISCOVER_CJC_MONITOR');
      socket.send(query, InternetAddress('255.255.255.255'), port);

      return await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DiscoveryService] Erro no broadcast UDP: $e');
      }
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Escaneia ativamente a sub-rede IPv4 (ex: 192.168.3.X) na porta do monitor
  Future<DiscoveredServer?> scanSubnetForServer({
    int port = AppConstants.defaultPort,
    String? preferredHost,
  }) async {
    // 1. Testa primeiro o host preferencial (ex: 192.168.3.170)
    if (preferredHost != null && preferredHost.isNotEmpty) {
      final quickCheck = await checkIpv4Host(preferredHost, port);
      if (quickCheck != null) return quickCheck;
    }

    final localIp = await getLocalDeviceIpv4();
    if (localIp == null || !localIp.contains('.')) return null;

    final parts = localIp.split('.');
    final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

    // Prioriza IPs comuns: .170 (Meu-PC), .1, .100, .101, .150, .200
    final priorityLastOctets = [170, 1, 100, 101, 102, 105, 110, 150, 200];
    for (final octet in priorityLastOctets) {
      final ip = '$subnetPrefix$octet';
      if (ip == localIp) continue;
      final server = await checkIpv4Host(ip, port);
      if (server != null) return server;
    }

    // Escaneamento em lotes paralelos dos demais endereços (1 a 254)
    final candidates = <String>[];
    for (int i = 1; i <= 254; i++) {
      if (priorityLastOctets.contains(i)) continue;
      final ip = '$subnetPrefix$i';
      if (ip != localIp) candidates.add(ip);
    }

    const batchSize = 25;
    for (int i = 0; i < candidates.length; i += batchSize) {
      final end = (i + batchSize < candidates.length) ? i + batchSize : candidates.length;
      final batch = candidates.sublist(i, end);

      final futures = batch.map((ip) => checkIpv4Host(ip, port));
      final results = await Future.wait(futures);

      for (final res in results) {
        if (res != null) return res;
      }
    }

    return null;
  }

  /// Verifica se um determinado IPv4 está rodando o servidor monitor
  Future<DiscoveredServer?> checkIpv4Host(String host, int port) async {
    try {
      final uri = Uri.parse('http://$host:$port/api/status');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 700));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'online') {
          return DiscoveredServer(
            hostname: data['hostname'] ?? host,
            ipv4: data['ipv4'] ?? host,
            port: data['port'] ?? port,
            version: data['version'] ?? '1.0.0',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _client.close();
  }
}

