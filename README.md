# 🏨 Sinar Harapan Frontdesk & Property Management System (PMS)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-14%20(App%20Router)-black?logo=next.js&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-5.22-2D3748?logo=prisma&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-red)
![QA Audit](https://img.shields.io/badge/QA%20Audit-v3.0%20Verified-success)

Sistem Informasi Manajemen Properti Terpadu (PMS) dan Meja Resepsionis untuk **Hotel Sinar Harapan** (Mitra Resmi RedDoorz). Dibangun dengan arsitektur modern berstandar enterprise untuk mengakomodasi operasional berkecepatan tinggi di lobi resepsionis dan pengambilan keputusan strategis oleh manajemen hotel.

---

## 📑 Daftar Isi

1. [Executive Summary & Masalah Bisnis](#-executive-summary--masalah-bisnis)
2. [Fitur Unggulan](#-fitur-unggulan)
3. [Arsitektur Sistem & Alur Data](#-arsitektur-sistem--alur-data)
4. [Role-Based Access Control (RBAC)](#-role-based-access-control-rbac)
5. [Struktur Repositori & Modul](#-struktur-repositori--modul)
6. [Panduan Instalasi & Menjalankan Sistem](#-panduan-instalasi--menjalankan-sistem)
7. [Skema Database & Prisma ORM](#-skema-database--prisma-orm)
8. [Integrasi Pihak Ketiga](#-integrasi-pihak-ketiga)
9. [Design System & Aksesibilitas (WCAG 2.1)](#-design-system--aksesibilitas-wcag-21)
10. [Pengujian & Penjaminan Kualitas (QA Suite)](#-pengujian--penjaminan-kualitas-qa-suite)
11. [Keamanan & Kepatuhan Privasi Data (UU PDP)](#-keamanan--kepatuhan-privasi-data-uu-pdp)
12. [Roadmap Pengembangan Masa Depan](#-roadmap-pengembangan-masa-depan)

---

## 🎯 Executive Summary & Masalah Bisnis

### Latar Belakang Masalah
1. **Antrean Lobi & Input KTP Manual** — Pencatatan identitas tamu secara manual saat *walk-in* memakan waktu 5–7 menit per tamu dan rentan salah ketik NIK 16-digit.
2. **Keterpisahan Kanal OTA vs Offline** — Risiko tinggi overbooking antara tamu aplikasi RedDoorz dengan tamu walk-in yang datang langsung.
3. **Keterlambatan Check-out (Late Check-out)** — Tidak adanya otomasi pengingat jam keluar mengakibatkan keterlambatan pembersihan kamar oleh housekeeping.
4. **Visibilitas Laporan yang Lemah** — Manajemen kesulitan memantau okupansi, rasio kanal penjualan, dan pendapatan harian tanpa rekapitulasi buku manual atau spreadsheet terpisah.

### Target Solusi & KPI
* ⚡ **Durasi Check-in:** Dipangkas dari 5–7 menit menjadi **< 2 menit** melalui pemindaian OCR KTP.
* 🟢 **Status Kamar Real-time:** Visualisasi denah kamar interaktif berbasis warna status (Tersedia, Terisi, Kotor, Perbaikan).
* 📲 **100% WhatsApp Reminder Otomatis:** Notifikasi pengingat keluar otomatis H-1 jam sebelum batas waktu check-out (12:00 WIB).
* 📊 **Eksekutif Dashboard:** Metrik KPI instan (RevPAR, ADR, Okupansi harian) dan ekspor laporan berkala terformat (Excel/PDF).
* 🛡️ **Zero Typo NIK:** Validasi format ketat dan ekstraksi gambar otomatis beresolusi tinggi.

---

## ✨ Fitur Unggulan

### 1. Visual Room Grid & Manajemen Kamar
* Denah kamar interaktif dengan pembagian per lantai (Lantai 1, 2, dst.).
* Indikator warna status real-time:
  * 🟢 **Available (Hijau):** Kamar bersih siap huni.
  * 🔵 **Occupied (Biru/Oranye):** Sedang dihuni tamu.
  * 🟡 **Dirty (Kuning Amber):** Menunggu pembersihan oleh housekeeping.
  * 🔴 **Maintenance (Merah/Abu-abu):** Dalam perbaikan teknis.
* Quick action menu: Update status kebersihan kamar dengan 1 kali klik.

### 2. Modul Check-in Cepat (Walk-in & RedDoorz)
* **Kanal RedDoorz:** Input ID booking OTA, auto-fill tarif khusus mitra.
* **Kanal Walk-in:** Integrasi pemindaian kamera untuk OCR KTP (Nama, NIK, Alamat, TTL terisi otomatis).
* Kalkulasi biaya kamar, durasi menginap, deposit kunci, dan diskon negosiasi.
* Proteksi anti *double-submit* saat pemrosesan reservasi.

### 3. Otomasi WhatsApp Gateway
* Pengiriman invoice digital otomatis ke nomor WhatsApp tamu setelah pembayaran.
* Pengingat otomatis check-out pada pukul 11:00 WIB (H-1 jam sebelum batas waktu).
* Webhook sinkronisasi status pengiriman pesan (*Sent, Delivered, Read, Failed*).

### 4. Modul Check-out & Kasir
* Kalkulasi tagihan otomatis: durasi menginap + denda keterlambatan + minibar/kerusakan - pengembalian deposit.
* Preview cetak struk kasir termal (format standar 58mm dan 80mm).
* Cetak invoice digital PDF berlogo resmi Sinar Harapan.

### 5. Dashboard Analitik & Laporan Manajerial
* Kartu performa metrik: Tingkat Okupansi (%), Total Tamu Aktif, Pendapatan Hari Ini, Kamar Kotor.
* Grafik tren komparasi: Pendapatan RedDoorz vs Walk-in per minggu/bulan.
* Filter rentang tanggal fleksibel (Hari ini, 7 Hari Terakhir, Bulan Ini, Kustom).
* Mesin ekspor laporan terformat:
  * **Excel (.xlsx):** Multi-sheet rekap reservasi, pendapatan, dan log audit.
  * **PDF:** Format cetak resmi untuk arsip direksi dan pembukuan akuntansi.

---

## 🏛️ Arsitektur Sistem & Alur Data

Sistem mengadopsi pola **Modular Monolith** dengan pendekatan **API-First** dan arsitektur frontend **Feature-First**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FRONTEND: FLUTTER APP                           │
│             (Web Desktop / Tablet Kasir Meja Resepsionis)              │
│  - Presentation: Riverpod StateNotifier + GoRouter                     │
│  - UI: Responsive Breakpoints (1024px, 1280px, 1920px)                 │
│  - Design System: Custom Token-based Theme (No AI Slop)                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST API (JSON)
                                    │ Authorization: Bearer <JWT>
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      BACKEND: NEXT.JS (APP ROUTER)                     │
│  • Route Handlers (API Endpoints: /api/v1/...)                         │
│  • RBAC & Auth Middleware Guard                                        │
│  • Zod Schema Validator                                                │
│  • Node-cron Scheduler (Trigger Pengingat Check-out)                   │
│  • Prisma ORM Layer (Transactions & Queries)                           │
└──────────────┬────────────────────┬────────────────────┬───────────────┘
               │                    │                    │
┌──────────────┴───────┐   ┌────────┴─────────┐ ┌────────┴─────────────┐
│   DATABASE ENGINE    │   │  OCR SERVICE     │ │    WA GATEWAY        │
│ PostgreSQL 15+       │   │ Google Cloud     │ │ Fonnte / Wablas API  │
│ (Tables & Audits)    │   │ Vision API       │ │ (Template & Webhook) │
└──────────────────────┘   └──────────────────┘ └──────────────────────┘
```

### Karakteristik Teknis
* **Stateless Session:** Backend tidak menyimpan sesi di memori server; otentikasi menggunakan stateless JWT dengan masa aktif terukur.
* **Audit-First Data Integrity:** Setiap mutasi data kamar dan transaksi keuangan wajib dicatat di tabel `activity_logs`.
* **Graceful Degradation:** Kegagalan koneksi OCR atau gateway WhatsApp tidak memblokir alur operasional utama resepsionis (fallback ke input manual).

---

## 👥 Role-Based Access Control (RBAC)

Aplikasi menerapkan pembatasan hak akses berbasis peran secara ketat (*Defense in Depth*):

| Modul / Kemampuan | Resepsionis (Frontdesk) | Manajer Hotel |
|---|:---:|:---:|
| **Denah Kamar (Room Grid)** | View & Update Status | View Only |
| **Proses Check-in (Scan KTP & Input Tamu)** | Akses Penuh (Create/Edit) | ❌ Dilarang |
| **Proses Check-out & Cetak Invoice** | Akses Penuh | View Only |
| **Pembersihan Kamar (Housekeeping update)** | Akses Cepat | ❌ Dilarang |
| **Manajemen Inventaris Kamar (CRUD Kamar)** | ❌ Dilarang | Akses Penuh (Tambah/Hapus/Edit Tarif) |
| **Executive Dashboard & Grafik Finansial** | ❌ Dilarang | Akses Penuh |
| **Ekspor Laporan (Excel & PDF)** | ❌ Dilarang | Akses Penuh |
| **Audit Trail (Log Aktivitas Staf)** | ❌ Dilarang | Akses Penuh (Read Only) |

---

## 📂 Struktur Repositori & Modul

```
sinarharapan_app/
├── lib/                                # FRONTEND FLUTTER
│   ├── main.dart                       # Entry point aplikasi & inisialisasi lokalisasi ID
│   ├── app/
│   │   ├── router.dart                 # Konfigurasi GoRouter & proteksi rute
│   │   └── theme.dart                  # Design tokens, warna status, & tipografi
│   └── features/
│       ├── auth/                       # Autentikasi pengguna & manajemen sesi
│       │   ├── data/                   # AuthRepository & JWT token handler
│       │   ├── domain/                 # Model UserModel & Role Enum
│       │   └── presentation/           # LoginScreen & AuthStateProvider
│       ├── room_management/            # Modul denah kamar & status
│       │   ├── data/                   # RoomRepository & mock data kamar
│       │   ├── domain/                 # RoomModel & RoomStatus Enum
│       │   └── presentation/           # RoomGridScreen, RoomCard, RoomFilterBar, RoomCrudDialog
│       ├── reservation/                # Modul reservasi & check-in
│       │   ├── presentation/           # CheckInModal (OCR KTP, input durasi), ActiveGuestsModal
│       ├── checkout/                   # Modul keluar tamu & kasir
│       │   ├── presentation/           # CheckOutDialog, InvoicePreviewDialog, WhatsAppReceiptDialog
│       ├── reporting/                  # Modul laporan & dashboard eksekutif
│       │   ├── presentation/           # ManagerDashboardScreen, ExecutiveTrendChart, ExportDialog
│       └── shared_widgets/             # Komponen UI bersama
│           ├── app_button.dart         # Varian tombol (Primary, Secondary, Outline, Destructive)
│           ├── app_text_field.dart     # Input form dengan label & pesan error
│           ├── app_header.dart         # TopBar resepsionis & status shift kerja
│           ├── metric_card.dart        # Kartu statistik dashboard
│           └── status_badge.dart       # Lencana status kamar & reservasi
│
├── backend/                            # BACKEND NEXT.JS (APP ROUTER)
│   ├── package.json                    # Dependensi backend (Next.js, Prisma, Zod, ExcelJS)
│   ├── prisma/
│   │   └── schema.prisma               # Definisi skema PostgreSQL & relasi tabel
│   └── lib/
│       ├── cron/                       # Node-cron scheduler (Reminder Check-out H-1 jam)
│       ├── services/                   # Layanan OCR, WhatsApp Gateway, & Generator Invoice
│       └── validators/                 # Validasi skema Zod (Reservation, Auth, Room)
│
├── test/                               # SUITE PENGUJIAN & QA
│   └── qa/
│       ├── qa_verification_test.dart   # Widget test Flutter (Button sizing, grid layout, RBAC)
│       ├── run_grep_suite.py           # Script audit integritas statis
│       ├── validate_parity.py          # Script validasi ID bug dua arah
│       └── calc_totals.py              # Script kalkulasi matriks hasil audit QA
│
├── PRD.MD                              # Dokumen Spesifikasi Kebutuhan Produk (v1.0 Baseline)
├── Arsitektur.md                       # Dokumen Spesifikasi Arsitektur Teknis Sistem
├── design.md                           # Dokumen Pedoman Desain & Design Tokens
└── LAPORAN_QA_v3.md                    # Laporan Audit QA Komprehensif (98 Test Cases)
```

---

## 🚀 Panduan Instalasi & Menjalankan Sistem

### Prasyarat Sistem
* **Flutter SDK:** Version 3.24.x atau lebih tinggi ([Unduh Flutter](https://docs.flutter.dev/get-started/install))
* **Node.js:** Version 20.x LTS ([Unduh Node.js](https://nodejs.org/))
* **Database:** PostgreSQL versi 15 atau lebih tinggi
* **Web Browser:** Google Chrome / Edge versi terbaru

---

### 1. Menjalankan Frontend (Flutter)

1. Masuk ke direktori utama aplikasi:
   ```bash
   cd "c:/Sinar Harapan APP/sinarharapan_app"
   ```

2. Unduh seluruh dependensi Flutter:
   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi dalam mode Web Server (Port 8080):
   ```bash
   flutter run -d web-server --web-port=8080
   ```
   *Buka peramban di `http://localhost:8080`.*

4. Untuk menjalankan langsung di peramban Chrome lokal:
   ```bash
   flutter run -d chrome
   ```

5. Menjalankan build bundle produksi (Web):
   ```bash
   flutter build web --release
   ```

---

### 2. Menjalankan Backend (Next.js & Prisma)

1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```

2. Pasang dependensi Node.js:
   ```bash
   npm install
   ```

3. Buat berkas variabel lingkungan `.env` di folder `backend/`:
   ```env
   # Database Connection
   DATABASE_URL="postgresql://postgres:password@localhost:5432/sinarharapan_pms?schema=public"

   # Keamanan & JWT
   JWT_SECRET="super-secret-sinar-harapan-jwt-key-minimum-32-chars"
   JWT_EXPIRES_IN="8h"

   # Layanan OCR (Google Cloud Vision)
   GCP_VISION_API_KEY="AIzaSyYourApiKeyHere"

   # Gateway WhatsApp (Fonnte / Wablas)
   WA_GATEWAY_URL="https://api.fonnte.com/send"
   WA_API_TOKEN="your_wa_token_here"

   # Cron Engine
   ENABLE_CHECKOUT_REMINDER="true"
   ```

4. Sinkronisasi skema database menggunakan Prisma:
   ```bash
   npx prisma generate
   npx prisma migrate dev --name init
   ```

5. Jalankan server pengembangan backend:
   ```bash
   npm run dev
   ```
   *Backend API aktif di `http://localhost:3000/api`.*

---

## 🗄️ Skema Database & Prisma ORM

Skema database PostgreSQL dirancang secara relasional dengan integritas data tingkat tinggi:

```mermaid
erDiagram
    User ||--o{ Reservation : handles
    User ||--o{ ActivityLog : performs
    Room ||--o{ Reservation : assigned_to
    Guest ||--o{ Reservation : books
    Reservation ||--o| Payment : generates
    Reservation ||--o{ WaNotification : logs

    User {
        uuid id PK
        string username UK
        string passwordHash
        string fullName
        enum role "RECEPTIONIST | MANAGER"
        boolean isActive
    }

    Room {
        uuid id PK
        string roomNumber UK
        string roomType "Standard | Deluxe | Family"
        int floor
        decimal basePrice
        enum status "AVAILABLE | OCCUPIED | DIRTY | MAINTENANCE"
    }

    Guest {
        uuid id PK
        string nik UK
        string fullName
        string phone
        string address
    }

    Reservation {
        uuid id PK
        string bookingCode UK
        enum source "REDDOORZ | WALK_IN"
        datetime checkIn
        datetime checkOut
        decimal totalPrice
        decimal depositAmount
    }
```

---

## 🔌 Integrasi Pihak Ketiga

### 1. Optical Character Recognition (OCR KTP)
* **Penyedia:** Google Cloud Vision API / Tesseract Engine.
* **Mekanisme:** Gambar KTP diunggah oleh webcam resepsionis atau ponsel kasir, diproses untuk mengekstrak string:
  * NIK (16 digit angka)
  * Nama Lengkap
  * Alamat & Kota
  * Tanggal Lahir
* **Keamanan:** Berkas foto mentah disimpan sementara dengan signed URL (kedaluwarsa 15 menit) dan tidak dapat diakses secara publik.

### 2. WhatsApp Business Gateway (Fonnte / Wablas)
* **Kanal Komunikasi:** REST API JSON via HTTPS.
* **Use Case:**
  * Pengiriman faktur pembayaran resmi format digital instan ke nomor WhatsApp tamu.
  * Pengiriman pesan pengingat jadwal check-out otomatis setiap hari pada pukul 11:00 WIB.
* **Webhook Sinkronisasi:** Memperbarui indikator status pengiriman pada dasbor resepsionis secara real-time.

---

## 🎨 Design System & Aksesibilitas (WCAG 2.1)

Aplikasi mengikuti panduan desain ketat di `design.md` tanpa elemen *generic AI slop* (tidak menggunakan blur berlebihan, glassmorphism sembarangan, atau gradien acak).

### Token Warna Resmi
| Peran Warna | Hex Code | Relative Luminance ($L$) | Penggunaan |
|---|---|:---:|---|
| **Primary Navy** | `#0A192F` | `0.0133` | Sidebar, AppBar, teks heading utama |
| **Accent Orange** | `#FF6600` | `0.3076` | Tombol CTA utama, badge RedDoorz, highlight |
| **Status Available** | `#16A34A` | `0.2686` | Kamar bersih & reservasi selesai |
| **Status Dirty** | `#CA8A04` | `0.3074` | Kamar kotor menunggu housekeeping |
| **Status Occupied** | `#2563EB` | `0.1356` | Kamar aktif dihuni tamu |
| **Status Maintenance** | `#DC2626` | `0.1477` | Kamar rusak / blok perbaikan |
| **Surface Light** | `#F8FAFC` | `0.9632` | Background layar kerja |

### Standar Ukuran & Ergonomi Tablet
* **Ukuran Tombol Interaktif:** Minimum tinggi **48px–50px** (memenuhi batas standar sentuhan tangan tablet kasir).
* **Kartu Kamar (Room Card):** Dimensi **140px × 100px** dengan visual badge nomor kamar tegas dan indikator kebersihan.
* **Kontras Rasio WCAG 2.1:**
  * Kontras Teks Normal ($< 18\text{pt}$): Wajib $\ge 4.5:1$.
  * Rekomendasi teks pada tombol oranye: Menggunakan warna Navy 900 (`#001B4E`) dengan kontras rasio **$5.65:1$** (Lolos WCAG AA).

---

## 🧪 Pengujian & Penjaminan Kualitas (QA Suite)

Aplikasi memiliki rangkaian uji otomatis di folder `test/qa/` yang memverifikasi tata letak, ukuran elemen, dan kepatuhan peran (RBAC).

### Menjalankan Uji Widget Flutter
Eksekusi pengujian verifikasi otomatis:
```bash
flutter test test/qa/qa_verification_test.dart
```

### Hasil Verifikasi Pengujian (Terminal Output)
```text
00:00 +0: loading test/qa/qa_verification_test.dart
00:04 +0: QA-1 [EXECUTED]: Verifikasi tinggi tombol AppButton minimum 48px pada semua varian
00:05 +1: QA-2 [EXECUTED]: Verifikasi jumlah kolom grid kamar pada lebar 1280px dan 1920px
00:06 +2: QA-3 [EXECUTED]: Verifikasi RBAC Receptionist mencoba akses route Manager Dashboard (/manager/dashboard)
00:07 +3: QA-4 [EXECUTED]: Verifikasi RBAC Manager mencoba klik kartu kamar untuk membuka CheckInModal
00:07 +4: All tests passed!
```

### Matriks Laporan Audit QA v3.0 (`LAPORAN_QA_v3.md`)
Berdasarkan hasil audit komprehensif terhadap 98 kasus uji:
* **EXECUTED (Pengujian Nyata di Lingkungan Kerja):** 12 Kasus Uji.
* **STATIC (Audit Kode & Analisis Struktural):** 83 Kasus Uji.
* **BLOCKED (Ketergantungan Infrastruktur/Kamera Nyata):** 3 Kasus Uji.
* **Tingkat Kepatuhan Keseluruhan:** Status Pass (42), Partial (13), Fail (40), Blocked (3).

---

## 🔒 Keamanan & Kepatuhan Privasi Data (UU PDP)

1. **Perlindungan NIK & Data Pribadi:**
   * Nomor Induk Kependudukan (NIK) disamarkan (*masked*) pada tampilan layar umum resepsionis (contoh: `3201************`).
   * Foto KTP disimpan dalam bucket tertutup dengan akses berbasis *time-limited signed URL* (15 menit).
2. **Keamanan Autentikasi:**
   * Password di-hash menggunakan algoritma `bcryptjs` dengan *salt rounds* 10.
   * Token JWT tersimpan aman dan divalidasi oleh middleware pada setiap endpoint API backend.
3. **Pencegahan Double-Submit:**
   * Seluruh tombol transaksi (Simpan Check-in, Pembayaran, Check-out) dilengkapi *loading state debounce* untuk mencegah pembuatan data ganda saat terjadi lag koneksi.

---

## 🗺️ Roadmap Pengembangan Masa Depan

* [ ] **Fase 2 (Channel Manager Multi-OTA):** Integrasi langsung API Traveloka, Tiket.com, dan Agoda dengan sinkronisasi inventaris kamar dua arah otomatis.
* [ ] **Fase 3 (Housekeeping PWA Mobile):** Aplikasi web ringan untuk staf kebersihan hotel untuk mengubah status kamar kotor menjadi bersih secara real-time dari ponsel.
* [ ] **Fase 4 (Guest Self-Service Kiosk):** Layanan anjungan mandiri di lobi hotel untuk check-in mandiri tamu tanpa antre di meja resepsionis.

---

<p align="center">
  <b>Hotel Sinar Harapan Frontdesk & Property Management System</b><br>
  <i>Dikembangkan secara profesional untuk keunggulan operasional hotel.</i>
</p>
