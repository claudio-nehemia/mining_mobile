# Peningkatan Error Handling

## Deskripsi
Dokumentasi ini menjelaskan peningkatan error handling di aplikasi mobile untuk menampilkan pesan error yang lebih detail dan informatif dari backend.

## Perbaikan yang Dilakukan

### 1. **Service Layer Error Handling**

#### CheckInService
- ✅ Menangkap detail error dari response backend
- ✅ Menampilkan validation errors jika ada
- ✅ Error message yang lebih deskriptif

#### CheckoutService
- ✅ Parse error message lengkap dari backend
- ✅ Menampilkan error seperti "belum ada biaya rute" dengan detail
- ✅ Menangani validation errors

#### HomeService (Turn On/Off Status)
- ✅ Detail error saat gagal mengubah status
- ✅ Informasi validation errors jika ada

#### SaldoService (Top Up)
- ✅ Error handling untuk request top up gagal
- ✅ Menampilkan alasan penolakan dari backend

### 2. **UI Error Display**

#### Dialog untuk Error Panjang
Jika error message lebih dari 80-100 karakter, akan ditampilkan dalam dialog dengan:
- Icon error yang jelas
- Title yang informatif
- Message lengkap yang bisa dibaca
- Tombol OK untuk menutup

#### SnackBar untuk Error Pendek
Error message pendek tetap ditampilkan di SnackBar dengan:
- Background merah untuk error
- Duration 4-5 detik untuk error (lebih lama dari success)
- Text yang mudah dibaca

### 3. **Fix Overflow Issue - Checkout Modal**

#### Dropdown Checkpoint
- ✅ Menggunakan `Expanded` widget untuk mencegah overflow
- ✅ `TextOverflow.ellipsis` untuk text yang terlalu panjang
- ✅ `maxLines: 1` untuk membatasi tinggi
- ✅ Nama checkpoint panjang akan dipotong dengan "..."

Contoh perbaikan:
```dart
child: Row(
  children: [
    Expanded(
      child: Text(
        '${checkpoint['name']} (${checkpoint['distance_text']})',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontSize: 14),
      ),
    ),
  ],
),
```

### 4. **Operasi dengan Error Handling Lengkap**

#### ✅ Check-In
- Gagal karena driver inactive → "Akun Anda sedang tidak aktif"
- Gagal karena di luar radius → "Anda berada di luar radius checkpoint"
- Gagal karena masih check-in → "Anda masih dalam status check-in di [nama]"
- GPS error → Detail error GPS

#### ✅ Checkout Request
- Gagal karena belum ada biaya rute → "Belum ada biaya rute dari [A] ke [B]"
- Gagal validasi → Detail field yang error
- Gagal karena saldo tidak cukup → "Saldo tidak mencukupi untuk biaya rute"

#### ✅ Toggle Status (On/Off)
- Gagal karena masih check-in → "Tidak dapat nonaktifkan saat masih check-in"
- Gagal karena network → Detail error koneksi
- Success → "Status berhasil diubah menjadi ON/OFF"

#### ✅ Top Up Request
- Gagal karena amount invalid → "Jumlah harus diisi" / "Minimal Rp 10.000"
- Gagal karena network → Detail error
- Success → "Request top up berhasil dikirim!"

### 5. **Backend Error Format**

Service layer sekarang bisa menangani error format dari backend:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "amount": ["Amount harus lebih dari 10000"],
    "checkpoint_id": ["Checkpoint tidak ditemukan"]
  }
}
```

Yang akan ditampilkan sebagai:
```
Validation failed: Amount harus lebih dari 10000, Checkpoint tidak ditemukan
```

## Testing

### Test Case yang Sudah Diperbaiki:

1. **Checkout tanpa biaya rute**
   - Backend: "Biaya rute belum diatur dari [checkpoint A] ke [checkpoint B]"
   - Mobile: Tampil di dialog dengan error lengkap ✅

2. **Check-in saat driver inactive**
   - Backend: "Akun Anda sedang tidak aktif. Silakan hubungi admin."
   - Mobile: Tampil di dialog/snackbar dengan error lengkap ✅

3. **Dropdown overflow**
   - Checkpoint dengan nama panjang → Dipotong dengan ellipsis ✅
   - Tidak ada text keluar dari box ✅

4. **Top up dengan amount invalid**
   - Validation error → Tampil sebelum submit ✅
   - Backend error → Tampil di dialog/snackbar ✅

## Manfaat

1. **User Experience Lebih Baik**
   - User tahu persis kenapa operasi gagal
   - User tahu apa yang harus dilakukan (hubungi admin, top up saldo, dll)

2. **Debugging Lebih Mudah**
   - Error detail membantu identifikasi masalah
   - Log error lebih informatif

3. **UI Lebih Rapi**
   - Tidak ada text overflow
   - Error display konsisten
   - Dialog untuk error panjang, snackbar untuk pendek

## Catatan Pengembangan

- Semua error dari backend harus format JSON dengan field `message` dan optional `errors`
- Error panjang (>80 karakter) tampil di dialog
- Error pendek (<80 karakter) tampil di snackbar
- Duration error display: 4-5 detik (lebih lama dari success: 2-3 detik)
