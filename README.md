# SakuKelas Bendahara (Aplikasi Mobile)

SakuKelas Bendahara adalah aplikasi mobile berbasis **Flutter** yang dirancang khusus sebagai "Pusat Kendali" bagi Bendahara Kelas untuk mengelola uang kas kelas secara lebih cepat, terstruktur, dan transparan. 

Aplikasi ini memiliki hak akses penuh (**CRUD**) untuk mengelola data siswa, mencatat iuran kas masuk, serta mengunggah bukti pengeluaran langsung menggunakan kamera perangkat.

---

## 🚀 Fitur Utama

- **Dashboard Keuangan:** Menampilkan ringkasan total saldo, pemasukan, dan pengeluaran secara real-time.
- **Manajemen Siswa:** Menambah, memperbarui, atau menonaktifkan data siswa dalam kelas.
- **Pencatatan Pemasukan (Batch & Custom):**
  - *Batch Checklist:* Pembayaran kas massal dengan mencentang nama siswa untuk pelunasan cepat.
  - *Custom Amount:* Mencatat pembayaran iuran dengan nominal kustom untuk siswa yang mencicil.
- **Pencatatan Pengeluaran & Bukti Nota:**
  - Input transaksi pengeluaran lengkap dengan kategori dan deskripsi.
  - Integrasi kamera untuk memfoto nota/struk pengeluaran dan mengunggahnya langsung ke server.
- **Pengingat Tunggakan (WhatsApp Blast):** Mengirim pesan penagihan otomatis ke nomor WhatsApp siswa yang memiliki tunggakan iuran.
- **Tutup Buku (Reset Semester):** Menyimpan riwayat transaksi semester lalu, serta melakukan reset saldo dan tunggakan untuk memulai semester baru tanpa kehilangan data historis.

---

## 🛠️ Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) untuk manajemen state yang type-safe dan terstruktur.
- **Database & Auth:** [Supabase SDK](https://supabase.com/docs/reference/dart/introduction) (`supabase_flutter`) sebagai backend serverless utama.
- **Charting:** [FL Chart](https://pub.dev/packages/fl_chart) untuk visualisasi diagram kas di dashboard.
- **Icons:** [Lucide Icons](https://pub.dev/packages/lucide_icons) untuk ikon antarmuka yang konsisten dengan web.
- **Localization:** [Intl](https://pub.dev/packages/intl) untuk format mata uang Rupiah (`Rp`) dan penanggalan Indonesia.
- **Camera & Storage:** [Image Picker](https://pub.dev/packages/image_picker) untuk mengambil foto nota dari kamera.
- **WhatsApp Integration:** [URL Launcher](https://pub.dev/packages/url_launcher) untuk memicu aplikasi WhatsApp secara langsung.

---

## 📁 Struktur Proyek

Berikut adalah struktur folder utama dalam direktori `application/`:

```text
lib/
├── config/       # Konfigurasi Supabase (URL dan Anon Key)
├── models/       # Representasi data (Class, Expense, Payment, Student)
├── providers/    # Riverpod providers untuk business logic & Supabase fetcher
├── screens/      # Halaman aplikasi (Login, Dashboard, Student, Transaction, dll.)
├── theme.dart    # Konfigurasi tema gelap (Dark Theme) custom
└── main.dart     # Entry point aplikasi
```

---

## 📥 Panduan Instalasi dan Menjalankan Proyek

Aplikasi ini merupakan bagian dari monorepo **SakuKelas** dan terletak di folder `/application`.

### Prasyarat:
Pastikan Anda sudah menginstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.10.x atau terbaru)
- Android Studio / VS Code dengan plugin Flutter & Dart
- Emulator Android / iOS atau perangkat fisik (USB Debugging aktif)

### Langkah Langkah Run:

1. **Clone Repository Utama & Masuk ke Folder Aplikasi:**
   ```bash
   git clone https://github.com/ZyuuDev/webkassekolah.git
   cd webkassekolah/application
   ```

2. **Ambil Dependensi:**
   ```bash
   flutter pub get
   ```

3. **Pastikan Konfigurasi Supabase Sudah Benar:**
   Buka file [supabase_config.dart](application/lib/config/supabase_config.dart) dan pastikan kredensial Supabase Anda sudah sesuai dengan database pusat.

4. **Jalankan Aplikasi:**
   Mulai jalankan aplikasi pada emulator atau perangkat yang terhubung:
   ```bash
   flutter run
   ```

---

## 🔐 Keamanan & Hak Akses (RLS)
Keamanan data kas kelas dikelola menggunakan **Row Level Security (RLS)** di Supabase:
- **Bendahara:** Harus melakukan autentikasi (Login) untuk mendapatkan akses penuh `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` data kelas yang dikelolanya.
- **Siswa/Website:** Hanya memiliki akses read-only (`SELECT`) tanpa perlu login untuk menjaga transparansi kas.
