import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitor_provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _tokenController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MonitorProvider>();
    _hostController = TextEditingController(text: provider.host);
    _portController = TextEditingController(text: provider.port.toString());
    _tokenController = TextEditingController(text: provider.token ?? '');
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? AppConstants.defaultPort;
    final token = _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim();

    final provider = context.read<MonitorProvider>();
    final ok = await provider.testConnection(host, port, targetToken: token);

    setState(() {
      _isTesting = false;
      _testSuccess = ok;
      _testResult = ok
          ? 'Servidor IPv4 online e respondendo em $host:$port!'
          : 'Falha ao conectar no IPv4 $host:$port';
    });
  }

  Future<void> _handleAutoDiscover() async {
    final provider = context.read<MonitorProvider>();
    final found = await provider.autoDiscoverIpv4();

    if (found && mounted) {
      _hostController.text = provider.host;
      _portController.text = provider.port.toString();
      setState(() {
        _testSuccess = true;
        _testResult = 'Servidor localizado automaticamente em ${provider.host}:${provider.port}!';
      });
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Nenhum servidor encontrado via broadcast/varredura na sub-rede IPv4.';
      });
    }
  }

  Future<void> _handleConnect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? AppConstants.defaultPort;
    final token = _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim();

    final provider = context.read<MonitorProvider>();
    await provider.connect(host, port, targetToken: token);

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitorProvider>(
      builder: (context, provider, child) {
        final clientIp = provider.clientIpv4 ?? 'Identificando...';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configuração de Rede IPv4'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.settings_ethernet,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comunicação IPv4 Local',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Badge mostrando o IP do próprio smartphone/display
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android, size: 14, color: AppTheme.accentGreen),
                        const SizedBox(width: 6),
                        Text(
                          'IPv4 do Dispositivo: $clientIp',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botão de Auto-Descoberta IPv4
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: provider.isDiscovering ? null : _handleAutoDiscover,
                  icon: provider.isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                          ),
                        )
                      : const Icon(Icons.radar),
                  label: Text(
                    provider.isDiscovering
                        ? 'Varrendo Sub-rede IPv4...'
                        : 'Auto-Descobrir Servidor IPv4 na LAN',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),

                // Chips com Atalhos Rápidos
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      backgroundColor: AppTheme.surfaceVariant,
                      label: const Text('Meu PC (192.168.3.170:4080)'),
                      labelStyle: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue),
                      onPressed: () {
                        _hostController.text = '192.168.3.170';
                        _portController.text = '4080';
                      },
                    ),
                    ActionChip(
                      backgroundColor: AppTheme.surfaceVariant,
                      label: const Text('Localhost (10.0.2.2)'),
                      labelStyle: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      onPressed: () {
                        _hostController.text = '10.0.2.2';
                        _portController.text = '4080';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo Host IPv4
                TextField(
                  controller: _hostController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Endereço IPv4 do Computador',
                    hintText: 'Ex: 192.168.3.170',
                    prefixIcon: Icon(Icons.computer, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Porta
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porta HTTP/WebSocket (Faixa 4000-4099)',
                    hintText: '4080',
                    prefixIcon: Icon(Icons.numbers, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Token Opcional
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Chave de API / Token (Opcional)',
                    hintText: 'Deixe em branco se livre na LAN',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                if (_testResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testSuccess
                          ? AppTheme.accentGreen.withValues(alpha: 0.15)
                          : AppTheme.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testSuccess ? AppTheme.accentGreen : AppTheme.accentRed,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testSuccess ? Icons.check_circle : Icons.error_outline,
                          color: _testSuccess ? AppTheme.accentGreen : AppTheme.accentRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              color: _testSuccess ? AppTheme.accentGreen : AppTheme.accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isTesting ? null : _handleTest,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_ping),
                        label: const Text('Testar IPv4'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _handleConnect,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Conectar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
