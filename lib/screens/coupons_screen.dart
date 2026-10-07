import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_services.dart';
import '../core/utils/formatters.dart';
import '../data/models/coupon.dart';
import '../data/models/delivery_platform.dart';
import '../ui/theme.dart';
import '../widgets/platform_badge.dart';
import '../widgets/section_header.dart';

/// Todos os cupons dos apps em um lugar (abre pelos banners da Home).
/// Agrupa por app, permite copiar o código e separa os expirados no fim.
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  /// `null` = todos os apps.
  String? _platformId;

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final coupons = catalog.coupons.where((c) => _platformId == null || c.platformId == _platformId).toList();
    final active = coupons.where((c) => !c.isExpired()).toList();
    final expired = coupons.where((c) => c.isExpired()).toList();
    // Cupons válidos agrupados por app, na ordem dos apps.
    final groups = [
      for (final platform in catalog.platforms)
        (platform, active.where((c) => c.platformId == platform.id).toList()),
    ].where((group) => group.$2.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(title: const Text('Cupons')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _platformId == null,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _platformId = null),
                ),
                for (final platform in catalog.platforms) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: PlatformBadge(platform: platform, small: true),
                    selected: _platformId == platform.id,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _platformId = platform.id),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: coupons.isEmpty
                ? const _NoCoupons()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      for (final (platform, list) in groups) ...[
                        _PlatformHeader(platform: platform, count: list.length),
                        for (final coupon in list)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: _CouponCard(coupon: coupon),
                          ),
                      ],
                      if (expired.isNotEmpty) ...[
                        const SectionHeader(
                          title: 'Expirados',
                          subtitle: 'Não valem mais, ficam aqui só para consulta',
                          icon: Icons.history_rounded,
                        ),
                        for (final coupon in expired)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: _CouponCard(coupon: coupon, expired: true),
                          ),
                      ],
                      const _Footer(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlatformHeader extends StatelessWidget {
  final DeliveryPlatform platform;
  final int count;

  const _PlatformHeader({required this.platform, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          PlatformBadge(platform: platform),
          const SizedBox(width: 8),
          Text(count == 1 ? '1 cupom' : '$count cupons', style: AppText.caption),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool expired;

  const _CouponCard({required this.coupon, this.expired = false});

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _copy(BuildContext context, String platformName) async {
    await Clipboard.setData(ClipboardData(text: coupon.code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Código ${coupon.code} copiado! Use no $platformName.')));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final platform = catalog.platformOrNull(coupon.platformId);
    final restaurant = coupon.restaurantId == null ? null : catalog.restaurantById(coupon.restaurantId!);
    final accent = expired ? AppColors.textGrey : AppColors.teal;

    final rules = <(IconData, String)>[
      if (coupon.minOrder > 0) (Icons.shopping_bag_outlined, 'Pedido mín. ${Fmt.brl(coupon.minOrder)}'),
      if (coupon.maxDiscount != null) (Icons.vertical_align_top_rounded, 'Até ${Fmt.brl(coupon.maxDiscount!)} de desconto'),
      if (coupon.firstOrderOnly) (Icons.celebration_outlined, 'Só no 1º pedido'),
      if (restaurant != null) (Icons.storefront_outlined, 'Exclusivo: ${restaurant.name}'),
    ];

    return Opacity(
      opacity: expired ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: expired ? AppColors.bgLightGray : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.strokeLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: expired ? AppColors.bgGray : AppColors.tealSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    coupon.type == CouponType.freeDelivery
                        ? Icons.delivery_dining_rounded
                        : Icons.local_offer_rounded,
                    size: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.title, style: AppText.h6),
                      if (coupon.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(coupon.description, style: AppText.caption),
                      ],
                    ],
                  ),
                ),
                if (expired && platform != null) ...[
                  const SizedBox(width: 8),
                  PlatformBadge(platform: platform, small: true),
                ],
              ],
            ),
            if (rules.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final (icon, text) in rules)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: AppColors.textDarkGrey),
                        const SizedBox(width: 4),
                        Flexible(child: Text(text, style: AppText.caption)),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: expired ? AppColors.bgGray : AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: expired ? AppColors.strokeGrey : AppColors.peach),
                    ),
                    child: Text(
                      coupon.code,
                      style: AppText.price(
                        size: 15,
                        color: expired ? AppColors.textGrey : AppColors.orange,
                      ).copyWith(
                        letterSpacing: 1.2,
                        decoration: expired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: expired ? null : () => _copy(context, platform?.name ?? 'app'),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              expired ? 'Expirou em ${_date(coupon.expiresAt)}' : 'Válido até ${_date(coupon.expiresAt)}',
              style: AppText.caption.copyWith(color: expired ? AppColors.error : AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'A comparação já aplica automaticamente o melhor cupom',
                style: AppText.caption.copyWith(color: AppColors.textBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCoupons extends StatelessWidget {
  const _NoCoupons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
              child: const Icon(Icons.local_offer_outlined, size: 38, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            Text('Nenhum cupom neste app', textAlign: TextAlign.center, style: AppText.h5),
            const SizedBox(height: 6),
            Text(
              'Escolha outro app ou veja todos os cupons.',
              textAlign: TextAlign.center,
              style: AppText.body2,
            ),
          ],
        ),
      ),
    );
  }
}
