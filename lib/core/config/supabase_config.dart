/// Configuração do Supabase.
///
/// A chave abaixo é a **publishable key** (antiga "anon key"): ela foi feita
/// para ficar no app do cliente e só consegue o que as políticas de RLS do
/// `supabase/schema.sql` permitem (leitura do catálogo). NUNCA coloque aqui a
/// `service_role` / secret key.
///
/// Dá para sobrescrever na linha de comando:
///   flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  );

  /// Tempo máximo para carregar o catálogo antes de usar os dados locais.
  static const Duration timeout = Duration(seconds: 6);

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
