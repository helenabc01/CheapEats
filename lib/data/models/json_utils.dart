import 'package:flutter/material.dart';

/// Conversões tolerantes: o mesmo `fromJson` lê o JSON local e as linhas do
/// Supabase (onde `numeric` pode chegar como número ou texto).
double toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

double? toDoubleOrNull(dynamic value) => value == null ? null : toDouble(value);

int toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool toBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return value.toString().toLowerCase() == 'true';
}

/// "#FD6737" -> Color(0xFFFD6737)
Color colorFromHex(String? hex, [Color fallback = const Color(0xFF5C6068)]) {
  if (hex == null) return fallback;
  final clean = hex.replaceAll('#', '');
  final value = int.tryParse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
  return value == null ? fallback : Color(value);
}
