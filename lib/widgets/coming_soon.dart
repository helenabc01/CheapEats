import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// Conteúdo provisório das telas que ainda serão feitas pela equipe.
/// Quem pegar a tarefa substitui o `body` da tela inteira (ver docs/cp5/TAREFAS.md).
class ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;

  const ComingSoon({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.orange),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: AppText.h4),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: AppText.body2),
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Flexible(child: Text(b, style: AppText.caption)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.strokeGrey),
              ),
              child: Text('Em construção', style: AppText.label.copyWith(color: AppColors.textDarkGrey)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mesma ideia, em formato de bottom sheet.
Future<void> showComingSoonSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ComingSoon(icon: icon, title: title, description: description),
      ),
    ),
  );
}
