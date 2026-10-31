import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../providers/monitor_provider.dart';
import '../widgets/cpu_cores_expansion.dart';
import '../widgets/disks_list_card.dart';
import '../widgets/metric_card.dart';
import 'connect_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitorProvider>(
      builder: (context, provider, child) {
        final stats = provider.currentStats;

        if (stats == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider.isConnecting
                        ? Icons.sync
                        : Icons.cloud_off_outlined,
                    size: 64,
                    color: provider.isConnecting
                        ? AppTheme.accentYellow
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.isConnecting
                        ? 'Conectando ao computador...'
                        : 'Nenhuma conexão ativa',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.isConnecting
                        ? 'Aguardando telemetria de ${provider.host}:${provider.port}...'
                        : 'Conecte-se ao daemon local para visualizar as métricas de hardware.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConnectScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_ethernet),
                    label: const Text('Configurar Conexão'),
                  ),
                ],
              ),
            ),
          );
        }

        final primaryGpu = stats.gpu.isNotEmpty ? stats.gpu.first : null;

        return RefreshIndicator(
          backgroundColor: AppTheme.surface,
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            await provider.connect(provider.host, provider.port, targetToken: provider.token);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Header Informativo Rápido
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.desktop_windows, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${stats.hostname} (${stats.network.ip4})',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Ativo há ${FormatUtils.formatUptime(stats.uptime)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card de CPU
              MetricCard(
                title: 'Processador (CPU)',
                value: '${stats.cpu.usage.toStringAsFixed(1)}%',
                subtitle:
                    '${stats.cpu.brand} • ${stats.cpu.speed} GHz${stats.cpu.temp != null ? ' • ${stats.cpu.temp}°C' : ''}',
                icon: Icons.memory,
                iconColor: AppTheme.primaryBlue,
                progressPercent: stats.cpu.usage,
              ),

              // Card de Memória RAM
              MetricCard(
                title: 'Memória RAM',
                value: '${stats.memory.usagePercent.toStringAsFixed(1)}%',
                subtitle:
                    '${FormatUtils.formatBytes(stats.memory.used)} em uso de ${FormatUtils.formatBytes(stats.memory.total)} (Livre: ${FormatUtils.formatBytes(stats.memory.free)})',
                icon: Icons.storage_rounded,
                iconColor: AppTheme.accentGreen,
                progressPercent: stats.memory.usagePercent,
              ),

              // Card de Rede em Tempo Real
              MetricCard(
                title: 'Tráfego de Rede (${stats.network.interfaceName})',
                value: '↓ ${FormatUtils.formatSpeed(stats.network.rxSec)}',
                subtitle:
                    'Upload: ↑ ${FormatUtils.formatSpeed(stats.network.txSec)} • Total: ↓ ${FormatUtils.formatBytes(stats.network.rxTotal)}',
                icon: Icons.swap_vert,
                iconColor: AppTheme.accentYellow,
              ),

              // Card de GPU (Placa de Vídeo)
              if (primaryGpu != null)
                MetricCard(
                  title: 'Placa de Vídeo (GPU)',
                  value: primaryGpu.utilizationGpu != null
                      ? '${primaryGpu.utilizationGpu!.toStringAsFixed(1)}%'
                      : primaryGpu.model,
                  subtitle: primaryGpu.memoryTotal != null
                      ? '${primaryGpu.vendor} • VRAM: ${FormatUtils.formatBytes(primaryGpu.memoryTotal! * 1024 * 1024)}'
                      : primaryGpu.vendor,
                  icon: Icons.videogame_asset_outlined,
                  iconColor: AppTheme.accentPurple,
                  progressPercent: primaryGpu.utilizationGpu,
                ),

              // Detalhamento de Discos e Unidades
              DisksListCard(disks: stats.disks),

              // Grid de Núcleos Lógicos da CPU
              CpuCoresExpansion(cpu: stats.cpu),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

