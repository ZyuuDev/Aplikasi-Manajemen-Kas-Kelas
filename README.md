# Aplikasi Manajemen Kas Kelas

Aplikasi ini adalah proyek Flutter untuk membantu mengelola kas kelas secara lebih rapi, cepat, dan transparan. Dengan aplikasi ini, pengguna dapat mencatat pemasukan, pengeluaran, saldo kas, dan riwayat transaksi dalam satu tempat.

> Proyek ini dibangun menggunakan Flutter dan Dart, sehingga dapat dikembangkan menjadi aplikasi Android, iOS, web, maupun desktop sesuai kebutuhan.

## Tujuan Proyek

Tujuan utama dari aplikasi ini adalah:

- memudahkan pengelolaan uang kas kelas,
- mengurangi pencatatan manual di buku,
- membantu bendahara kelas melihat data keuangan dengan jelas,
- menjaga transparansi pemasukan dan pengeluaran,
- meminimalkan kesalahan pencatatan.

## Fitur Utama

Berikut fitur yang bisa dikembangkan atau sudah disiapkan dalam proyek ini:

- pencatatan iuran kas siswa,
- pencatatan pengeluaran kas,
- tampilan saldo kas terkini,
- riwayat transaksi pemasukan dan pengeluaran,
- rekap data kas,
- antarmuka yang sederhana dan mudah digunakan,
- struktur proyek Flutter yang siap dikembangkan lebih lanjut.

## Teknologi yang Digunakan

- Flutter
- Dart
- Material Design

## Cara Instalasi dari Nol

Ikuti langkah berikut untuk menjalankan proyek ini dari awal sampai siap digunakan.

### 1. Persiapkan kebutuhan dasar

Pastikan perangkat kamu sudah memiliki:

- **Git**
- **Flutter SDK**
- **Dart**  
  Biasanya sudah termasuk di Flutter SDK.
- **Android Studio** atau **VS Code**
- Emulator Android / perangkat fisik

### 2. Install Flutter

Jika Flutter belum terpasang:

1. Download Flutter SDK dari:
   https://docs.flutter.dev/get-started/install
2. Ekstrak Flutter ke folder yang mudah diakses.
3. Tambahkan Flutter ke `PATH`.
4. Jalankan perintah berikut untuk memastikan instalasi berhasil:

```bash
flutter doctor
```

Jika ada komponen yang belum lengkap, ikuti saran dari `flutter doctor` sampai semua kebutuhan utama siap.

### 3. Clone repository

Buka terminal lalu jalankan:

```bash
git clone https://github.com/ZyuuDev/Aplikasi-Manajemen-Kas-Kelas.git
cd Aplikasi-Manajemen-Kas-Kelas
```

### 4. Ambil dependency

Setelah masuk ke folder proyek, jalankan:

```bash
flutter pub get
```

Perintah ini akan mengunduh semua package yang dibutuhkan oleh aplikasi.

### 5. Jalankan aplikasi

Pastikan emulator atau perangkat sudah aktif, lalu jalankan:

```bash
flutter run
```

Jika ingin memilih device tertentu:

```bash
flutter devices
flutter run -d <device_id>
```

## Setup Tambahan yang Mungkin Diperlukan

Kalau kamu ingin melakukan pengembangan lebih lanjut, pastikan:

- Android emulator sudah dibuat di Android Studio,
- iOS simulator tersedia jika menggunakan macOS,
- project sudah dibuka di editor favorit seperti VS Code,
- semua file konfigurasi Flutter tidak mengalami error.

## Struktur Proyek

Secara umum, struktur proyek Flutter biasanya berisi:

- `lib/` → source code utama aplikasi,
- `android/` → konfigurasi Android,
- `ios/` → konfigurasi iOS,
- `web/` → konfigurasi web,
- `assets/` → gambar atau file statis jika digunakan,
- `pubspec.yaml` → daftar package dan aset proyek.

## Alur Penggunaan Aplikasi

Contoh alur penggunaan aplikasi ini:

1. Pengguna membuka aplikasi.
2. Pengguna melihat dashboard atau halaman utama.
3. Bendahara menambahkan transaksi kas masuk.
4. Bendahara mencatat pengeluaran jika ada kebutuhan kelas.
5. Sistem menampilkan saldo terbaru.
6. Semua transaksi tersimpan sebagai riwayat.

## Pengembangan Selanjutnya

Beberapa fitur tambahan yang bisa ditambahkan ke proyek ini:

- login untuk bendahara atau admin,
- data siswa per kelas,
- notifikasi pembayaran kas,
- export data ke PDF atau Excel,
- grafik pemasukan dan pengeluaran,
- backup dan restore data,
- penyimpanan lokal atau cloud database,
- filter transaksi berdasarkan tanggal.

## Catatan

Saat ini repository ini masih dapat dikembangkan lebih lanjut sesuai kebutuhan proyek sekolah atau organisasi kelas. README ini dibuat agar lebih jelas, informatif, dan siap dipakai sebagai dokumentasi awal proyek.

## Referensi Flutter

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Codelabs](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

## License

Tambahkan lisensi sesuai kebutuhan proyek jika diperlukan.
