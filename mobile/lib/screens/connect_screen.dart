import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/server_connection_state.dart';
import '../providers/monitor_provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late TextEditingController _devHostController;
  late TextEditingController _devPortController;
  late TextEditingController _devTokenController;

  late TextEditingController _ubuntuHostController;
  late TextEditingController _ubuntuPortController;
  late TextEditingController _ubuntuTokenController;

  bool _isTestingDev = false;
  String? _testResultDev;
  bool _testSuccessDev = false;

  bool _isTestingUbuntu = false;
  String? _testResultUbuntu;
  bool _testSuccessUbuntu = false;

  bool _autoCycle = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MonitorProvider>();

    _devHostController = TextEditingController(text: provider.devPc.host);
    _devPortController = TextEditingController(text: provider.devPc.port.toString());
    _devTokenController = TextEditingController(text: provider.devPc.token ?? '');

    _ubuntuHostController = TextEditingController(text: provider.ubuntuServer.host);
    _ubuntuPortController = TextEditingController(text: provider.ubuntuServer.port.toString());
    _ubuntuTokenController = TextEditingController(text: provider.ubuntuServer.token ?? '');

    _autoCycle = provider.autoCycle;
  }

  @override
  void dispose() {
    _devHostController.dispose();
    _devPortController.dispose();
    _devTokenController.dispose();
    _ubuntuHostController.dispose();
    _ubuntuPortController.dispose();
    _ubuntuTokenController.dispose();
    super.dispose();
  }

  Future<void> _testServer(bool isDev) async {
    setState(() {
      if (isDev) {
        _isTestingDev = true;
        _testResultDev = null;
      } else {
        _isTestingUbuntu = true;
        _testResultUbuntu = null;
      }
    });

    final host = (isDev ? _devHostController : _ubuntuHostController).text.trim();
    final port = int.tryParse((isDev ? _devPortController : _ubuntuPortController).text.trim()) ?? AppConstants.defaultPort;
    final token = (isDev ? _devTokenController : _ubuntuTokenController).text.trim().isEmpty
        ? null
        : (isDev ? _devTokenController : _ubuntuTokenController).text.trim();

    final provider = context.read<MonitorProvider>();
    final ok = await provider.testConnection(host, port, targetToken: token);

    setState(() {
      if (isDev) {
        _isTestingDev = false;
        _testSuccessDev = ok;
        _testResultDev = ok ? 'Online ($host:$port)' : 'Falha na conexão ($host:$port)';
      } else {
        _isTestingUbuntu = false;
        _testSuccessUbuntu = ok;
        _testResultUbuntu = ok ? 'Online ($host:$port)' : 'Falha na conexão ($host:$port)';
      }
    });
  }

  void _saveAndConnectAll() {
    final provider = context.read<MonitorProvider>();

    final devHost = _devHostController.text.trim();
    final devPort = int.tryParse(_devPortController.text.trim()) ?? AppConstants.defaultDevPort;
    final devToken = _devTokenController.text.trim().isEmpty ? null : _devTokenController.text.trim();

    final ubuntuHost = _ubuntuHostController.text.trim();
    final ubuntuPort = int.tryParse(_ubuntuPortController.text.trim()) ?? AppConstants.defaultUbuntuPort;
    final ubuntuToken = _ubuntuTokenController.text.trim().isEmpty ? null : _ubuntuTokenController.text.trim();

    if (_autoCycle != provider.autoCycle) {
      provider.toggleAutoCycle();
    }

    provider.connectServer(provider.devPc, targetHost: devHost, targetPort: devPort, targetToken: devToken);
    provider.connectServer(provider.ubuntuServer, targetHost: ubuntuHost, targetPort: ubuntuPort, targetToken: ubuntuToken);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitorProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configuração de Monitoramento Duplo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.accentGreen),
            tooltip: 'Salvar e Conectar',
            onPressed: _saveAndConnectAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row com os dois servidores lado a lado no layout landscape
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PC DESENVOLVIMENTO
                Expanded(
                  child: _buildServerCard(
                    title: '💻 PC Desenvolvimento (Win 11)',
                    server: provider.devPc,
                    hostController: _devHostController,
                    portController: _devPortController,
                    tokenController: _devTokenController,
                    isTesting: _isTestingDev,
                    testSuccess: _testSuccessDev,
                    testResult: _testResultDev,
                    onTest: () => _testServer(true),
                    accentColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                // 2. UBUNTU SERVER 24.04 LTS
                Expanded(
                  child: _buildServerCard(
                    title: '🐧 Ubuntu Server 24.04 LTS',
                    server: provider.ubuntuServer,
                    hostController: _ubuntuHostController,
                    portController: _ubuntuPortController,
                    tokenController: _ubuntuTokenController,
                    isTesting: _isTestingUbuntu,
                    testSuccess: _testSuccessUbuntu,
                    testResult: _testResultUbuntu,
                    onTest: () => _testServer(false),
                    accentColor: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Opções Globais e Auto-Cycle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 0.6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.autorenew, color: AppTheme.accentYellow, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alternância Automática (Auto-Cycle)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Alterna entre as 2 telas a cada 12 segundos (ideal para display contínuo)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoCycle,
                    activeThumbColor: AppTheme.accentGreen,
                    onChanged: (val) {
                      setState(() {
                        _autoCycle = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _saveAndConnectAll,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Salvar e Conectar Ambos os Servidores', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard({
    required String title,
    required ServerConnectionState server,
    required TextEditingController hostController,
    required TextEditingController portController,
    required TextEditingController tokenController,
    required bool isTesting,
    required bool testSuccess,
    required String? testResult,
    required VoidCallback onTest,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: server.isConnected
                      ? AppTheme.accentGreen
                      : (server.isConnecting ? AppTheme.accentYellow : AppTheme.accentRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: TextField(
                  controller: hostController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: 'Endereço IPv4',
                    labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: 'Porta',
                    labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: tokenController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
            decoration: const InputDecoration(
              labelText: 'Token de Segurança (Opcional)',
              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: BorderSide(color: accentColor, width: 0.8),
                ),
                onPressed: isTesting ? null : onTest,
                icon: isTesting
                    ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : const Icon(Icons.network_check, size: 12),
                label: Text(isTesting ? 'Testando...' : 'Testar', style: TextStyle(color: accentColor, fontSize: 9)),
              ),
              if (testResult != null)
                Text(
                  testResult,
                  style: TextStyle(
                    color: testSuccess ? AppTheme.accentGreen : AppTheme.accentRed,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
