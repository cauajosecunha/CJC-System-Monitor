import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../models/server_connection_state.dart';
import '../models/system_specs_model.dart';
import '../models/system_stats_model.dart';
import '../providers/monitor_provider.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MonitorProvider>();
      provider.onPageChangeRequested = (index) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
          );
        }
      };
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<MonitorProvider>(
          builder: (context, provider, child) {
            final activeServer = provider.selectedServer;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
              child: Column(
                children: [
                  // 1. BARRA HUD SUPERIOR COM SELETOR DE MÁQUINAS (Altura fixa ~28dp)
                  _buildTopHudBar(provider, activeServer),
                  const SizedBox(height: 3),

                  // 2. CORPO DIVIDIDO EM 2 TELAS DE MONITORAMENTO (PAGEVIEW)
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        provider.setSelectedScreenIndex(index);
                      },
                      children: [
                        // TELA 1: PC DESENVOLVIMENTO (WINDOWS)
                        _buildCockpitScreen(provider.devPc, provider),
                        // TELA 2: SERVIDOR PRODUÇÃO (UBUNTU SERVER 24.04 LTS)
                        _buildCockpitScreen(provider.ubuntuServer, provider),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. TOPO: BARRA HUD COMPACTA COM ABAS DOS COMPUTADORES ---
  Widget _buildTopHudBar(MonitorProvider provider, ServerConnectionState activeServer) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, color: AppTheme.primaryBlue, size: 13),
          const SizedBox(width: 4),
          const Text(
            'CJC MONITOR',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 8),

          // SELETOR / ABAS DOS 2 COMPUTADORES
          _buildMachineTab(
            provider: provider,
            server: provider.devPc,
            index: 0,
            icon: Icons.desktop_windows,
            label: '💻 Meu-PC (Win)',
            activeColor: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 4),
          _buildMachineTab(
            provider: provider,
            server: provider.ubuntuServer,
            index: 1,
            icon: Icons.dns_outlined,
            label: '🐧 Ubuntu Server',
            activeColor: AppTheme.accentGreen,
          ),

          const Spacer(),

          // Uptime do computador ativo
          if (activeServer.currentStats != null) ...[
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 10, color: AppTheme.textSecondary),
                const SizedBox(width: 3),
                Text(
                  'Uptime: ${FormatUtils.formatUptime(activeServer.currentStats!.uptime)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],

          // Botão de Alternância Automática (Auto-Cycle)
          InkWell(
            onTap: () => provider.toggleAutoCycle(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: provider.autoCycle ? AppTheme.accentYellow.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: provider.autoCycle ? AppTheme.accentYellow : Colors.transparent,
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 11,
                    color: provider.autoCycle ? AppTheme.accentYellow : AppTheme.textSecondary,
                  ),
                  if (provider.autoCycle) ...[
                    const SizedBox(width: 2),
                    const Text('12s', style: TextStyle(color: AppTheme.accentYellow, fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Botão Configurações
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            },
            child: const Icon(Icons.settings_outlined, size: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineTab({
    required MonitorProvider provider,
    required ServerConnectionState server,
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = provider.selectedScreenIndex == index;

    Color statusColor;
    if (server.isConnected) {
      statusColor = AppTheme.accentGreen;
    } else if (server.isConnecting || server.isDiscovering) {
      statusColor = AppTheme.accentYellow;
    } else {
      statusColor = AppTheme.accentRed;
    }

    return InkWell(
      onTap: () => provider.switchToScreen(index),
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : AppTheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border,
            width: isSelected ? 1.0 : 0.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              server.host,
              style: TextStyle(
                color: isSelected ? activeColor : AppTheme.textSecondary,
                fontSize: 7.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. TELA DE COCKPIT COMPLETO (3 COLUNAS) ---
  Widget _buildCockpitScreen(ServerConnectionState server, MonitorProvider provider) {
    final stats = server.currentStats;
    final specs = server.specs;

    if (stats == null) {
      return _buildDisconnectedState(server, provider);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // COLUNA 1: CPU & MATRIZ DE NÚCLEOS
        Expanded(
          flex: 32,
          child: _buildColumnCpuAndCores(stats),
        ),
        const SizedBox(width: 4),

        // COLUNA 2: TELEMETRIA CONTÍNUA (GRÁFICO), RAM E DISCOS
        Expanded(
          flex: 38,
          child: _buildColumnTelemetryAndMemory(stats, server),
        ),
        const SizedBox(width: 4),

        // COLUNA 3: GPU, REDE, TOP PROCESSOS E FICHA DO SISTEMA
        Expanded(
          flex: 30,
          child: _buildColumnGpuNetworkAndProcesses(stats, specs),
        ),
      ],
    );
  }

  // --- COLUNA 1: CPU E MATRIZ DE 12 NÚCLEOS ---
  Widget _buildColumnCpuAndCores(SystemStatsModel stats) {
    final cpuColor = AppTheme.getLoadColor(stats.cpu.usage);

    return Column(
      children: [
        // Card Principal da CPU
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.memory, color: AppTheme.primaryBlue, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'CPU',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${stats.cpu.speed} GHz${stats.cpu.temp != null ? ' • ${stats.cpu.temp}°C' : ''}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.cpu.usage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: cpuColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    stats.cpu.brand.replaceAll('Processor', '').trim(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (stats.cpu.usage / 100.0).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(cpuColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Matriz Compacta de Núcleos
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NÚCLEOS DA CPU',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.cpu.cores.length} THREADS',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 3,
                      childAspectRatio: 2.3,
                    ),
                    itemCount: stats.cpu.cores.length,
                    itemBuilder: (context, index) {
                      final core = stats.cpu.cores[index];
                      final load = core;
                      final color = AppTheme.getLoadColor(load);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border, width: 0.4),
                        ),
                        child: Row(
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: SizedBox(
                                width: 14,
                                height: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1.5),
                                  child: LinearProgressIndicator(
                                    value: (load / 100.0).clamp(0.0, 1.0),
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'C${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${load.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- COLUNA 2: TELEMETRIA CONTÍNUA (GRÁFICO), RAM E DISCOS ---
  Widget _buildColumnTelemetryAndMemory(SystemStatsModel stats, ServerConnectionState server) {
    final ramColor = AppTheme.getLoadColor(stats.memory.usagePercent);

    return Column(
      children: [
        // Gráfico de Linha ao Vivo (CPU + RAM)
        Expanded(
          flex: 52,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HISTÓRICO AO VIVO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLegendItem('CPU', AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        _buildLegendItem('RAM', AppTheme.accentGreen),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: server.cpuHistory.length < 2
                      ? const Center(
                          child: Text(
                            'Aguardando telemetria...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppTheme.border.withValues(alpha: 0.3),
                                strokeWidth: 0.6,
                              ),
                            ),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minY: 0,
                            maxY: 100,
                            lineTouchData: const LineTouchData(enabled: false),
                            lineBarsData: [
                              // Linha CPU
                              LineChartBarData(
                                spots: server.cpuHistory,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppTheme.primaryBlue,
                                barWidth: 1.8,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                              // Linha RAM
                              LineChartBarData(
                                spots: server.ramHistory,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppTheme.accentGreen,
                                barWidth: 1.8,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                          duration: Duration.zero,
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Card Compacto da Memória RAM
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reorder, color: AppTheme.accentGreen, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'MEMÓRIA RAM',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${FormatUtils.formatBytes(stats.memory.used)} / ${FormatUtils.formatBytes(stats.memory.total)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.memory.usagePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: ramColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Livre: ${FormatUtils.formatBytes(stats.memory.free)} • Swap: ${stats.memory.swapPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (stats.memory.usagePercent / 100.0).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(ramColor),
                  minHeight: 3.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Unidades de Armazenamento / Discos
        Expanded(
          flex: 48,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ARMAZENAMENTO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.disks.length} UNIDADES',
                      style: const TextStyle(
                        color: AppTheme.accentPurple,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.disks.length.clamp(0, 3),
                    separatorBuilder: (context, index) => const SizedBox(height: 3),
                    itemBuilder: (context, index) {
                      final disk = stats.disks[index];
                      final diskColor = AppTheme.getLoadColor(disk.usePercent);

                      return Row(
                        children: [
                          SizedBox(
                            width: 58,
                            child: Text(
                              '${disk.fs} (${disk.type})',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1.5),
                              child: LinearProgressIndicator(
                                value: (disk.usePercent / 100.0).clamp(0.0, 1.0),
                                backgroundColor: AppTheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(diskColor),
                                minHeight: 3.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${FormatUtils.formatBytes(disk.used)} / ${FormatUtils.formatBytes(disk.size)} (${disk.usePercent.toStringAsFixed(0)}%)',
                            style: TextStyle(color: diskColor, fontSize: 7.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- COLUNA 3: GPU, REDE, TOP PROCESSOS E FICHA DO SISTEMA ---
  Widget _buildColumnGpuNetworkAndProcesses(SystemStatsModel stats, SystemSpecsModel? specs) {
    final primaryGpu = stats.gpu.isNotEmpty ? stats.gpu.first : null;
    final dlKb = (stats.network.rxSec / 1024.0);
    final ulKb = (stats.network.txSec / 1024.0);
    final topProcs = stats.topProcesses.take(4).toList();

    return Column(
      children: [
        // Quadrante Rápido: GPU & REDE (Lado a lado)
        Row(
          children: [
            // GPU
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border, width: 0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.videogame_asset_outlined, color: AppTheme.accentPurple, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'GPU',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primaryGpu != null ? primaryGpu.model.replaceAll('Series', '').trim() : 'Integrada / Sem GPU',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      primaryGpu?.memoryTotal != null
                          ? '${FormatUtils.formatBytes(primaryGpu!.memoryTotal! * 1024 * 1024)} VRAM'
                          : (primaryGpu != null ? primaryGpu.vendor : 'Headless'),
                      style: const TextStyle(color: AppTheme.accentPurple, fontSize: 7.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // REDE
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border, width: 0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_vert, color: AppTheme.accentYellow, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          stats.network.interfaceName.toUpperCase(),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '↓ ${dlKb >= 1024 ? (dlKb / 1024.0).toStringAsFixed(1) : dlKb.toStringAsFixed(0)} ${dlKb >= 1024 ? "MB/s" : "KB/s"}',
                      style: const TextStyle(color: AppTheme.accentYellow, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '↑ ${ulKb >= 1024 ? (ulKb / 1024.0).toStringAsFixed(1) : ulKb.toStringAsFixed(0)} ${ulKb >= 1024 ? "MB/s" : "KB/s"}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Top Processos
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOP PROCESSOS',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${stats.topProcesses.length} ATIVOS',
                      style: const TextStyle(color: AppTheme.accentGreen, fontSize: 7.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topProcs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final proc = topProcs[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              proc.name,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'C ${proc.cpu.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppTheme.getLoadColor(proc.cpu),
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'R ${proc.mem.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppTheme.getLoadColor(proc.mem),
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 3),

        // Barra de Ficha Técnica / SO
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border, width: 0.4),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 9, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  specs != null
                      ? '${specs.distro} (${specs.arch}) • ${stats.hostname}'
                      : '${stats.platform.toUpperCase()} • ${stats.hostname}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDisconnectedState(ServerConnectionState server, MonitorProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border, width: 0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              server.isConnecting || server.isDiscovering ? Icons.radar : Icons.cloud_off_outlined,
              size: 32,
              color: server.isConnecting || server.isDiscovering ? AppTheme.accentYellow : AppTheme.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              server.defaultName,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              server.isDiscovering
                  ? 'Varrendo rede IPv4 local...'
                  : (server.isConnecting ? 'Conectando ao daemon...' : 'Painel Desconectado'),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              'Aguardando telemetria em ${server.host}:${server.port}...',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: server.isDiscovering ? null : () => provider.autoDiscoverServer(server),
                  icon: const Icon(Icons.radar, size: 12),
                  label: const Text('Auto-Descobrir IPv4', style: TextStyle(fontSize: 9)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => provider.connectServer(server),
                  icon: const Icon(Icons.refresh, size: 12),
                  label: const Text('Reconectar', style: TextStyle(fontSize: 9)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConnectScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings, size: 12),
                  label: const Text('Ajustar IP', style: TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
