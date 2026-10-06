import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';

/// TODO(PARTE-2): Tela de Cupons (abre pelos banners da Home).
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. Listar `AppServices.catalog.coupons` agrupados por app (iFood, 99Food, Keeta).
///   2. Card de cupom: código, título, regra (pedido mínimo, teto, 1º pedido),
///      validade e, se for de um restaurante, o nome dele.
///   3. Botão "Copiar código" (`Clipboard.setData`) com SnackBar de confirmação.
///   4. Cupons expirados (`coupon.isExpired()`) numa seção "Expirados", apagados.
///   5. Filtro por app no topo (chips).
class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cupons')),
      body: const ComingSoon(
        icon: Icons.local_offer_outlined,
        title: 'Todos os cupons em um lugar',
        description: 'Cupons do iFood, 99Food e Keeta com as regras de cada um. '
            'A comparação de preços já aplica o melhor cupom automaticamente.',
      ),
    );
  }
}
