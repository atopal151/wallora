class Wallpaper {
  final String id;
  final String thumb;
  final String fullImage;
  final int width;
  final int height;

  Wallpaper({
    required this.id,
    required this.thumb,
    required this.fullImage,
    required this.width,
    required this.height,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    // API'den gelen format için
    if (json.containsKey("thumbs") && json.containsKey("path")) {
      return Wallpaper(
        id: json["id"],
        thumb: json["thumbs"]["small"],
        fullImage: json["path"],
        width: json["dimension_x"],
        height: json["dimension_y"],
      );
    }
    // Veritabanından gelen format için
    return Wallpaper(
      id: json["id"],
      thumb: json["thumb"],
      fullImage: json["fullImage"],
      width: json["width"],
      height: json["height"],
    );
  }

  /// Modeli JSON formatına çevirir (veritabanına kaydetmek için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thumb': thumb,
      'fullImage': fullImage,
      'width': width,
      'height': height,
    };
  }
}

