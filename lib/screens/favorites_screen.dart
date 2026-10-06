import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../ui/theme.dart';
import '../widgets/restaurant_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: ListenableBuilder(
        listenable: AppServices.favorites,
        builder: (context, _) {
          final favoriteIds = AppServices.favorites.ids;
          
          if (favoriteIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: AppColors.strokeGrey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Seus restaurantes favoritos',
                      style: AppText.h4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Toque no coração de um restaurante para salvar aqui.',
                      style: AppText.body2.copyWith(color: AppColors.textDarkGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final restaurants = favoriteIds
              .map((id) => AppServices.catalog.restaurantById(id))
              .where((r) => r != null)
              .map((r) => r!)
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return RestaurantCard(
                restaurant: restaurant,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.restaurant,
                  arguments: restaurant,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
