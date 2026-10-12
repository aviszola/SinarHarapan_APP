# QA Report — Penggantian Data Kamar dengan Data Nyata Hotel Sinar Harapan

**Tanggal Verifikasi**: 12 Oktober 2026  
**Branch**: `data/real-rooms`  
**Baseline Git Commit**: `77cc7be` (`ui/room-toolbar`)  
**Metodologi QA**: Manual inspection, static analysis (`flutter analyze`), automated test suites (`flutter test`), dan color diff audit (`git diff`).  
**Status Keseluruhan**: **PASS**

---

## 1. Ringkasan Eksekutif & Keputusan Arsitektur

### Data Nyata Hotel Sinar Harapan (16 Kamar)
Hotel Sinar Harapan hanya memiliki Lantai 1 dan Lantai 2 dengan total 16 kamar berstatus fisik nyata:
- **Lantai 1 (6 Kamar)**:
  - `"01"`: AC — Rp 170.000 / malam
  - `"02"`: AC — Rp 170.000 / malam
  - `"03"`: AC — Rp 170.000 / malam
  - `"04"`: Kipas — Rp 120.000 / malam
  - `"05"`: AC — Rp 170.000 / malam
  - `"5A"`: AC — Rp 200.000 / malam
- **Lantai 2 (10 Kamar)**:
  - `"06"`: AC — Rp 170.000 / malam
  - `"07"`: AC Twin — Rp 200.000 / malam
  - `"08"`: Kipas — Rp 120.000 / malam
  - `"09"`: AC Twin — Rp 200.000 / malam
  - `"10"`: AC — Rp 170.000 / malam
  - `"11"`: AC — Rp 170.000 / malam
  - `"12"`: AC — Rp 170.000 / malam
  - `"13"`: Kipas — Rp 120.000 / malam
  - `"14"`: Kipas — Rp 120.000 / malam
  - `"15"`: Kipas — Rp 120.000 / malam

### Keputusan Kunci & Rencana Migrasi Database
1. **Single Source of Truth**:
   - Dibuat di `lib/features/room_management/data/room_seed_data.dart` (`kRealHotelRooms`, `kRealRoomTypes`, `kRealRoomFilterTypes`, `kRealRoomFloors`, `compareRoomNumbers`, `seedRooms`).
   - Harga disimpan dalam bilangan bulat (`int`), tanpa `double`. Komentar eksplisit ditambahkan bahwa harga di atas adalah **harga FINAL yang sudah termasuk kenaikan +Rp 10.000** dari tarif dasar.
2. **Seed Idempotent**:
   - Fungsi `seedRooms({List<RoomModel>? existingRooms})` menggunakan Map keyed by `roomNumber`. Dijalankan 1x maupun berkali-kali tetap menghasilkan tepat 16 kamar tanpa duplikasi nomor kamar atau inkonsistensi state.
3. **Representasi Tipe Kamar**:
   - Tipe kamar di model berupa `String` (`'Kipas'`, `'AC'`, `'AC Twin'`).
   - Konstanta `kRealRoomTypes` mendefinisikan himpunan tipe kamar nyata (`['Kipas', 'AC', 'AC Twin']`), sedangkan filter dropdown UI menggunakan `kRealRoomFilterTypes = ['ALL', 'Kipas', 'AC', 'AC Twin']`.
   - Perubahan terkontrol dan minim tanpa merusak kontrak modul reservasi atau pelaporan.
4. **Natural Sorting (Pengurutan Alami "5A")**:
   - Fungsi `compareRoomNumbers(a, b)` mengekstrak digit numerik awalan dan suffix alfanumerik.
   - Hasil pengurutan: `01, 02, 03, 04, 05, 5A, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15`. Kamar `5A` tepat berada di antara `05` dan `06`.
5. **Kebijakan & Rencana Migrasi Database Produksi**:
   - Database PostgreSQL backend memiliki relasi foreign key dari `reservations.room_id -> rooms.id` dan audit logs yang mencatat ID kamar masa lampau.
   - **JANGAN PERNAH HARD-DELETE**: Kamar lama contoh di database dev/staging dinonaktifkan via `deletedAt` (soft delete) atau diperbarui ID dan nomor kamarnya secara idempotent menggunakan script migrasi UPSERT (`ON CONFLICT (room_number) DO UPDATE`).

---

## 2. Status Verifikasi Per Kriteria Uji

| No | Kriteria Uji | Metode & Lokasi Uji | Status | Bukti / Catatan |
|---|---|---|:---:|---|
| 1 | **Total Kamar = 16** | Unit test `room_real_data_test.dart:8` | **PASS** | Tepat 16 kamar unik |
| 2 | **Lantai Hanya {1, 2}** | Unit test `room_real_data_test.dart:12` | **PASS** | Lt 1 = 6 kamar, Lt 2 = 10 kamar |
| 3 | **Harga Persis & Tipe Integer** | Unit test `room_real_data_test.dart:23` | **PASS** | 16 kamar diaudit per baris, `basePricePerNight is int`, harga final sudah +10.000 |
| 4 | **Pengurutan 5A di antara 05 & 06** | Unit test `room_real_data_test.dart:55` | **PASS** | Regex split natural sort memastikan urutan tepat |
| 5 | **Seed Idempotent** | Unit test `room_real_data_test.dart:75` | **PASS** | Dijalankan 1x vs 2x vs 5x tetap 16 kamar unik |
| 6 | **Format Rupiah Titik Pemisah Ribuan** | Unit test `room_real_data_test.dart:88` & `room_card.dart` | **PASS** | Format `"Rp 170.000 / malam"` dan `"Rp 200.000 / malam"` via `id_ID` |
| 7 | **Pengelompokan Lantai "Lantai N · X kamar"** | Widget UI `room_grid_screen.dart:404` | **PASS** | Tampil judul "Lantai 1 · 6 kamar" & "Lantai 2 · 10 kamar" |
| 8 | **Filter Lantai & Tipe Kamar Nyata** | Widget test `room_filter_bar_test.dart` & `room_filter_bar.dart` | **PASS** | Filter lantai hanya 1 & 2 (lantai 3 dihapus). Filter tipe: Kipas, AC, AC Twin |
| 9 | **Kartu Kamar (Nomor Besar & Fasilitas Teks)** | Widget test `room_card.dart:184, 274, 412` | **PASS** | Nomor kamar 18px w800, fasilitas sebagai teks, format harga per malam |
| 10 | **Hunian & Ringkasan Berbasis 16 Kamar** | Controller & Filter bar `room_controller.dart` | **PASS** | Total dihitung dinamis dari koleksi 16 kamar |
| 11 | **Pembersihan Kamar Contoh & Lantai 3** | Codebase audit di seed, UI, dialog, test fixtures | **PASS** | Kamar 101-104, 201-202, 400 dan Lantai 3 dihapus dari seed & opsi dropdown |
| 12 | **Grid Responsif Bebas Overflow** | Responsiveness test di lebar 360, 768, 1280, 1920 & text scale 1.3x | **PASS** | Tidak ada `A RenderFlex overflowed` |
| 13 | **Nol Perubahan Warna (Color() / 0x)** | PowerShell script git diff | **PASS** | `git diff 77cc7be -- lib/ \| Select-String "Color\(","0x"` menghasilkan 0 match |
| 14 | **Static Analysis (`flutter analyze`)** | CI / Terminal analyzer | **PASS** | 0 error, 0 warning (clean) |
| 15 | **Test Suite Keseluruhan (`flutter test`)** | Terminal test runner | **PASS** | 178/178 tests PASSED (100% lulus) |

---

## 3. Daftar File yang Diubah

### Sumber Kode Aplikasi (`lib/`)
1. `lib/features/room_management/data/room_seed_data.dart` (BARU)
   - Definisi data 16 kamar nyata Hotel Sinar Harapan.
   - Konstanta `kRealRoomTypes`, `kRealRoomFilterTypes`, `kRealRoomFloors`.
   - Fungsi sorting natural `compareRoomNumbers` dan `compareRooms`.
   - Fungsi seeding idempotent `seedRooms`.
2. `lib/features/room_management/domain/room_model.dart`
   - Mengubah tipe `basePricePerNight` dari `double` ke `int`.
   - Menyediakan getter kompatibilitas `basePricePerNightDouble => basePricePerNight.toDouble()`.
3. `lib/features/room_management/data/room_repository.dart`
   - Penyesuaian parameter `addRoom` dan `updateRoom` dari `double` ke `int`.
4. `lib/features/room_management/presentation/room_controller.dart`
   - Inisialisasi hitungan `roomTypeCountsProvider` menggunakan `kRealRoomFilterTypes`.
   - Pengurutan default `roomListProvider` menggunakan `compareRooms`.
5. `lib/features/room_management/presentation/room_filter_bar.dart`
   - Membatasi dropdown tipe hanya Kipas, AC, dan AC Twin.
   - Membatasi dropdown lantai hanya Semua Lantai, Lantai 1, dan Lantai 2 (Lantai 3 dihapus).
6. `lib/features/room_management/presentation/room_grid_screen.dart`
   - Mengubah judul section lantai menjadi format `"Lantai $floor · ${floorRooms.length} kamar"`.
7. `lib/features/room_management/presentation/room_crud_dialog.dart`
   - Menghapus opsi Lantai 3 (hanya Lantai 1 dan Lantai 2).
   - Tipe kamar hanya Kipas, AC, AC Twin.
   - Input harga integer.
8. `lib/features/room_management/presentation/room_card.dart`
   - Nomor kamar dipertegas (18px, `FontWeight.w800`, tabular figures).
   - Menampilkan fasilitas kamar sebagai teks.
   - Format harga per malam: `"Rp 170.000 / malam"`.
9. `lib/features/checkout/presentation/check_out_dialog.dart`
   - Penyesuaian assignment double pada `_roomSubtotal`.
10. `lib/features/reservation/presentation/check_in_modal.dart`
    - Penyesuaian return value double pada `_currentEffectiveTotal`.
11. `lib/features/reporting/domain/report_export_service.dart`
    - Penyesuaian konversi double pada `roomCost` saat export.

### Pengujian & Test Fixture (`test/`)
1. `test/features/room_management/data/room_real_data_test.dart` (BARU)
   - 7 unit test spesifik untuk verifikasi 16 kamar, harga per baris, sort 5A, idempotent seed, dan format rupiah.
2. `test/features/room_management/presentation/room_filter_bar_test.dart`
   - Perbarui fixture `_FakeRoomRepo` menggunakan kamar 01, 02, 06, 07 dengan tipe AC & AC Twin.
   - Penyesuaian ekspektasi header lantai `"Lantai 1 · 2 kamar"`.
3. `test/features/room_management/presentation/room_motion_interaction_test.dart`
   - Perbarui mock rooms dan key kartu kamar (`room_card_rm-01`, `room_card_rm-02`).
4. `test/room_inventory_test.dart`
   - Perbarui `TestRoomRepository` dan test case CRUD dengan nomor kamar nyata 01, 02 dan tipe `int basePricePerNight`.
5. `test/qa/targeted_room_operations_test.dart`
   - Perbarui target checkout test dari kamar 102 ke kamar nyata 02.
6. `test/qa/invoice_sequence_and_large_export_test.dart`
   - Perbarui mock data harga kamar menjadi integer.
7. `test/qa/export_service_test.dart`
   - Perbarui sample rooms dari 101/102 ke kamar nyata 01/02.
8. `test/backend_bugs_verification_test.dart`
   - Perbarui kamar uji dari rm-101/rm-102 ke rm-01/rm-02.
9. `test/tool/capture_toolbar_screenshots_test.dart`, `capture_toolbar_motion_frames_test.dart`, `capture_split_door_transition_screenshots_test.dart`, `capture_icon_screenshots_test.dart`
   - Perbarui mock fixture kamar contoh ke kamar nyata.

---

## 4. Bukti Perintah Audit Warna (Color Tokens)

Perintah yang dieksekusi:
```powershell
git add -N . ; git diff 77cc7be -- lib/ | Select-String "Color\(","0x"
```

Hasil:
```text
(0 match — Bersih tanpa token atau definisi warna baru)
```

Seluruh warna tampilan kartu kamar, badge status, chip filter, dan dialog tetap menggunakan token `AppColors` yang sudah ada sebelumnya.
