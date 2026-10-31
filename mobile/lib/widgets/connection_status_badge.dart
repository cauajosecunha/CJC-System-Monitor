import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitor_provider.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final String hostname;
  final VoidCallback? onTap;

  const ConnectionStatusBadge({
    super.key,
    required this.status,
    required this.hostname,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        dotColor = AppTheme.accentGreen;
        statusText = hostname.isNotEmpty ? hostname : 'Conectado';
        break;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        dotColor = AppTheme.accentYellow;
        statusText = 'Conectando...';
        break;
      case ConnectionStatus.error:
        dotColor = AppTheme.accentRed;
        statusText = 'Erro de Rede';
        break;
      case ConnectionStatus.disconnected:
        dotColor = AppTheme.textSecondary;
        statusText = 'Desconectado';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

