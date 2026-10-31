import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitor_provider.dart';
import '../widgets/live_chart_card.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitorProvider>(
      builder: (context, provider, child) {
        final stats = provider.currentStats;

        if (stats == null) {
          return const Center(
            child: Text(
              'Conecte-se para visualizar os gráficos em tempo real',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final dlKb = (stats.network.rxSec / 1024.0);
        final ulKb = (stats.network.txSec / 1024.0);

        // Calcula o máximo dinâmico para os gráficos de rede (mínimo 500 KB/s)
        double maxNetY = 500;
        for (final spot in provider.downloadHistory) {
          if (spot.y > maxNetY) maxNetY = spot.y * 1.2;
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            LiveChartCard(
              title: 'Histórico de Carga da CPU',
              currentValue: stats.cpu.usage.toStringAsFixed(1),
              unit: '%',
              spots: provider.cpuHistory,
              lineColor: AppTheme.primaryBlue,
              maxY: 100,
              minY: 0,
            ),
            LiveChartCard(
              title: 'Histórico de Uso da Memória RAM',
              currentValue: stats.memory.usagePercent.toStringAsFixed(1),
              unit: '%',
              spots: provider.ramHistory,
              lineColor: AppTheme.accentGreen,
              maxY: 100,
              minY: 0,
            ),
            LiveChartCard(
              title: 'Velocidade de Download (Rede)',
              currentValue: dlKb >= 1024
                  ? (dlKb / 1024.0).toStringAsFixed(2)
                  : dlKb.toStringAsFixed(1),
              unit: dlKb >= 1024 ? 'MB/s' : 'KB/s',
              spots: provider.downloadHistory,
              lineColor: AppTheme.accentYellow,
              maxY: maxNetY,
              minY: 0,
            ),
            LiveChartCard(
              title: 'Velocidade de Upload (Rede)',
              currentValue: ulKb >= 1024
                  ? (ulKb / 1024.0).toStringAsFixed(2)
                  : ulKb.toStringAsFixed(1),
              unit: ulKb >= 1024 ? 'MB/s' : 'KB/s',
              spots: provider.uploadHistory,
              lineColor: AppTheme.accentPurple,
              maxY: maxNetY,
              minY: 0,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

