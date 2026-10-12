# QA REPORT: Redesign Toolbar Filter & Ringkasan Kamar — Sinar Harapan PMS

**Tanggal Pengujian**: 12 Oktober 2026  
**Platform**: Flutter Desktop (Windows) / Web / Mobile  
**Branch**: `ui/room-toolbar`  
**Baseline Commit**: `d07a215`  
**Engineer / QA**: Autonomous Elite Engineering Agent (`sinarharapan-qa`, `sinarharapan-ui-design`)  

---

## 1. Executive Summary

| Target Verifikasi | Status | Bukti Perintah / Test |
| :--- | :---: | :--- |
| **Ringkasan Hunian + Chip Status** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 1 & 2) |
| **Custom Dropdown Tipe & Lantai (`MenuAnchor`)** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 3 & 4) |
| **Tombol Reset (n) Dinamis** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 5) |
| **Kolom Cari, Clear ✕, Ctrl+F, Debounce 250ms** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 6 & 7) |
| **Tombol Segarkan (3 State, Error Inline, Diperbarui HH:mm)** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 8) |
| **Responsif 7 Breakpoint (360–1920px & Text Scale 1.3x)** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 10) |
| **Empty State & Fade Transition (≤ 150ms)** | **PASS** | `flutter test test/features/room_management/presentation/room_filter_bar_test.dart` (Test 9) |
| **Zero Color Mutation (Hard Constraint 1)** | **PASS** | `git diff d07a215 -- lib/ \| Select-String "Color\(","0x"` (0 lines) |
| **Static Analysis (`flutter analyze`)** | **PASS** | 0 issues found |
| **Suite Regresi Seluruh Proyek (`flutter test`)** | **PASS** | 146/146 tests passed |
| **Bukti Tangkapan Layar & Frame Motion** | **PASS** | 7 screenshot visual & 5 frame motion (`docs/screenshots/toolbar/`) |

**Status Akhir Keseluruhan**: **PASS**

---

## 2. Daftar Perubahan File

| Path File | Jenis Perubahan | Deskripsi Singkat |
| :--- | :---: | :--- |
| `lib/features/room_management/presentation/room_controller.dart` | Modified | Menambahkan getter `activeFilterCount`, fungsi helper `matchesRoomSearch`, dan derived provider dinamis `roomTypeCountsProvider`, `floorCountsProvider`, `statusCountsProvider`. |
| `lib/features/room_management/presentation/room_filter_bar.dart` | Modified | Redesign penuh toolbar: Ringkasan hunian (bar 4px), chip status single-select dengan dot & tint, MenuAnchor kustom Tipe & Lantai, Reset (n), search field (✕, Ctrl+F, debounce 250ms), Segarkan (3 state, inline error, waktu sukses), responsif 3 mode. |
| `lib/features/room_management/presentation/room_grid_screen.dart` | Modified | `AnimatedSwitcher` fade ≤ 150 ms pada list kamar, empty state teks bersih tanpa ilustrasi + tombol Reset filter. |
| `test/qa/targeted_motion_and_interaction_test.dart` | Modified | Penyelarasan durasi debounce test dari 150 ms ke 250 ms sesuai spesifikasi baru. |
| `test/features/room_management/presentation/room_filter_bar_test.dart` | Added | 16 widget tests komprehensif untuk seluruh fungsionalitas toolbar dan responsivitas. |
| `test/tool/capture_toolbar_screenshots_test.dart` | Added | Test tool otomatis untuk render dan capture screenshot pixel-perfect di resolusi 1920, 1280, 734, dan 360 px. |
| `test/tool/capture_toolbar_motion_frames_test.dart` | Added | Test tool otomatis untuk mengekstrak frame transisi fade `AnimatedSwitcher` pada 0ms, 33ms, 66ms, 100ms, dan 150ms. |

---

## 3. Daftar Elemen yang Dihapus & Alasannya

1. **Dropdown Status Kamar Lama (`_buildStatusDropdown`)**:
   - *Alasan*: Digantikan secara fungsional oleh Chip Status horizontal ("Semua", "Tersedia", "Terisi", "Kotor", "Perawatan") beserta indikator jumlah kamar per status secara real-time. Mempermudah resepsionis memantau okupansi kamar secara langsung tanpa klik tambahan.
2. **Ilustrasi Gambar / SVG pada Empty State**:
   - *Alasan*: Dihapus sesuai aturan Anti-Slop Rules. Diganti dengan teks informatif bersih *"Tidak ada kamar yang cocok."* dan tombol OutlinedButton *"Reset filter"*.
3. **Sorotan Default Flutter pada Dropdown (`DropdownButton`)**:
   - *Alasan*: Dropdown lama menggunakan `DropdownButton` yang membuka overlay di atas tombol dengan highlight abu-abu bawaan dan tanpa dukungan counter per opsi yang fleksibel. Diganti dengan `MenuAnchor` kustom yang membuka tepat di bawah tombol (`alignmentOffset: Offset(0, 4)`) dengan tint halus navy dan tanda centang di kanan.

---

## 4. Bukti Eksekusi & Pengujian Nyata

### A. Static Analysis (`flutter analyze`)
```
Analyzing sinarharapan_app...
No issues found! (ran in 10.9s)
```

### B. Project Test Suite (`flutter test`)
```
00:38 +146: All tests passed!
```
Total: **146 tests passed** (termasuk 16 unit/widget tests baru pada toolbar filter).

### C. Hard Constraint Immutabilitas Warna
Perintah:
```powershell
git diff d07a215 -- lib/ | Select-String "Color\(","0x"
```
Hasil: **0 baris** (Tidak ada kode hex baru maupun instansiasi warna kustom baru. Semua styling menggunakan `AppColors.brandNavy`, `AppColors.brandNavyTint`, `AppColors.surface`, `AppColors.border`, dan warna status eksisting).

### D. Tangkapan Layar Visual (Screenshots)
Semua file tersimpan di `docs/screenshots/toolbar/`:
1. `room_toolbar_1920_default.png`: Layout desktop lebar (≥ 1400px) satu baris rapi.
2. `room_toolbar_1280_default.png`: Layout desktop standar (900–1399px) 2 baris proporsional.
3. `room_toolbar_1280_filter_active.png`: Filter Tipe "Deluxe", Status "Tersedia", teks cari "10", tombol "Reset (3)", dan counter opsi bernilai 0 diredupkan.
4. `room_toolbar_1280_menu_open.png`: Menu dropdown `MenuAnchor` terbuka tepat di bawah tombol dengan centang di item aktif, counter jumlah kamar dinamis di kanan, dan baris 40px.
5. `room_toolbar_1280_empty_state.png`: Empty state teks bersih tanpa ilustrasi saat pencarian tidak menemukan hasil.
6. `room_toolbar_734_default.png`: Layout tablet (< 900px) 3 baris.
7. `room_toolbar_360_default.png`: Layout mobile 360px tanpa RenderFlex overflow.

### E. Bukti Frame Animasi Motion (30 FPS Timeline)
Tersimpan di `docs/screenshots/toolbar/motion/`:
- `fade_f_001_0ms.png`: t = 0 ms (Mulai transisi perubahan list)
- `fade_f_002_33ms.png`: t = 33 ms (Transisi opacity berjalan halus)
- `fade_f_003_66ms.png`: t = 66 ms (Transisi fade pertengahan)
- `fade_f_004_100ms.png`: t = 100 ms (Elemen target memudar masuk)
- `fade_f_005_150ms.png`: t = 150 ms (Fade selesai penuh, total ≤ 150 ms)

Semua animasi menghormati `MediaQuery.maybeDisableAnimationsOf(context)` dan beralih ke durasi instan saat reduced motion aktif.

---

## 5. Audit Anti-Slop & Desain

- [x] **Zero Slop Gradients**: Tidak ada gradient pelangi atau dekorasi acak.
- [x] **Typography Hierarchy**: Konsisten dengan `AppTextStyles` (Plus Jakarta Sans).
- [x] **Hit Area Accessibility**: Hit area tombol dan chip ≥ 40px (tinggi visual 36px/40px).
- [x] **Keyboard Accessibility**: Mendukung navigasi Tab, Enter, Space, Arrow Up/Down, Esc pada MenuAnchor, serta Ctrl+F shortcut pencarian.
- [x] **Debounce Safety**: Debounce 250ms dibatalkan secara bersih pada clear tombol ✕, reset filter, dan widget `dispose()` (terbukti dari lolosnya assertion `!timersPending`).

---

## 6. Gap & Catatan Masa Depan (Future Improvements)

- **Backend Query Pushdown**: Saat ini penghitungan jumlah kamar per opsi dihitung di memori sisi klien via Riverpod providers (`roomTypeCountsProvider`, `floorCountsProvider`, `statusCountsProvider`). Jika jumlah kamar hotel bertambah ke skala ribuan, endpoint agregasi backend (misal `GET /rooms/facets`) dapat disediakan tanpa mengubah kontrak UI toolbar saat ini.
