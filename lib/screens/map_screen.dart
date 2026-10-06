import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../data/models/food_category.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import '../widgets/food_image.dart';
import '../widgets/platform_badge.dart';
import '../widgets/restaurant_logo.dart';
import '../widgets/savings_badge.dart';

/// Mapa interativo dos restaurantes próximos.
///
/// Os pinos mostram a economia máxima de cada restaurante; tocar num pino
/// (ou arrastar os cards de baixo) seleciona o restaurante e move o mapa.
/// Mapa base: OpenStreetMap (sem chave de API), levemente dessaturado para
/// os pinos se destacarem.
class MapScreen extends StatefulWidget {
  /// `false` nos testes automatizados (eles não têm internet para baixar o mapa).
  final bool showTiles;

  const MapScreen({super.key, this.showTiles = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Tira ~65% da saturação e clareia um pouco o mapa (estilo "light").
  static const _softMap = ColorFilter.matrix(<double>[
    0.4882, 0.4649, 0.0469, 0, 12, //
    0.1382, 0.8149, 0.0469, 0, 12, //
    0.1382, 0.4649, 0.3969, 0, 12, //
    0, 0, 0, 1, 0, //
  ]);

  final _map = MapController();
  final _cards = PageController(viewportFraction: 0.88);
  AnimationController? _moveAnimation;

  String? _category;
  int _selected = 0;

  LatLng get _user {
    final address = AppServices.address.current;
    return LatLng(address.latitude, address.longitude);
  }

  /// Restaurantes do filtro atual, do mais perto ao mais longe.
  List<Restaurant> get _restaurants {
    final list = AppServices.catalog.restaurants
        .where((r) => _category == null || r.category == _category)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  @override
  void dispose() {
    _moveAnimation?.dispose();
    _cards.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Move o mapa suavemente até [target].
  void _flyTo(LatLng target, {double? zoom}) {
    final MapCamera camera;
    try {
      camera = _map.camera;
    } catch (_) {
      return; // mapa ainda não desenhado
    }
    final lat = Tween(begin: camera.center.latitude, end: target.latitude);
    final lng = Tween(begin: camera.center.longitude, end: target.longitude);
    final z = Tween(begin: camera.zoom, end: zoom ?? camera.zoom);

    _moveAnimation?.dispose();
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    // offset: deixa o ponto um pouco acima do centro (os cards cobrem a parte de baixo).
    controller.addListener(() => _map.move(
          LatLng(lat.evaluate(curve), lng.evaluate(curve)),
          z.evaluate(curve),
          offset: const Offset(0, -70),
        ));
    _moveAnimation = controller..forward();
  }

  void _select(int index, {bool fromCards = false}) {
    final list = _restaurants;
    if (index < 0 || index >= list.length) return;
    setState(() => _selected = index);
    final r = list[index];
    _flyTo(LatLng(r.latitude, r.longitude), zoom: 15.2);
    if (!fromCards && _cards.hasClients) {
      _cards.animateToPage(index, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _setCategory(String? category) {
    setState(() {
      _category = category;
      _selected = 0;
    });
    if (_cards.hasClients) _cards.jumpToPage(0);
    final list = _restaurants;
    if (list.isNotEmpty) _flyTo(LatLng(list.first.latitude, list.first.longitude), zoom: 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _restaurants;
    final calculator = AppServices.calculator;
    final categories = FoodCategory.all
        .where((c) => AppServices.catalog.restaurants.any((r) => r.category == c.id))
        .toList();
    final points = [_user, for (final r in AppServices.catalog.restaurants) LatLng(r.latitude, r.longitude)];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _user,
              initialZoom: 14,
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.fromLTRB(40, 150, 40, 230),
              ),
              minZoom: 11,
              maxZoom: 18,
              backgroundColor: const Color(0xFFEDEAE6),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (widget.showTiles)
                TileLayer(
                  urlTemplate: _tiles,
                  userAgentPackageName: 'br.com.fiap.cheapeats',
                  maxNativeZoom: 19,
                  tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _softMap, child: tile),
                ),
              MarkerLayer(
                markers: [
                  Marker(point: _user, width: 34, height: 34, child: const _UserDot()),
                  // O selecionado é desenhado por último, para ficar por cima dos outros.
                  for (final i in [
                    for (var j = 0; j < restaurants.length; j++)
                      if (j != _selected) j,
                    if (_selected < restaurants.length) _selected,
                  ])
                    Marker(
                      key: ValueKey(restaurants[i].id),
                      point: LatLng(restaurants[i].latitude, restaurants[i].longitude),
                      width: 128,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: _RestaurantPin(
                        restaurant: restaurants[i],
                        savings: calculator.maxSavingsRatio(restaurants[i]),
                        selected: i == _selected,
                        onTap: () => _select(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Crédito exigido pela licença do OpenStreetMap.
          Positioned(
            left: 12,
            right: 72,
            bottom: 188,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '© colaboradores do OpenStreetMap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 10, color: AppColors.textDarkGrey),
                ),
              ),
            ),
          ),
          _TopBar(
            categories: categories,
            selected: _category,
            onCategory: _setCategory,
          ),
          Positioned(
            right: 16,
            bottom: 196,
            child: FloatingActionButton.small(
              heroTag: 'recentrar',
              tooltip: 'Voltar para o meu endereço',
              backgroundColor: AppColors.bgWhite,
              foregroundColor: AppColors.orange,
              onPressed: () => _flyTo(_user, zoom: 14.5),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            height: 160,
            child: restaurants.isEmpty
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _cards,
                    itemCount: restaurants.length,
                    onPageChanged: (i) => _select(i, fromCards: true),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _MapCard(restaurant: restaurants[i], selected: i == _selected),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final List<FoodCategory> categories;
  final String? selected;
  final ValueChanged<String?> onCategory;

  const _TopBar({required this.categories, required this.selected, required this.onCategory});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Material(
                  color: AppColors.bgWhite,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: IconButton(
                    tooltip: 'Voltar',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Restaurantes perto de você', style: AppText.h6),
                        Text(
                          AppServices.address.current.full,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'Todos', selected: selected == null, onTap: () => onCategory(null)),
                for (final c in categories)
                  _FilterChip(
                    label: c.label,
                    icon: c.icon,
                    selected: selected == c.id,
                    onTap: () => onCategory(selected == c.id ? null : c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.orange : AppColors.bgWhite,
        borderRadius: BorderRadius.circular(999),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textDarkGrey),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: selected ? Colors.white : AppColors.textBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Você está aqui".
class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Seu endereço',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E88E5).withValues(alpha: 0.18),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E88E5),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

/// Pino do restaurante: logo + economia (ou "Fechado").
class _RestaurantPin extends StatelessWidget {
  final Restaurant restaurant;
  final double savings;
  final bool selected;
  final VoidCallback onTap;

  const _RestaurantPin({
    required this.restaurant,
    required this.savings,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showRating = restaurant.isOpen && savings < 0.05;
    final label = !restaurant.isOpen
        ? 'Fechado'
        : savings >= 0.05
            ? '−${Fmt.percent(savings)}'
            : Fmt.rating(restaurant.rating);
    final labelColor = !restaurant.isOpen
        ? AppColors.textGrey
        : savings >= 0.05
            ? AppColors.teal
            : AppColors.textDarkGrey;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: restaurant.name,
        child: AnimatedScale(
          scale: selected ? 1.12 : 1,
          alignment: Alignment.bottomCenter,
          duration: const Duration(milliseconds: 200),
          child: Opacity(
            opacity: restaurant.isOpen ? 1 : 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.orange : AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RestaurantLogo(restaurant: restaurant, size: 30),
                      const SizedBox(width: 6),
                      if (showRating)
                        Icon(Icons.star_rounded, size: 13, color: selected ? Colors.white : const Color(0xFFFFB300)),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(
                            fontSize: 12,
                            color: selected ? Colors.white : labelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: const Size(12, 8),
                  painter: _PinTip(color: selected ? AppColors.orange : AppColors.bgWhite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinTip extends CustomPainter {
  final Color color;

  const _PinTip({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTip oldDelegate) => oldDelegate.color != color;
}

/// Card do restaurante na parte de baixo do mapa.
class _MapCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool selected;

  const _MapCard({required this.restaurant, required this.selected});

  @override
  Widget build(BuildContext context) {
    final calculator = AppServices.calculator;
    final best = calculator.bestPlatformFor(restaurant);
    final savings = calculator.maxSavingsRatio(restaurant);
    final category = FoodCategory.byId(restaurant.category);
    final (minTime, maxTime) = restaurant.deliveryRange;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(top: selected ? 0 : 8),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: selected ? AppColors.orange : Colors.transparent, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.restaurant, arguments: restaurant.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                FoodImage(url: restaurant.imageUrl, categoryId: restaurant.category, width: 96, height: double.infinity),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h6),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${Fmt.rating(restaurant.rating)} · ${category.label} · ${Fmt.distance(restaurant.distanceKm)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        restaurant.isOpen
                            ? Fmt.deliveryTime(minTime, maxTime)
                            : 'Fechado · abre às ${restaurant.opensAt ?? '--:--'}',
                        style: AppText.caption.copyWith(
                          fontSize: 11.5,
                          color: restaurant.isOpen ? AppColors.textDarkGrey : AppColors.error,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                if (best != null && restaurant.platforms.length > 1) ...[
                                  Text('Melhor:', style: AppText.caption.copyWith(fontSize: 11)),
                                  PlatformBadge(platform: best, small: true),
                                ] else
                                  Text('Só em 1 app', style: AppText.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          if (savings >= 0.05) SavingsBadge(ratio: savings),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
