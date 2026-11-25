import 'package:flutter/material.dart';

const List<String> categoriasLugar = [
  'Praia',
  'Montanha',
  'Cidade',
  'Centro histórico',
  'Parque',
  'Museu',
  'Restaurante',
  'Café',
  'Hospedagem',
  'Trilha',
  'Compras',
  'Outro',
];

IconData iconeCategoria(String categoria) {
  switch (categoria) {
    case 'Praia':
      return Icons.beach_access_outlined;
    case 'Montanha':
      return Icons.terrain_outlined;
    case 'Cidade':
      return Icons.location_city_outlined;
    case 'Centro histórico':
      return Icons.account_balance_outlined;
    case 'Parque':
      return Icons.park_outlined;
    case 'Museu':
      return Icons.museum_outlined;
    case 'Restaurante':
      return Icons.restaurant_outlined;
    case 'Café':
      return Icons.local_cafe_outlined;
    case 'Hospedagem':
    case 'Hotel':
      return Icons.hotel_outlined;
    case 'Trilha':
      return Icons.hiking_outlined;
    case 'Compras':
      return Icons.shopping_bag_outlined;
    case 'Outro':
      return Icons.place_outlined;
    default:
      return Icons.place_outlined;
  }
}
