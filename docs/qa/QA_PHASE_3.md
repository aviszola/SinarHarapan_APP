# PHASE 3 — TARGETED REGRESSION TESTS REPORT
**Proyek:** Sinar Harapan Property Management System (PMS)  
**Target:** Penutupan Kesenjangan Pengujian (Closing Test Gaps) dari `QA_SECOND_PASS.md`  
**Komit Basis:** `4e6fa64` (`4e6fa645a5b78118c4aff1505a52774b9b56ce87`)  
**Branch:** `icons-refresh`  
**Tanggal:** 10 Oktober 2026  
**Auditor / Test Engineer:** Autonomous QA Engineer / Senior Flutter Test Engineer  

---

## 1. Ringkasan Eksekutif & Status Akhir

Kesenjangan pengujian (test gaps) yang diidentifikasi pada laporan `QA_SECOND_PASS.md` kini telah **berhasil ditutup melalui 14 automated widget tests baru**. Seluruh tes baru berjalan menggunakan mock/in-memory repository tanpa menyentuh server produksi Railway dan tanpa mengubah baris kode produksi mana pun di folder `lib/`.

- **Total Tes Proyek Sebelumnya:** 90 tes
- **Tes Baru yang Ditambahkan:** 14 tes
- **Total Tes Proyek Saat Ini:** **104 tes**
- **Hasil Eksekusi:** **104 / 104 LULUS (100% PASS, 0 GAGAL)**
- **Hasil Static Analysis:** **0 Issues (`flutter analyze` EXIT 0)**

### **Status Akhir: PASS — TARGETED TESTS VERIFIED**

---

## 2. File & Skenario Tes Baru yang Ditambahkan

### File 1: `test/qa/targeted_room_operations_test.dart` (5 Skenario)
Fokus: Alur bisnis transaksi kamar, dialog checkout, dialog pembersihan (cleaning), dan dialog perawatan (maintenance).

| ID | Nama Skenario Tes | Deskripsi & Verifikasi | Hasil Aktual |
| :---: | :--- | :--- | :---: |
| **A1** | `Occupied room tap opens CheckOutDialog and successfully checks out` | Mengetuk kartu kamar berstatus `occupied` (Kamar 102 - Budi Santoso), memverifikasi modal `CheckOutDialog` ("Proses Check-Out Tamu") terbuka, menekan tombol `Selesaikan Check-Out (Tanpa Biaya)`, memverifikasi `processCheckout` pada repository dipanggil, dialog tertutup, dan status kamar beralih ke `dirty` (Kotor). | **PASS** |
| **A2** | `Occupied room checkout failure displays error feedback and preserves occupied state` | Mensimulasikan kegagalan transaksi backend (`ApiException` tagihan tertunda). Memverifikasi dialog menampilkan pesan error `Gagal Check-Out`, dan state kamar **TIDAK beralih palsu** (tetap `occupied`). | **PASS** |
| **B1** | `Dirty room tap displays cleaning confirmation, and confirm marks room available` | Mengetuk kartu kamar berstatus `dirty` (Kamar 103), memverifikasi `AppConfirmationDialog` ("Pembersihan Kamar 103") muncul dengan tombol `Tandai Siap Huni`, menekan konfirmasi, memverifikasi `markRoomClean` dipanggil, dan status kamar beralih ke `available` (Tersedia). | **PASS** |
| **B2** | `Dirty room tap cancelation leaves room in dirty state` | Mengetuk kamar kotor, menekan tombol pembatalan `Nanti Dulu`, memverifikasi dialog tertutup, `markRoomClean` **tidak dipanggil**, dan kamar tetap berstatus `dirty`. | **PASS** |
| **B3** | `Maintenance room tap displays informational dialog and closes cleanly` | Mengetuk kamar berstatus `maintenance` (Kamar 104), memverifikasi dialog informasi ("Kamar 104 Dalam Perawatan") muncul, menekan tombol `Tutup`, dan memverifikasi dialog tertutup tanpa perubahan status. | **PASS** |

---

### File 2: `test/qa/targeted_motion_and_interaction_test.dart` (9 Skenario)
Fokus: Timer debounce 150ms, pembatalan/reset pencarian, tombol segarkan & status loading, aksesibilitas reduced motion, micro-interaction tap scale, dan keselamatan lifecycle unmount.

| ID | Nama Skenario Tes | Deskripsi & Verifikasi | Hasil Aktual |
| :---: | :--- | :--- | :---: |
| **C1** | `Rapid typing in RoomFilterBar debounces query for 150ms before updating provider` | Pengetikan cepat karakter '1', '10', '101' di `TextField`. Memverifikasi query **tidak dikirim** sebelum 150ms berlalu. Memverifikasi query '101' **tepat diproses** setelah 150ms dari ketikan terakhir. | **PASS** |
| **C2** | `Tapping search clear button immediately resets query and cancels debounce timer` | Mengetik 'Deluxe', lalu menekan icon clear ('x'). Memverifikasi timer debounce langsung dibatalkan, text field dikosongkan, dan provider state seketika menjadi kosong tanpa menunggu 150ms. | **PASS** |
| **C3** | `Tapping Reset button clears search and restores initial filter state` | Mengetik filter pencarian, lalu menekan tombol `Reset`. Memverifikasi query kosong dan filter tipe/lantai kembali ke default (`ALL` dan `0`). | **PASS** |
| **D1** | `Refresh button invokes onRefresh and is disabled while isRefreshing is true` | Mengetuk tombol `Segarkan`. Memverifikasi callback `onRefresh` dipanggil. Memverifikasi selama `isRefreshing == true`, tombol berada dalam status disabled (`onPressed == null`) untuk mencegah multiple request. Memverifikasi tombol aktif kembali saat refreshing selesai. | **PASS** |
| **E1** | `StatusBadge uses Duration.zero when disableAnimations is true vs 180ms normally` | Menguji widget `StatusBadge` pada dua kondisi: normal (`disableAnimations == false`) menghasilkan durasi animasi 180ms; dan reduced motion (`disableAnimations == true`) menghasilkan `Duration.zero` (transisi warna instan). | **PASS** |
| **E2** | `RoomCard preserves scale 1.0 even when pressed if disableAnimations is true` | Menguji interaksi tekan pada `RoomCard` saat `disableAnimations == true`. Memverifikasi nilai `AnimatedScale.scale` **tetap 1.0 konstan** (tidak mengecil ke 0.99). | **PASS** |
| **F1** | `RoomCard pointer down sets scale 0.99 and pointer cancel restores scale 1.0` | Menguji event pointer pada kondisi normal: pointer down memicu transisi skala ke `0.99`; pointer cancel (drag keluar area kartu) memulihkan skala ke `1.0` tanpa meninggalkan status tekan tersangkut. | **PASS** |
| **F2** | `Unmounting RoomFilterBar with active in-flight debounce timer disposes cleanly without timer leaks` | Mengetik pada search field untuk menyalakan timer 150ms, lalu meng-unmount widget seketika di milidetik ke-30. Memverifikasi `_debounceTimer?.cancel()` di `dispose()` bekerja sempurna tanpa `pending timer exception`. | **PASS** |
| **F3** | `Unmounting RoomFilterBar with active repeating refresh animation disposes cleanly without ticker leaks` | Me-mount `RoomFilterBar` dengan `isRefreshing: true` (animasi rotasi berulang aktif), lalu meng-unmount widget seketika. Memverifikasi `_refreshController.dispose()` bekerja bersih tanpa ticker leak. | **PASS** |

---

## 3. Log Perintah yang Dijalankan & Exit Code

| No | Perintah | Directory | Exit Code | Output Ringkas |
| :---: | :--- | :--- | :---: | :--- |
| 1 | `flutter test test/qa/targeted_room_operations_test.dart` | `sinarharapan_app` | 0 | `00:03 +5: All tests passed!` |
| 2 | `flutter test test/qa/targeted_motion_and_interaction_test.dart` | `sinarharapan_app` | 0 | `00:03 +9: All tests passed!` |
| 3 | `flutter analyze` | `sinarharapan_app` | 0 | `No issues found! (ran in 7.0s)` |
| 4 | `flutter test` (Full Suite) | `sinarharapan_app` | 0 | `00:38 +104: All tests passed!` |
| 5 | `git diff --check` | `sinarharapan_app` | 0 | Bersih (tidak ada konflik / trailing whitespace) |
| 6 | `git status --short` | `sinarharapan_app` | 0 | Tidak ada modifikasi kode pada folder `lib/` |

---

## 4. Temuan Bug & Observasi Arsitektur

### A. Bug Implementasi Produksi
- **Hasil:** **TIDAK DITEMUKAN BUG KRITIS PADA IMPLEMENTASI KODE `lib/`**.
  - Seluruh logika transisi status (Check-in, Check-out, Cleaning, Maintenance) pada `room_grid_screen.dart` dan `room_card.dart` berfungsi secara tepat sesuai spesifikasi.
  - Penanganan error pada `check_out_dialog.dart` menangkap `ApiException` dengan benar dan tidak memicu pergeseran status prematur.
  - Debounce timer dan animation controller di `room_filter_bar.dart` terbukti membersihkan resource secara aman saat di-unmount di tengah jalan.

### B. Catatan Testing Harness (Observasi Penting)
- Pada pengujian `RoomFilterBar` mandiri, widget membaca `ref.watch(roomStatsProvider)` yang secara otomatis memicu `RoomListNotifier._startPolling()`. Polling background ini menginisialisasi timer periodik 15 detik. Dalam widget test framework, timer periodik ini memerlukan pembersihan eksplisit melalui `container.dispose()`. Pola ini telah diintegrasikan dengan rapi pada suite tes baru melalui `_FakeRoomRepo` dan pembersihan container terkontrol.

---

## 5. Kesenjangan yang Belum Bisa Diotomatisasi (Boundary Limitations)

1. **Pengujian Fisik Native Desktop Window OS:**
   - **Status:** **BLOCKED**
   - **Alasan Teknis:** Runner agen berbasis CLI headless tidak memiliki akses ke driver otomasi jendela native OS (seperti WinAppDriver) untuk mengendalikan event mouse kursor di tingkat Win32 OS secara visual.
   - **Mitigasi:** Seluruh logika gesture, hover, pointer event, scale micro-interaction, dan rendering multi-resolusi telah diverifikasi secara mendalam melalui Flutter `WidgetTester` dan RepaintBoundary headless screenshot.
2. **Transaksi Nyata pada Server Produksi Railway:**
   - **Status:** **DIISOLASI SECARA SENGAJA (BY DESIGN)**
   - **Alasan Teknis:** Server di `https://sinar-harapan-backend-production.up.railway.app/api` memuat data riil hotel. Seluruh pengujian checkout dan cleaning dijalankan menggunakan mock repository in-memory yang mematuhi kontrak API asli untuk menjamin keamanan data.

---

## 6. Daftar File yang Diubah / Dibuat

1. `test/qa/targeted_room_operations_test.dart` (File Baru — 5 tes checkout, cleaning, maintenance)
2. `test/qa/targeted_motion_and_interaction_test.dart` (File Baru — 9 tes debounce, clear, refresh, reduced motion, lifecycle)
3. `docs/qa/QA_PHASE_3.md` (Dokumen laporan ini)
4. *Zero modification* pada folder `lib/`.
