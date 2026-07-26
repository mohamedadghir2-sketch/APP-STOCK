import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/shoe.dart';
import '../models/shoe_filter.dart';
import '../models/stock_summary.dart';
import '../utils/constants.dart';

/// Accès à la base SQLite locale (aucune connexion réseau nécessaire).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'stock_chaussures.db';
  static const int _dbVersion = 1;
  static const String table = 'shoes';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        brand          TEXT    NOT NULL,
        model          TEXT    NOT NULL,
        color          TEXT    NOT NULL,
        size           REAL    NOT NULL,
        quantity       INTEGER NOT NULL DEFAULT 0,
        purchase_price REAL    NOT NULL DEFAULT 0,
        sale_price     REAL    NOT NULL DEFAULT 0,
        photo          TEXT,
        note           TEXT,
        created_at     TEXT    NOT NULL,
        updated_at     TEXT    NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_shoes_brand ON $table(brand)');
    await db.execute('CREATE INDEX idx_shoes_color ON $table(color)');
    await db.execute('CREATE INDEX idx_shoes_size ON $table(size)');
    await db.execute('CREATE INDEX idx_shoes_model ON $table(model)');
  }

  /// Point d'entrée pour les futures migrations de schéma.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Exemple :
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $table ADD COLUMN supplier TEXT');
    // }
  }

  // --- Lecture ------------------------------------------------------------

  /// Liste filtrée, recherchée et triée.
  Future<List<Shoe>> fetchShoes(ShoeFilter filter) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    // Recherche multi-mots : chaque mot doit apparaître dans au moins un champ.
    if (filter.hasSearch) {
      final terms = filter.search.trim().toLowerCase().split(RegExp(r'\s+'));
      for (final term in terms) {
        where.add('(LOWER(brand) LIKE ? OR LOWER(model) LIKE ? '
            'OR LOWER(color) LIKE ? OR CAST(size AS TEXT) LIKE ?)');
        final like = '%$term%';
        args.addAll([like, like, like, like]);
      }
    }
    if (filter.brands.isNotEmpty) {
      where.add('brand IN (${_placeholders(filter.brands.length)})');
      args.addAll(filter.brands);
    }
    if (filter.colors.isNotEmpty) {
      where.add('color IN (${_placeholders(filter.colors.length)})');
      args.addAll(filter.colors);
    }
    if (filter.sizes.isNotEmpty) {
      where.add('size IN (${_placeholders(filter.sizes.length)})');
      args.addAll(filter.sizes);
    }
    if (filter.onlyLowStock) {
      where.add('quantity <= ?');
      args.add(kLowStockThreshold);
    }

    final rows = await db.query(
      table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: _orderBy(filter.sort),
    );
    return rows.map(Shoe.fromMap).toList();
  }

  Future<Shoe?> findById(int id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Shoe.fromMap(rows.first);
  }

  /// Valeurs distinctes d'une colonne texte (marques, couleurs, modèles).
  Future<List<String>> distinctText(String column) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT $column AS value FROM $table "
      "WHERE TRIM($column) <> '' ORDER BY value COLLATE NOCASE ASC",
    );
    return rows.map((r) => r['value'] as String).toList();
  }

  Future<List<double>> distinctSizes() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT size AS value FROM $table ORDER BY value ASC',
    );
    return rows.map((r) => (r['value'] as num).toDouble()).toList();
  }

  /// Totaux sur l'intégralité du stock.
  Future<StockSummary> summary() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*)                                         AS refs,
        COALESCE(SUM(quantity), 0)                       AS items,
        COALESCE(SUM(quantity * purchase_price), 0)      AS buy,
        COALESCE(SUM(quantity * sale_price), 0)          AS sell,
        COALESCE(SUM(CASE WHEN quantity > 0 AND quantity <= $kLowStockThreshold
                          THEN 1 ELSE 0 END), 0)         AS low,
        COALESCE(SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END), 0) AS out
      FROM $table
    ''');
    return StockSummary.fromRow(rows.first);
  }

  Future<List<BrandStat>> brandStats() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        brand,
        COUNT(*)                                    AS refs,
        COALESCE(SUM(quantity), 0)                  AS items,
        COALESCE(SUM(quantity * purchase_price), 0) AS buy,
        COALESCE(SUM(quantity * sale_price), 0)     AS sell
      FROM $table
      GROUP BY brand
      ORDER BY buy DESC, brand COLLATE NOCASE ASC
    ''');
    return rows.map(BrandStat.fromRow).toList();
  }

  /// Références à réapprovisionner (rupture d'abord).
  Future<List<Shoe>> lowStock({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: 'quantity <= ?',
      whereArgs: [kLowStockThreshold],
      orderBy: 'quantity ASC, brand COLLATE NOCASE ASC',
      limit: limit,
    );
    return rows.map(Shoe.fromMap).toList();
  }

  // --- Écriture -----------------------------------------------------------

  Future<int> insertShoe(Shoe shoe) async {
    final db = await database;
    final now = DateTime.now();
    return db.insert(
      table,
      shoe.copyWith(createdAt: now, updatedAt: now).toMap()..remove('id'),
    );
  }

  Future<int> updateShoe(Shoe shoe) async {
    final db = await database;
    return db.update(
      table,
      shoe.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [shoe.id],
    );
  }

  Future<int> updateQuantity(int id, int quantity) async {
    final db = await database;
    return db.update(
      table,
      {
        'quantity': quantity < 0 ? 0 : quantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteShoe(int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(table);
  }

  // --- Helpers ------------------------------------------------------------

  String _placeholders(int count) => List.filled(count, '?').join(', ');

  String _orderBy(SortOption sort) {
    switch (sort) {
      case SortOption.brandAsc:
        return 'brand COLLATE NOCASE ASC, model COLLATE NOCASE ASC, size ASC';
      case SortOption.quantityDesc:
        return 'quantity DESC, brand COLLATE NOCASE ASC';
      case SortOption.quantityAsc:
        return 'quantity ASC, brand COLLATE NOCASE ASC';
      case SortOption.valueDesc:
        return '(quantity * purchase_price) DESC';
      case SortOption.profitDesc:
        return '((sale_price - purchase_price) * quantity) DESC';
      case SortOption.recent:
        return 'updated_at DESC';
    }
  }
}
