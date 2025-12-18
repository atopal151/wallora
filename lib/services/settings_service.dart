import '../services/database_service.dart';

/// Uygulama ayarlarını yöneten servis
/// Local veritabanı (sqflite) kullanarak ayarları saklar
class SettingsService {
  final DatabaseService _databaseService = DatabaseService();

  static const String _keyDarkMode = 'dark_mode';
  static const String _keyGridColumns = 'grid_columns';

  /// Dark mode durumunu alır
  Future<bool> getDarkMode() async {
    final value = await _databaseService.getSetting(_keyDarkMode);
    if (value == null) return false;
    return value == 'true';
  }

  /// Dark mode durumunu kaydeder
  Future<void> setDarkMode(bool value) async {
    await _databaseService.setSetting(_keyDarkMode, value.toString());
  }

  /// Grid sütun sayısını alır
  Future<int> getGridColumns() async {
    final value = await _databaseService.getSetting(_keyGridColumns);
    if (value == null) return 2;
    return int.tryParse(value) ?? 2;
  }

  /// Grid sütun sayısını kaydeder
  Future<void> setGridColumns(int columns) async {
    await _databaseService.setSetting(_keyGridColumns, columns.toString());
  }
}
