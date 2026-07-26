import '../utils/constants.dart';

/// Une référence du stock (une paire = marque + modèle + couleur + pointure).
class Shoe {
  final int? id;
  final String brand;
  final String model;
  final String color;
  final double size;
  final int quantity;
  final double purchasePrice;
  final double salePrice;

  /// Nom du fichier photo dans le dossier privé de l'app (voir [PhotoStorage]).
  final String? photo;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shoe({
    this.id,
    required this.brand,
    required this.model,
    required this.color,
    required this.size,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    this.photo,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shoe.empty() {
    final now = DateTime.now();
    return Shoe(
      brand: '',
      model: '',
      color: '',
      size: 40,
      quantity: 1,
      purchasePrice: 0,
      salePrice: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // --- Calculs financiers -------------------------------------------------

  /// Valeur immobilisée : prix d'achat × quantité.
  double get stockValue => purchasePrice * quantity;

  /// Chiffre d'affaires potentiel : prix de vente × quantité.
  double get potentialRevenue => salePrice * quantity;

  /// Bénéfice potentiel sur la ligne.
  double get potentialProfit => (salePrice - purchasePrice) * quantity;

  /// Marge unitaire.
  double get unitMargin => salePrice - purchasePrice;

  /// Taux de marge en % du prix d'achat.
  double get marginRate =>
      purchasePrice <= 0 ? 0 : (unitMargin / purchasePrice) * 100;

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity <= kLowStockThreshold;

  String get title => '$brand $model'.trim();

  // --- Sérialisation ------------------------------------------------------

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'brand': brand.trim(),
        'model': model.trim(),
        'color': color.trim(),
        'size': size,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'photo': photo,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Shoe.fromMap(Map<String, Object?> map) => Shoe(
        id: map['id'] as int?,
        brand: (map['brand'] as String?) ?? '',
        model: (map['model'] as String?) ?? '',
        color: (map['color'] as String?) ?? '',
        size: (map['size'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0,
        photo: map['photo'] as String?,
        note: map['note'] as String?,
        createdAt:
            DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  Shoe copyWith({
    int? id,
    String? brand,
    String? model,
    String? color,
    double? size,
    int? quantity,
    double? purchasePrice,
    double? salePrice,
    String? photo,
    bool clearPhoto = false,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shoe(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      photo: clearPhoto ? null : (photo ?? this.photo),
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
