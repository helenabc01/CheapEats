import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/services/session_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../ui/theme.dart';
import '../widgets/platform_badge.dart';

/// Login SIMULADO do protótipo: valida o formulário e cria a sessão local.
/// (Autenticação real com Supabase Auth fica para a próxima entrega.)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  static final _emailPattern = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppServices.session.signIn(email: _emailController.text, password: _passwordController.text);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    _goHome();
  }

  void _fillDemoAccount() {
    setState(() {
      _emailController.text = SessionController.demoEmail;
      _passwordController.text = SessionController.demoPassword;
    });
    _formKey.currentState?.validate();
  }

  void _enterAsGuest() {
    AppServices.session.loginAsGuest();
    _goHome();
  }

  void _goHome() => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponível na versão com autenticação real.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platforms = AppServices.catalog.platforms;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset('assets/imgs/icon.png', width: 44, height: 44),
                    const SizedBox(width: 10),
                    Text('CheapEats', style: AppText.h4),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Pare de pagar a mais\nno delivery.', style: AppText.h2),
                const SizedBox(height: 10),
                Text(
                  'Comparamos o mesmo prato em todos os apps — com frete, taxas e cupons — '
                  'e te mostramos onde sai mais barato.',
                  style: AppText.body2.copyWith(color: AppColors.textDarkGrey),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final p in platforms) PlatformBadge(platform: p, small: true),
                    Text('comparados lado a lado', style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'voce@email.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Informe seu e-mail';
                    if (!_emailPattern.hasMatch(text)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Mostrar senha' : 'Esconder senha',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) =>
                      (value ?? '').length < 6 ? 'A senha precisa ter pelo menos 6 caracteres' : null,
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _loading ? null : _fillDemoAccount,
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Conta demo'),
                    ),
                    TextButton(
                      onPressed: () => _notAvailable('Recuperar senha'),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: AppText.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _enterAsGuest,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Explorar sem conta'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Ainda não tem conta?', style: AppText.caption),
                    TextButton(
                      onPressed: () => _notAvailable('O cadastro'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Protótipo acadêmico (FIAP · CP5). Login simulado: nada é enviado ou salvo. '
                  'Preços fictícios.',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
