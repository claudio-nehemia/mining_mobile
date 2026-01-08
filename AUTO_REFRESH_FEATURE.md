# Fitur Auto-Refresh

## Deskripsi
Fitur auto-refresh memungkinkan aplikasi mobile untuk secara otomatis memperbarui data secara berkala tanpa perlu interaksi manual dari user.

## Fitur yang Diimplementasikan

### 1. **Auto-Refresh Timer**
- Data di-refresh secara otomatis setiap **10 detik**
- Berjalan di background tanpa mengganggu user experience
- Tidak menampilkan loading indicator saat refresh otomatis

### 2. **Data yang Di-refresh**
- ✅ **Saldo** - Otomatis update jika ada perubahan (top-up/potongan)
- ✅ **Status Check-in** - Deteksi perubahan status check-in/checkout
- ✅ **Status Checkout Request** - Monitor approval/rejection checkout
- ✅ **Riwayat Aktivitas** - Update history hari ini

### 3. **Smart Refresh Management**
- ⏸️ **Pause saat app di background** - Hemat battery dan data
- ▶️ **Resume saat app aktif** - Otomatis lanjut refresh
- 🛑 **Stop saat screen di-dispose** - Clean resource management

### 4. **Toggle Auto-Refresh**
- Icon di AppBar untuk enable/disable auto-refresh
- Icon `sync` (berputar/gold) = aktif
- Icon `sync_disabled` (abu-abu) = nonaktif
- Notifikasi saat toggle on/off

### 5. **Manual Refresh**
- Tombol refresh manual tetap tersedia
- Untuk refresh immediate jika diperlukan

## Konfigurasi

### Mengubah Interval Refresh
Edit di `lib/providers/home_provider.dart`:

```dart
static const Duration _refreshInterval = Duration(seconds: 10); // Ubah sesuai kebutuhan
```

### Menonaktifkan Auto-Refresh Default
Edit di `lib/providers/home_provider.dart`:

```dart
bool _isAutoRefreshEnabled = false; // Set false untuk disabled by default
```

## Logging

Untuk memonitor auto-refresh, perhatikan log berikut:

```
🔄 Starting auto-refresh (every 10s)
🔄 Auto-refreshing data...
💰 Saldo berubah: Rp 100000 -> Rp 90000
⏹️ Stopping auto-refresh
```

## Benefits

1. **User Experience** - Data selalu up-to-date tanpa interaksi manual
2. **Real-time Updates** - Perubahan saldo, status check-in, dll terdeteksi cepat
3. **Battery Efficient** - Pause otomatis saat app di background
4. **User Control** - User bisa disable jika tidak diperlukan

## Catatan Teknis

- Menggunakan `Timer.periodic` dari `dart:async`
- Implementasi `WidgetsBindingObserver` untuk lifecycle management
- Refresh dilakukan tanpa loading indicator untuk seamless UX
- Error handling tidak menampilkan error message agar tidak mengganggu
