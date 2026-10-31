import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';
import '../providers/monitor_provider.dart';

class SpecsScreen extends StatelessWidget {
  const SpecsScreen({super.key});

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
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
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitorProvider>(
      builder: (context, provider, child) {
        final specs = provider.specs;

        if (specs == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                const Text(
                  'Especificações não carregadas',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Conecte-se para puxar a ficha técnica do hardware',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    provider.connect(provider.host, provider.port, targetToken: provider.token);
                  },
                  child: const Text('Carregar Especificações'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Sistema Operacional
            _buildSectionCard(
              title: 'Sistema & Host',
              icon: Icons.computer,
              iconColor: AppTheme.primaryBlue,
              children: [
                _buildInfoRow('Nome do Host', specs.hostname),
                _buildInfoRow('Plataforma', '${specs.platform} (${specs.arch})'),
                _buildInfoRow('Distribuição', specs.distro),
                _buildInfoRow('Versão / Build', specs.release),
              ],
            ),

            // Processador
            _buildSectionCard(
              title: 'Processador (CPU)',
              icon: Icons.memory,
              iconColor: AppTheme.accentGreen,
              children: [
                _buildInfoRow('Modelo', specs.cpu.brand),
                _buildInfoRow('Fabricante', specs.cpu.manufacturer),
                _buildInfoRow('Frequência Base', '${specs.cpu.speed} GHz'),
                if (specs.cpu.speedMax > 0)
                  _buildInfoRow('Clock Máximo', '${specs.cpu.speedMax} GHz'),
                _buildInfoRow(
                  'Topologia',
                  '${specs.cpu.physicalCores} núcleos físicos / ${specs.cpu.cores} threads',
                ),
                if (specs.cpu.socket.isNotEmpty)
                  _buildInfoRow('Soquete', specs.cpu.socket),
              ],
            ),

            // Memória RAM
            _buildSectionCard(
              title: 'Memória RAM',
              icon: Icons.storage_rounded,
              iconColor: AppTheme.accentYellow,
              children: [
                _buildInfoRow('Total Instalado', FormatUtils.formatBytes(specs.totalMemory)),
                _buildInfoRow('Slots Detectados', '${specs.memLayout.length} módulos'),
                ...specs.memLayout.map(
                  (slot) => _buildInfoRow(
                    'Slot ${slot.bank}',
                    '${FormatUtils.formatBytes(slot.size)} ${slot.type}${slot.clockSpeed != null ? ' @ ${slot.clockSpeed} MHz' : ''}',
                  ),
                ),
              ],
            ),

            // GPUs
            if (specs.gpus.isNotEmpty)
              _buildSectionCard(
                title: 'Controladoras Gráficas (GPU)',
                icon: Icons.videogame_asset_outlined,
                iconColor: AppTheme.accentPurple,
                children: specs.gpus.map((gpu) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gpu.model,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${gpu.vendor} • Driver: ${gpu.driverVersion}${gpu.vram != null ? ' • VRAM: ${FormatUtils.formatBytes(gpu.vram! * 1024 * 1024)}' : ''}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // Discos Físicos
            if (specs.disks.isNotEmpty)
              _buildSectionCard(
                title: 'Discos Físicos Instalados',
                icon: Icons.disc_full_outlined,
                iconColor: AppTheme.primaryBlue,
                children: specs.disks.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${d.name.isNotEmpty ? d.name : d.device} (${d.type} ${d.interfaceType})',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          FormatUtils.formatBytes(d.size),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

