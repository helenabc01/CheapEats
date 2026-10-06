import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'address_controller.dart';

/// Erro ao obter a localização, com uma mensagem pronta para o usuário.
class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

/// Descobre o endereço de onde o usuário está agora.
abstract class LocationService {
  static const currentLabel = 'Localização atual';

  /// Lança [LocationException] se não for possível obter a localização.
  Future<DeliveryAddress> currentAddress();
}

/// Usa o GPS do celular (ou a localização do navegador, na web) e traduz as
/// coordenadas em rua e bairro pelo OpenStreetMap (Nominatim).
/// Se a tradução falhar, o endereço fica só com as coordenadas.
class DeviceLocationService implements LocationService {
  static const _positionTimeout = Duration(seconds: 15);
  static const _geocodeTimeout = Duration(seconds: 6);

  @override
  Future<DeliveryAddress> currentAddress() async {
    final position = await _currentPosition();
    return await _reverseGeocode(position.latitude, position.longitude) ??
        DeliveryAddress(
          label: LocationService.currentLabel,
          street: 'Sua localização atual',
          district: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Ative a localização do aparelho para continuar.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'O acesso à localização está bloqueado. Libere nas configurações do aparelho ou do navegador.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Permita o acesso à localização para usar esta opção.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _positionTimeout),
      );
    } on PermissionDeniedException {
      throw const LocationException('Permita o acesso à localização para usar esta opção.');
    } catch (error) {
      debugPrint('[CheapEats] Falha ao ler a localização: $error');
      throw const LocationException('Não conseguimos encontrar sua localização. Tente de novo.');
    }
  }

  Future<DeliveryAddress?> _reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$latitude',
      'lon': '$longitude',
      'zoom': '18',
      'accept-language': 'pt-BR',
    });
    try {
      final response = await http
          .get(uri, headers: kIsWeb ? null : const {'User-Agent': 'CheapEats/1.0 (prototipo academico FIAP)'})
          .timeout(_geocodeTimeout);
      if (response.statusCode != 200) return null;
      final address = (jsonDecode(response.body) as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
      final road = address?['road'] as String?;
      if (address == null || road == null) return null;

      final number = address['house_number'] as String?;
      final district = address['suburb'] ?? address['neighbourhood'] ?? address['city_district'];
      final city = address['city'] ?? address['town'] ?? address['village'];
      return DeliveryAddress(
        label: LocationService.currentLabel,
        street: number == null ? road : '$road, $number',
        district: [district, city].whereType<String>().join(', '),
        latitude: latitude,
        longitude: longitude,
      );
    } catch (error) {
      debugPrint('[CheapEats] Não foi possível obter o nome da rua: $error');
      return null;
    }
  }
}
