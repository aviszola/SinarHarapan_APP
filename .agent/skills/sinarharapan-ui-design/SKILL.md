---
name: sinarharapan-ui-design
description: Design standard, visual tokens, and anti-slop guidelines for Sinar Harapan PMS (Flutter/Dart). Standardizes operational hotel tool UI across mobile and desktop.
---

# Sinar Harapan PMS — UI & Design Standard Skill

Skill ini menetapkan panduan desain, token visual, dan standar anti-slop untuk antarmuka pengguna Sinar Harapan Property Management System (PMS).

## 1. Filosofi & Karakter Produk
- **Alat Kerja Operasional Frontdesk**: Digunakan oleh staf hotel berkali-kali per shift kerja. Desain harus efisien, kokoh, ergonomis, dan tidak melelahkan mata.
- **Bukan Template SaaS Generik**: Hindari kesan landing page promosi marketing. Utamakan data operasional nyata (jam kerja live, nomor shift, status koneksi lokal, ringkasan kamar).
- **Prinsip Eliminasi**: Setiap elemen UI harus memiliki fungsi jelas. Jika sebuah elemen hanya "tampak bagus" tanpa kegunaan operasional, elemen tersebut wajib dihapus.

## 2. Hard Constraints & Aturan Warna
- **Zero Color Mutation**: Dilarang menambahkan warna baru, gradient baru, atau kode hex ad-hoc.
- **Gunakan Token Resmi `AppColors`**:
  - `brandNavy` (`#0A2A6E`) / `brandNavyDark` (`#001B4E`) / `brandNavyLight` (`#1E4499`) / `brandNavyTint` (`#EEF2F9`): Struktur, sidebar, header, tombol sekunder, border fokus.
  - `brandOrange` (`#FF6600`) / `brandOrangeHover` (`#E65C00`) / `brandOrangeTint` (`#FFF4EB`): Aksi utama, brand mark SH, indikator aktif terpilih.
  - `surface` (`#FFFFFF`) / `bg` (`#F7F8FA`): Latar kanvas kerja hangat & bersih.
  - `textPrimary` (`#1A1F2C`) / `textSecondary` (`#505A69`) / `textMuted` (`#8690A0`): Tipografi tajam berstandar kontras.
  - `border` (`#E2E4E8`): Garis batas pemisah halus (1px).
  - Variasi opasitas dari warna dasar yang ada diperbolehkan (misal `white.withValues(alpha: 0.7)` / `withAlpha(...)`).
- **Kontras WCAG AA**:
  - Teks normal (< 18pt): rasio kontras $\ge 4.5:1$.
  - Teks besar ($\ge 18pt$ atau $\ge 14pt$ tebal): rasio kontras $\ge 3.0:1$.
  - Tombol primer oranye wajib memakai teks `navy900` / `brandNavyDark` (5.65:1) karena teks putih hanya mencapai ~2.76:1.

## 3. Anti-Slop Directives
1. **Dilarang Kotak Ikon Bulat Transparan untuk Fitur Marketing**: Jangan membuat deretan fitur promosi dengan wadah lingkaran berlatar warna transparan pada layar kerja staf.
2. **Dilarang Animasi Dekoratif Berlebih**: Tidak ada fade/slide masuk kartu yang memperlambat alur kerja staf. Animasi dibatasi hanya untuk feedback fungsional (fokus, hover, loading) dengan durasi $\le 150\text{ ms}$.
3. **Dilarang Ikon Prefix Mubazir**: Field input formulir standar tidak memerlukan ikon dekoratif di sebelah kiri (`person`, `lock`) kecuali terbukti fungsional.
4. **Dilarang Efek Visual Murahan**: Bebas dari glassmorphism, background blur berlebihan, bayangan berlapis bertingkat (multi-drop shadows), blob abstrak warna-warni, dan emoji.
5. **Copywriting Lugas & Berorientasi Hotel**: Gunakan istilah perhotelan berbahasa Indonesia yang tepat, padat, dan tanpa basa-basi (contoh: "Masuk ke Sistem", "Nama pengguna atau kata sandi salah. Coba lagi.").
6. **Watermark Identitas Operasional**: Satu elemen identitas tegas di panel navigasi/kiri, seperti monogram SH watermark beropasitas rendah atau motif tipis penomoran kamar.

## 4. Tipografi & Skala Spasi
- Font keluarga: **Plus Jakarta Sans** (`GoogleFonts.plusJakartaSans`).
- Hirarki ukuran:
  - Judul Layar: 24–28px, `FontWeight.w700`.
  - Subjudul / Section Header: 16–20px, `FontWeight.w600`.
  - Form Label & Body: 14px, `FontWeight.w500` / `w400`.
  - Tombol Aksi: 15–16px, `FontWeight.w600`.
  - Teks Bantuan & Caption: 11–12px, `FontWeight.w400`.
- Angka uang, statistik, dan jam wajib menggunakan `FontFeature.tabularFigures()`.
- Grid spasi kelipatan 4/8/12/16/20/24/32/48px (`AppSpacing`).

## 5. Standar Komponen Input & Tombol
- **Input Field**:
  - Tinggi target: 52–56px.
  - Border default: 1px `AppColors.border`.
  - Border fokus: 1.5–2px `AppColors.brandNavy` / `borderFocus`.
  - Border error: 1.5px `AppColors.error`.
  - Placeholder: kontras jelas ($\ge 60\%$ opasitas dari teks netral).
  - Aksi keyboard: `TextInputAction.next` / `done`, auto-submit pada Enter untuk form login.
  - Autofill hints & indikator Caps Lock aktif pada field kata sandi.
- **Tombol Aksi**:
  - Tinggi target: $\ge 52\text{px}$ untuk aksi utama login, minimal 48px untuk aksi umum.
  - Target sentuh/klik minimal 48x48.
  - Hover desktop: perubahan elevasi/opasitas halus tanpa warna baru.
  - State loading: indikator loading terintegrasi dalam tombol dan tombol dinonaktifkan untuk mencegah submit ganda.

## 6. Layout Responsif
- **Desktop ($\ge 900\text{px}$)**:
  - Split layout proporsional (5:6).
  - Panel kiri: Identitas hotel, live date/time, status terminal frontdesk, status koneksi lokal, monogram watermark.
  - Panel kanan: Kartu form rapi (`maxWidth: 440`), padding 40px, border tipis bersih tanpa shadow berlebihan.
  - Autofocus otomatis pada username field untuk efisiensi keyboard staf.
- **Mobile & Tablet (< 900px)**:
  - Header brand terintegrasi menyatu dengan kartu formulir dalam satu alur visual terpadu.
  - `SafeArea` + `SingleChildScrollView` + `ConstrainedBox` + `resizeToAvoidBottomInset: true` agar input tidak tertutup virtual keyboard.
  - Padding horizontal 20–24px, `maxWidth: 480`.


## Signature Transition (allowed exception)
- Exactly one decorative-looking motion is permitted: the split-door reveal on successful login (≤ 700 ms, easeInOutCubic, existing theme colors only).
- Must be skipped when reduced motion is on, never run on failed login, and never block or double-trigger navigation.
- No other entrance or decorative animations are allowed without an explicit request.