import 'package:flutter/material.dart';

import '../data/models/restaurant.dart';
import '../ui/theme.dart';

/// "Logo" do restaurante: monograma com a cor da marca.
class RestaurantLogo extends StatelessWidget {
  final Restaurant restaurant;
  final double size;

  const RestaurantLogo({super.key, required this.restaurant, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [restaurant.brandColor, Color.lerp(restaurant.brandColor, Colors.black, 0.25)!],
        ),
        border: Border.all(color: Colors.white, width: size > 50 ? 3 : 2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Text(
        restaurant.initials,
        style: AppText.h6.copyWith(color: Colors.white, fontSize: size * 0.32, letterSpacing: 0.5),
      ),
    );
  }
}
