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

  Future<void> saveConnectionConfig({
    required String host,
    required int port,
    String? token,
  }) async {
    try {
      final file = _getFile();
      final data = {
        AppConstants.keyHost: host.trim(),
        AppConstants.keyPort: port,
        if (token != null && token.trim().isNotEmpty)
          AppConstants.keyToken: token.trim(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<String?> getHost() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return json[AppConstants.keyHost] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<int> getPort() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return (json[AppConstants.keyPort] as num?)?.toInt() ?? AppConstants.defaultPort;
      }
    } catch (_) {}
    return AppConstants.defaultPort;
  }

  Future<String?> getToken() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return json[AppConstants.keyToken] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
