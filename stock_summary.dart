/// Totaux calculés sur l'ensemble du stock.
class StockSummary {
  final int references;
  final int items;
  final double purchaseValue;
  final double saleValue;
  final int lowStockCount;
  final int outOfStockCount;

  const StockSummary({
    this.references = 0,
    this.items = 0,
    this.purchaseValue = 0,
    this.saleValue = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
  });

  static const StockSummary empty = StockSummary();

  /// Bénéfice potentiel si tout le stock est vendu au prix de vente.
  double get potentialProfit => saleValue - purchaseValue;

  /// Taux de marge global (% du prix d'achat).
  double get marginRate =>
      purchaseValue <= 0 ? 0 : (potentialProfit / purchaseValue) * 100;

  factory StockSummary.fromRow(Map<String, Object?> row) => StockSummary(
        references: (row['refs'] as num?)?.toInt() ?? 0,
        items: (row['items'] as num?)?.toInt() ?? 0,
        purchaseValue: (row['buy'] as num?)?.toDouble() ?? 0,
        saleValue: (row['sell'] as num?)?.toDouble() ?? 0,
        lowStockCount: (row['low'] as num?)?.toInt() ?? 0,
        outOfStockCount: (row['out'] as num?)?.toInt() ?? 0,
      );
}

/// Agrégat par marque, utilisé dans l'onglet Statistiques.
class BrandStat {
  final String brand;
  final int references;
  final int items;
  final double purchaseValue;
  final double saleValue;

  const BrandStat({
    required this.brand,
    required this.references,
    required this.items,
    required this.purchaseValue,
    required this.saleValue,
  });

  double get potentialProfit => saleValue - purchaseValue;

  factory BrandStat.fromRow(Map<String, Object?> row) => BrandStat(
        brand: (row['brand'] as String?) ?? '—',
        references: (row['refs'] as num?)?.toInt() ?? 0,
        items: (row['items'] as num?)?.toInt() ?? 0,
        purchaseValue: (row['buy'] as num?)?.toDouble() ?? 0,
        saleValue: (row['sell'] as num?)?.toDouble() ?? 0,
      );
}
