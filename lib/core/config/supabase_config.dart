/// Configuração do Supabase.
///
/// A chave abaixo é a **publishable key** (antiga "anon key"): ela foi feita
/// para ficar no app do cliente e só consegue o que as políticas de RLS do
/// `supabase/schema.sql` permitem (leitura do catálogo). NUNCA coloque aqui a
/// secret key / `service_role`.
///
/// Para testar o modo offline (dados locais), rode com a URL vazia:
///   flutter run -d chrome --dart-define=SUPABASE_URL=
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vafmfwnszuvwyejgnqsm.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_nxP6uY_sbplvD_gpt8fzqQ_JuKRsZCs',
  );

  /// Tempo máximo para carregar o catálogo antes de usar os dados locais.
  static const Duration timeout = Duration(seconds: 6);

  /// Os testes automatizados ligam isto para nunca acessar a internet.
  static bool forceOffline = false;

  static bool get isConfigured => !forceOffline && url.isNotEmpty && publishableKey.isNotEmpty;
}
