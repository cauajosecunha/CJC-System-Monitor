import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../models/system_specs_model.dart';
import '../models/system_stats_model.dart';
import '../providers/monitor_provider.dart';
import '../widgets/connection_status_badge.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MonitorProvider>();
      if (provider.status == ConnectionStatus.disconnected) {
        final ok = await provider.testConnection(
          provider.host,
          provider.port,
          targetToken: provider.token,
        );
        if (ok) {
          provider.connect(provider.host, provider.port, targetToken: provider.token);
        } else {
          provider.autoDiscoverIpv4();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<MonitorProvider>(
          builder: (context, provider, child) {
            final stats = provider.currentStats;
            final specs = provider.specs;

            if (stats == null) {
              return _buildDisconnectedState(provider);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Column(
                children: [
                  // 1. BARRA HUD SUPERIOR COMPACTA (Altura fixa ~26dp)
                  _buildTopHudBar(stats, provider),
                  const SizedBox(height: 4),

                  // 2. CORPO PRINCIPAL EM 3 COLUNAS COCKPIT (Ocupa todo o espaço vertical sem scroll)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // COLUNA 1: CPU & MATRIZ DE 12 NÚCLEOS
                        Expanded(
                          flex: 32,
                          child: _buildColumnCpuAndCores(stats),
                        ),
                        const SizedBox(width: 4),

                        // COLUNA 2: TELEMETRIA CONTÍNUA (GRÁFICO), RAM E DISCOS
                        Expanded(
                          flex: 38,
                          child: _buildColumnTelemetryAndMemory(stats, provider),
                        ),
                        const SizedBox(width: 4),

                        // COLUNA 3: GPU, REDE, TOP PROCESSOS E FICHA DO SISTEMA
                        Expanded(
                          flex: 30,
                          child: _buildColumnGpuNetworkAndProcesses(stats, specs),
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
    );
  }

  // --- 1. TOPO: BARRA HUD COMPACTA ---
  Widget _buildTopHudBar(SystemStatsModel stats, MonitorProvider provider) {
    final clientIp = provider.clientIpv4 ?? '192.168.3.11';

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, color: AppTheme.primaryBlue, size: 14),
          const SizedBox(width: 4),
          const Text(
            'CJC MONITOR',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          // Rota IPv4
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, size: 11, color: AppTheme.accentGreen),
                const SizedBox(width: 3),
                Text(
                  '$clientIp ⇄ ${provider.host}:${provider.port}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Uptime
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 11, color: AppTheme.textSecondary),
              const SizedBox(width: 3),
              Text(
                'Uptime: ${FormatUtils.formatUptime(stats.uptime)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Status Badge
          ConnectionStatusBadge(
            status: provider.status,
            hostname: stats.hostname,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            },
            child: const Icon(Icons.settings_outlined, size: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
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
                  Row(
                    children: [
                      const Icon(Icons.memory, color: AppTheme.primaryBlue, size: 13),
                      const SizedBox(width: 4),
                      const Text(
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
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (stats.cpu.usage / 100.0).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(cpuColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Matriz de Todos os Núcleos da CPU (Ex: 12 threads do Ryzen 5 3600)
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
                      style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                    itemCount: stats.cpu.cores.length,
                    itemBuilder: (context, idx) {
                      final load = stats.cpu.cores[idx];
                      final col = AppTheme.getLoadColor(load);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border, width: 0.4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'C${idx + 1}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${load.toStringAsFixed(0)}%',
                                  style: TextStyle(color: col, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(1.5),
                              child: LinearProgressIndicator(
                                value: (load / 100.0).clamp(0.0, 1.0),
                                minHeight: 2.5,
                                backgroundColor: AppTheme.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(col),
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
  Widget _buildColumnTelemetryAndMemory(SystemStatsModel stats, MonitorProvider provider) {
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
                  child: provider.cpuHistory.length < 2
                      ? const Center(
                          child: Text(
                            'Aguardando telemetria...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: provider.cpuHistory.first.x,
                            maxX: provider.cpuHistory.last.x,
                            minY: 0,
                            maxY: 100,
                            lineTouchData: const LineTouchData(enabled: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: provider.cpuHistory,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                color: AppTheme.primaryBlue,
                                barWidth: 1.8,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: provider.ramHistory,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                color: AppTheme.accentGreen,
                                barWidth: 1.8,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Card de Memória RAM
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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
                  Row(
                    children: [
                      const Icon(Icons.storage_rounded, color: AppTheme.accentGreen, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'MEMÓRIA RAM',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${FormatUtils.formatBytes(stats.memory.used)} / ${FormatUtils.formatBytes(stats.memory.total)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.memory.usagePercent.toStringAsFixed(1)}%',
                    style: TextStyle(color: ramColor, fontSize: 16, fontWeight: FontWeight.bold),
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
                  minHeight: 3.5,
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(ramColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Armazenamento & Unidades de Disco (C:, D:, E:)
        Expanded(
          flex: 48,
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
                      'ARMAZENAMENTO',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${stats.disks.length} UNIDADES',
                      style: const TextStyle(color: AppTheme.accentPurple, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.disks.length,
                    itemBuilder: (context, idx) {
                      final d = stats.disks[idx];
                      final col = AppTheme.getLoadColor(d.usePercent);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${d.fs} (${d.type})',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${FormatUtils.formatBytes(d.used)} / ${FormatUtils.formatBytes(d.size)} (${d.usePercent.toStringAsFixed(0)}%)',
                                  style: TextStyle(color: col, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1.5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(1.5),
                              child: LinearProgressIndicator(
                                value: (d.usePercent / 100.0).clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor: AppTheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(col),
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
                    Row(
                      children: [
                        const Icon(Icons.videogame_asset_outlined, color: AppTheme.accentPurple, size: 11),
                        const SizedBox(width: 3),
                        const Text(
                          'GPU',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primaryGpu != null ? primaryGpu.model.replaceAll('Series', '').trim() : 'N/A',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      primaryGpu?.memoryTotal != null ? '${FormatUtils.formatBytes(primaryGpu!.memoryTotal! * 1024 * 1024)} VRAM' : 'AMD Radeon',
                      style: const TextStyle(color: AppTheme.accentPurple, fontSize: 8),
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
                      style: const TextStyle(color: AppTheme.accentYellow, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '↑ ${ulKb >= 1024 ? (ulKb / 1024.0).toStringAsFixed(1) : ulKb.toStringAsFixed(0)} ${ulKb >= 1024 ? "MB/s" : "KB/s"}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8),
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
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${stats.topProcesses.length} ATIVOS',
                      style: const TextStyle(color: AppTheme.accentGreen, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topProcs.length,
                    itemBuilder: (context, idx) {
                      final p = topProcs[idx];
                      final col = AppTheme.getLoadColor(p.cpu);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'C ${p.cpu.toStringAsFixed(0)}%',
                                style: TextStyle(color: col, fontSize: 7.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'R ${p.mem.toStringAsFixed(0)}%',
                                style: const TextStyle(color: AppTheme.accentGreen, fontSize: 7.5, fontWeight: FontWeight.bold),
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

        const SizedBox(height: 4),

        // Rodapé Ficha Técnica
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border, width: 0.4),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 10, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  specs != null
                      ? '${specs.distro} (${specs.arch}) • ${stats.hostname}'
                      : '${stats.platform.toUpperCase()} • ${stats.hostname}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w500),
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
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDisconnectedState(MonitorProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isConnecting || provider.isDiscovering ? Icons.radar : Icons.cloud_off_outlined,
            size: 40,
            color: provider.isConnecting || provider.isDiscovering ? AppTheme.accentYellow : AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            provider.isDiscovering
                ? 'Varrendo rede IPv4...'
                : (provider.isConnecting ? 'Conectando ao computador...' : 'Painel Desconectado'),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Aguardando telemetria em ${provider.host}:${provider.port}...',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentGreen,
                  side: const BorderSide(color: AppTheme.accentGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: provider.isDiscovering ? null : () => provider.autoDiscoverIpv4(),
                icon: const Icon(Icons.radar, size: 14),
                label: const Text('Auto-Descobrir IPv4', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConnectScreen()),
                  );
                },
                icon: const Icon(Icons.settings_ethernet, size: 14),
                label: const Text('Ajustar IP', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
