# LAPORAN QA: IMPLEMENTASI MOTION PRIORITAS TINGGI — SINAR HARAPAN PMS

**Tanggal Pengujian**: 12 Oktober 2026  
**Platform**: Flutter Desktop (Windows) / Web / Mobile  
**Branch**: `ui/room-toolbar`  
**Baseline Commit**: `d07a215`  
**Prinsip Verifikasi**: `sinarharapan-qa` (No Execution, No Pass — No Evidence, No Claim)  
**Status Keseluruhan**: **PASS (Kode & Widget Test) / NOT VERIFIED (Visual Motion Menunggu Rekaman Pengguna)**

---

## 1. Ringkasan Eksekusi Baseline & Quality Gates

| Pengecekan | Perintah / Bukti | Target | Hasil Nyata | Status |
| :--- | :--- | :---: | :---: | :---: |
| **Static Analysis** | `flutter analyze` | 0 issues | **No issues found!** | **PASS** |
| **Project Test Suite** | `flutter test` | 100% pass | **172/172 tests passed** | **PASS** |
| **Motion Test Suite** | `flutter test test/features/room_management/presentation/room_motion_interaction_test.dart` | 100% pass | **23/23 tests passed** | **PASS** |
| **Immutability Warna** | `git diff -- lib/ \| Select-String "Color\(","0x"` | 0 diff baris baru | **0 matches (bersih / 100% token lama)** | **PASS** |
| **Clean Git Status** | `git status --short` | Tanpa foto baru di-track | **Tidak ada artefak foto baru di-track** | **PASS** |

---

## 2. Analisis Akar Masalah: Selisih ±3,2 Detik Penutupan Dialog (Detik 36,0 vs 39,2)

Berdasarkan rekaman layar Windows (30 fps), `InvoicePreviewDialog` menutup di detik 36,0 sedangkan `CheckInModal` menutup di detik 39,2 (selisih ±3,2 detik).

### Jalur Eksekusi & Bukti File:Baris Kode Lama
1. **Pemicu**: Tombol konfirmasi di `InvoicePreviewDialog` ditekan.
2. **`invoice_preview_dialog.dart:62`**: Memanggil `await widget.onConfirmCheckIn()`.
3. **`check_in_modal.dart:543-549`**: Masuk ke callback `_executeFinalCheckIn`:
   ```dart
   // Baris 545: Memanggil controller check-in
   final success = await ref.read(roomControllerProvider.notifier).checkIn(...);
   // Baris 549 (POP PERTAMA):
   Navigator.of(context).pop();
   ```
   - **`checkIn()` di `room_controller.dart:156-176`**:
     - `createReservation()` (POST API call): memakan waktu ±1,5 detik.
     - `loadRooms(silent: true)` (GET API call refresh kamar): memakan waktu ±0,5 detik.
     - Total `checkIn`: ±2,0 detik.
   - **Pop Pertama di Baris 549**: Menutup route teratas pada saat itu, yaitu `InvoicePreviewDialog` pada **detik 36,0**.
4. **`check_in_modal.dart:565`**:
   - `AppFeedback.showSuccess(context, 'Check-in berhasil disimpan');` dipanggil, memicu penjadwalan floating SnackBar (durasi 4 detik).
5. **Kembali ke `invoice_preview_dialog.dart:62`**:
   - Meskipun visual invoice dialog telah di-pop di baris 549, state `_InvoicePreviewDialogState` masih hidup di memori karena sedang mengeksekusi asynchronous microtask.
6. **`invoice_preview_dialog.dart:72-76` (POP KEDUA)**:
   ```dart
   // Baris 72: Await delay centang sukses
   await Future.delayed(const Duration(milliseconds: 600));
   // Baris 76: Pop kedua
   if (mounted) Navigator.of(context).pop();
   ```
   - State melanjutkan eksekusi delay 600 ms, lalu di baris 76 memanggil `Navigator.of(context).pop()`.
   - Karena `InvoicePreviewDialog` sudah di-pop di detik 36,0, pop kedua ini mengenai route di bawahnya, yaitu **`CheckInModal`** pada **detik 39,2**.
7. **Dampak Cacat UX**:
   - Selama ±3,2 detik, `CheckInModal` tetap terbuka di layar.
   - Tombol modal tampak aktif tanpa guard in-flight, rentan terhadap double-submit atau manipulasi input yang membingungkan resepsionis.

---

## 3. Implementasi 9 Poin Penyesuaian Arsitektur Dialog

### 1. Pola Kepemilikan Tunggal Penutupan Dialog (Single-Owner Pattern)
- **`InvoicePreviewDialog`**: Hanya menutup dirinya sendiri via `Navigator.of(context).pop(true)` saat transaksi sukses, atau `Navigator.of(context).pop(false)` saat dibatalkan/ditutup.
- **`CheckInModal`**: Menunggu hasil boolean dari `showDialog<bool>` invoice:
  ```dart
  final invoiceConfirmed = await showDialog<bool>(...);
  if (invoiceConfirmed == true && mounted) {
    Navigator.of(context).pop(true);
  }
  ```
- **Hasil**: 0 pop silang antar-dialog.

### 2. Eliminasi Blocking Await pada Alur Penutupan
- Callback `_executeFinalCheckIn` di `check_in_modal.dart` **TIDAK LAGI** memanggil `Navigator.pop()` atau `AppFeedback.showSuccess`.
- Dialog ditutup terlebih dahulu sebelum feedback visual dan pembaruan UI latar belakang dijalankan.

### 3. In-Flight UI Guard dari Konfirmasi sampai Kedua Modal Tertutup
- State `_isSubmitting` di `CheckInModal` aktif sejak dialog invoice dibuka hingga `CheckInModal` tertutup.
- Tombol close header dan tombol "Batal" di-disable saat `_isSubmitting == true`.
- Tombol submit menampilkan status `isLoading: true` dengan label `"Menyimpan…"`.

### 4. Widget Test Pump Bertahap (< 1 Detik)
- Diuji di `test/features/room_management/presentation/room_motion_interaction_test.dart` (Grup `Prioritas 1B`):
  - Step 1: Pump invoice confirmation (loading).
  - Step 2: Pump 450 ms (centang sukses).
  - Step 3: Pump 50 ms (InvoicePreviewDialog tertutup).
  - Step 4: Pump 200 ms (CheckInModal tertutup).
  - Total durasi dari centang selesai sampai kedua modal tertutup adalah **250 ms (< 1,0 detik)**.

### 5. Durasi Centang Sukses 450 ms
- Durasi centang disetel menjadi tepat `const Duration(milliseconds: 450)` pada `InvoicePreviewDialog` dan `CheckOutDialog`.

### 6. Tombol Lebar Tetap (Anti Layout Shift)
- `AppButton` menerapkan `ConstrainedBox(constraints: BoxConstraints(minWidth: minWidth ?? 120))` dan mempertahankan ukuran saat teks berubah menjadi `"Memproses…"` atau `"Berhasil"`.
- Spinner ukuran tetap `18x18px` dengan `SizedBox(width: 8)` di sebelah label.

### 7. Penundaan Sorotan Kartu Kamar Setelah Exit Dialog
- Di `room_grid_screen.dart`, sorotan kartu ditunda sampai transisi keluar dialog selesai:
  ```dart
  final exitDuration = isReducedMotion ? Duration.zero : const Duration(milliseconds: 150);
  if (exitDuration > Duration.zero) {
    await Future.delayed(exitDuration);
  }
  highlightNotifier.highlightRoom(room.id);
  ```
- Sorotan otomatis di-reset setelah 500 ms.

### 8. Penangkapan Provider Ref Aman Unmount
- `highlightNotifier` ditangkap dari `ref.read(highlightedRoomIdProvider.notifier)` **sebelum** dialog ditutup, sehingga aman meskipun context dialog telah unmounted.

### 9. Penanganan Skenario Gagal & Batal
- Skenario gagal: Jika API melempar exception, invoice tetap terbuka, tombol kembali aktif, inline error merah muncul di atas tombol, dan flag `_isSubmitting` di modal direset ke `false`.
- Skenario batal: Jika invoice ditutup/dibatalkan, modal tetap terbuka, flag in-flight direset, dan resepsionis dapat mengoreksi data form.

---

## 4. Status Audit Verifikasi Visual (Poin 8: Rekaman Pengguna)

Sesuai instruksi Poin 8, agen **TIDAK melakukan perekaman layar atau membuat frame screenshot otomatis**. Status visual ditandai untuk diverifikasi langsung oleh pengguna melalui rekaman desktop Windows:

| Komponen & Transisi | Target Visual | Status Verifikasi |
| :--- | :--- | :---: |
| **Tombol Konfirmasi Invoice** | Normal → Spinner + "Memproses…" → Centang 450ms → Tutup | **NOT VERIFIED (Menunggu Rekaman Pengguna)** |
| **Penutupan CheckInModal** | Modal tertutup instan (< 1s) setelah invoice menutup | **NOT VERIFIED (Menunggu Rekaman Pengguna)** |
| **In-Flight Guard CheckInModal** | Tombol "Menyimpan…", header close nonaktif | **NOT VERIFIED (Menunggu Rekaman Pengguna)** |
| **Sorotan Kartu Kamar (400ms)** | Muncul di grid kamar persis setelah modal keluar layar | **NOT VERIFIED (Menunggu Rekaman Pengguna)** |
| **Tombol CheckOutDialog** | Normal → Spinner + "Memproses…" → Centang 450ms → Tutup | **NOT VERIFIED (Menunggu Rekaman Pengguna)** |

---

## 5. Ringkasan File Terdampak

1. `lib/features/shared_widgets/app_button.dart` (Fixed width, loadingLabel, zero layout shift)
2. `lib/features/checkout/presentation/invoice_preview_dialog.dart` (450ms success, single-owner pop(true/false), loadingLabel)
3. `lib/features/reservation/presentation/check_in_modal.dart` (In-flight guard, single-owner pop, no blocking awaits)
4. `lib/features/checkout/presentation/check_out_dialog.dart` (450ms success, loadingLabel, single-owner pop)
5. `lib/features/room_management/presentation/room_controller.dart` (Clean decoupling dari premature highlight)
6. `lib/features/room_management/presentation/room_grid_screen.dart` (Exit transition delay 150ms, pre-captured highlight notifier)
7. `test/features/room_management/presentation/room_motion_interaction_test.dart` (23 widget tests komprehensif)
