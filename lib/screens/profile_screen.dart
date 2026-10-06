import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';
import '../widgets/data_source_chip.dart';

/// TODO(PARTE-1): Aba Perfil.
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. Cabeçalho com avatar (iniciais), nome e e-mail de `AppServices.session`
///      (ou "Visitante" se entrou sem conta).
///   2. Card "Minha economia": soma de `AppServices.orders.totalSavings`.
///   3. Menu: Favoritos (rota `AppRoutes.favorites`), Endereços (`AppRoutes.address`),
///      Cupons (`AppRoutes.coupons`), Sobre o app (integrantes do grupo).
///   4. Mostrar o `DataSourceChip` (de onde vêm os dados).
///   5. Botão "Sair": `AppServices.session.logout()` e voltar ao login com
///      `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false)`.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const Column(
        children: [
          Expanded(
            child: ComingSoon(
              icon: Icons.person_outline_rounded,
              title: 'Seu perfil',
              description: 'Seus dados, quanto você já economizou, favoritos e configurações.',
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 24), child: DataSourceChip()),
        ],
      ),
    );
  }
}
