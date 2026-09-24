import re

# We will generate sec5_formatted.md containing all 31 bugs in exact §14 format.

bugs_data = [
    {
        "id": "QA-RBAC-01",
        "modul": "Otorisasi & Routing (Cross-Module RBAC)",
        "role": "Resepsionis & Manajer",
        "req": "Matriks Hak Akses PRD §2.3 ([PRD.MD:57-79](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L57-L79)), Arsitektur §3.1",
        "title": "Tidak Adanya Route Guard Otorisasi Berbasis Role (Broken Access Control)",
        "sev": "KRITIS (P1)",
        "steps": "1. Login sebagai `receptionist` (role RECEPTIONIST).\n2. Pada address bar atau melalui `router.go('/manager/dashboard')`, arahkan rute ke Dashboard Manajer.\n3. Amati layar yang dirender oleh aplikasi.\n4. Login sebagai `manager` (role MANAGER), navigasikan ke `/receptionist/rooms`, lalu klik kamar Available (Kamar 101).",
        "expected": "Resepsionis dilarang mengakses Dashboard Manajer (redirect ke 403 Forbidden atau `/receptionist/rooms`). Manajer dilarang memproses Formulir Check-In Tamu ([PRD.MD:61-75](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L61-L75)).",
        "actual": "Resepsionis dapat membuka seluruh data analitik eksekutif dan inventaris kamar. Manajer dapat membuka dan memproses check-in tamu. Diverifikasi terotomasi via [qa_verification_test.dart:163, 214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L163).",
        "impact": "Pelanggaran serius privasi data finansial hotel dan integritas pemisahan tugas operasional (SoD). Resepsionis dapat mengubah konfigurasi tarif kamar hotel.",
        "rec": "Terapkan `redirect` guard berbasis `authState.user.role` pada rute GoRouter di [router.dart:28](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/app/router.dart#L28) dan validasi level widget/dialog."
    },
    {
        "id": "QA-RES-01",
        "modul": "Reservasi & Check-in (OCR KTP)",
        "role": "Resepsionis",
        "req": "FR-RES-03, Arsitektur §2.4, PRD §7 ([PRD.MD:130](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L130), [277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277))",
        "title": "Bypass Ambang Batas Akurasi OCR KTP (Confidence Threshold < 70%)",
        "sev": "TINGGI (P2)",
        "steps": "1. Buka formulir Check-in tamu.\n2. Lakukan simulasi ekstraksi OCR KTP dengan confidence score rendah (< 0.70).\n3. Amati apakah sistem mewajibkan verifikasi manual atau memblokir auto-fill tanpa peringatan.",
        "expected": "Jika confidence score OCR < 70%, sistem wajib menampilkan banner peringatan oranye dan mewajibkan resepsionis memverifikasi field secara manual ([PRD.MD:277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277)).",
        "actual": "Logika pengecekan confidence score tidak memblokir auto-fill dan tidak memvalidasi ulang form sebelum tombol submit aktif di [check_in_modal.dart:450](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L450).",
        "impact": "Data NIK dan nama tamu berisiko salah rekam ke database dan invoice resmi apabila KTP buram/rusak.",
        "rec": "Tambahkan state `isOcrVerified` yang wajib bernilai true bila `confidence < 0.70` sebelum tombol Simpan dapat diklik."
    },
    {
        "id": "QA-RES-02",
        "modul": "Reservasi & Ketersediaan Jaringan",
        "role": "Resepsionis",
        "req": "FR-RES-08, Arsitektur §2.4 ([PRD.MD:135](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L135), [Arsitektur.md:145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L145))",
        "title": "Ketiadaan Persistensi Offline-Caching (Hive Box)",
        "sev": "TINGGI (P2)",
        "steps": "1. Mulai pengisian form reservasi tamu.\n2. Simulasikan koneksi jaringan offline / terputus.\n3. Periksa penyimpanan cache lokal (Hive box) pada perangkat.",
        "expected": "Data form tersimpan sementara secara lokal dalam Hive box dan otomatis disinkronisasi saat koneksi pulih ([PRD.MD:135](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L135)).",
        "actual": "Tidak ditemukan pustaka Hive atau persistensi lokal di `pubspec.yaml` dan seluruh modul reservasi. Pemutusan koneksi menyebabkan data form hilang.",
        "method": "STATIC",
        "impact": "Resepsionis kehilangan seluruh input tamu yang sedang check-in saat Wi-Fi hotel mengalami gangguan fluktuatif.",
        "rec": "Pasang Hive/Isar untuk offline caching draft reservasi sebelum dikirim ke backend."
    },
    {
        "id": "QA-RES-03",
        "modul": "Reservasi & Check-in (Tarif Kamar)",
        "role": "Resepsionis",
        "req": "FR-RES-02, FR-RES-05, Matriks RBAC PRD §2.3 ([PRD.MD:68-71](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L68-L71), [132](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L132))",
        "title": "Resepsionis Dapat Mengubah Tarif Kamar Bebas Tanpa Otorisasi Manajer",
        "sev": "TINGGI (P2)",
        "steps": "1. Login sebagai `receptionist`.\n2. Klik kamar kosong untuk membuka formulir Check-in.\n3. Arahkan kursor ke field input 'Total Biaya (Rp)'.\n4. Hapus nominal otomatis dan ketikkan nominal sembarang (misal Rp 50.000).",
        "expected": "Tarif dihitung otomatis berdasarkan tipe kamar dan durasi menginap (FR-RES-05); hak mengubah tarif kamar hanya dimiliki oleh Manager (RBAC PRD §2.3 [PRD.MD:68-71](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L68-L71)).",
        "actual": "Field total biaya menggunakan controller terbuka tanpa proteksi `readOnly`, sehingga resepsionis dapat mengetikkan nominal sekehendak hati ([check_in_modal.dart:45](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L45)). Kode mencatat komentar 'diskon khusus/negosiasi'. [Perlu konfirmasi Product Owner].",
        "impact": "Potensi fraud atau manipulasi penerimaan kas hotel oleh staf frontdesk tanpa jejak otorisasi manajer.",
        "rec": "Kunci field harga menjadi `readOnly: true` untuk role Resepsionis. Bila diperlukan diskon/negosiasi, sediakan modal input kode otorisasi PIN Manajer."
    },
    {
        "id": "QA-RES-04",
        "modul": "Reservasi & Check-in (OCR KTP)",
        "role": "Resepsionis",
        "req": "FR-RES-04, NFR §4.1 ([PRD.MD:131](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L131), [Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148))",
        "title": "Ketiadaan Mekanisme Timeout Otomatis pada Pemrosesan OCR KTP (> 3 Detik)",
        "sev": "SEDANG (P3)",
        "steps": "1. Unggah berkas gambar KTP pada modal check-in.\n2. Simulasikan pemrosesan OCR yang memakan waktu > 3 detik.",
        "expected": "Jika pemrosesan OCR melebihi 3 detik, sistem otomatis menghentikan proses (timeout fallback) dan mengarahkan pengguna ke input manual penuh ([PRD.MD:277](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L277)).",
        "actual": "Tidak ada konfigurasi `timeout(Duration(seconds: 3))` pada simulasi OCR di [check_in_modal.dart:89](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L89); loading spinner berputar tanpa batas waktu.",
        "impact": "Antrean tamu di frontdesk tertahan jika proses OCR di server/client mengalami stall.",
        "rec": "Tambahkan `.timeout(const Duration(seconds: 3))` dan handler catchError untuk beralih otomatis ke manual mode."
    },
    {
        "id": "QA-RES-05",
        "modul": "Reservasi & Kompresi Berkas",
        "role": "Resepsionis",
        "req": "Arsitektur §2.4, Arsitektur §3.3 ([Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148))",
        "title": "Ketiadaan Pipeline Kompresi Gambar KTP Client (Maks 1.5MB, 1600px)",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa berkas implementasi penanganan gambar KTP di `check_in_modal.dart`.",
        "expected": "Ukuran gambar terkompresi maks 1.5MB, resize longest-edge 1600px sebelum dikirim ke API OCR ([Arsitektur.md:148](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L148)).",
        "actual": "Pipeline kompresi gambar client belum terintegrasi di [check_in_modal.dart:89](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L89); data masih menggunakan OCR mock berbasis delay waktu.",
        "impact": "Pengunggahan foto resolusi tinggi kamera tablet (10-20MB) akan membebani bandwidth jaringan hotel dan memicu error payload too large.",
        "rec": "Integrasikan paket `flutter_image_compress` dengan target resolusi max 1600px dan ukuran < 1.5MB."
    },
    {
        "id": "QA-RES-06",
        "modul": "Reservasi & Integritas Transaksi",
        "role": "Resepsionis",
        "req": "NFR §4.1, Integritas Transaksi ([PRD.MD:133](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L133), [PRD.MD:245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L245))",
        "title": "Tombol Submit Form Check-In Rentan Penekanan Ganda (Double-Submit)",
        "sev": "TINGGI (P2)",
        "steps": "1. Isi lengkap form check-in tamu.\n2. Lakukan klik cepat ganda (double-click) pada tombol 'Simpan & Check-In Tamu'.",
        "expected": "Tombol submit dinonaktifkan (disabled / isLoading: true) seketika setelah ketukan pertama agar tidak terjadi duplikasi transaksi reservasi.",
        "actual": "Widget `AppButton` pada [check_in_modal.dart:736](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L736) tidak mengikat parameter `isLoading: _isSubmitting`, sehingga callback `onPressed` dapat terpanggil berulang.",
        "impact": "Terjadinya race condition pembuatan invoice ganda atau bentrok alokasi kamar di database.",
        "rec": "Ikat state `isLoading: _isSubmitting` pada `AppButton` dan return segera bila `_isSubmitting == true`."
    },
    {
        "id": "QA-WA-01",
        "modul": "Notifikasi WhatsApp & Webhook",
        "role": "Resepsionis / Sistem",
        "req": "FR-WA-04, FR-WA-05, Arsitektur §6.2 ([PRD.MD:144-145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L144-L145))",
        "title": "Ketiadaan Penanganan Status Kegagalan Gateway WhatsApp Riil",
        "sev": "TINGGI (P2)",
        "steps": "1. Buka modal Daftar Tamu Aktif (`ActiveGuestsModal`).\n2. Tekan tombol pemicu manual 'Kirim Ulang WA'.\n3. Amati perubahan status dan penanganan error.",
        "expected": "Sistem mencatat status pengiriman (Sent/Delivered/Read/Failed) dari callback webhook gateway dan menampilkan UI penanganan jika Failed ([PRD.MD:145](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L145)).",
        "actual": "Tombol pemicu manual hanya menampilkan `ScaffoldMessenger` SnackBar lokal dengan delay tiruan; integrasi API Gateway WhatsApp riil belum ada di [active_guests_modal.dart:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L285).",
        "impact": "Resepsionis mengira pesan WhatsApp sudah terkirim ke tamu padahal gateway backend belum terhubung.",
        "rec": "Hubungkan pemicu manual dengan REST endpoint WhatsApp Gateway service dan dengarkan webhook status callback."
    },
    {
        "id": "QA-WA-02",
        "modul": "Notifikasi WhatsApp (Retry)",
        "role": "Sistem / Resepsionis",
        "req": "NFR §4.2, Arsitektur §6.3 ([PRD.MD:245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L245), [Arsitektur.md:345](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L345))",
        "title": "Ketiadaan Indikator dan Logika Auto-Retry WhatsApp 3x pada Frontend",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa berkas `active_guests_modal.dart` pada penanganan status pesan failed.",
        "expected": "Frontend menampilkan status percobaan ulang (mis. 'Mencoba ulang 1/3') saat pengiriman gagal ([Arsitektur.md:345](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L345)).",
        "actual": "Tidak ditemukan variabel pencatat counter percobaan ulang maupun teks status retry di [active_guests_modal.dart:46](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L46).",
        "impact": "Resepsionis tidak mengetahui apakah sistem sedang mencoba mengirim ulang atau pesan sudah gagal permanen.",
        "rec": "Tampilkan badge status percobaan `Retry X/3` pada baris tamu aktif di modal."
    },
    {
        "id": "QA-WA-03",
        "modul": "Notifikasi WhatsApp (Eskalasi)",
        "role": "Resepsionis / Manajer",
        "req": "Arsitektur §6.3 ([Arsitektur.md:348](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L348))",
        "title": "Ketiadaan Banner Notifikasi Peringatan Eskalasi Kegagalan WhatsApp 3x",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa kode antarmuka resepsionis saat kegagalan pengiriman berulang 3 kali.",
        "expected": "Alert otomatis ditampilkan di dashboard resepsionis bila pengingat WA gagal 3 kali berturut-turut ([Arsitektur.md:348](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L348)).",
        "actual": "Tidak ada komponen banner atau notifikasi peringatan eskalasi kegagalan di [active_guests_modal.dart:20](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/active_guests_modal.dart#L20).",
        "impact": "Tamu tidak menerima pengingat checkout tanpa disadari oleh staf resepsionis, menyebabkan keterlambatan checkout tak tertangani.",
        "rec": "Sediakan banner alert merah pada top bar resepsionis jika terdapat antrean pesan WhatsApp yang gagal 3 kali."
    },
    {
        "id": "QA-OUT-01",
        "modul": "Check-Out & Invoice",
        "role": "Resepsionis",
        "req": "FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))",
        "title": "Penomoran Invoice Menggunakan Nomor Kamar, Membuka Risiko Duplikasi Nomor Faktur",
        "sev": "TINGGI (P2)",
        "steps": "1. Buka `invoice_preview_dialog.dart` baris 40.\n2. Amati logika generator nomor invoice default.",
        "expected": "Format nomor invoice unik otomatis: `INV/SH/YYYYMMDD/XXXX` dengan urutan counter sekuensial 4 digit ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).",
        "actual": "Generator default membuat nomor invoice dengan format `INV/SH/YYYYMMDD/{room.roomNumber}`, bukan nomor sekuensial unik ([invoice_preview_dialog.dart:40](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L40)).",
        "impact": "Bila kamar 101 dihuni oleh dua tamu berbeda pada hari yang sama (mis. check-in siang setelah check-out pagi), nomor faktur akan terduplikasi sama persis.",
        "rec": "Gunakan sekuens generator unik terpusat dari server/database atau UUID v4 substring."
    },
    {
        "id": "QA-OUT-02",
        "modul": "Check-Out & Denda Keterlambatan",
        "role": "Resepsionis / Manajer",
        "req": "FR-OUT-05 ([PRD.MD:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L171))",
        "title": "Besaran Tarif Denda Keterlambatan Check-out Di-hardcode Rp 50.000/Jam",
        "sev": "SEDANG (P3)",
        "steps": "1. Buka dialog check-out untuk kamar yang melewati batas jam 12:00 WIB.\n2. Periksa kalkulasi nominal denda keterlambatan.",
        "expected": "Tarif denda keterlambatan dapat dikonfigurasi oleh manajer hotel ([PRD.MD:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L171)).",
        "actual": "Kalkulasi denda di-hardcode dengan konstanta `50000` per jam di [check_out_dialog.dart:58](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/check_out_dialog.dart#L58) tanpa membaca konfigurasi pengaturan manajer.",
        "impact": "Manajer tidak dapat menyesuaikan kebijakan tarif denda saat musim ramai (peak season) atau kebijakan promo hotel.",
        "rec": "Pindahkan konfigurasi tarif denda per jam ke `hotelSettingsProvider` yang dapat diedit di dashboard manajer."
    },
    {
        "id": "QA-OUT-03",
        "modul": "Check-Out & Pencetakan Faktur",
        "role": "Resepsionis",
        "req": "FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))",
        "title": "Tombol Cetak Thermal Printer Belum Terintegrasi Protokol ESC/POS Riil",
        "sev": "SEDANG (P3)",
        "steps": "1. Pada dialog invoice preview, klik tombol 'Cetak Thermal (58/80mm)'.\n2. Amati perilaku sistem.",
        "expected": "Fitur cetak langsung ke thermal printer (58mm/80mm) menghasilkan byte stream ESC/POS ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).",
        "actual": "Tombol hanya memicu SnackBar simulasi: `Simulasi cetak struk thermal 58mm...` ([invoice_preview_dialog.dart:488](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L488)).",
        "impact": "Frontdesk tidak dapat mencetak struk fisik bukti check-out ke mesin printer kasir hotel.",
        "rec": "Integrasikan driver/library pencetakan Bluetooth/USB printer ESC/POS (mis. `esc_pos_printer`)."
    },
    {
        "id": "QA-OUT-04",
        "modul": "Check-Out & Arsip Dokumen",
        "role": "Resepsionis",
        "req": "FR-OUT-03 ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169))",
        "title": "Tombol Unduh PDF Faktur Belum Menghasilkan Berkas PDF Riil",
        "sev": "SEDANG (P3)",
        "steps": "1. Pada dialog invoice preview, klik tombol 'Unduh PDF'.\n2. Periksa apakah berkas PDF diunduh.",
        "expected": "Sistem menghasilkan dan mengunduh berkas PDF faktur resmi ([PRD.MD:169](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L169)).",
        "actual": "Tombol hanya menampilkan SnackBar tiruan `Mengunduh PDF Invoice...` ([invoice_preview_dialog.dart:502](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/invoice_preview_dialog.dart#L502)).",
        "impact": "Tamu yang meminta salinan dokumen PDF resmi tidak dapat dilayani langsung.",
        "rec": "Implementasikan pembuatan dokumen PDF menggunakan paket `pdf` dan `printing` Dart."
    },
    {
        "id": "QA-REP-01",
        "modul": "Analitik Manajer & KPI",
        "role": "Manajer",
        "req": "FR-REP-01 ([PRD.MD:177](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L177))",
        "title": "Perhitungan Rasio Okupansi Mengabaikan Filter Kamar Under Maintenance",
        "sev": "SEDANG (P3)",
        "steps": "1. Login sebagai `manager`.\n2. Buka dashboard analitik.\n3. Periksa rumus kalkulasi widget 'Rasio Okupansi'.",
        "expected": "Rasio Okupansi dihitung dengan rumus: Kamar Terisi ÷ Total Kamar Aktif × 100% ([PRD.MD:177](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L177)). Kamar nonaktif/maintenance wajib dikeluarkan dari pembagi.",
        "actual": "Pembagi rasio okupansi di [manager_dashboard_screen.dart:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L215) membagi terhadap `totalRooms` termasuk kamar yang sedang rusak/maintenance.",
        "impact": "Angka KPI rasio hunian yang disajikan ke manajemen hotel terdistorsi lebih rendah dari kapasitas operasional riil.",
        "rec": "Koreksi rumus menjadi: `occupied / (totalRooms - maintenanceRooms) * 100`."
    },
    {
        "id": "QA-REP-02",
        "modul": "Analitik Manajer (Design System)",
        "role": "Manajer",
        "req": "Design System §6.8 ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215))",
        "title": "Palet Warna Grafik Saluran RedDoorz Menggunakan Non-Token `Colors.red.shade700`",
        "sev": "RENDAH (P4)",
        "steps": "1. Buka grafik komposisi saluran pemesanan di dashboard manajer.\n2. Periksa definisi warna segmen RedDoorz.",
        "expected": "Palet warna grafik: navy/700 dan orange/600 flat solid ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215)).",
        "actual": "Segmen RedDoorz menggunakan `Colors.red.shade700` ([manager_dashboard_screen.dart:458](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L458)) di luar sistem warna `AppColors`.",
        "impact": "Inkonsistensi identitas visual antarmuka analitik hotel.",
        "rec": "Gunakan `AppColors.orange600` untuk RedDoorz dan `AppColors.navy700` untuk Walk-In sesuai spec §6.8."
    },
    {
        "id": "QA-REP-03",
        "modul": "Laporan & Ekspor Excel",
        "role": "Manajer",
        "req": "FR-REP-03 ([PRD.MD:179](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L179))",
        "title": "Ekspor Laporan Excel (.xlsx) 2 Sheet Belum Menghasilkan File Spreadsheet Nyata",
        "sev": "TINGGI (P2)",
        "steps": "1. Pada panel manajer, klik tombol 'Ekspor Excel'.\n2. Periksa berkas keluaran.",
        "expected": "Sistem mengunduh berkas `.xlsx` berisi 2 sheet: Summary KPI dan Raw Data Detail Transaksi ([PRD.MD:179](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L179)).",
        "actual": "Tombol hanya menampilkan SnackBar mock `Membuat laporan Excel (XLSX)...` ([manager_dashboard_screen.dart:82](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L82)).",
        "impact": "Manajer tidak dapat melakukan rekapitulasi data keuangan bulanan ke akuntansi hotel.",
        "rec": "Hubungkan ke backend `/api/reports/export-excel` atau generate client-side via paket `excel` Dart."
    },
    {
        "id": "QA-REP-04",
        "modul": "Laporan & Ekspor PDF",
        "role": "Manajer",
        "req": "FR-REP-04 ([PRD.MD:180](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L180))",
        "title": "Ekspor PDF Format A4 Resmi dengan Kop Surat Belum Diimplementasikan",
        "sev": "TINGGI (P2)",
        "steps": "1. Klik tombol 'Ekspor PDF' pada panel manajer.\n2. Periksa berkas keluaran.",
        "expected": "Sistem menghasilkan PDF format A4 kop surat resmi, tabel rangkuman, grafik visual okupansi, dan kolom tanda tangan pengesahan Manajer ([PRD.MD:180](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L180)).",
        "actual": "Tombol hanya menampilkan SnackBar mock `Membuat laporan eksekutif PDF A4...` ([manager_dashboard_screen.dart:100](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L100)).",
        "impact": "Ketiadaan dokumen cetak fisik resmi untuk laporan pertanggungjawaban kepada pemilik properti hotel.",
        "rec": "Implementasikan pembuatan dokumen PDF format A4 lengkap dengan kop surat dan kolom pengesahan."
    },
    {
        "id": "QA-AUTH-01",
        "modul": "Autentikasi (Keamanan Brute-Force)",
        "role": "Pengguna Login",
        "req": "Arsitektur §3.3 ([Arsitektur.md:214-225](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L214-L225))",
        "title": "Ketiadaan Umpan Balik UI untuk Rate Limiter Percobaan Login (> 5 Kali/Menit)",
        "sev": "SEDANG (P3)",
        "steps": "1. Masukkan kata sandi salah berturut-turut lebih dari 5 kali dalam waktu 1 menit.\n2. Amati respons antarmuka form login.",
        "expected": "Sistem menampilkan alert pemblokiran sementara dengan timer hitung mundur bila terdeteksi percobaan > 5 kali ([Arsitektur.md:217](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L217)). Logika server rate limiting terpisah sebagai BLOCKED.",
        "actual": "Frontend tidak memiliki counter percobaan gagal di client dan tidak menampilkan banner lockout di [auth_controller.dart:41](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L41).",
        "impact": "Kurangnya perlindungan visual dan proteksi lokal terhadap serangan coba-coba kredensial di terminal frontdesk.",
        "rec": "Tambahkan counter percobaan login di `AuthNotifier` dan nonaktifkan tombol submit selama 60 detik setelah 5 kali kegagalan."
    },
    {
        "id": "QA-AUTH-02",
        "modul": "Autentikasi (Manajemen Sesi)",
        "role": "Resepsionis / Manajer",
        "req": "FR-AUTH-04 ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109))",
        "title": "Ketiadaan Mekanisme Auto-Logout Otomatis Setelah Sesi Idle 12 Jam",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa berkas `auth_controller.dart`.\n2. Cari konfigurasi timer idle atau token expiry.",
        "expected": "Sistem melakukan auto-logout otomatis saat sesi mencapai 12 jam, redirect ke login disertai pesan notifikasi ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109)).",
        "actual": "Tidak ada timer pendeteksi idle atau listener masa berlaku token di [auth_controller.dart:9](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L9); sesi bertahan di memori tanpa batas waktu.",
        "impact": "Komputer frontdesk yang ditinggalkan saat pergantian shift tetap terbuka tanpa memerlukan re-autentikasi staf baru.",
        "rec": "Pasang timer pengawas aktivitas sesi dan batalkan token setelah 12 jam."
    },
    {
        "id": "QA-AUTH-03",
        "modul": "Autentikasi (Persistensi Sesi)",
        "role": "Resepsionis / Manajer",
        "req": "FR-AUTH-04, Usabilitas Web ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109))",
        "title": "Refresh Halaman Web Browser (F5) Memusnahkan Sesi dan Memaksa Login Ulang",
        "sev": "SEDANG (P3)",
        "steps": "1. Login sebagai resepsionis.\n2. Lakukan refresh halaman browser (tekan F5 / Ctrl+R).\n3. Amati status navigasi aplikasi.",
        "expected": "Sesi tetap dipertahankan setelah refresh browser dan pengguna tetap berada di dashboard aktif.",
        "actual": "State autentikasi hanya tersimpan di memori volatil StateNotifier. Refresh memuat ulang kode dan mengarahkan kembali ke `/login` ([auth_controller.dart:76](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L76)).",
        "impact": "Resepsionis kehilangan konteks kerja dan harus login ulang setiap kali browser me-reload halaman.",
        "rec": "Simpan token sesi terenkripsi di `flutter_secure_storage` atau `shared_preferences` web."
    },
    {
        "id": "QA-AUTH-04",
        "modul": "Autentikasi (Keamanan Enumerasi)",
        "role": "Pengguna Login",
        "req": "Keamanan Enumerasi, FR-AUTH-01 ([PRD.MD:106](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L106))",
        "title": "Pesan Error Login Membocorkan Validitas Keberadaan Nama Pengguna",
        "sev": "RENDAH (P4)",
        "steps": "1. Pada form login, masukkan username acak `penyusup` dan sembarang password.\n2. Klik tombol Masuk.\n3. Baca teks pesan kesalahan yang tampil di layar.",
        "expected": "Pesan error generik yang tidak membocorkan apakah username terdaftar atau tidak (mis. 'Username atau kata sandi tidak valid').",
        "actual": "Sistem menampilkan: `Kredensial tidak valid. Gunakan akun receptionist atau manager.` di [auth_repository.dart:37](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/data/auth_repository.dart#L37), membocorkan daftar akun valid.",
        "impact": "Mempermudah penyerang memetakan (meng-enumerasi) nama akun yang ada pada sistem hotel.",
        "rec": "Gunakan pesan generik tanpa menyebutkan nama akun valid."
    },
    {
        "id": "QA-AUTH-05",
        "modul": "Autentikasi (Design System)",
        "role": "Pengguna Login",
        "req": "Design System §7 ([design.md:238-245](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L238-L245))",
        "title": "Pelanggaran Aturan Desain Tombol Aksen Oranye Tunggal pada Halaman Login",
        "sev": "RENDAH (P4)",
        "steps": "1. Buka halaman login.\n2. Amati elemen-elemen berwarna oranye pada layar.",
        "expected": "Nuansa Navy dominan, hanya ada satu aksen oranye pada tombol utama masuk saja ([design.md:240](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L240)).",
        "actual": "Terdapat kontainer ikon logo SH oranye 52x52px di samping tombol CTA oranye di [login_screen.dart:259](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/login_screen.dart#L259).",
        "impact": "Pelemahan fokus visual resepsionis terhadap tombol call-to-action utama.",
        "rec": "Ubah latar belakang kontainer logo menjadi Navy 800 dengan ikon putih/emas netral."
    },
    {
        "id": "QA-SEC-01",
        "modul": "Keamanan Data & Kredensial",
        "role": "Pengembang / Penyerang",
        "req": "FR-AUTH-05, Arsitektur §5 ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110), [Arsitektur.md:214-225](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L214-L225))",
        "title": "Kredensial Pengguna dan Kata Sandi Hardcoded dalam Berkas Kode Client",
        "sev": "KRITIS (P1)",
        "steps": "1. Buka berkas `lib/features/auth/data/auth_repository.dart`.\n2. Periksa array `_mockUsers` pada baris 4-19.",
        "expected": "Password tidak pernah disimpan plain text atau di-hardcode dalam client bundle ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110)).",
        "actual": "Kredensial username `receptionist` dan `manager` beserta password plain text `password123` tertulis langsung di kode sumber client.",
        "impact": "Siapa pun yang menginspeksi build bundle Flutter web dapat membaca password staf dan manajer hotel secara langsung.",
        "rec": "Hapus mock static users; hubungkan autentikasi ke backend API Supabase/PostgreSQL dengan hashing bcrypt."
    },
    {
        "id": "QA-SEC-02",
        "modul": "Keamanan Sesi & Token",
        "role": "Penyerang / Pengembang",
        "req": "Arsitektur §5 ([Arsitektur.md:218](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L218))",
        "title": "Penyimpanan Token Autentikasi Tanpa Mekanisme Secure Storage",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa penanganan token JWT tiruan di `auth_repository.dart` baris 42 dan `auth_controller.dart`.",
        "expected": "Token JWT disimpan dalam mekanisme secure storage atau HttpOnly cookie ([Arsitektur.md:218](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L218)).",
        "actual": "Token hanya berupa string di memori RAM StateNotifier tanpa persistensi terenkripsi.",
        "impact": "Ketiadaan manajemen token standar membatasi implementasi refresh token dan keamanan sesi lintas jendela browser.",
        "rec": "Terapkan `flutter_secure_storage` untuk menyimpan access token secara terenkripsi."
    },
    {
        "id": "QA-TEST-01",
        "modul": "Otomasi QA Suite",
        "role": "QA Engineer",
        "req": "DoD PRD §8 ([PRD.MD:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L285))",
        "title": "Kegagalan Eksekusi Automated Widget Test Bawaan (`widget_test.dart`)",
        "sev": "SEDANG (P3)",
        "steps": "1. Jalankan perintah `flutter test test/widget_test.dart` pada terminal.",
        "expected": "Seluruh suite automated test berjalan dan lulus tanpa exception/failure ([PRD.MD:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L285)).",
        "actual": "Test gagal karena matcher teks `Sinar Harapan Frontdesk` tidak ditemukan pada widget tree LoginScreen di [widget_test.dart:18](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/widget_test.dart#L18).",
        "impact": "Pipeline CI/CD otomatis akan memblokir proses build akibat kegagalan tes regresi bawaan.",
        "rec": "Perbarui teks pencarian pada test agar sesuai dengan label judul antarmuka `HOTEL SINAR HARAPAN`."
    },
    {
        "id": "QA-DS-01",
        "modul": "Design System (Status Kamar)",
        "role": "Resepsionis",
        "req": "FR-ROOM-02, Design System §6.3 ([PRD.MD:117](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L117), [design.md:171](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L171))",
        "title": "Konflik Dua Set Hex Token Warna Status Kamar Antara Spec §2.3 dan §6.3",
        "sev": "SEDANG (P3)",
        "steps": "1. Periksa definisi warna pada `lib/app/theme.dart` baris 25-45.\n2. Bandingkan `RoomCard._stripeColor` dengan `StatusBadge`.",
        "expected": "Satu sumber kebenaran (single source of truth) untuk kode warna status: Hijau, Merah, Kuning, Abu-abu.",
        "actual": "Terjadi perbedaan nilai hex antara `AppColors` di theme.dart dan spesifikasi badge status di status_badge.dart (mis. #16A34A vs #22C55E).",
        "impact": "Persepsi visual resepsionis terhadap kamar Available vs Dirty dapat membingungkan saat pencahayaan layar redup.",
        "rec": "Unifikasi seluruh token warna status ke dalam `AppColors` di `theme.dart` merujuk ke hex dengan rasio kontras terbaik."
    },
    {
        "id": "QA-DS-02",
        "modul": "Design System & Aksesibilitas Layout",
        "role": "Resepsionis / Manajer",
        "req": "Design System §6.7, Design System §6.1 ([design.md:150](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L150), [202](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L202))",
        "title": "Responsivitas Layout Baris Metrik / Header Mengalami RenderFlex Overflow pada Resolusi Tablet",
        "sev": "SEDANG (P3)",
        "steps": "1. Jalankan aplikasi pada resolusi tablet (lebar 768px - 1024px).\n2. Buka dashboard resepsionis atau dashboard manajer.",
        "expected": "Seluruh baris metrik dan tombol beradaptasi responsif tanpa RenderFlex overflow.",
        "actual": "Ditemukan layout overflow: Row di [app_header.dart:511](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/shared_widgets/app_header.dart#L511) overflow 52px, Row di [manager_dashboard_screen.dart:592](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L592) overflow 39px, dan icon button memiliki touch target < 44px.",
        "impact": "Tampilan antarmuka tampak rusak dengan garis belang kuning-hitam di layar tablet resepsionis.",
        "rec": "Bungkus teks panjang dengan `Flexible`/`Expanded` dan pastikan `mainAxisSize: MainAxisSize.min`."
    },
    {
        "id": "QA-DS-04",
        "modul": "Design System Compliance (Anti-AI Slop)",
        "role": "Manajer",
        "req": "Design System §6.8, Design System §9 ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215), [268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268))",
        "title": "Pelanggaran Anti AI-Slop: Area Bawah Grafik Tren Menggunakan Isian `LinearGradient`",
        "sev": "RENDAH (P4)",
        "steps": "1. Buka berkas `lib/features/reporting/presentation/widgets/executive_trend_chart.dart` baris 607.",
        "expected": "Palet grafik: navy/700 dan orange/600 flat solid, dilarang gradient ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215), [268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268)).",
        "actual": "Ditemukan penggunaan `LinearGradient` pada properti area bawah grafik tren eksekutif di baris 607.",
        "impact": "Menyalahi aturan estetika minimalis profesional Anti-AI Slop yang ditetapkan spesifikasi desain.",
        "rec": "Ganti isian gradient dengan warna solid transparan `AppColors.navy700.withAlpha(20)` atau hilangkan area fill."
    },
    {
        "id": "QA-DS-05",
        "modul": "Design System Compliance (Elevasi)",
        "role": "Resepsionis",
        "req": "Design System §4.3 ([design.md:135-142](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L135-L142))",
        "title": "Penggunaan Inline `BoxShadow` Hardcoded di Luar Spesifikasi Elevation Token",
        "sev": "RENDAH (P4)",
        "steps": "1. Periksa berkas `whatsapp_receipt_dialog.dart` baris 637 dan 828.",
        "expected": "Seluruh elevasi bayangan wajib menggunakan token `AppElevation.none`, `AppElevation.card`, `AppElevation.modal`, atau `AppElevation.dropdown` ([design.md:137](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L137)).",
        "actual": "Ditemukan definisi `BoxShadow(blurRadius: 10, offset: Offset(0, 4))` dan `BoxShadow(blurRadius: 3)` hardcoded inline di luar token sistem.",
        "impact": "Inkonsistensi kedalaman elevasi elemen UI di dialog bukti bayar WhatsApp.",
        "rec": "Ganti inline BoxShadow dengan `boxShadow: AppElevation.card` atau `AppElevation.modal`."
    },
    {
        "id": "QA-DS-06",
        "modul": "Design System (Navigasi & Top Bar)",
        "role": "Resepsionis",
        "req": "Design System §6.9 ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223))",
        "title": "Informasi Jam Shift Bertugas Resepsionis Tidak Ditampilkan pada Top Bar",
        "sev": "RENDAH (P4)",
        "steps": "1. Amati tampilan widget `ReceptionistTopBar` di bagian atas denah kamar.",
        "expected": "Top bar tinggi 64px, menampilkan identitas brand, jam live, dan jam shift bertugas (mis. Shift 07:00 - 19:00 WIB) ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223)).",
        "actual": "Widget `ReceptionistTopBar` hanya menampilkan jam live detik dan tanggal; informasi jam shift bertugas sama sekali tidak ada di kode (0 hit grep `shift`).",
        "impact": "Staf resepsionis tidak melihat indikator batas akhir waktu kerja shift mereka di header aplikasi.",
        "rec": "Tambahkan badge teks informasi shift kerja (mis. 'Shift Pagi · 07:00 - 19:00') di samping jam live pada `ReceptionistTopBar`."
    }
]

print(f"Total detailed bugs defined in Section 5: {len(bugs_data)}")

sec5_md = "## 5. Daftar Lengkap Laporan Bug (Format §14)\n\n"
for b in bugs_data:
    sec5_md += f"### {b['id']}: {b['title']}\n"
    sec5_md += f"- **ID Bug:** {b['id']}\n"
    sec5_md += f"- **Modul:** {b['modul']}\n"
    sec5_md += f"- **Role Diuji:** {b['role']}\n"
    sec5_md += f"- **Requirement:** {b['req']}\n"
    sec5_md += f"- **Judul:** {b['title']}\n"
    sec5_md += f"- **Tingkat Keparahan:** {b['sev']}\n"
    sec5_md += f"- **Langkah Reproduksi:**\n"
    for line in b['steps'].splitlines():
        sec5_md += f"  {line}\n"
    sec5_md += f"- **Expected Behavior:** {b['expected']}\n"
    sec5_md += f"- **Actual Behavior:** {b['actual']}\n"
    sec5_md += f"- **Dampak Bisnis / Teknis:** {b['impact']}\n"
    sec5_md += f"- **Rekomendasi Perbaikan:** {b['rec']}\n\n"

with open("test/qa/sec5_formatted.md", "w", encoding="utf-8") as out:
    out.write(sec5_md)

print("Saved Section 5 to test/qa/sec5_formatted.md")
