# Wallora

Wallora, modern ve sade bir duvar kağıdı uygulamasıdır. Harici bir API'den JSON formatında duvar kağıdı verilerini alır ve bunları liste ve detay ekranlarında gösterir.

## Özellikler

- 📱 Modern ve sade kullanıcı arayüzü
- 🖼️ Grid formatında duvar kağıdı listesi
- 🔄 Pull-to-refresh ile yenileme
- 💾 Görsellerin önbelleklenmesi
- 📄 Detaylı duvar kağıdı görüntüleme
- ⚡ Hızlı ve stabil performans

## Nasıl Çalıştırılır?

1. Proje dizinine gidin:
```bash
cd ~/Desktop/project/wallora
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

## Release Build Oluşturma

### Android Release Build

#### 1. Keystore Oluşturma

İlk kez release build oluşturmadan önce bir keystore dosyası oluşturmanız gerekir:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Bu komut sizden şifre ve bilgiler isteyecektir. Bu bilgileri güvenli bir yerde saklayın.

#### 2. key.properties Dosyası Oluşturma

`android` klasöründe `key.properties` dosyası oluşturun:

```properties
storePassword=<keystore-şifreniz>
keyPassword=<key-şifreniz>
keyAlias=upload
storeFile=<keystore-dosya-yolu>
```

**ÖNEMLİ:** `key.properties` dosyasını Git'e commit etmeyin! Bu dosya `.gitignore`'a eklenmiştir.

#### 3. build.gradle.kts'i Güncelleme

`android/app/build.gradle.kts` dosyasında signing config'i güncelleyin. Şu anda debug signing kullanılıyor. Production için keystore kullanmak istiyorsanız, `build.gradle.kts` dosyasındaki yorumları takip edin.

#### 4. Release APK Oluşturma

```bash
flutter build apk --release
```

APK dosyası `build/app/outputs/flutter-apk/app-release.apk` konumunda oluşturulacaktır.

#### 5. App Bundle Oluşturma (Google Play Store için)

```bash
flutter build appbundle --release
```

AAB dosyası `build/app/outputs/bundle/release/app-release.aab` konumunda oluşturulacaktır.

### iOS Release Build

#### 1. Xcode'da Yapılandırma

1. Xcode'da `ios/Runner.xcworkspace` dosyasını açın
2. Runner target'ını seçin
3. "Signing & Capabilities" sekmesine gidin
4. "Automatically manage signing" seçeneğini işaretleyin
5. Team'inizi seçin

#### 2. Release Build Oluşturma

```bash
flutter build ios --release
```

#### 3. Archive ve Upload

1. Xcode'da Product > Archive seçeneğini kullanın
2. Archive tamamlandıktan sonra "Distribute App" butonuna tıklayın
3. App Store Connect'e yüklemek için talimatları takip edin

### Genel Release Kontrol Listesi

- [ ] Version numarasını `pubspec.yaml`'da kontrol edin (`version: 1.0.0+1`)
- [ ] Android keystore oluşturuldu ve güvenli bir yerde saklandı
- [ ] `key.properties` dosyası oluşturuldu (Git'e commit edilmedi)
- [ ] ProGuard rules dosyası kontrol edildi
- [ ] AndroidManifest.xml'de uygulama adı doğru
- [ ] iOS Info.plist'te gerekli izin açıklamaları mevcut
- [ ] AdMob App ID'leri doğru yapılandırıldı
- [ ] Test edildi: Release build'de uygulama düzgün çalışıyor

## API Endpoint Değiştirme

API endpoint'ini değiştirmek için `lib/utils/constants.dart` dosyasındaki `apiEndpoint` sabitini güncelleyin:

```dart
static const String apiEndpoint = "https://example.com/api/wallpapers.json";
```

Bu değer `lib/services/api_service.dart` dosyasında otomatik olarak kullanılır.

## JSON Formatı

Uygulama aşağıdaki JSON formatını bekler:

```json
{
  "status": "ok",
  "wallpapers": [
    {
      "id": "1",
      "title": "Sunset Beach",
      "image_url": "https://example.com/images/sunset.jpg",
      "author": "John Doe",
      "tags": ["sunset", "beach"]
    }
  ]
}
```

## Proje Yapısı

```
lib/
 ├─ main.dart                 # Uygulama giriş noktası
 ├─ app.dart                  # MaterialApp yapılandırması
 ├─ screens/
 │   ├─ home_screen.dart      # Ana ekran (liste)
 │   └─ detail_screen.dart    # Detay ekranı
 ├─ models/
 │   └─ wallpaper_model.dart  # Wallpaper model sınıfı
 ├─ services/
 │   └─ api_service.dart      # API servis sınıfı
 ├─ widgets/
 │   └─ wallpaper_card.dart   # Duvar kağıdı kart widget'ı
 └─ utils/
     └─ constants.dart        # Uygulama sabitleri
```

## Kullanılan Paketler

- `http` - API istekleri için
- `cached_network_image` - Görsellerin önbelleklenmesi için
- `flutter_staggered_grid_view` - Grid düzeni için
- `pull_to_refresh` - Yenileme özelliği için

## Lisans

Bu proje özel kullanım içindir.
