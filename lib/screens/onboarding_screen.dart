import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../widgets/coming_soon.dart';

/// TODO(PARTE-1): Onboarding (3 slides) mostrado só na primeira vez que o app abre.
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. `PageView` com 3 páginas: "Compare" (mesmo prato em vários apps),
///      "Economize" (frete, taxas e cupons no total) e "Peça no app mais barato".
///   2. Indicador de página (bolinhas), botão "Pular" e botão "Começar" na última.
///   3. Ao terminar, salvar `onboarding_visto = true` com `shared_preferences`
///      e ir para o login: `Navigator.pushReplacementNamed(context, AppRoutes.login)`.
///   4. No `splash_screen.dart`, ler a flag e decidir entre onboarding e login.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: ComingSoon(
                icon: Icons.auto_awesome_rounded,
                title: 'Boas-vindas ao CheapEats',
                description: 'Três telas apresentando como o app compara preços entre iFood, 99Food e Keeta.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('Começar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
