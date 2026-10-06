import 'package:flutter/material.dart';

import 'json_utils.dart';

/// Um app de delivery comparado pelo CheapEats (iFood, 99Food, Keeta).
class DeliveryPlatform {
  final String id;
  final String name;
  final Color color;
  final Color onColor;
  final String webUrl;

  /// Taxa de serviço cobrada pelo app em todo pedido.
  final double serviceFee;
  final int sortOrder;

  const DeliveryPlatform({
    required this.id,
    required this.name,
    required this.color,
    required this.onColor,
    required this.webUrl,
    required this.serviceFee,
    required this.sortOrder,
  });

  factory DeliveryPlatform.fromJson(Map<String, dynamic> json) => DeliveryPlatform(
        id: json['id'] as String,
        name: json['name'] as String,
        color: colorFromHex(json['color'] as String?),
        onColor: colorFromHex(json['on_color'] as String?, Colors.white),
        webUrl: json['web_url'] as String,
        serviceFee: toDouble(json['service_fee']),
        sortOrder: toInt(json['sort_order']),
      );
}
