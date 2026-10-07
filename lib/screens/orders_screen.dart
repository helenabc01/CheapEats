import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../screens/main_shell.dart';
import '../ui/theme.dart';
import '../widgets/platform_badge.dart';
import '../widgets/restaurant_logo.dart';
import '../widgets/savings_badge.dart';

import '../core/services/orders_controller.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  void _showOrderDetails(BuildContext context, OrderRecord order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final restaurant = AppServices.catalog.restaurantById(order.restaurantId);
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(order.restaurantName, style: AppText.h4),
                const SizedBox(height: 8),
                Text(order.itemsSummary, style: AppText.body2.copyWith(color: AppColors.textDarkGrey)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total pago', style: AppText.body1),
                    Text(Fmt.brl(order.total), style: AppText.price()),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (restaurant != null) {
                      Navigator.of(context).pushNamed(AppRoutes.restaurant, arguments: restaurant);
                    }
                  },
                  child: const Text('Pedir de novo'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: ListenableBuilder(
        listenable: AppServices.orders,
        builder: (context, _) {
          final orders = AppServices.orders.orders;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: AppColors.strokeGrey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum pedido ainda',
                      style: AppText.h4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Compare preços e faça seu primeiro pedido.',
                      style: AppText.body2.copyWith(color: AppColors.textDarkGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        MainShell.tab.value = MainShell.searchTab;
                      },
                      child: const Text('Buscar pratos'),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: AppColors.teal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Você já economizou',
                            style: AppText.body2.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Fmt.brl(AppServices.orders.totalSavings),
                            style: AppText.price(size: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'com o CheapEats',
                            style: AppText.body2.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final restaurant = AppServices.catalog.restaurantById(order.restaurantId);
                    final platform = AppServices.catalog.platforms.firstWhere(
                      (p) => p.id == order.platformId,
                      orElse: () => AppServices.catalog.platforms.first,
                    );
                    
                    final dateFormat = "${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')} · ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}";

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showOrderDetails(context, order),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (restaurant != null)
                                    RestaurantLogo(restaurant: restaurant, size: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.restaurantName,
                                          style: AppText.h5,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateFormat,
                                          style: AppText.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PlatformBadge(platform: platform),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                order.itemsSummary,
                                style: AppText.body2.copyWith(color: AppColors.textDarkGrey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(Fmt.brl(order.total), style: AppText.price()),
                                  if (order.savings > 0) SavingsBadge(amount: order.savings),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
