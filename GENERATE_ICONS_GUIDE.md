# Quick Start - Generate Icons

## 🚀 Langkah Cepat

### Windows
```cmd
generate_icons.bat
```

### Mac/Linux
```bash
chmod +x generate_icons.sh
./generate_icons.sh
```

### Manual
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter clean
```

## ✅ Setelah Generate

1. **Build & Install**
   ```bash
   flutter run
   ```

2. **Check Icon**
   - Lihat app icon di home screen
   - Pastikan logo tidak kepotong
   - Check di berbagai launcher styles (circle, rounded, square)

3. **Jika Logo Masih Kepotong**
   
   Pilihan A - Gunakan Python Script:
   ```bash
   pip install pillow
   python create_padded_logo.py
   ```
   Lalu update di `pubspec.yaml`:
   ```yaml
   image_path: "assets/logo_padded.png"
   ```
   
   Pilihan B - Edit Manual:
   - Buka `assets/logo.jpeg` di image editor
   - Tambahkan white space 20-25% di semua sisi
   - Save as PNG
   - Generate ulang icons

## 📱 Test Checklist

- [ ] Icon tampil di home screen
- [ ] Logo tidak kepotong
- [ ] Nama app "Nadya Loka Truck Tracking" tampil
- [ ] Icon terlihat jelas di berbagai ukuran
- [ ] Background konsisten (putih)

## 🔧 Troubleshooting

**Icon tidak update?**
```bash
flutter clean
flutter pub run flutter_launcher_icons
flutter run --uninstall-first
```

**Nama app tidak berubah?**
- Uninstall app lama dari device
- Install ulang
- Restart device (optional)

## 📝 Files yang Diupdate

✅ `pubspec.yaml` - Package name & description
✅ `android/app/src/main/AndroidManifest.xml` - Display name (Android)
✅ `ios/Runner/Info.plist` - Display name (iOS)
✅ Launcher icons configuration

## 💡 Tips

1. **Untuk Logo Optimal**: Logo harus memiliki padding/margin agar tidak kepotong di adaptive icons
2. **Safe Zone**: 66% tengah dari icon adalah safe zone, 33% luar bisa kepotong
3. **Background**: Gunakan solid color (putih) untuk konsistensi
4. **Format**: PNG lebih baik dari JPEG untuk icons
