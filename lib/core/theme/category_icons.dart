import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';

/// Set curado de íconos que el usuario puede elegir para una categoría
/// (RF03 ampliado) — no la librería completa de Material Icons, solo los
/// que tienen sentido para gastos de hogar. La key elegida se guarda en
/// `Categories.iconKey`.
const Map<String, IconData> kSelectableCategoryIcons = {
  'restaurant': Icons.restaurant_outlined,
  'fastfood': Icons.fastfood_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'local_grocery_store': Icons.local_grocery_store_outlined,
  'directions_car': Icons.directions_car_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'flight': Icons.flight_outlined,
  'home': Icons.home_outlined,
  'apartment': Icons.apartment_outlined,
  'bolt': Icons.bolt_outlined,
  'wifi': Icons.wifi,
  'theaters': Icons.theaters_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'movie': Icons.movie_outlined,
  'music_note': Icons.music_note_outlined,
  'sports_soccer': Icons.sports_soccer,
  'fitness_center': Icons.fitness_center_outlined,
  'favorite': Icons.favorite_border,
  'medical_services': Icons.medical_services_outlined,
  'spa': Icons.spa_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'checkroom': Icons.checkroom_outlined,
  'devices': Icons.devices_outlined,
  'pets': Icons.pets_outlined,
  'child_care': Icons.child_care_outlined,
  'school': Icons.school_outlined,
  'work': Icons.work_outline,
  'savings': Icons.savings_outlined,
  'credit_card': Icons.credit_card_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'celebration': Icons.celebration_outlined,
  'build': Icons.build_outlined,
  'category': Icons.category_outlined,
};

const kDefaultCategoryIconKey = 'category';

IconData iconForCategory(Category category) =>
    kSelectableCategoryIcons[category.iconKey] ?? Icons.category_outlined;
