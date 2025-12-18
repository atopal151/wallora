import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../models/wallpaper_model.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/animated_navbar.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/banner_ad_widget.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FavoritesScreenState> _favoritesScreenKey = GlobalKey<FavoritesScreenState>();
  final GlobalKey<SettingsScreenState> _settingsScreenKey = GlobalKey<SettingsScreenState>();
  
  List<Wallpaper> _wallpapers = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _isCheckingPermissions = false;
  List<String> _selectedCategories = [];
  int _currentNavIndex = 0;
  Set<String> _favorites = {}; // Favori duvar kağıtlarının ID'lerini tutar
  int _gridColumns = 2; // Grid sütun sayısı
  
  // Kategori listesi
  final List<String> _categories = [
    'nature',
    'city',
    'abstract',
    'anime',
    'space',
    'cars',
    'architecture',
    'minimalist',
    'dark',
    'landscape',
    'portrait',
    'art',
    'animals',
    'flowers',
    'ocean',
    'mountains',
    'sunset',
    'forest',
    'beach',
    'sky',
    'clouds',
    'water',
    'technology',
    'gaming',
    'music',
    'sports',
    'food',
    'travel',
    'vintage',
    'retro',
    'neon',
    'geometric',
    'patterns',
    'textures',
    'colors',
    'gradients',
    'winter',
    'summer',
    'autumn',
    'spring',
    'night',
    'morning',
    'urban',
    'rural',
    'fantasy',
    'sci-fi',
    'horror',
    'romantic',
    'calm',
    'energetic',
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadGridColumns();
    _checkAndRequestPermissions();
    _scrollController.addListener(_onScroll);
  }

  /// Grid sütun sayısını yükler
  Future<void> _loadGridColumns() async {
    final columns = await _settingsService.getGridColumns();
    setState(() {
      _gridColumns = columns;
    });
  }

  /// Veritabanından favorileri yükler
  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await _databaseService.getAllFavoriteIds();
      setState(() {
        _favorites = favoriteIds;
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Error loading favorites: $e');
    }
  }

  /// İlk açılışta izinleri kontrol et ve iste
  /// İzin durumuna göre ilk açılışı belirler (shared_preferences yerine)
  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    // İzin durumunu kontrol et - izin henüz verilmemişse iste
    if (Platform.isAndroid) {
      final isAndroid13Plus = await _isAndroid13OrHigher();
      final permission = isAndroid13Plus 
          ? Permission.photos 
          : Permission.storage;
      
      final status = await permission.status;
      // İzin henüz verilmemişse iste
      if (!status.isGranted) {
        await permission.request();
      }
    } else if (Platform.isIOS) {
      // iOS'ta sadece kaydetmek için photosAddOnly kullanıyoruz
      var status = await Permission.photosAddOnly.status;
      // İzin durumunu kontrol et
      if (status.isDenied) {
        // İzin henüz istenmemiş, iste
        status = await Permission.photosAddOnly.request();
      }
      // İzin kalıcı olarak reddedilmişse ayarlara yönlendir
      if (status.isPermanentlyDenied) {
        // Kullanıcıyı sessizce ayarlara yönlendir (ilk açılışta çok agresif olmamak için)
        // openAppSettings(); // İsteğe bağlı: otomatik açmak isterseniz
      }
    }

    setState(() {
      _isCheckingPermissions = false;
    });

    // İzinler kontrol edildikten sonra duvar kağıtlarını yükle
    _loadWallpapers(reset: true);
  }

  /// Android 13 (API 33) veya üstü kontrolü
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      const platform = MethodChannel('com.lunexo.app.system');
      final int sdkVersion = await platform.invokeMethod('getAndroidSdkVersion');
      return sdkVersion >= 33;
    } catch (e) {
      return true; // Hata durumunda varsayılan olarak yeni versiyon kabul et
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll listener - kullanıcı aşağı kaydırdıkça yeni sayfa yükler
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // %80'e ulaştığında yeni sayfa yükle
      if (!_isLoading && _hasMore) {
        _loadMoreWallpapers();
      }
    }
  }

  /// İlk sayfa ve sonraki sayfaları yükler
  Future<void> _loadWallpapers({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (reset) {
        _wallpapers.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final wallpapers = await api.fetchWallpapers(
        page: _currentPage,
        categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      );
      
      setState(() {
        if (reset) {
          _wallpapers = wallpapers;
        } else {
          _wallpapers.addAll(wallpapers);
        }
        _isLoading = false;
        // Eğer gelen veri 24'ten azsa (varsayılan sayfa boyutu), daha fazla yok demektir
        _hasMore = wallpapers.length >= 24;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Sonraki sayfayı yükler (infinite scroll)
  Future<void> _loadMoreWallpapers() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _currentPage++;
    });

    await _loadWallpapers();
  }

  /// Favorites screen'i yeniler (eğer açıksa)
  void _refreshFavoritesScreen() {
    if (_favoritesScreenKey.currentState != null) {
      _favoritesScreenKey.currentState!.loadFavorites();
    }
  }

  /// Favori durumunu değiştirir ve veritabanına kaydeder
  Future<void> _toggleFavorite(String wallpaperId) async {
    try {
      final isCurrentlyFavorite = _favorites.contains(wallpaperId);
      
      if (isCurrentlyFavorite) {
        // Favoriden çıkar
        await _databaseService.removeFavorite(wallpaperId);
        setState(() {
          _favorites.remove(wallpaperId);
        });
      } else {
        // Favoriye ekle
        final wallpaper = _wallpapers.firstWhere(
          (w) => w.id == wallpaperId,
          orElse: () => throw Exception('Wallpaper bulunamadı'),
        );
        await _databaseService.addFavorite(wallpaper);
        setState(() {
          _favorites.add(wallpaperId);
        });
      }
      
      // Favorites screen'i güncelle (eğer açıksa)
      _refreshFavoritesScreen();
      
      // Settings screen'i güncelle (favori sayısı değişti)
      if (_settingsScreenKey.currentState != null) {
        _settingsScreenKey.currentState!.refreshFavoriteCount();
      }
      
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favorite operation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Home Screen (Index 0)
          _buildHomeContent(),
          // Favorites Screen (Index 1)
          FavoritesScreen(
            key: _favoritesScreenKey,
            onFavoriteChanged: () {
              // Settings screen'i güncelle (favori sayısı değişti)
              if (_settingsScreenKey.currentState != null) {
                _settingsScreenKey.currentState!.refreshFavoriteCount();
              }
            },
          ),
          // Settings Screen (Index 2)
          SettingsScreen(
            key: _settingsScreenKey,
            onThemeChanged: () {
              widget.onThemeChanged?.call();
              // Grid columns değiştiyse yeniden yükle
              _loadGridColumns();
              // Favorites screen'i de güncelle
              if (_favoritesScreenKey.currentState != null) {
                _favoritesScreenKey.currentState!.refreshGridColumns();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: AnimatedNavBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
        ),
      ),
    );
  }

  /// Home screen içeriğini oluşturur
  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Wallora",
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
      body: Column(
        children: [
          _buildCategorySelector(),
          SizedBox(height: 10),
          Expanded(child: _buildBody()),
          const BannerAdWidget(),
        ],
      ),
    );
  }


  /// Kategoriye göre icon döndürür
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'nature':
        return Icons.forest;
      case 'city':
        return Icons.location_city;
      case 'abstract':
        return Icons.auto_awesome;
      case 'anime':
        return Icons.animation;
      case 'space':
        return Icons.rocket_launch;
      case 'cars':
        return Icons.directions_car;
      case 'architecture':
        return Icons.account_balance;
      case 'minimalist':
        return Icons.crop_free;
      case 'dark':
        return Icons.dark_mode;
      case 'landscape':
        return Icons.landscape;
      case 'portrait':
        return Icons.portrait;
      case 'art':
        return Icons.palette;
      case 'animals':
        return Icons.pets;
      case 'flowers':
        return Icons.local_florist;
      case 'ocean':
        return Icons.water;
      case 'mountains':
        return Icons.terrain;
      case 'sunset':
        return Icons.wb_twilight;
      case 'forest':
        return Icons.park;
      case 'beach':
        return Icons.beach_access;
      case 'sky':
        return Icons.cloud;
      case 'clouds':
        return Icons.cloud_queue;
      case 'water':
        return Icons.water_drop;
      case 'technology':
        return Icons.computer;
      case 'gaming':
        return Icons.sports_esports;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports_soccer;
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.flight;
      case 'vintage':
        return Icons.camera_alt;
      case 'retro':
        return Icons.radio;
      case 'neon':
        return Icons.lightbulb;
      case 'geometric':
        return Icons.shape_line;
      case 'patterns':
        return Icons.grid_view;
      case 'textures':
        return Icons.texture;
      case 'colors':
        return Icons.color_lens;
      case 'gradients':
        return Icons.gradient;
      case 'winter':
        return Icons.ac_unit;
      case 'summer':
        return Icons.wb_sunny;
      case 'autumn':
        return Icons.eco;
      case 'spring':
        return Icons.emoji_nature;
      case 'night':
        return Icons.nightlight;
      case 'morning':
        return Icons.wb_twilight;
      case 'urban':
        return Icons.apartment;
      case 'rural':
        return Icons.home;
      case 'fantasy':
        return Icons.stars;
      case 'sci-fi':
        return Icons.science;
      case 'horror':
        return Icons.masks;
      case 'romantic':
        return Icons.favorite;
      case 'calm':
        return Icons.spa;
      case 'energetic':
        return Icons.bolt;
      default:
        return Icons.category;
    }
  }

  /// Kategori seçim widget'ı
  Widget _buildCategorySelector() {
    return Container(
      height: 35,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategories.contains(category);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                  // Kategori değiştiğinde duvar kağıtlarını yeniden yükle
                  _loadWallpapers(reset: true);
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.only(left: 7, right: 14, top: 7, bottom: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? Colors.black : Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isCheckingPermissions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomLoadingIndicator(
              size: 40.0,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Checking permissions...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (_wallpapers.isEmpty && _isLoading) {
      return Center(
        child: CustomLoadingIndicator(
          size: 40.0,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null && _wallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Failed: $_errorMessage"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadWallpapers(reset: true);
              },
              child: const Text("Retry"),
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
    
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _wallpapers.length + (_hasMore ? 1 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, i) {
        // Son öğe loading indicator
        if (i >= _wallpapers.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CustomLoadingIndicator(
                size: 30.0,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        final wallpaper = _wallpapers[i];
        final isFavorite = _favorites.contains(wallpaper.id);
        
        return WallpaperCard(
          wallpaper: wallpaper,
          isFavorite: isFavorite,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  wallpapers: _wallpapers,
                  initialIndex: i,
                  onFavoriteChanged: () {
                    // Settings screen'i güncelle (favori sayısı değişti)
                    if (_settingsScreenKey.currentState != null) {
                      _settingsScreenKey.currentState!.refreshFavoriteCount();
                    }
                  },
                ),
              ),
            ).then((_) {
              // Detail screen'den dönünce favorites screen'i güncelle
              _refreshFavoritesScreen();
              // Favori listesini de güncelle
              _loadFavorites();
            });
          },
          onFavoriteTap: () {
            _toggleFavorite(wallpaper.id);
          },
        );
      },
    );
  }
}

