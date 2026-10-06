import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

/// Sessão do usuário: quem está usando o app (conta ou visitante).
///
/// Quem confere e-mail e senha é o [AuthRepository]. No CP5 ele é SIMULADO
/// ([LocalAuthRepository]); para usar o Supabase Auth basta passar outra
/// implementação no construtor, sem mudar as telas.
class SessionController extends ChangeNotifier {
  /// Conta de demonstração (fictícia) para testes e apresentação.
  static const demoEmail = 'ana.demo@cheapeats.app';
  static const demoPassword = 'cheap123';

  final AuthRepository _auth;

  SessionController({AuthRepository? auth}) : _auth = auth ?? LocalAuthRepository();

  AuthUser? _user;
  bool _guest = false;

  /// Apps em que o usuário ainda não fez pedido. Simulação: ele é novo no
  /// Keeta, então o cupom de 1º pedido do Keeta vale até ele pedir lá.
  final Set<String> _firstOrderPlatforms = {'keeta'};

  bool get isLoggedIn => _user != null || _guest;
  bool get isGuest => _guest;
  AuthUser? get user => _user;
  String? get email => _user?.email;
  String get displayName => _user?.name ?? 'Visitante';
  String get firstName => displayName.split(' ').first;

  Set<String> get firstOrderPlatforms => Set.unmodifiable(_firstOrderPlatforms);

  /// Entra com e-mail e senha. Lança [AuthException] se não der certo.
  Future<void> signIn({required String email, required String password}) async {
    _user = await _auth.signIn(email: email, password: password);
    _guest = false;
    notifyListeners();
  }

  /// Cria a conta e já entra nela. Lança [AuthException] se não der certo.
  Future<void> signUp({required String name, required String email, required String password}) async {
    _user = await _auth.signUp(name: name, email: email, password: password);
    _guest = false;
    notifyListeners();
  }

  void loginAsGuest() {
    _user = null;
    _guest = true;
    notifyListeners();
  }

  /// Sai da conta. Mesmo que o servidor não responda, a sessão local é encerrada.
  Future<void> logout() async {
    try {
      if (_user != null) await _auth.signOut();
    } finally {
      _user = null;
      _guest = false;
      notifyListeners();
    }
  }

  /// Chamado quando um pedido é feito no app: o cupom de 1º pedido deixa de valer.
  void markOrderedOn(String platformId) {
    if (_firstOrderPlatforms.remove(platformId)) notifyListeners();
  }
}
