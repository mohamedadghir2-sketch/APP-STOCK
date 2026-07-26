import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/shoe.dart';
import '../models/shoe_filter.dart';
import '../models/stock_summary.dart';
import '../utils/photo_storage.dart';

/// Source unique de vérité pour l'écran de stock.
class ShoeProvider extends ChangeNotifier {
  ShoeProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  List<Shoe> _shoes = [];
  StockSummary _summary = StockSummary.empty;
  List<BrandStat> _brandStats = [];
  List<Shoe> _lowStock = [];
  List<String> _brands = [];
  List<String> _colors = [];
  List<double> _sizes = [];
  ShoeFilter _filter = const ShoeFilter();
  bool _loading = true;
  Timer? _searchDebounce;

  // --- Lecture publique ---------------------------------------------------

  List<Shoe> get shoes => _shoes;
  StockSummary get summary => _summary;
  List<BrandStat> get brandStats => _brandStats;
  List<Shoe> get lowStock => _lowStock;
  List<String> get brands => _brands;
  List<String> get colors => _colors;
  List<double> get sizes => _sizes;
  ShoeFilter get filter => _filter;
  bool get loading => _loading;

  bool get isFiltered => _filter.hasFilters || _filter.hasSearch;
  bool get isEmptyStock => _summary.references == 0;

  /// Totaux de la sélection affichée (utile quand un filtre est actif).
  int get visibleItems => _shoes.fold(0, (sum, s) => sum + s.quantity);
  double get visiblePurchaseValue =>
      _shoes.fold<double>(0, (sum, s) => sum + s.stockValue);
  double get visibleSaleValue =>
      _shoes.fold<double>(0, (sum, s) => sum + s.potentialRevenue);
  double get visibleProfit => visibleSaleValue - visiblePurchaseValue;

  // --- Chargement ---------------------------------------------------------

  Future<void> refresh({bool showLoader = false}) async {
    if (showLoader) {
      _loading = true;
      notifyListeners();
    }
    final results = await Future.wait([
      _db.fetchShoes(_filter),
      _db.summary(),
      _db.distinctText('brand'),
      _db.distinctText('color'),
      _db.distinctSizes(),
      _db.brandStats(),
      _db.lowStock(),
    ]);
    _shoes = results[0] as List<Shoe>;
    _summary = results[1] as StockSummary;
    _brands = results[2] as List<String>;
    _colors = results[3] as List<String>;
    _sizes = results[4] as List<double>;
    _brandStats = results[5] as List<BrandStat>;
    _lowStock = results[6] as List<Shoe>;
    _loading = false;
    notifyListeners();
  }

  // --- Recherche & filtres ------------------------------------------------

  /// Recherche avec anti-rebond : on interroge la base 250 ms après la
  /// dernière frappe pour garder la saisie fluide.
  void search(String value) {
    _filter = _filter.copyWith(search: value);
    notifyListeners();
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 250), () => refresh());
  }

  void applyFilter(ShoeFilter filter) {
    _filter = filter;
    refresh();
  }

  void setSort(SortOption sort) {
    _filter = _filter.copyWith(sort: sort);
    refresh();
  }

  void toggleBrand(String brand) {
    final next = Set<String>.from(_filter.brands);
    next.contains(brand) ? next.remove(brand) : next.add(brand);
    applyFilter(_filter.copyWith(brands: next));
  }

  void toggleColor(String color) {
    final next = Set<String>.from(_filter.colors);
    next.contains(color) ? next.remove(color) : next.add(color);
    applyFilter(_filter.copyWith(colors: next));
  }

  void toggleSize(double size) {
    final next = Set<double>.from(_filter.sizes);
    next.contains(size) ? next.remove(size) : next.add(size);
    applyFilter(_filter.copyWith(sizes: next));
  }

  void clearFilters() => applyFilter(_filter.cleared());

  void clearSearch() {
    _filter = _filter.copyWith(search: '');
    refresh();
  }

  // --- Écriture -----------------------------------------------------------

  /// Crée ou met à jour une référence, puis rafraîchit l'écran.
  Future<int> save(Shoe shoe) async {
    final int id;
    if (shoe.id == null) {
      id = await _db.insertShoe(shoe);
    } else {
      await _db.updateShoe(shoe);
      id = shoe.id!;
    }
    await refresh();
    return id;
  }

  Future<void> delete(Shoe shoe) async {
    if (shoe.id == null) return;
    await _db.deleteShoe(shoe.id!);
    await PhotoStorage.delete(shoe.photo);
    await refresh();
  }

  /// Ajuste la quantité (+1 réassort, -1 vente) sans ouvrir le formulaire.
  Future<Shoe?> adjustQuantity(Shoe shoe, int delta) async {
    if (shoe.id == null) return null;
    final next = (shoe.quantity + delta).clamp(0, 99999);
    if (next == shoe.quantity) return shoe;
    await _db.updateQuantity(shoe.id!, next);
    await refresh();
    return _db.findById(shoe.id!);
  }

  Future<Shoe?> byId(int id) => _db.findById(id);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
