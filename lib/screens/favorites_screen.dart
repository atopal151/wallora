import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../models/wallpaper_model.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/banner_ad_widget.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onFavoriteChanged;
  
  const FavoritesScreen({super.key, this.onFavoriteChanged});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  List<Wallpaper> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _gridColumns = 2;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadGridColumns();
  }

  /// Grid sütun sayısını yükler
  Future<void> _loadGridColumns() async {
    final columns = await _settingsService.getGridColumns();
    if (mounted) {
      setState(() {
        _gridColumns = columns;
      });
    }
  }

  /// Grid columns'u günceller (dışarıdan çağrılabilir)
  Future<void> refreshGridColumns() async {
    await _loadGridColumns();
  }

  /// Veritabanından favorileri yükler (public metod - dışarıdan çağrılabilir)
  Future<void> loadFavorites() async {
    await _loadFavorites();
  }

  /// Veritabanından favorileri yükler (internal)
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await _databaseService.getAllFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Favoriden çıkarır ve listeyi yeniler
  Future<void> _removeFavorite(String wallpaperId) async {
    try {
      await _databaseService.removeFavorite(wallpaperId);
      // Listeyi yeniden yükle
      await _loadFavorites();
      // Settings screen'i güncelle (favori sayısı değişti)
      widget.onFavoriteChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Favorites",
          style: GoogleFonts.pacifico(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CustomLoadingIndicator(
          size: 40.0,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error: $_errorMessage",
              style: GoogleFonts.inter(fontSize: 13.75, color: Colors.grey[600], fontWeight: FontWeight.w500,),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadFavorites();
              },
              child: Text("Retry", style: GoogleFonts.inter(fontSize: 13.75, color: Colors.grey[600], fontWeight: FontWeight.w500,)),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Text(
              "No favorite wallpapers yet",
              style: GoogleFonts.inter(
                fontSize: 13.75,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add wallpapers you like to favorites",
              style: GoogleFonts.inter(
                fontSize: 13.75,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Cihazın ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Grid sütun sayısına göre kartın boyutunu hesapla
    final padding = 12.0;
    final spacing = 12.0;
    final totalPadding = padding * 2;
    final totalSpacing = spacing * (_gridColumns - 1);
    final cardWidth = (screenWidth - totalPadding - totalSpacing) / _gridColumns;
    final cardHeight = screenHeight * 0.35; // Ekran yüksekliğinin %35'i
    final aspectRatio = cardWidth / cardHeight;

    return Column(
      children: [
        Expanded(
          child: CustomRefreshIndicator(
            onRefresh: () async {
              await _loadFavorites();
              await _loadGridColumns();
            },
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _favorites.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                final wallpaper = _favorites[index];
                
                return WallpaperCard(
                  wallpaper: wallpaper,
                  isFavorite: true, // Favorites screen'de hepsi favori
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          wallpapers: _favorites,
                          initialIndex: index,
                          onFavoriteChanged: () {
                            // Settings screen'i güncelle (favori sayısı değişti)
                            widget.onFavoriteChanged?.call();
                          },
                        ),
                      ),
                    ).then((_) {
                      // Detail screen'den dönünce favorileri yeniden yükle
                      // (kullanıcı favoriden çıkarmış olabilir)
                      _loadFavorites();
                    });
                  },
                  onFavoriteTap: () {
                    _removeFavorite(wallpaper.id);
                  },
                );
              },
            ),
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}

