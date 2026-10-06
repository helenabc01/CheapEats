import 'package:flutter/foundation.dart';

/// Sessão do usuário. O login do CP5 é SIMULADO (não existe backend de
/// autenticação ainda): qualquer e-mail válido + senha com 6+ caracteres entra.
class SessionController extends ChangeNotifier {
  /// Conta de demonstração (fictícia) para testes e apresentação.
  static const demoEmail = 'ana.demo@cheapeats.app';
  static const demoPassword = 'cheap123';

  String? _name;
  String? _email;
  bool _guest = false;

  /// Apps em que o usuário ainda não fez pedido. Simulação: ele é novo no
  /// Keeta, então o cupom de 1º pedido do Keeta vale até ele pedir lá.
  final Set<String> _firstOrderPlatforms = {'keeta'};

  bool get isLoggedIn => _email != null || _guest;
  bool get isGuest => _guest;
  String? get email => _email;
  String get displayName => _name ?? 'Visitante';
  String get firstName => displayName.split(' ').first;

  Set<String> get firstOrderPlatforms => Set.unmodifiable(_firstOrderPlatforms);

  void login({required String email, String? name}) {
    _email = email.trim().toLowerCase();
    _name = (name != null && name.trim().isNotEmpty) ? name.trim() : _nameFromEmail(_email!);
    _guest = false;
    notifyListeners();
  }

  void loginAsGuest() {
    _email = null;
    _name = null;
    _guest = true;
    notifyListeners();
  }

  void logout() {
    _email = null;
    _name = null;
    _guest = false;
    notifyListeners();
  }

  /// Chamado quando um pedido é feito no app: o cupom de 1º pedido deixa de valer.
  void markOrderedOn(String platformId) {
    if (_firstOrderPlatforms.remove(platformId)) notifyListeners();
  }

  static String _nameFromEmail(String email) {
    final user = email.split('@').first.replaceAll(RegExp(r'[._\-0-9]+'), ' ').trim();
    if (user.isEmpty) return 'Visitante';
    return user
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
