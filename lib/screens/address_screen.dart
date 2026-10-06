import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';

/// TODO(PARTE-1): Seleção do endereço de entrega (abre ao tocar no endereço da Home).
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. Lista de 4–6 endereços simulados em São Paulo (`DeliveryAddress`, de
///      `lib/core/services/address_controller.dart`) — ex.: Casa, Trabalho, FIAP.
///   2. Campo de busca que filtra a lista.
///   3. Opção "Usar minha localização atual" (simulada: escolhe o endereço da FIAP
///      depois de um pequeno carregamento).
///   4. Ao tocar em um endereço: `AppServices.address.select(endereco)` e
///      `Navigator.pop(context)`. A Home já atualiza o topo sozinha.
///   5. Destacar o endereço selecionado com um check.
class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Endereço de entrega')),
      body: const ComingSoon(
        icon: Icons.location_on_outlined,
        title: 'Onde você está?',
        description: 'Escolha o endereço de entrega para calcular frete e tempo em cada app.',
        bullets: ['Endereços salvos', 'Busca de endereço', 'Usar localização atual'],
      ),
    );
  }
}
