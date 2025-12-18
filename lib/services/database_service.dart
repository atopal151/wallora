import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/wallpaper_model.dart';

/// Local veritabanı servisi
/// Favori duvar kağıtlarını SQLite veritabanında saklar
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Veritabanı instance'ını döndürür, yoksa oluşturur
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlatır ve tabloları oluşturur
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wallora.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id TEXT PRIMARY KEY,
            json_data TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  /// Favoriye ekler
  /// [wallpaper] eklenecek duvar kağıdı
  Future<void> addFavorite(Wallpaper wallpaper) async {
    final db = await database;
    final jsonData = jsonEncode(wallpaper.toJson());
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'favorites',
      {
        'id': wallpaper.id,
        'json_data': jsonData,
        'created_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Favoriden çıkarır
  /// [wallpaperId] çıkarılacak duvar kağıdının ID'si
  Future<void> removeFavorite(String wallpaperId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [wallpaperId],
    );
  }

  /// Tüm favorileri getirir
  /// [Wallpaper] listesi döndürür
  Future<List<Wallpaper>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      final jsonData = jsonDecode(maps[i]['json_data'] as String);
      return Wallpaper.fromJson(jsonData);
    });
  }

  /// Belirli bir duvar kağıdının favori olup olmadığını kontrol eder
  /// [wallpaperId] kontrol edilecek duvar kağıdının ID'si
  /// [bool] favori ise true, değilse false
  Future<bool> isFavorite(String wallpaperId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [wallpaperId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// Tüm favori ID'lerini getirir (hızlı kontrol için)
  /// [Set<String>] favori ID'lerinin set'i
  Future<Set<String>> getAllFavoriteIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      columns: ['id'],
    );

    return maps.map((map) => map['id'] as String).toSet();
  }

  /// Ayarları kaydeder
  /// [key] ayar anahtarı
  /// [value] ayar değeri (JSON string olarak saklanır)
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ayarları getirir
  /// [key] ayar anahtarı
  /// [String?] ayar değeri, yoksa null
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps[0]['value'] as String?;
  }

  /// Veritabanını kapatır
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

