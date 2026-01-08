# Nadya Loka Truck Tracking - App Configuration

## Nama Aplikasi
**Nadya Loka Truck Tracking**

## Perubahan yang Dilakukan

### 1. Update Nama Aplikasi
- ✅ Package name: `nadya_loka_truck_tracking`
- ✅ Display name: "Nadya Loka Truck Tracking"
- ✅ Description: "Nadya Loka Truck Tracking - Driver Mobile App"

### 2. Fix Logo Kepotong di Launcher Icon

#### Masalah
Logo kepotong di app launcher karena:
- Android Adaptive Icons memiliki "safe zone" 
- 33% dari icon bisa kepotong saat di-mask (circle, rounded square, dll)
- Logo original terlalu besar/penuh tanpa padding

#### Solusi
Konfigurasi `flutter_launcher_icons` dengan:
- `adaptive_icon_background`: Background putih (#FFFFFF)
- `adaptive_icon_foreground`: Logo akan otomatis di-scale oleh plugin
- `min_sdk_android`: 21 untuk support adaptive icons
- `remove_alpha_ios`: true untuk iOS optimization

### 3. Generate Launcher Icons

Jalankan command berikut untuk generate ulang icons:

```bash
# Install dependencies dulu (jika belum)
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

### 4. Files yang Diupdate

#### pubspec.yaml
- Package name: `nadya_loka_truck_tracking`
- Description: Updated
- flutter_launcher_icons configuration: Improved

#### AndroidManifest.xml
- `android:label`: "Nadya Loka Truck Tracking"

### 5. Struktur Icon yang Akan Digenerate

```
android/app/src/main/res/
├── mipmap-hdpi/
│   ├── ic_launcher.png (72x72)
│   └── ic_launcher_foreground.png
├── mipmap-mdpi/
│   ├── ic_launcher.png (48x48)
│   └── ic_launcher_foreground.png
├── mipmap-xhdpi/
│   ├── ic_launcher.png (96x96)
│   └── ic_launcher_foreground.png
├── mipmap-xxhdpi/
│   ├── ic_launcher.png (144x144)
│   └── ic_launcher_foreground.png
└── mipmap-xxxhdpi/
    ├── ic_launcher.png (192x192)
    └── ic_launcher_foreground.png

ios/Runner/Assets.xcassets/AppIcon.appiconset/
└── [Various iOS icon sizes]
```

## Cara Build & Test

### Android
```bash
# Debug build
flutter run

# Release build
flutter build apk --release

# Install ke device
flutter install
```

### iOS
```bash
# Debug build
flutter run

# Release build
flutter build ios --release
```

## Tips untuk Logo yang Tidak Kepotong

### Best Practices untuk Adaptive Icons:
1. **Logo harus berada di tengah**
2. **Gunakan padding minimal 20-25%** dari ukuran canvas
3. **Safe zone adalah 66% dari total area** (33% bisa kepotong)
4. **Background solid color** lebih aman daripada transparent

### Contoh Safe Zone:
```
┌─────────────────────────┐
│  ← 33% bisa kepotong →  │
│  ┌─────────────────┐    │
│  │                 │    │
│  │   Safe Zone     │    │
│  │   (66% area)    │    │
│  │                 │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

## Testing Checklist

Setelah generate icons, test di:
- ✅ Android phone (berbagai launcher: Nova, Samsung, Stock)
- ✅ Android tablet
- ✅ iOS iPhone
- ✅ iOS iPad

Periksa:
- [ ] Logo tidak kepotong di semua shapes (circle, rounded square, squircle)
- [ ] Logo terlihat jelas dan tidak blur
- [ ] Background konsisten
- [ ] Nama app tampil lengkap

## Troubleshooting

### Logo Masih Kepotong?
1. Buka `assets/logo.jpeg` di image editor
2. Tambahkan white padding 25% di semua sisi
3. Save as PNG untuk better quality
4. Update pubspec.yaml: `image_path: "assets/logo.png"`
5. Generate ulang: `flutter pub run flutter_launcher_icons`

### Nama App Terpotong?
- Android max: ~13 characters untuk ditampilkan penuh
- Gunakan abbreviation jika perlu di home screen
- Nama penuh tetap muncul di app drawer

### Icon Tidak Update?
```bash
# Clean build
flutter clean

# Generate ulang icons
flutter pub run flutter_launcher_icons

# Build ulang
flutter build apk --release
```

## Alternative: Manual Padding Logo

Jika plugin tidak memberikan hasil optimal, buat manual:

### Python Script (sudah disediakan):
```bash
# Install PIL jika belum
pip install pillow

# Run script
python create_padded_logo.py
```

Script akan create `assets/logo_padded.png` dengan padding otomatis.

### Manual di Image Editor:
1. Buka logo di Photoshop/GIMP
2. Canvas Size → Increase by 40% (20% each side)
3. Fill new space dengan white
4. Export as PNG
5. Update `image_path` di pubspec.yaml

## Resources
- [Flutter Launcher Icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons Guide](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
