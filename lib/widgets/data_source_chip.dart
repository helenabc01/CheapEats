import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../data/repositories/catalog_repository.dart';
import '../ui/theme.dart';

/// Mostra de onde vieram os dados (Supabase ou locais). Útil na apresentação.
class DataSourceChip extends StatelessWidget {
  const DataSourceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final source = AppServices.dataSource;
    final online = source == DataSource.supabase;
    final color = online ? AppColors.teal : AppColors.textDarkGrey;
    return Tooltip(
      message: AppServices.fallbackReason == null
          ? source.description
          : '${source.description}\nMotivo: ${AppServices.fallbackReason}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: online ? AppColors.tealSoft : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: online ? Colors.transparent : AppColors.strokeGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              online ? 'Dados: Supabase' : 'Dados: locais (simulados)',
              style: AppText.label.copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
