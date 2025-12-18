import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper_model.dart';
import '../utils/constants.dart';

class ApiService {
  /// Belirli bir sayfadan duvar kağıtlarını getirir
  /// [page] sayfa numarası (1'den başlar)
  /// [categories] seçilen kategoriler listesi (örn: ["nature", "city"])
  /// Her sayfa için farklı rastgele sonuçlar için seed kullanılır
  Future<List<Wallpaper>> fetchWallpapers({
    int page = 1,
    List<String>? categories,
  }) async {
    // Her sayfa için farklı seed değeri ile daha karışık sonuçlar
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    
    String urlString = "${AppConstants.defaultSearchQuery}&page=$page&seed=$seed";
    
    // Eğer kategoriler seçilmişse, query parametresine ekle
    if (categories != null && categories.isNotEmpty) {
      final categoryQuery = categories.join("+");
      urlString += "&q=$categoryQuery";
    }
    
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {
          "X-API-Key": AppConstants.wallhavenApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["data"] != null) {
          return (data["data"] as List)
              .map((e) => Wallpaper.fromJson(e))
              .toList();
        } else {
          throw Exception("API response format unexpected.");
        }
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch wallpapers: $e");
    }
  }
}

