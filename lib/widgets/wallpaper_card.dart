import 'package:flutter/material.dart';
import '../models/wallpaper_model.dart';
import 'custom_loading_indicator.dart';

class WallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cihazın ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Kartın boyutunu ekran boyutuna göre hesapla
    // GridView'de 2 sütun olduğu için genişlik ekran genişliğinin yaklaşık yarısı
    final cardWidth = (screenWidth - 36) / 2; // 36 = padding (12*2) + spacing (12)
    // Yükseklik ekran yüksekliğine göre orantılı olarak ayarla
    final cardHeight = screenHeight * 0.35; // Ekran yüksekliğinin %35'i
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                wallpaper.thumb,
                fit: BoxFit.cover,
                width: cardWidth,
                height: cardHeight,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    color: Colors.grey[300],
                    child: Center(
                      child: CustomLoadingIndicator(
                        size: 30.0,
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
              // Tıklanabilir olduğunu gösteren overlay
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(),
                  ),
                ),
              ),
              // Favori ikonu
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onFavoriteTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite,
                        color: isFavorite ? Colors.red : Colors.white,
                        size:14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

