import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../models/server_connection_state.dart';
import '../models/system_specs_model.dart';
import '../models/system_stats_model.dart';
import '../providers/monitor_provider.dart';
import 'connect_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<MonitorProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              child: Column(
                children: [
                  // 1. BARRA HUD SUPERIOR GLOBAL (Altura ~24dp)
                  _buildGlobalHudBar(context, provider),
                  const SizedBox(height: 3),

                  // 2. CORPO: AS DUAS TELAS EXIBIDAS JUNTAS LADO A LADO
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LADO ESQUERDO: PC DE DESENVOLVIMENTO (MEU-PC / WINDOWS)
                        Expanded(
                          child: _buildMachinePanel(
                            context: context,
                            server: provider.devPc,
                            provider: provider,
                            isDevPc: true,
                          ),
                        ),
                        const SizedBox(width: 3),

                        // DIVISOR VERTICAL NEON
                        Container(
                          width: 1.0,
                          color: AppTheme.border,
                        ),
                        const SizedBox(width: 3),

                        // LADO DIREITO: SERVIDOR UBUNTU (UBUNTU SERVER 24.04 LTS)
                        Expanded(
                          child: _buildMachinePanel(
                            context: context,
                            server: provider.ubuntuServer,
                            provider: provider,
                            isDevPc: false,
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
    );
  }

  // --- 1. BARRA HUD SUPERIOR GLOBAL ---
  Widget _buildGlobalHudBar(BuildContext context, MonitorProvider provider) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, color: AppTheme.primaryBlue, size: 12),
          const SizedBox(width: 4),
          const Text(
            'CJC MONITOR',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),

          // Status Resumido Meu-PC
          _buildQuickStatusBadge(
            icon: Icons.desktop_windows,
            name: 'Meu-PC',
            server: provider.devPc,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 6),

          // Divisor
          Container(width: 1, height: 12, color: AppTheme.border),
          const SizedBox(width: 6),

          // Status Resumido Ubuntu Server
          _buildQuickStatusBadge(
            icon: Icons.dns_outlined,
            name: 'Ubuntu',
            server: provider.ubuntuServer,
            color: AppTheme.accentGreen,
          ),

          const Spacer(),

          // Botão Girar 180° (Inverter Orientação)
          InkWell(
            onTap: () async {
              const platform = MethodChannel('com.cjcdev.systemmonitor/orientation');
              try {
                await platform.invokeMethod('toggleOrientation');
              } catch (_) {}
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.border, width: 0.4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.screen_rotation, color: AppTheme.accentYellow, size: 10),
                  SizedBox(width: 2),
                  Text(
                    '180°',
                    style: TextStyle(color: AppTheme.accentYellow, fontSize: 7.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Botão Configurações
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.border, width: 0.4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.textSecondary, size: 10),
                  SizedBox(width: 2),
                  Text(
                    'CONFIG',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusBadge({
    required IconData icon,
    required String name,
    required ServerConnectionState server,
    required Color color,
  }) {
    Color dotColor;
    String statusText;
    if (server.isConnected) {
      dotColor = AppTheme.accentGreen;
      statusText = 'ON';
    } else if (server.isConnecting || server.isDiscovering) {
      dotColor = AppTheme.accentYellow;
      statusText = 'CONN...';
    } else {
      dotColor = AppTheme.accentRed;
      statusText = 'OFF';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          name,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 3),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 2),
        Text(
          statusText,
          style: TextStyle(color: dotColor, fontSize: 7, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- 2. PAINEL DEDICADO DE CADA MÁQUINA ---
  Widget _buildMachinePanel({
    required BuildContext context,
    required ServerConnectionState server,
    required MonitorProvider provider,
    required bool isDevPc,
  }) {
    final stats = server.currentStats;
    final specs = server.specs;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDevPc ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Header da Máquina (Nome, IP, Uptime)
          _buildMachineHeader(server, isDevPc),
          const SizedBox(height: 3),

          // Conteúdo: se desconectado, mostra placeholder com botão de reconexão
          Expanded(
            child: stats == null
                ? _buildDisconnectedPanel(server, provider, isDevPc)
                : _buildMachineContent(stats, specs, isDevPc),
          ),
        ],
      ),
    );
  }

  // Header interno de cada máquina
  Widget _buildMachineHeader(ServerConnectionState server, bool isDevPc) {
    final color = isDevPc ? AppTheme.primaryBlue : AppTheme.accentGreen;
    final icon = isDevPc ? Icons.desktop_windows : Icons.dns_outlined;
    final label = isDevPc ? '💻 MEU-PC (WINDOWS)' : '🐧 UBUNTU SERVER';

    Color dotColor;
    if (server.isConnected) {
      dotColor = AppTheme.accentGreen;
    } else if (server.isConnecting || server.isDiscovering) {
      dotColor = AppTheme.accentYellow;
    } else {
      dotColor = AppTheme.accentRed;
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(width: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            server.host,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontFamily: 'monospace'),
          ),
          const Spacer(),
          if (server.currentStats != null) ...[
            const Icon(Icons.timer_outlined, size: 9, color: AppTheme.textSecondary),
            const SizedBox(width: 2),
            Text(
              FormatUtils.formatUptime(server.currentStats!.uptime),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5),
            ),
          ],
        ],
      ),
    );
  }

  // Painel de estado desconectado
  Widget _buildDisconnectedPanel(ServerConnectionState server, MonitorProvider provider, bool isDevPc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 28, color: AppTheme.accentRed),
          const SizedBox(height: 4),
          Text(
            server.isConnecting ? 'CONECTANDO...' : 'DESCONECTADO',
            style: const TextStyle(color: AppTheme.accentRed, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'ws://${server.host}:${server.port}/ws',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () => provider.connectServer(server),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 22),
            ),
            child: const Text('RECONECTAR', style: TextStyle(fontSize: 8, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  // Conteúdo ativo de cada máquina (2 Sub-colunas compactas)
  Widget _buildMachineContent(SystemStatsModel stats, SystemSpecsModel? specs, bool isDevPc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SUB-COLUNA ESQUERDA: CPU, CORES, GPU E REDE
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloco CPU + Cores
              Expanded(
                flex: 56,
                child: _buildCpuAndCoresBlock(stats, specs),
              ),
              const SizedBox(height: 3),

              // Bloco GPU + Rede
              Expanded(
                flex: 44,
                child: _buildGpuAndNetworkBlock(stats, specs),
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),

        // SUB-COLUNA DIREITA: RAM, ARMAZENAMENTO E TOP PROCESSOS
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloco RAM + Armazenamento
              Expanded(
                flex: 52,
                child: _buildRamAndStorageBlock(stats),
              ),
              const SizedBox(height: 3),

              // Bloco Top Processos + Ficha SO
              Expanded(
                flex: 48,
                child: _buildProcessesAndOsBlock(stats, specs),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB-COLUNA ESQUERDA: BLOCO CPU & CORES ---
  Widget _buildCpuAndCoresBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    final cpuColor = AppTheme.getLoadColor(stats.cpu.usage);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha de Título CPU + Valor Gigante
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Row(
                children: [
                  Icon(Icons.memory, color: AppTheme.primaryBlue, size: 11),
                  SizedBox(width: 2),
                  Text(
                    'CPU',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${stats.cpu.usage.toStringAsFixed(1)}%',
                style: TextStyle(color: cpuColor, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          // Clock e Temperatura
          Row(
            children: [
              Text(
                '${stats.cpu.speed.toStringAsFixed(2)} GHz',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 7.5, fontWeight: FontWeight.w600),
              ),
              if (stats.cpu.temp != null && stats.cpu.temp! > 0) ...[
                Text(
                  ' • ${stats.cpu.temp!.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    color: stats.cpu.temp! > 75 ? AppTheme.accentRed : AppTheme.accentYellow,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          // Barra de progresso CPU global
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (stats.cpu.usage / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(cpuColor),
              minHeight: 2.5,
            ),
          ),

          const SizedBox(height: 3),

          // Mini Matriz de Cores (Adaptável: 12 threads detalhadas ou 56 threads em mapa de calor)
          Expanded(
            child: _buildCoresMatrix(stats.cpu.cores),
          ),
        ],
      ),
    );
  }

  // Mini-matriz adaptativa de núcleos
  Widget _buildCoresMatrix(List<double> cores) {
    if (cores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Se até 16 núcleos (ex: Ryzen 5 3600 com 12 threads), mostra grid legível
    if (cores.length <= 16) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cores.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 1.5,
              crossAxisSpacing: 1.5,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final load = cores[index];
              final color = AppTheme.getLoadColor(load);
              return Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: color.withValues(alpha: 0.35), width: 0.4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${load.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 6.5, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      );
    }

    // Se mais de 16 núcleos (ex: Xeon com 56 threads), mostra mapa de calor de micro-blocos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${cores.length} THREADS ATIVAS',
          style: const TextStyle(color: AppTheme.accentGreen, fontSize: 6.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 1.5),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cores.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 14,
                  mainAxisSpacing: 1.2,
                  crossAxisSpacing: 1.2,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final load = cores[index];
                  final color = AppTheme.getLoadColor(load);
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- SUB-COLUNA ESQUERDA: BLOCO GPU & REDE ---
  Widget _buildGpuAndNetworkBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    final dlKb = stats.network.rxSec / 1024.0;
    final ulKb = stats.network.txSec / 1024.0;

    final gpuName = (stats.gpu.isNotEmpty && stats.gpu.first.model.isNotEmpty)
        ? stats.gpu.first.model
        : (specs != null && specs.gpus.isNotEmpty ? specs.gpus.first.model : 'GPU Não Detectada');

    final vramTotal = (stats.gpu.isNotEmpty && stats.gpu.first.memoryTotal != null)
        ? stats.gpu.first.memoryTotal
        : (specs != null && specs.gpus.isNotEmpty ? specs.gpus.first.vram : null);

    final vramUsed = stats.gpu.isNotEmpty ? stats.gpu.first.memoryUsed : null;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Linha GPU
          Row(
            children: [
              const Icon(Icons.videogame_asset_outlined, color: AppTheme.accentPurple, size: 10),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  gpuName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 7.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vramTotal != null && vramTotal > 0)
                Text(
                  vramUsed != null
                      ? '${(vramUsed / 1024.0).toStringAsFixed(1)}G'
                      : '${(vramTotal / 1024.0).toStringAsFixed(0)}G VRAM',
                  style: const TextStyle(color: AppTheme.accentPurple, fontSize: 7, fontWeight: FontWeight.bold),
                ),
            ],
          ),

          // Divisor sutil
          Container(height: 0.4, color: AppTheme.border),

          // Linha Rede
          Row(
            children: [
              const Icon(Icons.swap_vert, color: AppTheme.accentYellow, size: 10),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  stats.network.interfaceName.toUpperCase(),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '↓ ${dlKb >= 1024 ? (dlKb / 1024.0).toStringAsFixed(1) : dlKb.toStringAsFixed(0)} ${dlKb >= 1024 ? "MB/s" : "KB/s"}',
                style: const TextStyle(color: AppTheme.accentYellow, fontSize: 7, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 3),
              Text(
                '↑ ${ulKb >= 1024 ? (ulKb / 1024.0).toStringAsFixed(1) : ulKb.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 6.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUB-COLUNA DIREITA: BLOCO RAM & ARMAZENAMENTO ---
  Widget _buildRamAndStorageBlock(SystemStatsModel stats) {
    final ramColor = AppTheme.getLoadColor(stats.memory.usagePercent);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RAM Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Row(
                children: [
                  Icon(Icons.storage, color: AppTheme.accentGreen, size: 10),
                  SizedBox(width: 2),
                  Text('RAM', style: TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '${stats.memory.usagePercent.toStringAsFixed(1)}%',
                style: TextStyle(color: ramColor, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          // RAM Valores & Barra
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${FormatUtils.formatBytes(stats.memory.used)} / ${FormatUtils.formatBytes(stats.memory.total)}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 7, fontWeight: FontWeight.w600),
              ),
              if (stats.memory.swapTotal > 0)
                Text(
                  'Swp ${stats.memory.swapPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 6.5),
                ),
            ],
          ),
          const SizedBox(height: 1.5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (stats.memory.usagePercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(ramColor),
              minHeight: 2.5,
            ),
          ),

          const SizedBox(height: 3),
          Container(height: 0.4, color: AppTheme.border),
          const SizedBox(height: 2),

          // Armazenamento / Discos (exibe até 2 discos principais)
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.disks.length.clamp(0, 2),
              separatorBuilder: (context, index) => const SizedBox(height: 1.5),
              itemBuilder: (context, index) {
                final disk = stats.disks[index];
                final diskColor = AppTheme.getLoadColor(disk.usePercent);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          disk.mount,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${disk.usePercent.toStringAsFixed(0)}% (${FormatUtils.formatBytes(disk.used)})',
                          style: TextStyle(color: diskColor, fontSize: 6.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(1.5),
                      child: LinearProgressIndicator(
                        value: (disk.usePercent / 100.0).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(diskColor),
                        minHeight: 2.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-COLUNA DIREITA: BLOCO TOP PROCESSOS & FICHA SO ---
  Widget _buildProcessesAndOsBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    final topProcs = stats.topProcesses.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top Processos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOP PROCESSOS',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 7, fontWeight: FontWeight.bold),
              ),
              Text(
                '${stats.topProcesses.length} ATIVOS',
                style: const TextStyle(color: AppTheme.accentGreen, fontSize: 6.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Lista de Processos
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProcs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 1.5),
              itemBuilder: (context, index) {
                final proc = topProcs[index];
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        proc.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 7, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'C:${proc.cpu.toStringAsFixed(0)}% R:${proc.mem.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 6.5, fontFamily: 'monospace'),
                    ),
                  ],
                );
              },
            ),
          ),

          // Mini Rodapé com Ficha de SO
          Container(
            padding: const EdgeInsets.only(top: 1.5),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 0.4)),
            ),
            child: Text(
              specs != null ? '${specs.distro} (${specs.arch})' : 'Sistema Ativo',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 6.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
