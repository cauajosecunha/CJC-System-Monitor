import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../models/system_stats_model.dart';

class DisksListCard extends StatelessWidget {
  final List<DiskStatsModel> disks;

  const DisksListCard({super.key, required this.disks});

  @override
  Widget build(BuildContext context) {
    if (disks.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storage, color: AppTheme.accentPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Armazenamento & Unidades',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...disks.map((d) {
              final color = AppTheme.getLoadColor(d.usePercent);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${d.fs} (${d.type})',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${FormatUtils.formatBytes(d.used)} / ${FormatUtils.formatBytes(d.size)} (${d.usePercent.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (d.usePercent / 100.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

