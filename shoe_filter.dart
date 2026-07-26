/// Critères de tri disponibles dans la liste de stock.
enum SortOption {
  recent('Modifiés récemment'),
  brandAsc('Marque (A → Z)'),
  quantityDesc('Quantité (décroissante)'),
  quantityAsc('Quantité (croissante)'),
  valueDesc('Valeur du stock'),
  profitDesc('Bénéfice potentiel');

  const SortOption(this.label);
  final String label;
}

/// État complet de la recherche + des filtres appliqués à la liste.
class ShoeFilter {
  final String search;
  final Set<String> brands;
  final Set<String> colors;
  final Set<double> sizes;
  final bool onlyLowStock;
  final SortOption sort;

  const ShoeFilter({
    this.search = '',
    this.brands = const {},
    this.colors = const {},
    this.sizes = const {},
    this.onlyLowStock = false,
    this.sort = SortOption.recent,
  });

  bool get hasFilters =>
      brands.isNotEmpty || colors.isNotEmpty || sizes.isNotEmpty || onlyLowStock;

  bool get hasSearch => search.trim().isNotEmpty;

  int get activeCount =>
      brands.length + colors.length + sizes.length + (onlyLowStock ? 1 : 0);

  ShoeFilter copyWith({
    String? search,
    Set<String>? brands,
    Set<String>? colors,
    Set<double>? sizes,
    bool? onlyLowStock,
    SortOption? sort,
  }) {
    return ShoeFilter(
      search: search ?? this.search,
      brands: brands ?? this.brands,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
      sort: sort ?? this.sort,
    );
  }

  /// Conserve la recherche et le tri, remet les filtres à zéro.
  ShoeFilter cleared() => ShoeFilter(search: search, sort: sort);
}
