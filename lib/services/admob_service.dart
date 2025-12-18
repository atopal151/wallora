import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob servisi - Reklam yönetimi için
class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._();
  
  AdMobService._();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  int _wallpaperViewCount = 0;
  
  // Gerçek reklam ID'leri
  // Banner reklam ID'si
  static const String bannerAdId = 'ca-app-pub-6187422410732790/3330603782';
  
  // Interstitial (geçiş) reklam ID'si
  static const String interstitialAdId = 'ca-app-pub-6187422410732790/2129202758';
  
  /// Banner reklam ID'sini döndürür
  String getBannerAdId() {
    return bannerAdId;
  }
  
  /// Interstitial reklam ID'sini döndürür
  String getInterstitialAdId() {
    return interstitialAdId;
  }
  
  /// AdMob'u initialize eder
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      // İlk interstitial reklamı yükle
      _loadInterstitialAd();
    } catch (e) {
      // Plugin henüz hazır değilse veya hata varsa sessizce devam et
      // Bu durum genellikle tam rebuild gerektiğinde olur
      debugPrint('AdMob initialization failed: $e');
      debugPrint('Please do a full rebuild (not hot restart)');
    }
  }
  
  /// Interstitial reklam yükler
  void _loadInterstitialAd() {
    if (_interstitialLoadAttempts >= 3) {
      // 3 denemeden sonra durdur
      return;
    }
    
    InterstitialAd.load(
      adUnitId: getInterstitialAdId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          
          // Reklam kapatıldığında yeni reklam yükle
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          
          // Hata durumunda tekrar dene (max 3 kez)
          if (_interstitialLoadAttempts < 3) {
            Future.delayed(const Duration(seconds: 2), () {
              _loadInterstitialAd();
            });
          }
        },
      ),
    );
  }
  
  /// Wallpaper görüntüleme sayısını artırır ve gerekirse reklam gösterir
  /// Her 3 wallpaper görüntülemede bir reklam gösterilir
  void incrementWallpaperView() {
    _wallpaperViewCount++;
    
    // Her 3 görüntülemede bir reklam göster
    if (_wallpaperViewCount >= 3 && _interstitialAd != null) {
      _wallpaperViewCount = 0;
      _interstitialAd?.show();
    }
  }
  
  /// Manuel olarak interstitial reklam gösterir
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd?.show();
    } else {
      // Reklam yüklenmemişse yükle ve göster
      _loadInterstitialAd();
    }
  }
  
  /// Servisi temizler
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

