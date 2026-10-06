import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/services/deep_link_service.dart';
import '../core/utils/formatters.dart';
import '../data/models/dish.dart';
import '../data/models/price_quote.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import '../widgets/coming_soon.dart';
import '../widgets/food_image.dart';
import '../widgets/platform_badge.dart';
import '../widgets/platform_tile.dart';
import '../widgets/quantity_stepper.dart';
import 'main_shell.dart';

/// Comparação do prato nos apps: total com frete, taxas e cupons,
/// do mais barato ao mais caro, e o botão para pedir no app vencedor.
class ComparisonScreen extends StatefulWidget {
  final CompareArgs args;

  const ComparisonScreen({super.key, required this.args});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late int _quantity = widget.args.quantity;

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final restaurant = catalog.restaurantById(widget.args.restaurantId);
    final dish = catalog.dishById(widget.args.dishId);
    if (restaurant == null || dish == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Prato não encontrado.')));
    }

    return ListenableBuilder(
      listenable: AppServices.session,
      builder: (context, _) {
        final items = [OrderItem(dish, _quantity)];
        final comparison = AppServices.calculator.compare(restaurant, items);
        final best = comparison.best;

        return Scaffold(
          appBar: AppBar(title: const Text('Comparar preços')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _DishHeader(
                restaurant: restaurant,
                dish: dish,
                quantity: _quantity,
                onQuantityChanged: (q) => setState(() => _quantity = q),
              ),
              if (!restaurant.isOpen) ...[
                const SizedBox(height: 12),
                _InfoBanner(
                  icon: Icons.schedule_rounded,
                  color: AppColors.error,
                  text: 'Restaurante fechado agora (abre às ${restaurant.opensAt ?? '--:--'}). '
                      'Você pode comparar, mas o pedido fica para depois.',
                ),
              ],
              const SizedBox(height: 16),
              _Summary(
                comparison: comparison,
                dish: dish,
                quantity: _quantity,
                onIncrease: (q) => setState(() => _quantity = q),
              ),
              const SizedBox(height: 22),
              Text('Detalhamento por app', style: AppText.h5),
              const SizedBox(height: 2),
              Text('Itens + entrega + taxa de serviço − melhor cupom disponível', style: AppText.caption),
              const SizedBox(height: 12),
              for (final quote in comparison.ranked) ...[
                PlatformTile(
                  quote: quote,
                  quantity: _quantity,
                  isBest: comparison.hasComparison && comparison.isBest(quote) && quote.meetsMinOrder,
                  isTie: comparison.isTie,
                  // O melhor app já tem o botão grande lá embaixo.
                  onOrder: quote.isAvailable &&
                          quote.meetsMinOrder &&
                          restaurant.isOpen &&
                          !comparison.isBest(quote)
                      ? () => _order(restaurant, items, quote, comparison)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              Text(
                'Valores simulados para o protótipo. Na versão final, os preços viriam '
                'das integrações com cada app.',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          bottomNavigationBar: best == null
              ? null
              : _OrderBar(
                  restaurant: restaurant,
                  best: best,
                  onOrder: () => _order(restaurant, items, best, comparison),
                  onAddToCart: () => showComingSoonSheet(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Sacola comparativa',
                    description: 'Monte um pedido com vários pratos e compare o total da sacola nos apps.',
                  ),
                ),
        );
      },
    );
  }

  Future<void> _order(Restaurant restaurant, List<OrderItem> items, PriceQuote quote, Comparison comparison) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RedirectSheet(
        restaurant: restaurant,
        items: items,
        quote: quote,
        comparison: comparison,
        parentContext: context,
      ),
    );
  }
}

class _DishHeader extends StatelessWidget {
  final Restaurant restaurant;
  final Dish dish;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const _DishHeader({
    required this.restaurant,
    required this.dish,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FoodImage(
          url: dish.imageUrl ?? restaurant.imageUrl,
          categoryId: restaurant.category,
          height: 180,
          width: double.infinity,
          radius: AppTheme.radius,
        ),
        const SizedBox(height: 14),
        Text(dish.name, style: AppText.h3.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.restaurant, arguments: restaurant.id),
          child: Text(
            restaurant.name,
            style: AppText.label.copyWith(color: AppColors.orange, fontSize: 13),
          ),
        ),
        const SizedBox(height: 6),
        Text(dish.description, style: AppText.body2.copyWith(color: AppColors.textDarkGrey)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.people_outline_rounded, size: 18, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                dish.serves > 1 ? 'Serve ${dish.serves} pessoas' : 'Serve 1 pessoa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ),
            QuantityStepper(value: quantity, onChanged: onQuantityChanged),
          ],
        ),
      ],
    );
  }
}

/// Cartão de resumo: quem ganha e quanto se economiza.
class _Summary extends StatelessWidget {
  final Comparison comparison;
  final Dish dish;
  final int quantity;
  final ValueChanged<int> onIncrease;

  const _Summary({
    required this.comparison,
    required this.dish,
    required this.quantity,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final best = comparison.best;

    if (best == null) {
      return const _InfoBanner(
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.error,
        text: 'Este item está indisponível em todos os apps agora.',
      );
    }

    if (!best.meetsMinOrder) {
      final unit = best.subtotal / quantity;
      final needed = unit > 0 ? (best.minOrder / unit).ceil() : quantity;
      return _InfoBanner(
        icon: Icons.shopping_basket_outlined,
        color: AppColors.orange,
        text: 'Nenhum app aceita esse pedido sozinho: o pedido mínimo é de '
            '${Fmt.brl(best.minOrder)}. Com $needed unidades já dá para comparar.',
        action: needed > quantity && needed <= 20
            ? TextButton(onPressed: () => onIncrease(needed), child: Text('Usar $needed unidades'))
            : null,
      );
    }

    if (!comparison.hasComparison) {
      return _InfoBanner(
        icon: Icons.info_outline_rounded,
        color: AppColors.textDarkGrey,
        text: 'Disponível só no ${best.platform.name} por ${Fmt.brl(best.total)}. '
            'Não há outro app para comparar este item.',
      );
    }

    if (comparison.isTie) {
      final second = comparison.available[1];
      return _HeroCard(
        title: 'Empate no melhor preço',
        total: best.total,
        lines: [
          '${best.platform.name} e ${second.platform.name} saem por ${Fmt.brl(best.total)}.',
          'Desempate: ${best.platform.name} entrega em ${Fmt.deliveryTime(best.deliveryTimeMin, best.deliveryTimeMax)}.',
        ],
        best: best,
      );
    }

    return _HeroCard(
      title: 'Melhor opção',
      total: best.total,
      best: best,
      lines: [
        'Você economiza ${Fmt.brl(comparison.savings)} (${Fmt.percent(comparison.savingsRatio)}) '
            'em relação ao ${comparison.worst!.platform.name}.',
        if (best.coupon != null) 'Já com o cupom ${best.coupon!.code} aplicado.',
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final double total;
  final PriceQuote best;
  final List<String> lines;

  const _HeroCard({required this.title, required this.total, required this.best, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, Color(0xFF00695C)],
        ),
        boxShadow: [
          BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(title.toUpperCase(), style: AppText.label.copyWith(color: Colors.white, letterSpacing: 0.8)),
              const Spacer(),
              PlatformBadge(platform: best.platform),
            ],
          ),
          const SizedBox(height: 10),
          Text(Fmt.brl(total), style: AppText.price(size: 34, color: Colors.white)),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line, style: AppText.body2.copyWith(color: Colors.white, fontWeight: FontWeight.w400)),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  const _InfoBanner({required this.icon, required this.color, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: AppText.body2.copyWith(color: AppColors.textBlack))),
            ],
          ),
          if (action != null) Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    );
  }
}

class _OrderBar extends StatelessWidget {
  final Restaurant restaurant;
  final PriceQuote best;
  final VoidCallback onOrder;
  final VoidCallback onAddToCart;

  const _OrderBar({
    required this.restaurant,
    required this.best,
    required this.onOrder,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final canOrder = restaurant.isOpen && best.meetsMinOrder;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        border: const Border(top: BorderSide(color: AppColors.strokeLight)),
        boxShadow: [BoxShadow(color: AppColors.bgBlack.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // TODO(BONUS): ligar à Sacola comparativa (CartController).
            OutlinedButton(
              onPressed: onAddToCart,
              style: OutlinedButton.styleFrom(minimumSize: const Size(56, 52), padding: EdgeInsets.zero),
              child: const Icon(Icons.add_shopping_cart_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: canOrder ? onOrder : null,
                child: Text(
                  !restaurant.isOpen
                      ? 'Fechado · abre às ${restaurant.opensAt ?? '--:--'}'
                      : !best.meetsMinOrder
                          ? 'Pedido mínimo não atingido'
                          : 'Pedir no ${best.platform.name} · ${Fmt.brl(best.total)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de redirecionamento para o app escolhido.
class _RedirectSheet extends StatelessWidget {
  final Restaurant restaurant;
  final List<OrderItem> items;
  final PriceQuote quote;
  final Comparison comparison;
  final BuildContext parentContext;

  const _RedirectSheet({
    required this.restaurant,
    required this.items,
    required this.quote,
    required this.comparison,
    required this.parentContext,
  });

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(parentContext);
    final navigator = Navigator.of(context);
    // Abre o app ANTES de qualquer outra espera: no navegador, o pop-up só é
    // liberado se vier logo depois do clique.
    final opened = DeepLinkService.openPlatform(quote.platform);
    // TODO(PARTE-3): o OrdersController deve salvar este pedido no Supabase.
    await AppServices.orders.register(
      restaurant: restaurant,
      items: items,
      chosen: quote,
      comparison: comparison,
    );
    final wasOpened = await opened;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasOpened
              ? 'Abrimos o ${quote.platform.name}. Pedido salvo no seu histórico!'
              : 'Não deu para abrir o ${quote.platform.name}, mas o pedido foi salvo no histórico.',
        ),
        action: SnackBarAction(
          label: 'Ver pedidos',
          onPressed: () {
            Navigator.of(parentContext).popUntil((r) => r.settings.name == AppRoutes.home);
            MainShell.tab.value = MainShell.ordersTab;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBest = comparison.isBest(quote);
    final coupon = quote.coupon;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: PlatformBadge(platform: quote.platform)),
            const SizedBox(height: 14),
            Text(
              'Vamos te levar ao ${quote.platform.name}',
              textAlign: TextAlign.center,
              style: AppText.h4,
            ),
            const SizedBox(height: 6),
            Text(
              'Finalize o pedido no app. O total estimado já considera frete, taxas e o melhor cupom.',
              textAlign: TextAlign.center,
              style: AppText.body2,
            ),
            const SizedBox(height: 18),
            _SheetRow(label: 'Total estimado', value: Fmt.brl(quote.total), strong: true),
            if (isBest && comparison.hasComparison && comparison.savingsCents > 0)
              _SheetRow(
                label: 'Economia vs ${comparison.worst!.platform.name}',
                value: Fmt.brl(comparison.savings),
                color: AppColors.teal,
              ),
            if (!isBest && comparison.best != null)
              _SheetRow(
                label: 'Mais caro que o ${comparison.best!.platform.name}',
                value: '+ ${Fmt.brl(quote.total - comparison.best!.total)}',
                color: AppColors.error,
              ),
            if (coupon != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 18, color: AppColors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Use o cupom ',
                          style: AppText.caption.copyWith(color: AppColors.textBlack),
                          children: [
                            TextSpan(text: coupon.code, style: AppText.label.copyWith(color: AppColors.tertiary)),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: coupon.code));
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text('Cupom ${coupon.code} copiado!'), duration: const Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _confirm(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text('Abrir ${quote.platform.name}'),
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Agora não')),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  const _SheetRow({required this.label, required this.value, this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body2.copyWith(color: AppColors.textDarkGrey))),
          Text(
            value,
            style: AppText.price(
              size: strong ? 20 : 15,
              color: color ?? AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}
