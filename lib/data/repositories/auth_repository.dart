/// Usuário autenticado. São os mesmos dados que o Supabase Auth devolve
/// (`User.id`, `User.email` e o nome em `userMetadata['name']`).
class AuthUser {
  final String id;
  final String email;
  final String name;

  const AuthUser({required this.id, required this.email, required this.name});
}

/// Erro de autenticação com uma mensagem pronta para mostrar ao usuário.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Contrato de qualquer fonte de autenticação (local ou Supabase Auth).
///
/// Hoje só existe a versão local ([LocalAuthRepository]). A versão com o
/// Supabase implementa os mesmos métodos, e as telas não precisam mudar:
///   - [signIn]  → `auth.signInWithPassword(email: ..., password: ...)`
///   - [signUp]  → `auth.signUp(email: ..., password: ..., data: {'name': ...})`
///   - [signOut] → `auth.signOut()`
///   - [currentUser] → `auth.currentUser` (o Supabase guarda a sessão no aparelho)
abstract class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUp({required String name, required String email, required String password});

  Future<void> signOut();
}

/// Autenticação SIMULADA do protótipo: nada sai do aparelho.
/// Qualquer e-mail válido com senha de 6+ caracteres entra; contas criadas
/// com [signUp] ficam em memória até o app fechar.
class LocalAuthRepository implements AuthRepository {
  /// Simula o tempo de resposta do servidor.
  final Duration delay;

  LocalAuthRepository({this.delay = const Duration(milliseconds: 700)});

  static const minPasswordLength = 6;

  /// Nome das contas criadas nesta sessão do app (e-mail → nome).
  final Map<String, String> _names = {};
  AuthUser? _current;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    await Future<void>.delayed(delay);
    _checkPassword(password);
    final normalized = _normalize(email);
    return _current = _userFor(normalized, _names[normalized] ?? _nameFromEmail(normalized));
  }

  @override
  Future<AuthUser> signUp({required String name, required String email, required String password}) async {
    await Future<void>.delayed(delay);
    _checkPassword(password);
    final normalized = _normalize(email);
    if (_names.containsKey(normalized)) {
      throw const AuthException('Já existe uma conta com este e-mail.');
    }
    final trimmed = name.trim();
    _names[normalized] = trimmed.isEmpty ? _nameFromEmail(normalized) : trimmed;
    return _current = _userFor(normalized, _names[normalized]!);
  }

  @override
  Future<void> signOut() async => _current = null;

  static void _checkPassword(String password) {
    if (password.length < minPasswordLength) {
      throw const AuthException('A senha precisa ter pelo menos $minPasswordLength caracteres.');
    }
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  static AuthUser _userFor(String email, String name) => AuthUser(id: 'local:$email', email: email, name: name);

  /// "ana.demo@..." → "Ana Demo".
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
