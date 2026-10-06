import 'package:flutter/foundation.dart';

class DeliveryAddress {
  final String label;
  final String street;
  final String district;

  /// Posição do endereço (o mapa centraliza aqui).
  final double latitude;
  final double longitude;

  const DeliveryAddress({
    required this.label,
    required this.street,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  String get short => street;
  String get full => '$street · $district';
}

/// Endereço de entrega selecionado (aparece no topo da Home e centraliza o mapa).
/// A escolha é feita em `lib/screens/address_screen.dart` (endereços salvos ou GPS).
class AddressController extends ChangeNotifier {
  static const defaultAddress = DeliveryAddress(
    label: 'FIAP Paulista',
    street: 'Av. Paulista, 1106',
    district: 'Bela Vista, São Paulo',
    latitude: -23.5641,
    longitude: -46.6534,
  );

  DeliveryAddress _current = defaultAddress;

  DeliveryAddress get current => _current;

  void select(DeliveryAddress address) {
    _current = address;
    notifyListeners();
  }
}
