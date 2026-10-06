import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../data/models/coupon.dart';
import '../data/models/food_category.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import '../widgets/category_tile.dart';
import '../widgets/data_source_chip.dart';
import '../widgets/deal_card.dart';
import '../widgets/map_preview_card.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/section_header.dart';
import 'main_shell.dart';

enum _RestaurantSort {
  savings('Mais econômicos', Icons.savings_outlined),
  distance('Mais próximos', Icons.near_me_outlined),
  rating('Melhor avaliados', Icons.star_outline_rounded);

  final String label;
  final IconData icon;
  const _RestaurantSort(this.label, this.icon);
}

/// Início: endereço, busca, categorias, cupons em destaque, "Economia do dia"
/// e restaurantes (layout inspirado no iFood, com a comparação em evidência).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _RestaurantSort _sort = _RestaurantSort.savings;

  /// Vai para a aba Busca; sem texto, só foca o campo de busca.
  void _openSearch([String query = '']) {
    MainShell.tab.value = MainShell.searchTab;
    AppServices.searchRequest.value = query;
  }

  void _openRestaurant(Restaurant restaurant) =>
      Navigator.of(context).pushNamed(AppRoutes.restaurant, arguments: restaurant.id);

  List<Restaurant> _sortedRestaurants() {
    final calculator = AppServices.calculator;
    final list = [...AppServices.catalog.restaurants];
    final savings = {for (final r in list) r.id: calculator.maxSavingsRatio(r)};
    list.sort((a, b) {
      if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1; // fechados por último
      return switch (_sort) {
        _RestaurantSort.savings => savings[b.id]!.compareTo(savings[a.id]!),
        _RestaurantSort.distance => a.distanceKm.compareTo(b.distanceKm),
        _RestaurantSort.rating => b.rating.compareTo(a.rating),
      };
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Redesenha quando o usuário faz um pedido (cupom de 1º pedido muda).
      listenable: AppServices.session,
      builder: (context, _) {
        final calculator = AppServices.calculator;
        final deals = calculator.topDeals();
        final restaurants = _sortedRestaurants();

        return Scaffold(
          backgroundColor: AppColors.bgGray,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverPersistentHeader(pinned: true, delegate: _SearchBarDelegate(onTap: _openSearch)),
                SliverToBoxAdapter(child: _Categories(onSelected: (c) => _openSearch(c.label))),
                SliverToBoxAdapter(child: _PromoCarousel(onSearch: () => _openSearch())),
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Perto de você',
                    subtitle: 'Escolha o restaurante pelo mapa',
                    icon: Icons.near_me_rounded,
                    padding: EdgeInsets.fromLTRB(20, 18, 12, 10),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: MapPreviewCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Economia do dia',
                    subtitle: 'O mesmo prato, mais barato em outro app',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final (restaurant, dish, comparison) = deals[i];
                        return DealCard(
                          restaurant: restaurant,
                          dish: dish,
                          comparison: comparison,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.compare,
                            arguments: CompareArgs(restaurantId: restaurant.id, dishId: dish.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Restaurantes',
                    subtitle: '${restaurants.length} perto de você · preços comparados em '
                        '${AppServices.catalog.platforms.length} apps',
                    actionLabel: 'Ver no mapa',
                    onAction: () => Navigator.of(context).pushNamed(AppRoutes.map),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        for (final sort in _RestaurantSort.values) ...[
                          ChoiceChip(
                            avatar: Icon(sort.icon, size: 16),
                            label: Text(sort.label),
                            selected: _sort == sort,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _sort = sort),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: restaurants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => RestaurantCard(
                      restaurant: restaurants[i],
                      onTap: () => _openRestaurant(restaurants[i]),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    child: Column(
                      children: [
                        const DataSourceChip(),
                        const SizedBox(height: 8),
                        Text(
                          'Preços, taxas e cupons simulados para o protótipo acadêmico.',
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: AppServices.address,
                  builder: (context, _) {
                    final address = AppServices.address.current;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.address),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entregar em', style: AppText.caption.copyWith(fontSize: 11)),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 18, color: AppColors.orange),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    address.short,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.h6,
                                  ),
                                ),
                                const Icon(Icons.expand_more_rounded, color: AppColors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Mapa de restaurantes',
                icon: const Icon(Icons.map_outlined),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.map),
              ),
              IconButton(
                tooltip: 'Notificações',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Você será avisado quando um prato favorito baixar de preço.')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: AppServices.session,
            builder: (context, _) => Text.rich(
              TextSpan(
                text: 'Olá, ${AppServices.session.firstName}! ',
                style: AppText.h4,
                children: [
                  TextSpan(
                    text: 'Bora economizar hoje?',
                    style: AppText.h4.copyWith(color: AppColors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onTap;

  _SearchBarDelegate({required this.onTap});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // O header precisa ocupar exatamente a altura declarada em min/maxExtent.
    return Container(
      height: maxExtent,
      color: AppColors.bgWhite,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Material(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Busque por prato ou restaurante',
                  style: AppText.body2.copyWith(color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => false;
}

class _Categories extends StatelessWidget {
  final ValueChanged<FoodCategory> onSelected;

  const _Categories({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgWhite,
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        scrollDirection: Axis.horizontal,
        itemCount: FoodCategory.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 2),
        itemBuilder: (context, i) {
          final category = FoodCategory.all[i];
          return CategoryTile(category: category, onTap: () => onSelected(category));
        },
      ),
    );
  }
}

/// Banners: proposta do app + um cupom de cada app (vindos dos dados).
/// Passa sozinho a cada 5 s, tem setas (para o mouse) e aceita arrastar.
class _PromoCarousel extends StatefulWidget {
  final VoidCallback onSearch;

  const _PromoCarousel({required this.onSearch});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _autoPlayEvery = Duration(seconds: 5);

  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoPlayEvery, (_) {
      if (!mounted || _count < 2 || MediaQuery.of(context).disableAnimations) return;
      _goTo((_page + 1) % _count);
    });
  }

  void _goTo(int page) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(page, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  void _step(int delta) {
    _goTo((_page + delta).clamp(0, _count - 1));
    _restartAutoPlay(); // quem clicou está olhando: espera mais 5 s
  }

  List<_BannerData> _banners() {
    final catalog = AppServices.catalog;
    final coupons = catalog.activeCoupons().where((c) => c.restaurantId == null).toList()
      ..sort((a, b) => _priority(a).compareTo(_priority(b)));

    // Um cupom por app, na ordem de prioridade (1º pedido, frete grátis, desconto).
    final perPlatform = <String, Coupon>{};
    for (final coupon in coupons) {
      perPlatform.putIfAbsent(coupon.platformId, () => coupon);
    }

    final names = catalog.platforms.map((p) => p.name).toList();
    final banners = <_BannerData>[
      _BannerData(
        title: 'Mesmo prato,\npreço diferente.',
        subtitle: 'Compare ${names.take(names.length - 1).join(', ')} e ${names.last} antes de pedir.',
        cta: 'Comparar agora',
        colors: const [AppColors.orange, AppColors.tertiary],
        icon: Icons.compare_arrows_rounded,
        onTap: widget.onSearch,
      ),
    ];
    for (final coupon in perPlatform.values) {
      final platform = catalog.platform(coupon.platformId);
      banners.add(
        _BannerData(
          title: coupon.title,
          subtitle: 'Cupom ${coupon.code} no ${platform.name} · já aplicado na comparação',
          cta: 'Ver cupons',
          colors: [platform.color, _shade(platform.color)],
          foreground: platform.onColor,
          icon: coupon.type == CouponType.freeDelivery ? Icons.delivery_dining_rounded : Icons.local_offer_rounded,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.coupons),
        ),
      );
    }
    return banners;
  }

  static int _priority(Coupon c) => c.firstOrderOnly ? 0 : (c.type == CouponType.freeDelivery ? 1 : 2);

  /// Segunda cor do degradê: mais escura (ou mais clara, se a cor já for escura).
  static Color _shade(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = hsl.lightness < 0.25 ? hsl.lightness + 0.14 : hsl.lightness - 0.12;
    return hsl.withLightness(lightness.clamp(0.0, 1.0)).withHue((hsl.hue - 8) % 360).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners();
    _count = banners.length;
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          SizedBox(
            height: 148,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              padEnds: false,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6),
                child: _Banner(data: banners[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Bolinhas à esquerda e setas à direita, fora dos banners
          // (assim não cobrem o texto).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
            child: Row(
              children: [
                for (var i = 0; i < banners.length; i++)
                  GestureDetector(
                    onTap: () {
                      _goTo(i);
                      _restartAutoPlay();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.orange : AppColors.strokeGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                const Spacer(),
                _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Anterior',
                  onTap: _page > 0 ? () => _step(-1) : null,
                ),
                const SizedBox(width: 8),
                _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Próximo',
                  onTap: _page < banners.length - 1 ? () => _step(1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seta pequena do carrossel (desabilitada no primeiro/último banner).
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ArrowButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.bgWhite,
        shape: CircleBorder(
          side: BorderSide(color: enabled ? AppColors.strokeGrey : AppColors.strokeLight),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.textBlack : AppColors.textLightGray,
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> colors;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.colors,
    required this.icon,
    required this.onTap,
    this.foreground = Colors.white,
  });
}

class _Banner extends StatelessWidget {
  final _BannerData data;

  const _Banner({required this.data});

  @override
  Widget build(BuildContext context) {
    final fg = data.foreground;
    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: data.colors),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -22,
                child: Icon(data.icon, size: 132, color: fg.withValues(alpha: 0.14)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, maxLines: 2, style: AppText.h5.copyWith(color: fg, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: fg.withValues(alpha: 0.9), fontSize: 11.5),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(data.cta, style: AppText.label.copyWith(color: fg)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
