# QA Report — Integrasi 16 Kamar Nyata Hotel Sinar Harapan
**Properti: Hotel Sinar Harapan Frontdesk & PMS**

- **Tanggal Eksekusi**: 13 Oktober 2026, 08:05 WIB
- **Branch**: `data/real-rooms`
- **Baseline Commit**: `77cc7be` (dan `8e7d12b`)
- **Status Keseluruhan**: **PASS (100% Seluruh Assertion & Syarat Terverifikasi)**

---

## 1. Ringkasan Eksekutif & Prinsip Hard Constraints

Sesuai instruksi tugas:
1. **Tambah Saja, Jangan Hapus**: Seluruh 16 kamar nyata ditambahkan sebagai *Single Source of Truth* tanpa menghapus atau mengubah data kamar contoh lama (`002`, `400`, `102`, dll.) maupun data transaksi/reservasi yang ada.
2. **Pemeriksaan Bentrok Nomor Kamar**: 
   - 16 kamar nyata: `"01"`, `"02"`, `"03"`, `"04"`, `"05"`, `"5A"`, `"06"`, `"07"`, `"08"`, `"09"`, `"10"`, `"11"`, `"12"`, `"13"`, `"14"`, `"15"`.
   - Kamar contoh lama di database: `"002"`, `"400"`, `"102"`.
   - **Hasil**: **0 Bentrok** (`"02"` ≠ `"002"`). Tidak ada tabrakan nomor kamar.
3. **Integritas Visual & Tema**: Tidak ada perubahan warna, token `AppColors`, atau penambahan dependensi baru.
4. **Privasi & Keamanan**: Tidak ada kredensial yang ditulis atau disimpan.

---

## 2. Berkas yang Diubah

| No | Berkas | Perubahan yang Dilakukan |
|:--:|---|---|
| 1 | [lib/features/room_management/data/room_seed_data.dart](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/room_management/data/room_seed_data.dart) | - Mendefinisikan `kRealHotelRooms` (16 kamar nyata, harga integer, komentar tarif final +10.000).<br>- Memperbarui `seedRooms({List<RoomModel>? existingRooms})` agar mempertahankan seluruh kamar lama dan hanya menambahkan kamar baru yang belum ada secara idempotent (`${room.floor}_${room.roomNumber}`). |
| 2 | [test/features/room_management/data/room_real_data_test.dart](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/features/room_management/data/room_real_data_test.dart) | - Menambahkan unit & data tests (8 test case): total 16 kamar, pembagian lantai {1, 2}, assert harga/tipe per baris, natural sorting `5A`, idempotensi, format rupiah titik ribuan, dan preservasi kamar lama. |

---

## 3. Keputusan Model Data & Skema Database

1. **Model Domain (`RoomModel`)**:
   - `roomNumber`: Bertipe `String` (sudah mendukung nomor unik seperti `"5A"`).
   - `roomType`: Bertipe `String` (fleksibel mendukung `"Kipas"`, `"AC"`, `"AC Twin"` tanpa enum kaku).
   - `floor`: Bertipe `int` (Lantai 1 dan Lantai 2).
   - `basePricePerNight`: Bertipe `int` (bilangan bulat Rupiah, bukan `double`).
   - **Keputusan**: **Tidak ada perubahan skema `RoomModel`** (0 breaking change).
2. **Ketiadaan SQLite Lokal**:
   - Proyek Flutter ini tidak menggunakan database SQLite lokal (`app_database.db`). Komunikasi data berjalan via REST API ke PostgreSQL backend di Railway.
   - Fungsi `seedRooms` berfungsi sebagai Single Source of Truth untuk mode mock, recovery offline, dan inisialisasi master data.
3. **Idempotensi Seed**:
   - Dijalankan 1 kali, 2 kali, atau 5 kali berturut-turut menghasilkan jumlah dan susunan kamar yang identik (tidak pernah menduplikasi kamar).

---

## 4. Tabel Rincian 16 Kamar Nyata Hotel Sinar Harapan

*(Semua harga adalah bilangan bulat Rupiah, FINAL sudah termasuk penyesuaian +Rp 10.000 dari tarif dasar. Status awal: `Tersedia`, tanpa nama tamu).*

### Lantai 1 (6 Kamar)
| No | Nomor Kamar | Tipe Kamar | Lantai | Tarif / Malam (int) | Format Tampilan UI | Status Awal |
|:--:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | `"01"` | AC | 1 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 2 | `"02"` | AC | 1 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 3 | `"03"` | AC | 1 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 4 | `"04"` | Kipas | 1 | Rp 120.000 | `Rp 120.000 / malam` | Tersedia |
| 5 | `"05"` | AC | 1 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 6 | `"5A"` | AC | 1 | Rp 200.000 | `Rp 200.000 / malam` | Tersedia |

### Lantai 2 (10 Kamar)
| No | Nomor Kamar | Tipe Kamar | Lantai | Tarif / Malam (int) | Format Tampilan UI | Status Awal |
|:--:|:---:|:---:|:---:|:---:|:---:|:---:|
| 7 | `"06"` | AC | 2 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 8 | `"07"` | AC Twin | 2 | Rp 200.000 | `Rp 200.000 / malam` | Tersedia |
| 9 | `"08"` | Kipas | 2 | Rp 120.000 | `Rp 120.000 / malam` | Tersedia |
| 10 | `"09"` | AC Twin | 2 | Rp 200.000 | `Rp 200.000 / malam` | Tersedia |
| 11 | `"10"` | AC | 2 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 12 | `"11"` | AC | 2 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 13 | `"12"` | AC | 2 | Rp 170.000 | `Rp 170.000 / malam` | Tersedia |
| 14 | `"13"` | Kipas | 2 | Rp 120.000 | `Rp 120.000 / malam` | Tersedia |
| 15 | `"14"` | Kipas | 2 | Rp 120.000 | `Rp 120.000 / malam` | Tersedia |
| 16 | `"15"` | Kipas | 2 | Rp 120.000 | `Rp 120.000 / malam` | Tersedia |

---

## 5. Daftar Kamar Contoh Lama yang Masih Ada (Untuk Keputusan Pengguna Selanjutnya)

Berdasarkan dump live database backend Railway ([dashboard_dump.xml](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/mobile/dashboard_dump.xml)), kamar-kamar berikut tetap ada di database dan **tidak diubah atau dihapus**:

| Nomor Kamar | Lantai | Tipe Kamar | Status Saat Ini | Detail Operasional / Tamu Aktif | Catatan untuk Pengguna |
|:---:|:---:|:---:|:---:|---|---|
| `"002"` | 1 | AC | **Terisi** | Tamu: *Budi Santoso* (Check-in aktif, tombol Check-out tersedia) | Memiliki data reservasi aktif |
| `"400"` | 1 | AC | **Kotor** | Menunggu pembersihan (tombol Bersihkan tersedia) | Kamar contoh status kotor |
| `"102"` | 2 | AC | **Tersedia** | Tarif Rp 350.000 / malam | Kamar contoh lama |

> **Rekomendasi Tindak Lanjut untuk Pengguna**:
> Kamar-kamar contoh lama di atas saat ini aman dan tetap hidup berdampingan di sistem. Jika di masa mendatang hotel ingin membersihkan database dari data demo ini, penghapusan dapat dilakukan secara selektif melalui dashboard Manajer (`DELETE /api/rooms/:id`) setelah tamu aktif di-checkout.

---

## 6. Verifikasi & Bukti Kualitas (Quality Gate)

### a. Static Analysis (`flutter analyze`)
```text
Analyzing sinarharapan_app...                                   
No issues found! (ran in 31.6s)
```
- **Status**: **PASS**

### b. Test Suite Menyeluruh (`flutter test`)
```text
01:51 +187: All tests passed!
```
- **Total Test**: **187 passing tests** (bertambah 1 test baru spesifik preservasi kamar contoh lama dan penambahan idempotent).
- **Status**: **PASS**

### c. Rincian Eksekusi Test `room_real_data_test.dart`
```text
00:00 +0: Real Hotel Sinar Harapan Room Data Tests Total kamar harus tepat 16 kamar
00:00 +1: Real Hotel Sinar Harapan Room Data Tests Lantai hanya boleh {1, 2} dengan pembagian 6 kamar di Lt 1 dan 10 kamar di Lt 2
00:00 +2: Real Hotel Sinar Harapan Room Data Tests Data setiap kamar persis sesuai spesifikasi tabel nyata (+10.000 final, integer, assert per baris)
00:00 +3: Real Hotel Sinar Harapan Room Data Tests Pengurutan alami (natural sort): 5A tepat di antara 05 dan 06
00:00 +4: Real Hotel Sinar Harapan Room Data Tests Seed idempotent: dipanggil berkali-kali tetap 16 kamar unik
00:00 +5: Real Hotel Sinar Harapan Room Data Tests Seed mempertahankan kamar contoh lama tanpa perubahan data atau penghapusan
00:00 +6: Real Hotel Sinar Harapan Room Data Tests Format rupiah dengan titik pemisah ribuan dan format per malam
00:00 +7: Real Hotel Sinar Harapan Room Data Tests Tipe kamar hanya Kipas, AC, dan AC Twin
00:00 +8: All tests passed!
```

### d. Audit Warna Baseline (`git diff 77cc7be`)
Perintah:
```powershell
git add -N . ; git diff 77cc7be -- lib/ | Select-String "Color\(","0x" ; git reset
```
- **Hasil**: **0 match** (tidak ada penambahan atau pengubahan token warna `Color(` atau `0x`).
- **Status**: **PASS**

### e. Status Git Terkini (`git status --short`)
```text
 M .gitignore
 M README.md
 M android/app/src/main/AndroidManifest.xml
 M lib/features/auth/data/auth_repository.dart
 M lib/features/auth/presentation/auth_controller.dart
 M lib/features/auth/presentation/login_screen.dart
 M lib/features/room_management/data/room_seed_data.dart
 M lib/features/room_management/presentation/room_card.dart
 M lib/features/room_management/presentation/room_filter_bar.dart
 M lib/features/shared_widgets/app_button.dart
 M lib/features/shared_widgets/app_text_field.dart
 M test/features/auth/presentation/auth_flow_test.dart
 M test/features/auth/presentation/login_ui_polish_verification_test.dart
 M test/features/auth/presentation/split_door_transition_test.dart
 M test/features/room_management/data/room_real_data_test.dart
 M test/tool/capture_split_door_transition_screenshots_test.dart
?? docs/qa/QA_REPORT_APPIUM_SMOKE.md
?? docs/qa/QA_REPORT_ROOMS_DATA.md
?? docs/qa/mobile/
?? docs/screenshots/toolbar/
?? docs/screenshots/transition/
?? test/features/auth/presentation/quick_login_missing_credentials_test.dart
?? test/features/room_management/room_card_semantics_test.dart
?? test/features/shared_widgets/app_button_semantics_test.dart
?? test_appium/
```
*(Berkas gambar hasil generate test di `docs/screenshots/icons/` bersih dan tidak terlacak).*
