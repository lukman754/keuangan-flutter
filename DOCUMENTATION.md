# Panduan Proyek Flutter - Finance Tracker

## 1. Persiapan Instalasi
Berikut adalah langkah-langkah singkat untuk menyiapkan lingkungan pengembangan:

1. **Flutter SDK**: Unduh dan ekstrak Flutter SDK, lalu masukkan folder `bin` ke dalam PATH Environment Variables.
2. **IDE**: Gunakan VS Code atau Android Studio dengan ekstensi **Flutter** & **Dart** yang sudah terpasang.
3. **Android SDK**: Pastikan Command-line Tools dan SDK Platform sudah terinstall melalui Android Studio.
4. **Validasi**: Jalankan `flutter doctor` di terminal untuk memastikan semua setup sudah hijau/centang.

## 2. Cara Menjalankan Project
1. Buka folder proyek ini di terminal.
2. Jalankan perintah:
   ```bash
   flutter pub get
   ```
3. Hubungkan perangkat (HP/Emulator).
4. Jalankan aplikasi dengan:
   ```bash
   flutter run
   ```

## 3. Struktur Database (SQLite)
Aplikasi ini menggunakan database **SQLite** dengan struktur tabel sebagai berikut:

- **users**: Menyimpan data akun pengguna (id, name, email, password, timestamps).
- **categories**: Master data kategori transaksi (id, user_id, name, type [income/expense], icon, color).
- **budgets**: Pengaturan anggaran bulanan per kategori (id, user_id, category_id, amount, month, year).
- **transactions**: Catatan transaksi masuk dan keluar (id, user_id, category_id, amount, type, description, date).

## 4. Lokasi Penyimpanan Database
Nama file database: `finance_app.db`

Lokasi penyimpanan tergantung pada platform yang digunakan:
- **Android**: `/data/user/0/com.example.flutter_tugas_uas/databases/finance_app.db` (Hanya bisa diakses di perangkat yang di-root atau melalui File Explorer Android Studio).
- **Windows (Desktop)**: Biasanya tersimpan di folder data aplikasi lokal di dalam direktori user (`AppData/Local`).
- **Web**: Menggunakan penyimpanan browser (IndexedDB).

---
*Dibuat untuk dokumentasi tugas UAS Flutter.*
