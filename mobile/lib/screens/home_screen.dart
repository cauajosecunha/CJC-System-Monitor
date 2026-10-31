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
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Column(
                children: [
                  // 1. BARRA HUD SUPERIOR GLOBAL (Altura ~28dp com fontes ampliadas)
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

  // --- 1. BARRA HUD SUPERIOR GLOBAL (+40% AMPLIADA) ---
  Widget _buildGlobalHudBar(BuildContext context, MonitorProvider provider) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 5),
          const Text(
            'CJC MONITOR',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),

          // Status Resumido Meu-PC
          _buildQuickStatusBadge(
            icon: Icons.desktop_windows,
            name: 'Meu-PC',
            server: provider.devPc,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),

          // Divisor
          Container(width: 1, height: 14, color: AppTheme.border),
          const SizedBox(width: 8),

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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.border, width: 0.6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.screen_rotation, color: AppTheme.accentYellow, size: 14),
                  SizedBox(width: 3),
                  Text(
                    '180°',
                    style: TextStyle(color: AppTheme.accentYellow, fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Botão Configurações
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.border, width: 0.6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.textSecondary, size: 14),
                  SizedBox(width: 3),
                  Text(
                    'CONFIG',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold),
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 3),
        Text(
          statusText,
          style: TextStyle(color: dotColor, fontSize: 9.5, fontWeight: FontWeight.bold),
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
          color: isDevPc ? AppTheme.primaryBlue.withValues(alpha: 0.35) : AppTheme.accentGreen.withValues(alpha: 0.35),
          width: 0.9,
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
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          const SizedBox(width: 3),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              server.host,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (server.currentStats != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.timer_outlined, size: 11, color: AppTheme.textSecondary),
            const SizedBox(width: 2),
            Text(
              FormatUtils.formatUptime(server.currentStats!.uptime),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
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
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.accentRed),
          const SizedBox(height: 6),
          Text(
            server.isConnecting ? 'CONECTANDO...' : 'DESCONECTADO',
            style: const TextStyle(color: AppTheme.accentRed, fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            'ws://${server.host}:${server.port}/ws',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.0, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => provider.connectServer(server),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(90, 30),
            ),
            child: const Text('RECONECTAR', style: TextStyle(fontSize: 12.0, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Conteúdo ativo de cada máquina (2 Sub-colunas espaçosas sem Rede e sem Top Processos)
  Widget _buildMachineContent(SystemStatsModel stats, SystemSpecsModel? specs, bool isDevPc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SUB-COLUNA ESQUERDA: CPU, MATRIZ DE CORES E GPU
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloco CPU + Cores (Expandido para máximo destaque)
              Expanded(
                flex: 62,
                child: _buildCpuAndCoresBlock(stats, specs),
              ),
              const SizedBox(height: 3),

              // Bloco GPU Dedicado
              Expanded(
                flex: 38,
                child: _buildGpuBlock(stats, specs),
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),

        // SUB-COLUNA DIREITA: MEMÓRIA RAM E ARMAZENAMENTO / DISCOS
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloco RAM + Swap (Expandido com fontes grandes)
              Expanded(
                flex: 48,
                child: _buildRamBlock(stats),
              ),
              const SizedBox(height: 3),

              // Bloco Armazenamento / Discos + Rodapé SO
              Expanded(
                flex: 52,
                child: _buildStorageAndOsBlock(stats, specs),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB-COLUNA ESQUERDA: BLOCO CPU & CORES (SUPER AMPLIADO) ---
  Widget _buildCpuAndCoresBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    final cpuColor = AppTheme.getLoadColor(stats.cpu.usage);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha de Título CPU + Valor Gigante (24pt!)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Row(
                children: [
                  Icon(Icons.memory, color: AppTheme.primaryBlue, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'CPU',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${stats.cpu.usage.toStringAsFixed(1)}%',
                style: TextStyle(color: cpuColor, fontSize: 24.0, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          // Clock e Temperatura (12.5pt)
          Row(
            children: [
              Text(
                '${stats.cpu.speed.toStringAsFixed(2)} GHz',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.0, fontWeight: FontWeight.w600),
              ),
              if (stats.cpu.temp != null && stats.cpu.temp! > 0) ...[
                Text(
                  ' • ${stats.cpu.temp!.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    color: stats.cpu.temp! > 75 ? AppTheme.accentRed : AppTheme.accentYellow,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          // Barra de progresso CPU global (Grossa e vibrante)
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (stats.cpu.usage / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(cpuColor),
              minHeight: 4.5,
            ),
          ),

          const SizedBox(height: 4),

          // Mini Matriz de Cores (Fontes 10.5pt grandes)
          Expanded(
            child: _buildCoresMatrix(stats.cpu.cores),
          ),
        ],
      ),
    );
  }

  // Mini-matriz adaptativa de núcleos com fontes grandes
  Widget _buildCoresMatrix(List<double> cores) {
    if (cores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Se até 16 núcleos (ex: Ryzen 5 3600 com 12 threads): grid 4x3 espaçoso com números 10.5pt
    if (cores.length <= 16) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cores.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 2.0,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, index) {
              final load = cores[index];
              final color = AppTheme.getLoadColor(load);
              return Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withValues(alpha: 0.45), width: 0.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${load.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      );
    }

    // Se mais de 16 núcleos (ex: Xeon com 56 threads): heatmap de micro-blocos ampliado
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${cores.length} THREADS ATIVAS',
          style: const TextStyle(color: AppTheme.accentGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cores.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 14,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final load = cores[index];
                  final color = AppTheme.getLoadColor(load);
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1.5),
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

  // --- SUB-COLUNA ESQUERDA: BLOCO GPU DEDICADO ---
  Widget _buildGpuBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    final gpuName = (stats.gpu.isNotEmpty && stats.gpu.first.model.isNotEmpty)
        ? stats.gpu.first.model
        : (specs != null && specs.gpus.isNotEmpty ? specs.gpus.first.model : 'GPU Integrada');

    final vramTotal = (stats.gpu.isNotEmpty && stats.gpu.first.memoryTotal != null)
        ? stats.gpu.first.memoryTotal
        : (specs != null && specs.gpus.isNotEmpty ? specs.gpus.first.vram : null);

    final vramUsed = stats.gpu.isNotEmpty ? stats.gpu.first.memoryUsed : null;
    final gpuTemp = stats.gpu.isNotEmpty ? stats.gpu.first.temperatureGpu : null;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Linha de Título GPU
          const Row(
            children: [
              Icon(Icons.videogame_asset_outlined, color: AppTheme.accentPurple, size: 16),
              SizedBox(width: 4),
              Text(
                'GPU',
                style: TextStyle(color: AppTheme.accentPurple, fontSize: 13.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Nome da GPU em destaque
          Text(
            gpuName,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.0, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // VRAM e Temperatura
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (vramTotal != null && vramTotal > 0)
                Text(
                  vramUsed != null
                      ? '${(vramUsed / 1024.0).toStringAsFixed(1)}G / ${(vramTotal / 1024.0).toStringAsFixed(0)}G VRAM'
                      : '${(vramTotal / 1024.0).toStringAsFixed(0)}G VRAM',
                  style: const TextStyle(color: AppTheme.accentPurple, fontSize: 11.5, fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'VRAM Dinâmica',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.0),
                ),
              if (gpuTemp != null && gpuTemp > 0)
                Text(
                  '${gpuTemp.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    color: gpuTemp > 75 ? AppTheme.accentRed : AppTheme.accentYellow,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUB-COLUNA DIREITA: BLOCO RAM (SUPER AMPLIADO) ---
  Widget _buildRamBlock(SystemStatsModel stats) {
    final ramColor = AppTheme.getLoadColor(stats.memory.usagePercent);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // RAM Header + Valor Gigante (24pt!)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Row(
                children: [
                  Icon(Icons.storage, color: AppTheme.accentGreen, size: 16),
                  SizedBox(width: 4),
                  Text('RAM', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.0, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '${stats.memory.usagePercent.toStringAsFixed(1)}%',
                style: TextStyle(color: ramColor, fontSize: 24.0, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          // RAM Valores GB
          Text(
            '${FormatUtils.formatBytes(stats.memory.used)} / ${FormatUtils.formatBytes(stats.memory.total)}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.0, fontWeight: FontWeight.bold),
          ),

          // Barra de progresso RAM
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (stats.memory.usagePercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(ramColor),
              minHeight: 4.5,
            ),
          ),

          // Swap Info
          if (stats.memory.swapTotal > 0)
            Text(
              'Swap: ${stats.memory.swapPercent.toStringAsFixed(0)}% (${FormatUtils.formatBytes(stats.memory.swapUsed)})',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            ),
        ],
      ),
    );
  }

  // --- SUB-COLUNA DIREITA: BLOCO ARMAZENAMENTO & FICHA SO ---
  Widget _buildStorageAndOsBlock(SystemStatsModel stats, SystemSpecsModel? specs) {
    // Filtra partições virtuais do kernel (/sys, /proc) priorizando discos reais
    final realDisks = stats.disks.where((d) => !d.mount.startsWith('/sys') && !d.mount.startsWith('/proc')).toList();
    final displayDisks = realDisks.isNotEmpty ? realDisks : stats.disks;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Armazenamento
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: AppTheme.accentYellow, size: 14),
              SizedBox(width: 4),
              Text(
                'ARMAZENAMENTO',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Discos Principais com Barras Grandes
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayDisks.length.clamp(0, 2),
              separatorBuilder: (context, index) => const SizedBox(height: 3),
              itemBuilder: (context, index) {
                final disk = displayDisks[index];
                final diskColor = AppTheme.getLoadColor(disk.usePercent);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          disk.mount,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${disk.usePercent.toStringAsFixed(0)}% (${FormatUtils.formatBytes(disk.used)})',
                          style: TextStyle(color: diskColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.5),
                      child: LinearProgressIndicator(
                        value: (disk.usePercent / 100.0).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(diskColor),
                        minHeight: 4.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Mini Rodapé com Ficha de SO
          Container(
            padding: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Text(
              specs != null ? '${specs.distro} (${specs.arch})' : 'Sistema Ativo',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
