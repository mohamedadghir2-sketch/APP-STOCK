import 'package:flutter/material.dart';

/// Seuil à partir duquel une référence est considérée en stock faible.
const int kLowStockThreshold = 3;

/// Symbole monétaire utilisé partout dans l'application.
/// Changez uniquement cette valeur pour passer en DH, CHF, $, etc.
const String kCurrencySymbol = '€';

/// Locale utilisée pour le formatage des nombres et des dates.
const String kLocale = 'fr_FR';

/// Rayon des cartes / conteneurs de l'application.
const double kRadius = 20;

/// Couleurs sémantiques (indépendantes du ColorScheme Material).
class StockColors {
  static const Color profit = Color(0xFF12866B);
  static const Color low = Color(0xFFE08700);
  static const Color out = Color(0xFFD32F2F);
  static const Color ok = Color(0xFF2E7D32);
}

/// Associe un nom de couleur (français ou anglais) à une couleur affichable,
/// utilisée pour la pastille de couleur des fiches produit.
Color? colorFromName(String name) {
  final n = name.trim().toLowerCase();
  const map = <String, Color>{
    'noir': Color(0xFF15171A),
    'black': Color(0xFF15171A),
    'blanc': Color(0xFFFAFAFA),
    'white': Color(0xFFFAFAFA),
    'gris': Color(0xFF9E9E9E),
    'grey': Color(0xFF9E9E9E),
    'gray': Color(0xFF9E9E9E),
    'rouge': Color(0xFFE53935),
    'red': Color(0xFFE53935),
    'bleu': Color(0xFF1E88E5),
    'blue': Color(0xFF1E88E5),
    'marine': Color(0xFF1A237E),
    'navy': Color(0xFF1A237E),
    'vert': Color(0xFF43A047),
    'green': Color(0xFF43A047),
    'jaune': Color(0xFFFDD835),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'rose': Color(0xFFEC407A),
    'pink': Color(0xFFEC407A),
    'violet': Color(0xFF8E24AA),
    'purple': Color(0xFF8E24AA),
    'marron': Color(0xFF6D4C41),
    'brown': Color(0xFF6D4C41),
    'beige': Color(0xFFD7C4A3),
    'crème': Color(0xFFEFE6D5),
    'creme': Color(0xFFEFE6D5),
    'or': Color(0xFFC9A227),
    'doré': Color(0xFFC9A227),
    'argent': Color(0xFFB0BEC5),
    'kaki': Color(0xFF7A7A46),
    'turquoise': Color(0xFF00ACC1),
  };
  for (final entry in map.entries) {
    if (n == entry.key) return entry.value;
  }
  for (final entry in map.entries) {
    if (n.contains(entry.key)) return entry.value;
  }
  return null;
}
