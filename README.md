# Finance Tracker

Aplikasi pencatatan keuangan pribadi yang dibangun menggunakan Flutter. Aplikasi ini dirancang untuk membantu pengguna mengelola pemasukan, pengeluaran, kategori transaksi, dan anggaran bulanan secara efisien dengan penyimpanan database lokal.

## 📱 Screenshots

Berikut adalah tampilan antarmuka aplikasi (2 kolom):

<div align="center">
  <table>
    <tr>
      <td><img src="https://github.com/user-attachments/assets/1226cd4b-bcb8-404b-9103-0ab42071e98c" width="100%" alt="Screen 1"/></td>
      <td><img src="https://github.com/user-attachments/assets/08122d85-323a-4db2-9e63-74f3b58ea639" width="100%" alt="Screen 2"/></td>
    </tr>
    <tr>
      <td><img src="https://github.com/user-attachments/assets/9a4bf31d-024e-4afb-a1f4-1909ec1a1951" width="100%" alt="Screen 3"/></td>
      <td><img src="https://github.com/user-attachments/assets/fec62f83-410c-44e8-87fe-6318272ea828" width="100%" alt="Screen 4"/></td>
    </tr>
    <tr>
      <td><img src="https://github.com/user-attachments/assets/a58ae812-7336-444e-99b1-7092ca8d0ae9" width="100%" alt="Screen 5"/></td>
      <td><img src="https://github.com/user-attachments/assets/7f37d66a-6ad7-465f-bf0f-d083baad9d0c" width="100%" alt="Screen 5"/></td>
    </tr>
  </table>
</div>

---

## ✨ Fitur Utama

- **Otentikasi Pengguna**: Sistem Login & Register dengan enkripsi password (SHA-256).
- **Manajemen Transaksi**: Mencatat pemasukan dan pengeluaran dengan detail tanggal dan deskripsi.
- **Kategori Dinamis**: Pengelompokan transaksi berdasarkan kategori dengan dukungan kustomisasi ikon dan warna.
- **Anggaran (Budgeting)**: Menetapkan batas anggaran bulanan per kategori untuk mengontrol pengeluaran.
- **Penyimpanan Lokal**: Menggunakan SQLite untuk performa offline yang cepat dan aman.

## 🚀 Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev)
- **Bahasa**: [Dart](https://dart.dev)
- **Database**: [sqflite](https://pub.dev/packages/sqflite) (SQLite)
- **State Management**: Local State & SharedPreferences
- **Fonts**: Google Fonts (Inter/Roboto)
- **Encryption**: Crypto (untuk hashing password)

## 🛠️ Instalasi & Persiapan

### Prasyarat
- Flutter SDK (Versi terbaru disarankan)
- Android Studio / VS Code dengan ekstensi Dart & Flutter
- Emulator Android atau perangkat fisik

### Langkah-langkah
1. **Clone Repository**
   ```bash
   git clone https://github.com/lukman754/keuangan-flutter.git
   cd keuangan-flutter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

## 📂 Struktur Database

Aplikasi menggunakan database `finance_app.db` dengan tabel berikut:
- `users`: Data akun pengguna.
- `categories`: Master kategori (Pemasukan/Pengeluaran).
- `budgets`: Pengaturan limit anggaran bulanan.
- `transactions`: Log aktivitas keuangan.

