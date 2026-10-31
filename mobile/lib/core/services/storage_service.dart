import 'dart:convert';
import 'dart:io';
import '../constants/app_constants.dart';

class StorageService {
  File _getFile() {
    if (Platform.isAndroid) {
      return File('/data/data/com.cjcdev.systemmonitor/app_config.json');
    }
    final home = Platform.environment['APPDATA'] ?? Platform.environment['HOME'] ?? '.';
    return File('$home/.cjc_system_monitor_config.json');
  }

  Future<Map<String, dynamic>> _readConfig() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeConfig(Map<String, dynamic> data) async {
    try {
      final file = _getFile();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> saveServerConfig({
    required String prefix, // 'dev' ou 'ubuntu'
    required String host,
    required int port,
    String? token,
  }) async {
    final current = await _readConfig();
    current['${prefix}_host'] = host.trim();
    current['${prefix}_port'] = port;
    if (token != null && token.trim().isNotEmpty) {
      current['${prefix}_token'] = token.trim();
    } else {
      current.remove('${prefix}_token');
    }
    await _writeConfig(current);
  }

  Future<String?> getServerHost(String prefix, {String? defaultVal}) async {
    final current = await _readConfig();
    return (current['${prefix}_host'] as String?) ?? defaultVal;
  }

  Future<int> getServerPort(String prefix, {int defaultVal = AppConstants.defaultPort}) async {
    final current = await _readConfig();
    return (current['${prefix}_port'] as num?)?.toInt() ?? defaultVal;
  }

  Future<String?> getServerToken(String prefix) async {
    final current = await _readConfig();
    return current['${prefix}_token'] as String?;
  }

  Future<bool> getAutoCycleEnabled() async {
    final current = await _readConfig();
    return (current[AppConstants.keyAutoCycle] as bool?) ?? false;
  }

  Future<void> setAutoCycleEnabled(bool enabled) async {
    final current = await _readConfig();
    current[AppConstants.keyAutoCycle] = enabled;
    await _writeConfig(current);
  }

  // Compatibilidade com métodos legados
  Future<void> saveConnectionConfig({
    required String host,
    required int port,
    String? token,
  }) async {
    await saveServerConfig(prefix: 'dev', host: host, port: port, token: token);
  }

  Future<String?> getHost() async => getServerHost('dev', defaultVal: AppConstants.defaultDevHost);
  Future<int> getPort() async => getServerPort('dev', defaultVal: AppConstants.defaultDevPort);
  Future<String?> getToken() async => getServerToken('dev');

  Future<void> clearAll() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
