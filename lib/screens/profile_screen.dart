import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../ui/theme.dart';
import '../widgets/data_source_chip.dart';

/// Aba Perfil: quem está usando o app, quanto já economizou, atalhos e "Sair".
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _version = '1.0.0'; // mesma do pubspec.yaml

  static const _members = [
    'Helena Barbosa Costa',
    'Henrique Mandrick',
    'Mateus Scandiuzzi Valente Tomomitsu',
    'Ryan Amorim de Castro Santana',
    'Thomas Joh Kobayashi',
  ];

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AppServices.session.logout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o CheapEats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compara o preço total do mesmo prato no iFood, 99Food, Keeta, Rappi e Aiqfome '
                'e mostra onde ele sai mais barato.',
                style: AppText.body2,
              ),
              const SizedBox(height: 12),
              Text('Versão $_version · Protótipo acadêmico (FIAP · CP5)', style: AppText.caption),
              const SizedBox(height: 16),
              Text('Integrantes', style: AppText.h6),
              const SizedBox(height: 6),
              for (final name in _members)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(name, style: AppText.body2),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListenableBuilder(
        listenable: Listenable.merge([AppServices.session, AppServices.orders, AppServices.address]),
        builder: (context, _) {
          final session = AppServices.session;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Header(name: session.displayName, email: session.email, isGuest: session.isGuest),
              const SizedBox(height: 20),
              _SavingsCard(total: AppServices.orders.totalSavings, orders: AppServices.orders.orders.length),
              const SizedBox(height: 20),
              Material(
                color: AppColors.bgWhite,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  side: const BorderSide(color: AppColors.strokeLight),
                ),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favoritos',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.favorites),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Endereço de entrega',
                      subtitle: AppServices.address.current.short,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.address),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Cupons',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.coupons),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Sobre o CheapEats',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: DataSourceChip()),
              const SizedBox(height: 12),
              Center(
                child: session.isGuest
                    ? TextButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Entrar ou criar conta'),
                      )
                    : TextButton.icon(
                        onPressed: () => _logout(context),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textDarkGrey),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sair da conta'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? email;
  final bool isGuest;

  const _Header({required this.name, required this.email, required this.isGuest});

  /// "Ana Demo" → "AD"; "Ana" → "A".
  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          child: isGuest
              ? const Icon(Icons.person_outline_rounded, size: 30)
              : Text(_initials(name), style: AppText.h4.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4),
              const SizedBox(height: 2),
              Text(
                isGuest ? 'Entrou sem conta' : email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card teal com a economia acumulada (mesma linguagem do card da comparação).
class _SavingsCard extends StatelessWidget {
  final double total;
  final int orders;

  const _SavingsCard({required this.total, required this.orders});

  @override
  Widget build(BuildContext context) {
    final detail = switch (orders) {
      0 => 'Sua economia começa no próximo pedido.',
      1 => 'Em 1 pedido feito pelo CheapEats',
      _ => 'Em $orders pedidos feitos pelo CheapEats',
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('MINHA ECONOMIA', style: AppText.label.copyWith(color: Colors.white, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          Text(Fmt.brl(total), style: AppText.price(size: 34, color: Colors.white)),
          const SizedBox(height: 4),
          Text(detail, style: AppText.body2.copyWith(color: Colors.white, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.orange),
      title: Text(title, style: AppText.h6),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
    );
  }
}
