import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_routes.dart';
import '../constants/app_constants.dart';
import '../../models/system_specs_model.dart';

class MonitorService {
  final http.Client _httpClient = http.Client();

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      headers['X-API-Key'] = token.trim();
    }
    return headers;
  }

  /// Verifica se o daemon está online
  Future<bool> checkHealth(String host, int port, {String? token}) async {
    try {
      final uri = Uri.parse(ApiRoutes.status(host, port));
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(token))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'online';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MonitorService] Erro ao verificar status: $e');
      }
      return false;
    }
  }

  /// Busca especificações completas de hardware (CPU, RAM, Discos, GPU, OS)
  Future<SystemSpecsModel?> fetchSpecs(String host, int port, {String? token}) async {
    try {
      final uri = Uri.parse(ApiRoutes.specs(host, port));
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(token))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SystemSpecsModel.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MonitorService] Erro ao buscar especificações: $e');
      }
      return null;
    }
  }

  /// Conecta ao canal duplex WebSocket para streaming contínuo
  WebSocketChannel connectWebSocket(String host, int port, {String? token}) {
    final wsUrl = ApiRoutes.ws(host, port, token: token);
    if (kDebugMode) {
      debugPrint('[MonitorService] Conectando WebSocket: $wsUrl');
    }
    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  void dispose() {
    _httpClient.close();
  }
}
