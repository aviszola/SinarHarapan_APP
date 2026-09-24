## 5. Daftar Lengkap Laporan Bug (Format §14)

### QA-RBAC-01: Tidak Adanya Route Guard Otorisasi Berbasis Role (Broken Access Control)
- **ID Bug:** QA-RBAC-01
- **Modul:** Otorisasi & Routing (Cross-Module RBAC)
- **Role Diuji:** Resepsionis & Manajer
- **Requirement:** Matriks Hak Akses PRD §2.3 ([PRD.MD:57-79](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L57-L79)), Arsitektur §3.1
- **Judul:** Tidak Adanya Route Guard Otorisasi Berbasis Role (Broken Access Control)
- **Tingkat Keparahan:** KRITIS (P1)
- **Langkah Reproduksi:**
  1. Login sebagai `receptionist` (role RECEPTIONIST).
  2. Pada address bar atau melalui `router.go('/manager/dashboard')`, arahkan rute ke Dashboard Manajer.
  3. Amati layar yang dirender oleh aplikasi.
  4. Login sebagai `manager` (role MANAGER), navigasikan ke `/receptionist/rooms`, lalu klik kamar Available (Kamar 101).
- **Expected Behavior:** Resepsionis dilarang mengakses Dashboard Manajer (redirect ke 403 Forbidden atau `/receptionist/rooms`). Manajer dilarang memproses Formulir Check-In Tamu ([PRD.MD:61-75](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L61-L75)).
- **Actual Behavior:** Resepsionis dapat membuka seluruh data analitik eksekutif dan inventaris kamar. Manajer dapat membuka dan memproses check-in tamu. Diverifikasi terotomasi via [qa_verification_test.dart:163, 214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L163).
- **Dampak Bisnis / Teknis:** Pelanggaran serius privasi data finansial hotel dan integritas pemisahan tugas operasional (SoD). Resepsionis dapat mengubah konfigurasi tarif kamar hotel.
- **Rekomendasi Perbaikan:** Terapkan `redirect` guard berbasis `authState.user.role` pada rute GoRouter di [router.dart:28](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/app/router.dart#L28) dan validasi level widget/dialog.

### QA-RES-01: Bypass Ambang Batas Akurasi OCR KTP (Confidence Threshold < 70%)
- **ID Bug:** QA-RES-01
- **Modul:** Reservasi & Check-in (OCR KTP)
- **Role Diuji:** Resepsionis
- **Requirement:** FR-RES-03, Arsitektur §2.4, PRD §7 ([PRD.MD:130](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L130), [277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277))
- **Judul:** Bypass Ambang Batas Akurasi OCR KTP (Confidence Threshold < 70%)
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Buka formulir Check-in tamu.
  2. Lakukan simulasi ekstraksi OCR KTP dengan confidence score rendah (< 0.70).
  3. Amati apakah sistem mewajibkan verifikasi manual atau memblokir auto-fill tanpa peringatan.
- **Expected Behavior:** Jika confidence score OCR < 70%, sistem wajib menampilkan banner peringatan oranye dan mewajibkan resepsionis memverifikasi field secara manual ([PRD.MD:277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277)).
- **Actual Behavior:** Logika pengecekan confidence score tidak memblokir auto-fill dan tidak memvalidasi ulang form sebelum tombol submit aktif di [check_in_modal.dart:450](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L450).
- **Dampak Bisnis / Teknis:** Data NIK dan nama tamu berisiko salah rekam ke database dan invoice resmi apabila KTP buram/rusak.
- **Rekomendasi Perbaikan:** Tambahkan state `isOcrVerified` yang wajib bernilai true bila `confidence < 0.70` sebelum tombol Simpan dapat diklik.

### QA-RES-02: Ketiadaan Persistensi Offline-Caching (Hive Box)
- **ID Bug:** QA-RES-02
- **Modul:** Reservasi & Ketersediaan Jaringan
- **Role Diuji:** Resepsionis
- **Requirement:** FR-RES-08, Arsitektur §2.4 ([PRD.MD:135](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L135), [Arsitektur.md:145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L145))
- **Judul:** Ketiadaan Persistensi Offline-Caching (Hive Box)
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Mulai pengisian form reservasi tamu.
  2. Simulasikan koneksi jaringan offline / terputus.
  3. Periksa penyimpanan cache lokal (Hive box) pada perangkat.
- **Expected Behavior:** Data form tersimpan sementara secara lokal dalam Hive box dan otomatis disinkronisasi saat koneksi pulih ([PRD.MD:135](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L135)).
- **Actual Behavior:** Tidak ditemukan pustaka Hive atau persistensi lokal di `pubspec.yaml` dan seluruh modul reservasi. Pemutusan koneksi menyebabkan data form hilang.
- **Dampak Bisnis / Teknis:** Resepsionis kehilangan seluruh input tamu yang sedang check-in saat Wi-Fi hotel mengalami gangguan fluktuatif.
- **Rekomendasi Perbaikan:** Pasang Hive/Isar untuk offline caching draft reservasi sebelum dikirim ke backend.

### QA-RES-03: Resepsionis Dapat Mengubah Tarif Kamar Bebas Tanpa Otorisasi Manajer
- **ID Bug:** QA-RES-03
- **Modul:** Reservasi & Check-in (Tarif Kamar)
- **Role Diuji:** Resepsionis
- **Requirement:** FR-RES-02, FR-RES-05, Matriks RBAC PRD §2.3 ([PRD.MD:68-71](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L68-L71), [132](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L132))
- **Judul:** Resepsionis Dapat Mengubah Tarif Kamar Bebas Tanpa Otorisasi Manajer
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Login sebagai `receptionist`.
  2. Klik kamar kosong untuk membuka formulir Check-in.
  3. Arahkan kursor ke field input 'Total Biaya (Rp)'.
  4. Hapus nominal otomatis dan ketikkan nominal sembarang (misal Rp 50.000).
- **Expected Behavior:** Tarif dihitung otomatis berdasarkan tipe kamar dan durasi menginap (FR-RES-05); hak mengubah tarif kamar hanya dimiliki oleh Manager (RBAC PRD §2.3 [PRD.MD:68-71](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L68-L71)).
- **Actual Behavior:** Field total biaya menggunakan controller terbuka tanpa proteksi `readOnly`, sehingga resepsionis dapat mengetikkan nominal sekehendak hati ([check_in_modal.dart:45](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L45)). Kode mencatat komentar 'diskon khusus/negosiasi'. [Perlu konfirmasi Product Owner].
- **Dampak Bisnis / Teknis:** Potensi fraud atau manipulasi penerimaan kas hotel oleh staf frontdesk tanpa jejak otorisasi manajer.
- **Rekomendasi Perbaikan:** Kunci field harga menjadi `readOnly: true` untuk role Resepsionis. Bila diperlukan diskon/negosiasi, sediakan modal input kode otorisasi PIN Manajer.

### QA-RES-04: Ketiadaan Mekanisme Timeout Otomatis pada Pemrosesan OCR KTP (> 3 Detik)
- **ID Bug:** QA-RES-04
- **Modul:** Reservasi & Check-in (OCR KTP)
- **Role Diuji:** Resepsionis
- **Requirement:** FR-RES-04, NFR §4.1 ([PRD.MD:131](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L131), [Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148))
- **Judul:** Ketiadaan Mekanisme Timeout Otomatis pada Pemrosesan OCR KTP (> 3 Detik)
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Unggah berkas gambar KTP pada modal check-in.
  2. Simulasikan pemrosesan OCR yang memakan waktu > 3 detik.
- **Expected Behavior:** Jika pemrosesan OCR melebihi 3 detik, sistem otomatis menghentikan proses (timeout fallback) dan mengarahkan pengguna ke input manual penuh ([PRD.MD:277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277)).
- **Actual Behavior:** Tidak ada konfigurasi `timeout(Duration(seconds: 3))` pada simulasi OCR di [check_in_modal.dart:89](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L89); loading spinner berputar tanpa batas waktu.
- **Dampak Bisnis / Teknis:** Antrean tamu di frontdesk tertahan jika proses OCR di server/client mengalami stall.
- **Rekomendasi Perbaikan:** Tambahkan `.timeout(const Duration(seconds: 3))` dan handler catchError untuk beralih otomatis ke manual mode.

### QA-RES-05: Ketiadaan Pipeline Kompresi Gambar KTP Client (Maks 1.5MB, 1600px)
- **ID Bug:** QA-RES-05
- **Modul:** Reservasi & Kompresi Berkas
- **Role Diuji:** Resepsionis
- **Requirement:** Arsitektur §2.4, Arsitektur §3.3 ([Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148))
- **Judul:** Ketiadaan Pipeline Kompresi Gambar KTP Client (Maks 1.5MB, 1600px)
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa berkas implementasi penanganan gambar KTP di `check_in_modal.dart`.
- **Expected Behavior:** Ukuran gambar terkompresi maks 1.5MB, resize longest-edge 1600px sebelum dikirim ke API OCR ([Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148)).
- **Actual Behavior:** Pipeline kompresi gambar client belum terintegrasi di [check_in_modal.dart:89](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L89); data masih menggunakan OCR mock berbasis delay waktu.
- **Dampak Bisnis / Teknis:** Pengunggahan foto resolusi tinggi kamera tablet (10-20MB) akan membebani bandwidth jaringan hotel dan memicu error payload too large.
- **Rekomendasi Perbaikan:** Integrasikan paket `flutter_image_compress` dengan target resolusi max 1600px dan ukuran < 1.5MB.

### QA-RES-06: Tombol Submit Form Check-In Rentan Penekanan Ganda (Double-Submit)
- **ID Bug:** QA-RES-06
- **Modul:** Reservasi & Integritas Transaksi
- **Role Diuji:** Resepsionis
- **Requirement:** NFR §4.1, Integritas Transaksi ([PRD.MD:133](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L133), [PRD.MD:245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L245))
- **Judul:** Tombol Submit Form Check-In Rentan Penekanan Ganda (Double-Submit)
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Isi lengkap form check-in tamu.
  2. Lakukan klik cepat ganda (double-click) pada tombol 'Simpan & Check-In Tamu'.
- **Expected Behavior:** Tombol submit dinonaktifkan (disabled / isLoading: true) seketika setelah ketukan pertama agar tidak terjadi duplikasi transaksi reservasi.
- **Actual Behavior:** Widget `AppButton` pada [check_in_modal.dart:736](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L736) tidak mengikat parameter `isLoading: _isSubmitting`, sehingga callback `onPressed` dapat terpanggil berulang.
- **Dampak Bisnis / Teknis:** Terjadinya race condition pembuatan invoice ganda atau bentrok alokasi kamar di database.
- **Rekomendasi Perbaikan:** Ikat state `isLoading: _isSubmitting` pada `AppButton` dan return segera bila `_isSubmitting == true`.

### QA-WA-01: Ketiadaan Penanganan Status Kegagalan Gateway WhatsApp Riil
- **ID Bug:** QA-WA-01
- **Modul:** Notifikasi WhatsApp & Webhook
- **Role Diuji:** Resepsionis / Sistem
- **Requirement:** FR-WA-04, FR-WA-05, Arsitektur §6.2 ([PRD.MD:144-145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L144-L145))
- **Judul:** Ketiadaan Penanganan Status Kegagalan Gateway WhatsApp Riil
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Buka modal Daftar Tamu Aktif (`ActiveGuestsModal`).
  2. Tekan tombol pemicu manual 'Kirim Ulang WA'.
  3. Amati perubahan status dan penanganan error.
- **Expected Behavior:** Sistem mencatat status pengiriman (Sent/Delivered/Read/Failed) dari callback webhook gateway dan menampilkan UI penanganan jika Failed ([PRD.MD:145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L145)).
- **Actual Behavior:** Tombol pemicu manual hanya menampilkan `ScaffoldMessenger` SnackBar lokal dengan delay tiruan; integrasi API Gateway WhatsApp riil belum ada di [active_guests_modal.dart:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L285).
- **Dampak Bisnis / Teknis:** Resepsionis mengira pesan WhatsApp sudah terkirim ke tamu padahal gateway backend belum terhubung.
- **Rekomendasi Perbaikan:** Hubungkan pemicu manual dengan REST endpoint WhatsApp Gateway service dan dengarkan webhook status callback.

### QA-WA-02: Ketiadaan Indikator dan Logika Auto-Retry WhatsApp 3x pada Frontend
- **ID Bug:** QA-WA-02
- **Modul:** Notifikasi WhatsApp (Retry)
- **Role Diuji:** Sistem / Resepsionis
- **Requirement:** NFR §4.2, Arsitektur §6.3 ([PRD.MD:245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L245), [Arsitektur.md:345](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L345))
- **Judul:** Ketiadaan Indikator dan Logika Auto-Retry WhatsApp 3x pada Frontend
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa berkas `active_guests_modal.dart` pada penanganan status pesan failed.
- **Expected Behavior:** Frontend menampilkan status percobaan ulang (mis. 'Mencoba ulang 1/3') saat pengiriman gagal ([Arsitektur.md:345](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L345)).
- **Actual Behavior:** Tidak ditemukan variabel pencatat counter percobaan ulang maupun teks status retry di [active_guests_modal.dart:46](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L46).
- **Dampak Bisnis / Teknis:** Resepsionis tidak mengetahui apakah sistem sedang mencoba mengirim ulang atau pesan sudah gagal permanen.
- **Rekomendasi Perbaikan:** Tampilkan badge status percobaan `Retry X/3` pada baris tamu aktif di modal.

### QA-WA-03: Ketiadaan Banner Notifikasi Peringatan Eskalasi Kegagalan WhatsApp 3x
- **ID Bug:** QA-WA-03
- **Modul:** Notifikasi WhatsApp (Eskalasi)
- **Role Diuji:** Resepsionis / Manajer
- **Requirement:** Arsitektur §6.3 ([Arsitektur.md:348](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L348))
- **Judul:** Ketiadaan Banner Notifikasi Peringatan Eskalasi Kegagalan WhatsApp 3x
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa kode antarmuka resepsionis saat kegagalan pengiriman berulang 3 kali.
- **Expected Behavior:** Alert otomatis ditampilkan di dashboard resepsionis bila pengingat WA gagal 3 kali berturut-turut ([Arsitektur.md:348](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L348)).
- **Actual Behavior:** Tidak ada komponen banner atau notifikasi peringatan eskalasi kegagalan di [active_guests_modal.dart:20](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L20).
- **Dampak Bisnis / Teknis:** Tamu tidak menerima pengingat checkout tanpa disadari oleh staf resepsionis, menyebabkan keterlambatan checkout tak tertangani.
- **Rekomendasi Perbaikan:** Sediakan banner alert merah pada top bar resepsionis jika terdapat antrean pesan WhatsApp yang gagal 3 kali.

### QA-OUT-01: Penomoran Invoice Menggunakan Nomor Kamar, Membuka Risiko Duplikasi Nomor Faktur
- **ID Bug:** QA-OUT-01
- **Modul:** Check-Out & Invoice
- **Role Diuji:** Resepsionis
- **Requirement:** FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))
- **Judul:** Penomoran Invoice Menggunakan Nomor Kamar, Membuka Risiko Duplikasi Nomor Faktur
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Buka `invoice_preview_dialog.dart` baris 40.
  2. Amati logika generator nomor invoice default.
- **Expected Behavior:** Format nomor invoice unik otomatis: `INV/SH/YYYYMMDD/XXXX` dengan urutan counter sekuensial 4 digit ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).
- **Actual Behavior:** Generator default membuat nomor invoice dengan format `INV/SH/YYYYMMDD/{room.roomNumber}`, bukan nomor sekuensial unik ([invoice_preview_dialog.dart:40](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L40)).
- **Dampak Bisnis / Teknis:** Bila kamar 101 dihuni oleh dua tamu berbeda pada hari yang sama (mis. check-in siang setelah check-out pagi), nomor faktur akan terduplikasi sama persis.
- **Rekomendasi Perbaikan:** Gunakan sekuens generator unik terpusat dari server/database atau UUID v4 substring.

### QA-OUT-02: Besaran Tarif Denda Keterlambatan Check-out Di-hardcode Rp 50.000/Jam
- **ID Bug:** QA-OUT-02
- **Modul:** Check-Out & Denda Keterlambatan
- **Role Diuji:** Resepsionis / Manajer
- **Requirement:** FR-OUT-05 ([PRD.MD:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L171))
- **Judul:** Besaran Tarif Denda Keterlambatan Check-out Di-hardcode Rp 50.000/Jam
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Buka dialog check-out untuk kamar yang melewati batas jam 12:00 WIB.
  2. Periksa kalkulasi nominal denda keterlambatan.
- **Expected Behavior:** Tarif denda keterlambatan dapat dikonfigurasi oleh manajer hotel ([PRD.MD:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L171)).
- **Actual Behavior:** Kalkulasi denda di-hardcode dengan konstanta `50000` per jam di [check_out_dialog.dart:58](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/check_out_dialog.dart#L58) tanpa membaca konfigurasi pengaturan manajer.
- **Dampak Bisnis / Teknis:** Manajer tidak dapat menyesuaikan kebijakan tarif denda saat musim ramai (peak season) atau kebijakan promo hotel.
- **Rekomendasi Perbaikan:** Pindahkan konfigurasi tarif denda per jam ke `hotelSettingsProvider` yang dapat diedit di dashboard manajer.

### QA-OUT-03: Tombol Cetak Thermal Printer Belum Terintegrasi Protokol ESC/POS Riil
- **ID Bug:** QA-OUT-03
- **Modul:** Check-Out & Pencetakan Faktur
- **Role Diuji:** Resepsionis
- **Requirement:** FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))
- **Judul:** Tombol Cetak Thermal Printer Belum Terintegrasi Protokol ESC/POS Riil
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Pada dialog invoice preview, klik tombol 'Cetak Thermal (58/80mm)'.
  2. Amati perilaku sistem.
- **Expected Behavior:** Fitur cetak langsung ke thermal printer (58mm/80mm) menghasilkan byte stream ESC/POS ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).
- **Actual Behavior:** Tombol hanya memicu SnackBar simulasi: `Simulasi cetak struk thermal 58mm...` ([invoice_preview_dialog.dart:488](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L488)).
- **Dampak Bisnis / Teknis:** Frontdesk tidak dapat mencetak struk fisik bukti check-out ke mesin printer kasir hotel.
- **Rekomendasi Perbaikan:** Integrasikan driver/library pencetakan Bluetooth/USB printer ESC/POS (mis. `esc_pos_printer`).

### QA-OUT-04: Tombol Unduh PDF Faktur Belum Menghasilkan Berkas PDF Riil
- **ID Bug:** QA-OUT-04
- **Modul:** Check-Out & Arsip Dokumen
- **Role Diuji:** Resepsionis
- **Requirement:** FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))
- **Judul:** Tombol Unduh PDF Faktur Belum Menghasilkan Berkas PDF Riil
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Pada dialog invoice preview, klik tombol 'Unduh PDF'.
  2. Periksa apakah berkas PDF diunduh.
- **Expected Behavior:** Sistem menghasilkan dan mengunduh berkas PDF faktur resmi ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).
- **Actual Behavior:** Tombol hanya menampilkan SnackBar tiruan `Mengunduh PDF Invoice...` ([invoice_preview_dialog.dart:502](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L502)).
- **Dampak Bisnis / Teknis:** Tamu yang meminta salinan dokumen PDF resmi tidak dapat dilayani langsung.
- **Rekomendasi Perbaikan:** Implementasikan pembuatan dokumen PDF menggunakan paket `pdf` dan `printing` Dart.

### QA-REP-01: Perhitungan Rasio Okupansi Mengabaikan Filter Kamar Under Maintenance
- **ID Bug:** QA-REP-01
- **Modul:** Analitik Manajer & KPI
- **Role Diuji:** Manajer
- **Requirement:** FR-REP-01 ([PRD.MD:177](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L177))
- **Judul:** Perhitungan Rasio Okupansi Mengabaikan Filter Kamar Under Maintenance
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Login sebagai `manager`.
  2. Buka dashboard analitik.
  3. Periksa rumus kalkulasi widget 'Rasio Okupansi'.
- **Expected Behavior:** Rasio Okupansi dihitung dengan rumus: Kamar Terisi ÷ Total Kamar Aktif × 100% ([PRD.MD:177](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L177)). Kamar nonaktif/maintenance wajib dikeluarkan dari pembagi.
- **Actual Behavior:** Pembagi rasio okupansi di [manager_dashboard_screen.dart:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L215) membagi terhadap `totalRooms` termasuk kamar yang sedang rusak/maintenance.
- **Dampak Bisnis / Teknis:** Angka KPI rasio hunian yang disajikan ke manajemen hotel terdistorsi lebih rendah dari kapasitas operasional riil.
- **Rekomendasi Perbaikan:** Koreksi rumus menjadi: `occupied / (totalRooms - maintenanceRooms) * 100`.

### QA-REP-02: Palet Warna Grafik Saluran RedDoorz Menggunakan Non-Token `Colors.red.shade700`
- **ID Bug:** QA-REP-02
- **Modul:** Analitik Manajer (Design System)
- **Role Diuji:** Manajer
- **Requirement:** Design System §6.8 ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215))
- **Judul:** Palet Warna Grafik Saluran RedDoorz Menggunakan Non-Token `Colors.red.shade700`
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Buka grafik komposisi saluran pemesanan di dashboard manajer.
  2. Periksa definisi warna segmen RedDoorz.
- **Expected Behavior:** Palet warna grafik: navy/700 dan orange/600 flat solid ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215)).
- **Actual Behavior:** Segmen RedDoorz menggunakan `Colors.red.shade700` ([manager_dashboard_screen.dart:458](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L458)) di luar sistem warna `AppColors`.
- **Dampak Bisnis / Teknis:** Inkonsistensi identitas visual antarmuka analitik hotel.
- **Rekomendasi Perbaikan:** Gunakan `AppColors.orange600` untuk RedDoorz dan `AppColors.navy700` untuk Walk-In sesuai spec §6.8.

### QA-REP-03: Ekspor Laporan Excel (.xlsx) 2 Sheet Belum Menghasilkan File Spreadsheet Nyata
- **ID Bug:** QA-REP-03
- **Modul:** Laporan & Ekspor Excel
- **Role Diuji:** Manajer
- **Requirement:** FR-REP-03 ([PRD.MD:179](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L179))
- **Judul:** Ekspor Laporan Excel (.xlsx) 2 Sheet Belum Menghasilkan File Spreadsheet Nyata
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Pada panel manajer, klik tombol 'Ekspor Excel'.
  2. Periksa berkas keluaran.
- **Expected Behavior:** Sistem mengunduh berkas `.xlsx` berisi 2 sheet: Summary KPI dan Raw Data Detail Transaksi ([PRD.MD:179](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L179)).
- **Actual Behavior:** Tombol hanya menampilkan SnackBar mock `Membuat laporan Excel (XLSX)...` ([manager_dashboard_screen.dart:82](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L82)).
- **Dampak Bisnis / Teknis:** Manajer tidak dapat melakukan rekapitulasi data keuangan bulanan ke akuntansi hotel.
- **Rekomendasi Perbaikan:** Hubungkan ke backend `/api/reports/export-excel` atau generate client-side via paket `excel` Dart.

### QA-REP-04: Ekspor PDF Format A4 Resmi dengan Kop Surat Belum Diimplementasikan
- **ID Bug:** QA-REP-04
- **Modul:** Laporan & Ekspor PDF
- **Role Diuji:** Manajer
- **Requirement:** FR-REP-04 ([PRD.MD:180](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L180))
- **Judul:** Ekspor PDF Format A4 Resmi dengan Kop Surat Belum Diimplementasikan
- **Tingkat Keparahan:** TINGGI (P2)
- **Langkah Reproduksi:**
  1. Klik tombol 'Ekspor PDF' pada panel manajer.
  2. Periksa berkas keluaran.
- **Expected Behavior:** Sistem menghasilkan PDF format A4 kop surat resmi, tabel rangkuman, grafik visual okupansi, dan kolom tanda tangan pengesahan Manajer ([PRD.MD:180](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L180)).
- **Actual Behavior:** Tombol hanya menampilkan SnackBar mock `Membuat laporan eksekutif PDF A4...` ([manager_dashboard_screen.dart:100](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L100)).
- **Dampak Bisnis / Teknis:** Ketiadaan dokumen cetak fisik resmi untuk laporan pertanggungjawaban kepada pemilik properti hotel.
- **Rekomendasi Perbaikan:** Implementasikan pembuatan dokumen PDF format A4 lengkap dengan kop surat dan kolom pengesahan.

### QA-AUTH-01: Ketiadaan Umpan Balik UI untuk Rate Limiter Percobaan Login (> 5 Kali/Menit)
- **ID Bug:** QA-AUTH-01
- **Modul:** Autentikasi (Keamanan Brute-Force)
- **Role Diuji:** Pengguna Login
- **Requirement:** Arsitektur §3.3 ([Arsitektur.md:214-225](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L214-L225))
- **Judul:** Ketiadaan Umpan Balik UI untuk Rate Limiter Percobaan Login (> 5 Kali/Menit)
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Masukkan kata sandi salah berturut-turut lebih dari 5 kali dalam waktu 1 menit.
  2. Amati respons antarmuka form login.
- **Expected Behavior:** Sistem menampilkan alert pemblokiran sementara dengan timer hitung mundur bila terdeteksi percobaan > 5 kali ([Arsitektur.md:217](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L217)). Logika server rate limiting terpisah sebagai BLOCKED.
- **Actual Behavior:** Frontend tidak memiliki counter percobaan gagal di client dan tidak menampilkan banner lockout di [auth_controller.dart:41](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L41).
- **Dampak Bisnis / Teknis:** Kurangnya perlindungan visual dan proteksi lokal terhadap serangan coba-coba kredensial di terminal frontdesk.
- **Rekomendasi Perbaikan:** Tambahkan counter percobaan login di `AuthNotifier` dan nonaktifkan tombol submit selama 60 detik setelah 5 kali kegagalan.

### QA-AUTH-02: Ketiadaan Mekanisme Auto-Logout Otomatis Setelah Sesi Idle 12 Jam
- **ID Bug:** QA-AUTH-02
- **Modul:** Autentikasi (Manajemen Sesi)
- **Role Diuji:** Resepsionis / Manajer
- **Requirement:** FR-AUTH-04 ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109))
- **Judul:** Ketiadaan Mekanisme Auto-Logout Otomatis Setelah Sesi Idle 12 Jam
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa berkas `auth_controller.dart`.
  2. Cari konfigurasi timer idle atau token expiry.
- **Expected Behavior:** Sistem melakukan auto-logout otomatis saat sesi mencapai 12 jam, redirect ke login disertai pesan notifikasi ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109)).
- **Actual Behavior:** Tidak ada timer pendeteksi idle atau listener masa berlaku token di [auth_controller.dart:9](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L9); sesi bertahan di memori tanpa batas waktu.
- **Dampak Bisnis / Teknis:** Komputer frontdesk yang ditinggalkan saat pergantian shift tetap terbuka tanpa memerlukan re-autentikasi staf baru.
- **Rekomendasi Perbaikan:** Pasang timer pengawas aktivitas sesi dan batalkan token setelah 12 jam.

### QA-AUTH-03: Refresh Halaman Web Browser (F5) Memusnahkan Sesi dan Memaksa Login Ulang
- **ID Bug:** QA-AUTH-03
- **Modul:** Autentikasi (Persistensi Sesi)
- **Role Diuji:** Resepsionis / Manajer
- **Requirement:** FR-AUTH-04, Usabilitas Web ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109))
- **Judul:** Refresh Halaman Web Browser (F5) Memusnahkan Sesi dan Memaksa Login Ulang
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Login sebagai resepsionis.
  2. Lakukan refresh halaman browser (tekan F5 / Ctrl+R).
  3. Amati status navigasi aplikasi.
- **Expected Behavior:** Sesi tetap dipertahankan setelah refresh browser dan pengguna tetap berada di dashboard aktif.
- **Actual Behavior:** State autentikasi hanya tersimpan di memori volatil StateNotifier. Refresh memuat ulang kode dan mengarahkan kembali ke `/login` ([auth_controller.dart:76](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L76)).
- **Dampak Bisnis / Teknis:** Resepsionis kehilangan konteks kerja dan harus login ulang setiap kali browser me-reload halaman.
- **Rekomendasi Perbaikan:** Simpan token sesi terenkripsi di `flutter_secure_storage` atau `shared_preferences` web.

### QA-AUTH-04: Pesan Error Login Membocorkan Validitas Keberadaan Nama Pengguna
- **ID Bug:** QA-AUTH-04
- **Modul:** Autentikasi (Keamanan Enumerasi)
- **Role Diuji:** Pengguna Login
- **Requirement:** Keamanan Enumerasi, FR-AUTH-01 ([PRD.MD:106](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L106))
- **Judul:** Pesan Error Login Membocorkan Validitas Keberadaan Nama Pengguna
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Pada form login, masukkan username acak `penyusup` dan sembarang password.
  2. Klik tombol Masuk.
  3. Baca teks pesan kesalahan yang tampil di layar.
- **Expected Behavior:** Pesan error generik yang tidak membocorkan apakah username terdaftar atau tidak (mis. 'Username atau kata sandi tidak valid').
- **Actual Behavior:** Sistem menampilkan: `Kredensial tidak valid. Gunakan akun receptionist atau manager.` di [auth_repository.dart:37](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/data/auth_repository.dart#L37), membocorkan daftar akun valid.
- **Dampak Bisnis / Teknis:** Mempermudah penyerang memetakan (meng-enumerasi) nama akun yang ada pada sistem hotel.
- **Rekomendasi Perbaikan:** Gunakan pesan generik tanpa menyebutkan nama akun valid.

### QA-AUTH-05: Pelanggaran Aturan Desain Tombol Aksen Oranye Tunggal pada Halaman Login
- **ID Bug:** QA-AUTH-05
- **Modul:** Autentikasi (Design System)
- **Role Diuji:** Pengguna Login
- **Requirement:** Design System §7 ([design.md:238-245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L238-L245))
- **Judul:** Pelanggaran Aturan Desain Tombol Aksen Oranye Tunggal pada Halaman Login
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Buka halaman login.
  2. Amati elemen-elemen berwarna oranye pada layar.
- **Expected Behavior:** Nuansa Navy dominan, hanya ada satu aksen oranye pada tombol utama masuk saja ([design.md:240](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L240)).
- **Actual Behavior:** Terdapat kontainer ikon logo SH oranye 52x52px di samping tombol CTA oranye di [login_screen.dart:259](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/login_screen.dart#L259).
- **Dampak Bisnis / Teknis:** Pelemahan fokus visual resepsionis terhadap tombol call-to-action utama.
- **Rekomendasi Perbaikan:** Ubah latar belakang kontainer logo menjadi Navy 800 dengan ikon putih/emas netral.

### QA-SEC-01: Kredensial Pengguna dan Kata Sandi Hardcoded dalam Berkas Kode Client
- **ID Bug:** QA-SEC-01
- **Modul:** Keamanan Data & Kredensial
- **Role Diuji:** Pengembang / Penyerang
- **Requirement:** FR-AUTH-05, Arsitektur §5 ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110), [Arsitektur.md:214-225](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L214-L225))
- **Judul:** Kredensial Pengguna dan Kata Sandi Hardcoded dalam Berkas Kode Client
- **Tingkat Keparahan:** KRITIS (P1)
- **Langkah Reproduksi:**
  1. Buka berkas `lib/features/auth/data/auth_repository.dart`.
  2. Periksa array `_mockUsers` pada baris 4-19.
- **Expected Behavior:** Password tidak pernah disimpan plain text atau di-hardcode dalam client bundle ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110)).
- **Actual Behavior:** Kredensial username `receptionist` dan `manager` beserta password plain text `password123` tertulis langsung di kode sumber client.
- **Dampak Bisnis / Teknis:** Siapa pun yang menginspeksi build bundle Flutter web dapat membaca password staf dan manajer hotel secara langsung.
- **Rekomendasi Perbaikan:** Hapus mock static users; hubungkan autentikasi ke backend API Supabase/PostgreSQL dengan hashing bcrypt.

### QA-SEC-02: Penyimpanan Token Autentikasi Tanpa Mekanisme Secure Storage
- **ID Bug:** QA-SEC-02
- **Modul:** Keamanan Sesi & Token
- **Role Diuji:** Penyerang / Pengembang
- **Requirement:** Arsitektur §5 ([Arsitektur.md:218](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L218))
- **Judul:** Penyimpanan Token Autentikasi Tanpa Mekanisme Secure Storage
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa penanganan token JWT tiruan di `auth_repository.dart` baris 42 dan `auth_controller.dart`.
- **Expected Behavior:** Token JWT disimpan dalam mekanisme secure storage atau HttpOnly cookie ([Arsitektur.md:218](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L218)).
- **Actual Behavior:** Token hanya berupa string di memori RAM StateNotifier tanpa persistensi terenkripsi.
- **Dampak Bisnis / Teknis:** Ketiadaan manajemen token standar membatasi implementasi refresh token dan keamanan sesi lintas jendela browser.
- **Rekomendasi Perbaikan:** Terapkan `flutter_secure_storage` untuk menyimpan access token secara terenkripsi.

### QA-TEST-01: Kegagalan Eksekusi Automated Widget Test Bawaan (`widget_test.dart`)
- **ID Bug:** QA-TEST-01
- **Modul:** Otomasi QA Suite
- **Role Diuji:** QA Engineer
- **Requirement:** DoD PRD §8 ([PRD.MD:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L285))
- **Judul:** Kegagalan Eksekusi Automated Widget Test Bawaan (`widget_test.dart`)
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Jalankan perintah `flutter test test/widget_test.dart` pada terminal.
- **Expected Behavior:** Seluruh suite automated test berjalan dan lulus tanpa exception/failure ([PRD.MD:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L285)).
- **Actual Behavior:** Test gagal karena matcher teks `Sinar Harapan Frontdesk` tidak ditemukan pada widget tree LoginScreen di [widget_test.dart:18](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/widget_test.dart#L18).
- **Dampak Bisnis / Teknis:** Pipeline CI/CD otomatis akan memblokir proses build akibat kegagalan tes regresi bawaan.
- **Rekomendasi Perbaikan:** Perbarui teks pencarian pada test agar sesuai dengan label judul antarmuka `HOTEL SINAR HARAPAN`.

### QA-DS-01: Konflik Dua Set Hex Token Warna Status Kamar Antara Spec §2.3 dan §6.3
- **ID Bug:** QA-DS-01
- **Modul:** Design System (Status Kamar)
- **Role Diuji:** Resepsionis
- **Requirement:** FR-ROOM-02, Design System §6.3 ([PRD.MD:117](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L117), [design.md:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L171))
- **Judul:** Konflik Dua Set Hex Token Warna Status Kamar Antara Spec §2.3 dan §6.3
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Periksa definisi warna pada `lib/app/theme.dart` baris 25-45.
  2. Bandingkan `RoomCard._stripeColor` dengan `StatusBadge`.
- **Expected Behavior:** Satu sumber kebenaran (single source of truth) untuk kode warna status: Hijau, Merah, Kuning, Abu-abu.
- **Actual Behavior:** Terjadi perbedaan nilai hex antara `AppColors` di theme.dart dan spesifikasi badge status di status_badge.dart (mis. #16A34A vs #22C55E).
- **Dampak Bisnis / Teknis:** Persepsi visual resepsionis terhadap kamar Available vs Dirty dapat membingungkan saat pencahayaan layar redup.
- **Rekomendasi Perbaikan:** Unifikasi seluruh token warna status ke dalam `AppColors` di `theme.dart` merujuk ke hex dengan rasio kontras terbaik.

### QA-DS-02: Responsivitas Layout Baris Metrik / Header Mengalami RenderFlex Overflow pada Resolusi Tablet
- **ID Bug:** QA-DS-02
- **Modul:** Design System & Aksesibilitas Layout
- **Role Diuji:** Resepsionis / Manajer
- **Requirement:** Design System §6.7, Design System §6.1 ([design.md:150](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L150), [202](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L202))
- **Judul:** Responsivitas Layout Baris Metrik / Header Mengalami RenderFlex Overflow pada Resolusi Tablet
- **Tingkat Keparahan:** SEDANG (P3)
- **Langkah Reproduksi:**
  1. Jalankan aplikasi pada resolusi tablet (lebar 768px - 1024px).
  2. Buka dashboard resepsionis atau dashboard manajer.
- **Expected Behavior:** Seluruh baris metrik dan tombol beradaptasi responsif tanpa RenderFlex overflow.
- **Actual Behavior:** Ditemukan layout overflow: Row di [app_header.dart:511](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/shared_widgets/app_header.dart#L511) overflow 52px, Row di [manager_dashboard_screen.dart:592](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L592) overflow 39px, dan icon button memiliki touch target < 44px.
- **Dampak Bisnis / Teknis:** Tampilan antarmuka tampak rusak dengan garis belang kuning-hitam di layar tablet resepsionis.
- **Rekomendasi Perbaikan:** Bungkus teks panjang dengan `Flexible`/`Expanded` dan pastikan `mainAxisSize: MainAxisSize.min`.

### QA-DS-04: Pelanggaran Anti AI-Slop: Area Bawah Grafik Tren Menggunakan Isian `LinearGradient`
- **ID Bug:** QA-DS-04
- **Modul:** Design System Compliance (Anti-AI Slop)
- **Role Diuji:** Manajer
- **Requirement:** Design System §6.8, Design System §9 ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215), [268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268))
- **Judul:** Pelanggaran Anti AI-Slop: Area Bawah Grafik Tren Menggunakan Isian `LinearGradient`
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Buka berkas `lib/features/reporting/presentation/widgets/executive_trend_chart.dart` baris 607.
- **Expected Behavior:** Palet grafik: navy/700 dan orange/600 flat solid, dilarang gradient ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215), [268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268)).
- **Actual Behavior:** Ditemukan penggunaan `LinearGradient` pada properti area bawah grafik tren eksekutif di baris 607.
- **Dampak Bisnis / Teknis:** Menyalahi aturan estetika minimalis profesional Anti-AI Slop yang ditetapkan spesifikasi desain.
- **Rekomendasi Perbaikan:** Ganti isian gradient dengan warna solid transparan `AppColors.navy700.withAlpha(20)` atau hilangkan area fill.

### QA-DS-05: Penggunaan Inline `BoxShadow` Hardcoded di Luar Spesifikasi Elevation Token
- **ID Bug:** QA-DS-05
- **Modul:** Design System Compliance (Elevasi)
- **Role Diuji:** Resepsionis
- **Requirement:** Design System §4.3 ([design.md:135-142](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L135-L142))
- **Judul:** Penggunaan Inline `BoxShadow` Hardcoded di Luar Spesifikasi Elevation Token
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Periksa berkas `whatsapp_receipt_dialog.dart` baris 637 dan 828.
- **Expected Behavior:** Seluruh elevasi bayangan wajib menggunakan token `AppElevation.none`, `AppElevation.card`, `AppElevation.modal`, atau `AppElevation.dropdown` ([design.md:137](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L137)).
- **Actual Behavior:** Ditemukan definisi `BoxShadow(blurRadius: 10, offset: Offset(0, 4))` dan `BoxShadow(blurRadius: 3)` hardcoded inline di luar token sistem.
- **Dampak Bisnis / Teknis:** Inkonsistensi kedalaman elevasi elemen UI di dialog bukti bayar WhatsApp.
- **Rekomendasi Perbaikan:** Ganti inline BoxShadow dengan `boxShadow: AppElevation.card` atau `AppElevation.modal`.

### QA-DS-06: Informasi Jam Shift Bertugas Resepsionis Tidak Ditampilkan pada Top Bar
- **ID Bug:** QA-DS-06
- **Modul:** Design System (Navigasi & Top Bar)
- **Role Diuji:** Resepsionis
- **Requirement:** Design System §6.9 ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223))
- **Judul:** Informasi Jam Shift Bertugas Resepsionis Tidak Ditampilkan pada Top Bar
- **Tingkat Keparahan:** RENDAH (P4)
- **Langkah Reproduksi:**
  1. Amati tampilan widget `ReceptionistTopBar` di bagian atas denah kamar.
- **Expected Behavior:** Top bar tinggi 64px, menampilkan identitas brand, jam live, dan jam shift bertugas (mis. Shift 07:00 - 19:00 WIB) ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223)).
- **Actual Behavior:** Widget `ReceptionistTopBar` hanya menampilkan jam live detik dan tanggal; informasi jam shift bertugas sama sekali tidak ada di kode (0 hit grep `shift`).
- **Dampak Bisnis / Teknis:** Staf resepsionis tidak melihat indikator batas akhir waktu kerja shift mereka di header aplikasi.
- **Rekomendasi Perbaikan:** Tambahkan badge teks informasi shift kerja (mis. 'Shift Pagi · 07:00 - 19:00') di samping jam live pada `ReceptionistTopBar`.

