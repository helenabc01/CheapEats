import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../data/models/food_category.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import '../widgets/dish_tile.dart';
import '../widgets/food_image.dart';
import '../widgets/platform_badge.dart';
import '../widgets/restaurant_logo.dart';
import '../widgets/savings_badge.dart';

/// Página do restaurante: condições em cada app, cupons e cardápio comparado.
class RestaurantScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final _scroll = ScrollController();

  /// O nome só aparece na barra quando a capa já foi recolhida.
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.hasClients && _scroll.offset > 150;
      if (show != _showTitle) setState(() => _showTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = AppServices.catalog.restaurantById(widget.restaurantId);
    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Restaurante não encontrado.')),
      );
    }

    final sections = restaurant.sections;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      // TODO(BONUS): barra "Ver sacola" aqui quando a Sacola comparativa existir.
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          _Cover(restaurant: restaurant, showTitle: _showTitle),
          SliverToBoxAdapter(child: _Info(restaurant: restaurant)),
          SliverToBoxAdapter(child: _PlatformConditions(restaurant: restaurant)),
          SliverToBoxAdapter(child: _Coupons(restaurant: restaurant)),
          for (final section in sections) ...[
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.bgGray,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(section, style: AppText.h5),
              ),
            ),
            SliverList.separated(
              itemCount: restaurant.dishes.where((d) => d.section == section).length,
              separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
              itemBuilder: (context, i) {
                final dish = restaurant.dishes.where((d) => d.section == section).elementAt(i);
                return DishTile(
                  restaurant: restaurant,
                  dish: dish,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.compare,
                    arguments: CompareArgs(restaurantId: restaurant.id, dishId: dish.id),
                  ),
                );
              },
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final Restaurant restaurant;
  final bool showTitle;

  const _Cover({required this.restaurant, required this.showTitle});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: AppColors.bgWhite,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _RoundButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      title: AnimatedOpacity(
        opacity: showTitle ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Text(restaurant.name, style: AppText.h6),
      ),
      actions: [
        // Coração de favorito — a lista de Favoritos é a Parte 3.
        ListenableBuilder(
          listenable: AppServices.favorites,
          builder: (context, _) {
            final favorite = AppServices.favorites.isFavorite(restaurant.id);
            return Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundButton(
                icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: favorite ? AppColors.tertiary : null,
                tooltip: favorite ? 'Remover dos favoritos' : 'Favoritar',
                onPressed: () {
                  AppServices.favorites.toggle(restaurant.id);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(favorite ? 'Removido dos favoritos' : 'Adicionado aos favoritos'),
                      duration: const Duration(seconds: 2),
                    ));
                },
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(url: restaurant.imageUrl, categoryId: restaurant.category, radius: 0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Color(0x33000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgWhite,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20, color: color ?? AppColors.textBlack),
        onPressed: onPressed,
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final Restaurant restaurant;

  const _Info({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final category = FoodCategory.byId(restaurant.category);
    final maxSavings = AppServices.calculator.maxSavingsRatio(restaurant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RestaurantLogo(restaurant: restaurant, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: AppText.h4),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text(
                          Fmt.rating(restaurant.rating),
                          style: AppText.label.copyWith(color: const Color(0xFFB37A00)),
                        ),
                        Flexible(
                          child: Text(
                            ' (${Fmt.compact(restaurant.reviewCount)})  ·  ${category.label}  ·  '
                            '${'\$' * restaurant.priceLevel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${restaurant.neighborhood} · ${Fmt.distance(restaurant.distanceKm)}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(restaurant.description, style: AppText.body2.copyWith(color: AppColors.textDarkGrey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(restaurant: restaurant),
              if (maxSavings >= 0.05) SavingsBadge(ratio: maxSavings),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Restaurant restaurant;

  const _StatusChip({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final open = restaurant.isOpen;
    final color = open ? AppColors.teal : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(open ? Icons.circle : Icons.schedule_rounded, size: open ? 8 : 13, color: color),
          const SizedBox(width: 5),
          Text(
            open ? 'Aberto agora' : 'Fechado · abre às ${restaurant.opensAt ?? '--:--'}',
            style: AppText.label.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Tabela com frete, tempo e pedido mínimo em cada app.
class _PlatformConditions extends StatelessWidget {
  final Restaurant restaurant;

  const _PlatformConditions({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final best = AppServices.calculator.bestPlatformFor(restaurant);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgLightGray,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.strokeLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Condições em cada app', style: AppText.h6),
          const SizedBox(height: 10),
          for (final platform in catalog.platforms) ...[
            Builder(builder: (context) {
              final info = restaurant.infoFor(platform.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: info == null ? 0.4 : 1,
                          child: PlatformBadge(platform: platform, small: true),
                        ),
                      ),
                    ),
                    Expanded(
                      child: info == null
                          ? Text('Não disponível', style: AppText.caption.copyWith(color: AppColors.textGrey))
                          : Text(
                              '${Fmt.deliveryTime(info.deliveryTimeMin, info.deliveryTimeMax)}  ·  '
                              'mín. ${Fmt.brl(info.minOrder)}',
                              style: AppText.caption,
                            ),
                    ),
                    if (info != null)
                      Text(
                        Fmt.fee(info.deliveryFee),
                        style: AppText.price(
                          size: 13,
                          weight: FontWeight.w600,
                          color: info.deliveryFee == 0 ? AppColors.teal : AppColors.textBlack,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          if (best != null && restaurant.platforms.length > 1) ...[
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Na maioria dos pratos, o mais barato é o ',
                      style: AppText.caption.copyWith(color: AppColors.textBlack),
                      children: [
                        TextSpan(text: best.name, style: AppText.label.copyWith(color: AppColors.teal)),
                        const TextSpan(text: ' (com frete, taxas e cupons).'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (restaurant.platforms.length == 1) ...[
            const SizedBox(height: 6),
            Text(
              'Este restaurante só está em um app — não há com o que comparar.',
              style: AppText.caption.copyWith(color: AppColors.textDarkGrey),
            ),
          ],
        ],
      ),
    );
  }
}

class _Coupons extends StatelessWidget {
  final Restaurant restaurant;

  const _Coupons({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final coupons = catalog.couponsForRestaurant(restaurant)
      ..sort((a, b) => (b.restaurantId != null ? 1 : 0).compareTo(a.restaurantId != null ? 1 : 0));
    if (coupons.isEmpty) return const SizedBox(height: 12);
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        scrollDirection: Axis.horizontal,
        itemCount: coupons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final coupon = coupons[i];
          final platform = catalog.platform(coupon.platformId);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, size: 15, color: AppColors.tertiary),
                const SizedBox(width: 6),
                Text(
                  '${coupon.code} · ${coupon.title}',
                  style: AppText.label.copyWith(color: AppColors.tertiary, fontSize: 11.5),
                ),
                const SizedBox(width: 6),
                PlatformBadge(platform: platform, small: true),
              ],
            ),
          );
        },
      ),
    );
  }
}
