import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/routes/app_routes.dart';
import '../ui/theme.dart';

/// Guarda se o onboarding já foi visto neste aparelho/navegador.
/// Continua valendo depois de sair da conta.
class OnboardingFlag {
  OnboardingFlag._();

  static const key = 'onboarding_visto';

  /// Na dúvida (erro ao ler), mostra o onboarding.
  static Future<bool> isSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (error) {
      debugPrint('[CheapEats] Não foi possível ler o onboarding: $error');
      return false;
    }
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String text;

  const _Page(this.icon, this.title, this.text);
}

/// Apresentação do app, mostrada só na primeira vez que ele abre.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _Page(
      Icons.compare_arrows_rounded,
      'Compare antes de pedir',
      'Veja o mesmo prato no iFood, 99Food, Keeta, Rappi e Aiqfome, lado a lado.',
    ),
    _Page(
      Icons.receipt_long_rounded,
      'O preço real aparece',
      'Entrega, taxas e o melhor cupom já vêm somados no total. Sem surpresa no fim.',
    ),
    _Page(
      Icons.shopping_bag_outlined,
      'Peça no mais barato',
      'Escolha a melhor oferta e finalize o pedido no app de delivery com um toque.',
    ),
  ];

  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await OnboardingFlag.markSeen();
    } catch (error) {
      // Sem salvar, o onboarding só aparece de novo na próxima abertura.
      debugPrint('[CheapEats] Não foi possível salvar o onboarding: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: Visibility.maintain(
                  visible: !_isLast,
                  child: TextButton(
                    onPressed: _finishing ? null : _finish,
                    style: TextButton.styleFrom(foregroundColor: AppColors.textDarkGrey),
                    child: const Text('Pular'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _PageContent(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Semantics(
                    label: 'Página ${_page + 1} de ${_pages.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _page ? AppColors.orange : AppColors.strokeGrey,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishing ? null : _next,
                      child: Text(_isLast ? 'Começar' : 'Próximo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _Page page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    // Rola em telas baixas ou com fonte ampliada, sem cortar o texto.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 148,
                height: 148,
                decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
                child: Icon(page.icon, size: 64, color: AppColors.orange),
              ),
              const SizedBox(height: 36),
              Text(page.title, textAlign: TextAlign.center, style: AppText.h3),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  page.text,
                  textAlign: TextAlign.center,
                  style: AppText.body2.copyWith(color: AppColors.textDarkGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
