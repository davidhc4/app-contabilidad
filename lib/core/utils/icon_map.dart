import 'package:flutter/material.dart';

/// Set fijo de iconos disponibles para categorías (predefinidas y
/// personalizadas). La clave es la que se guarda en la base de datos.
const Map<String, IconData> kCategoryIcons = {
  'restaurant': Icons.restaurant_rounded,
  'directions_car': Icons.directions_car_rounded,
  'home': Icons.home_rounded,
  'theaters': Icons.theaters_rounded,
  'favorite': Icons.favorite_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'more_horiz': Icons.more_horiz_rounded,
  'work': Icons.work_rounded,
  'laptop_mac': Icons.laptop_mac_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'trending_up': Icons.trending_up_rounded,
  'school': Icons.school_rounded,
  'pets': Icons.pets_rounded,
  'flight': Icons.flight_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'local_cafe': Icons.local_cafe_rounded,
  'savings': Icons.savings_rounded,
  'phone_iphone': Icons.phone_iphone_rounded,
  'celebration': Icons.celebration_rounded,
  'swap_horiz': Icons.swap_horiz_rounded,
};

IconData iconFor(String key) => kCategoryIcons[key] ?? Icons.category_rounded;

Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse(cleaned, radix: 16));
}

String colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}
