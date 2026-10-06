import '../core/services/address_controller.dart';

/// Endereços salvos do usuário (simulados), todos perto dos restaurantes do catálogo.
const mockAddresses = <DeliveryAddress>[
  AddressController.defaultAddress,
  DeliveryAddress(
    label: 'Casa',
    street: 'Rua Vergueiro, 3185',
    district: 'Vila Mariana, São Paulo',
    latitude: -23.5869,
    longitude: -46.6380,
  ),
  DeliveryAddress(
    label: 'Trabalho',
    street: 'Av. Faria Lima, 2232',
    district: 'Pinheiros, São Paulo',
    latitude: -23.5763,
    longitude: -46.6886,
  ),
  DeliveryAddress(
    label: 'Academia',
    street: 'Rua Augusta, 1500',
    district: 'Consolação, São Paulo',
    latitude: -23.5577,
    longitude: -46.6595,
  ),
];
