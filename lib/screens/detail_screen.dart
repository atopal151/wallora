import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:wallora/widgets/custom_loading_indicator.dart';
import '../models/wallpaper_model.dart';
import '../services/database_service.dart';
import '../services/admob_service.dart';

/// Detay/Önizleme ekranı
/// Seçilen duvar kağıdının tam görünümünü gösterir
class DetailScreen extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final int initialIndex;
  final VoidCallback? onFavoriteChanged;

  const DetailScreen({
    super.key,
    required this.wallpapers,
    this.initialIndex = 0,
    this.onFavoriteChanged,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isApplying = false;
  final DatabaseService _databaseService = DatabaseService();
  Map<String, bool> _favoriteStatus = {}; // Her wallpaper için favori durumu

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadFavoriteStatuses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  /// Sayfa değiştiğinde çağrılır - reklam gösterimi için
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Her wallpaper görüntülemede sayacı artır ve gerekirse reklam göster
    AdMobService.instance.incrementWallpaperView();
  }

  /// Tüm wallpaper'ların favori durumunu kontrol eder
  Future<void> _loadFavoriteStatuses() async {
    for (var wallpaper in widget.wallpapers) {
      final isFav = await _databaseService.isFavorite(wallpaper.id);
      _favoriteStatus[wallpaper.id] = isFav;
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Mevcut wallpaper'ın favori durumunu kontrol eder
  bool _isFavorite() {
    if (_currentIndex >= 0 && _currentIndex < widget.wallpapers.length) {
      return _favoriteStatus[widget.wallpapers[_currentIndex].id] ?? false;
    }
    return false;
  }

  /// Mevcut wallpaper'ı döndürür
  Wallpaper get _currentWallpaper {
    if (_currentIndex >= 0 && _currentIndex < widget.wallpapers.length) {
      return widget.wallpapers[_currentIndex];
    }
    return widget.wallpapers[0];
  }

  /// Favoriye ekler veya çıkarır
  Future<void> _toggleFavorite() async {
    try {
      final wallpaper = _currentWallpaper;
      final isCurrentlyFavorite = _favoriteStatus[wallpaper.id] ?? false;

      if (isCurrentlyFavorite) {
        await _databaseService.removeFavorite(wallpaper.id);
      } else {
        await _databaseService.addFavorite(wallpaper);
      }
      
      // Settings screen'i güncelle (favori sayısı değişti)
      widget.onFavoriteChanged?.call();
      
      if (mounted) {
        setState(() {
          _favoriteStatus[wallpaper.id] = !isCurrentlyFavorite;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce başarısız olur
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white,size: 20,),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // PageView - Sadece görselleri içerir
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.wallpapers.length,
            itemBuilder: (context, index) {
              final wallpaper = widget.wallpapers[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;

                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: SizedBox(
                      width: screenWidth,
                      height: screenHeight,
                      child: CachedNetworkImage(
                        imageUrl: wallpaper.fullImage,
                        fit: BoxFit.cover,
                        width: screenWidth,
                        height: screenHeight,
                        placeholder:
                            (context, url) => Container(
                              width: screenWidth,
                              height: screenHeight,
                              color: Colors.grey[900],
                              child: const Center(
                                child: CustomLoadingIndicator(
                                  size: 40.0,
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              width: screenWidth,
                              height: screenHeight,
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Alt bilgi paneli - Sabit kalır, PageView'in dışında
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Info butonu
                    InkWell(
                      onTap: () => _showWallpaperInfo(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Apply butonu
                    InkWell(
                      onTap:
                          _isApplying
                              ? null
                              : () => _showWallpaperOptions(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 54,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isApplying)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CustomLoadingIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                             
                            Text(
                              _isApplying ? '' : 'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Favori butonu
                    InkWell(
                      onTap: _toggleFavorite,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.favorite,
                          color: _isFavorite() ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Görsel bilgilerini gösteren bottom sheet
  void _showWallpaperInfo(BuildContext context) {
    final wallpaper = _currentWallpaper;
    // Dosya boyutunu hesapla (yaklaşık)
    final fileSizeMB = ((wallpaper.width * wallpaper.height * 3) /
            (1024 * 1024))
        .toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Wallpaper Information',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info items
                    _buildInfoItem(
                      context: context,
                      icon: Icons.aspect_ratio,
                      label: 'Resolution',
                      value: '${wallpaper.width} × ${wallpaper.height}',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context: context,
                      icon: Icons.tag,
                      label: 'ID',
                      value: wallpaper.id,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context: context,
                      icon: Icons.storage,
                      label: 'Estimated Size',
                      value: '$fileSizeMB MB',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context: context,
                      icon: Icons.link,
                      label: 'Image URL',
                      value: wallpaper.fullImage,
                      isUrl: true,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /// Bilgi öğesi widget'ı
  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isUrl = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (isUrl)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'URL copied to clipboard',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Duvar kağıdı seçeneklerini gösteren dialog
  void _showWallpaperOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Where to Apply Wallpaper?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Options
                    _buildOptionCard(
                      context: context,
                      icon: Icons.lock_outline,
                      title: 'Lock Screen Only',
                      subtitle: 'Apply to lock screen',
                      onTap: () {
                        Navigator.pop(context);
                        _applyWallpaper(1); // LOCK_SCREEN
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      context: context,
                      icon: Icons.home_outlined,
                      title: 'Home Screen Only',
                      subtitle: 'Apply to home screen',
                      onTap: () {
                        Navigator.pop(context);
                        _applyWallpaper(2); // HOME_SCREEN
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      context: context,
                      icon: Icons.phone_android_outlined,
                      title: 'Both Screens',
                      subtitle: 'Apply to both screens',
                      onTap: () {
                        Navigator.pop(context);
                        _applyWallpaper(3); // BOTH_SCREENS
                      },
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /// Seçenek kartı widget'ı
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isHighlighted
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border:
                isHighlighted
                    ? Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Duvar kağıdını uygular
  Future<void> _applyWallpaper(int screen) async {
    setState(() {
      _isApplying = true;
    });

    try {
      final wallpaper = _currentWallpaper;
      // Platform kontrolü
      if (Platform.isAndroid) {
        // Android için izin kontrolü (Android 13+ için READ_MEDIA_IMAGES, eski versiyonlar için storage)
        final permission =
            await _isAndroid13OrHigher()
                ? Permission
                    .photos // Android 13+ için READ_MEDIA_IMAGES
                : Permission.storage; // Android 12 ve altı için

        var status = await permission.status;
        if (!status.isGranted) {
          status = await permission.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Gallery permission required. Please grant permission from settings.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      openAppSettings();
                    },
                  ),
                ),
              );
            }
            setState(() {
              _isApplying = false;
            });
            return;
          }
        }

        // Görseli indir
        final response = await http.get(Uri.parse(wallpaper.fullImage));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }

        // Görsel verisinin geçerli olduğunu kontrol et
        if (response.bodyBytes.isEmpty) {
          throw Exception('Image data is empty');
        }

        // Android wallpaper boyutlarını al
        const systemChannel = MethodChannel('com.lunexo.app.system');
        Map<String, dynamic> wallpaperDimensions;
        try {
          wallpaperDimensions = await systemChannel.invokeMethod(
            'getWallpaperDimensions',
          );
        } catch (e) {
          // Hata durumunda ekran boyutlarını kullan
          final mediaQuery = MediaQuery.of(context);
          wallpaperDimensions = {
            'width':
                (mediaQuery.size.width * mediaQuery.devicePixelRatio).toInt(),
            'height':
                (mediaQuery.size.height * mediaQuery.devicePixelRatio).toInt(),
          };
        }

        final targetWidth = wallpaperDimensions['width'] as int;
        final targetHeight = wallpaperDimensions['height'] as int;

        // Ağdan gelen veriyi ana izoleyi kilitlemeden işlemek için compute kullan
        final croppedBytes = await compute(
          _processImageForWallpaper,
          _ProcessImageParams(
            bytes: response.bodyBytes,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
          ),
        );

        // Android için görseli galeriye kaydet (opsiyonel - kullanıcı galeriye de kaydedebilir)
        try {
          await ImageGallerySaver.saveImage(
            croppedBytes,
            quality: 100,
            name: 'wallpaper_${wallpaper.id}',
          );
        } catch (e) {
          // Galeriye kaydetme hatası wallpaper uygulamayı engellemez
          debugPrint('Failed to save to gallery: $e');
        }

        // Geçici dosyaya kaydet ve dosya yolunu kullan
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          path.join(
            tempDir.path,
            'wallpaper_${wallpaper.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
        await tempFile.writeAsBytes(croppedBytes);

        // Android için platform channel ile duvar kağıdını uygula
        const platform = MethodChannel('com.lunexo.app.wallpaper');
        try {
          await platform.invokeMethod('setWallpaper', {
            'path': tempFile.path,
            'screen': screen,
          });

          // Geçici dosyayı temizle
          try {
            await tempFile.delete();
          } catch (e) {
            // Dosya silme hatası kritik değil
            debugPrint('Failed to delete temp file: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallpaper applied successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } on PlatformException catch (e) {
          // Hata durumunda da geçici dosyayı temizlemeyi dene
          try {
            await tempFile.delete();
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to apply wallpaper: ${e.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (Platform.isIOS) {
        // Görseli indir
        final response = await http.get(Uri.parse(wallpaper.fullImage));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }

        // Görsel verisinin geçerli olduğunu kontrol et
        if (response.bodyBytes.isEmpty) {
          throw Exception('Image data is empty');
        }

        // iOS için sadece galeriye kaydet (iOS'ta programatik duvar kağıdı uygulama mümkün değil)
        // iOS için izin kontrolü - sadece kaydetmek için photosAddOnly kullanıyoruz
        var status = await Permission.photosAddOnly.status;
        
        // İzin durumunu kontrol et
        if (status.isDenied) {
          // İzin henüz istenmemiş, iste
          status = await Permission.photosAddOnly.request();
        }
        
        // İzin verilmemişse (kalıcı red veya normal red) kullanıcıyı bilgilendir
        if (!status.isGranted && !status.isLimited) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Photo permission required. Please grant permission from settings.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () {
                    openAppSettings();
                  },
                ),
              ),
            );
          }
          setState(() {
            _isApplying = false;
          });
          return;
        }

        // Kaydetmeyi dene (izin verilmiş veya sınırlı erişim verilmişse)
        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 100,
          name: 'wallpaper_${wallpaper.id}',
        );

        // Hata kontrolü - image_gallery_saver kendi izin kontrolünü yapıyor olabilir
        if (result['errorMessage'] != null) {
          final errorMsg = result['errorMessage'] as String;
          // İzin hatası olup olmadığını kontrol et
          if (errorMsg.toLowerCase().contains('permission') || 
              errorMsg.toLowerCase().contains('authorized') ||
              errorMsg.toLowerCase().contains('denied')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Photo permission required. Please grant permission from settings.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      openAppSettings();
                    },
                  ),
                ),
              );
            }
            setState(() {
              _isApplying = false;
            });
            return;
          }
          throw Exception('Failed to save image: $errorMsg');
        }

        if (result['isSuccess'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image saved to gallery. Please set it as wallpaper from the Photos app.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception('Failed to save image');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }
  /// Android 13 (API 33) veya üstü kontrolü
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      const platform = MethodChannel('com.lunexo.app.system');
      final int sdkVersion = await platform.invokeMethod(
        'getAndroidSdkVersion',
      );
      return sdkVersion >= 33;
    } catch (e) {
      // Hata durumunda varsayılan olarak yeni versiyon kabul et
      return true;
    }
  }
}

/// Compute için parametre modeli
class _ProcessImageParams {
  final Uint8List bytes;
  final int targetWidth;
  final int targetHeight;

  const _ProcessImageParams({
    required this.bytes,
    required this.targetWidth,
    required this.targetHeight,
  });
}

/// Ağdan gelen görseli ana izoleyi kilitlemeden kırpıp encode eder
Uint8List _processImageForWallpaper(_ProcessImageParams params) {
  final originalImage = img.decodeImage(params.bytes);
  if (originalImage == null) {
    throw Exception('Failed to decode image');
  }

  final croppedImage = _cropImageToFitIsolate(
    originalImage,
    params.targetWidth,
    params.targetHeight,
  );

  return Uint8List.fromList(
    img.encodeJpg(croppedImage, quality: 95),
  );
}

/// BoxFit.cover mantığıyla merkezden kırpma (isolate içinde çalışır)
img.Image _cropImageToFitIsolate(
  img.Image originalImage,
  int targetWidth,
  int targetHeight,
) {
  final originalWidth = originalImage.width;
  final originalHeight = originalImage.height;

  final originalAspect = originalWidth / originalHeight;
  final targetAspect = targetWidth / targetHeight;

  if (originalAspect > targetAspect) {
    final scale = targetHeight / originalHeight;
    final sourceWidth = (targetWidth / scale).round();
    final x = (originalWidth - sourceWidth) ~/ 2;

    final cropped = img.copyCrop(
      originalImage,
      x: x,
      y: 0,
      width: sourceWidth,
      height: originalHeight,
    );

    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  } else {
    final scale = targetWidth / originalWidth;
    final sourceHeight = (targetHeight / scale).round();
    final y = (originalHeight - sourceHeight) ~/ 2;

    final cropped = img.copyCrop(
      originalImage,
      x: 0,
      y: y,
      width: originalWidth,
      height: sourceHeight,
    );

    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }
}
