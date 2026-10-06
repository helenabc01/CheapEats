import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';

/// TODO(PARTE-3): Aba Pedidos (histórico) + gravação dos pedidos no Supabase.
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. Listar `AppServices.orders.orders` (use `ListenableBuilder` para atualizar
///      quando um pedido novo for feito pelo comparador).
///   2. Card do pedido: restaurante, app usado, itens, data, total e
///      "Você economizou R$ X".
///   3. Detalhe do pedido + botão "Pedir de novo" (abre a comparação do prato).
///   4. Histórico simulado inicial (3–5 pedidos antigos) para a tela não ficar vazia.
///   5. Em `OrdersController.register`, salvar na tabela `orders` do Supabase
///      (criar a tabela e a política RLS no `supabase/schema.sql`) com fallback local.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: const ComingSoon(
        icon: Icons.receipt_long_outlined,
        title: 'Seu histórico de pedidos',
        description: 'Os pedidos feitos pelo CheapEats e quanto você economizou em cada um.',
        bullets: ['Histórico salvo no Supabase', 'Economia por pedido', 'Pedir de novo'],
      ),
    );
  }
}
