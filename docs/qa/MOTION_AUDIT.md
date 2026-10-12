# AUDIT MOTION & INTERAKSI — SINAR HARAPAN PMS (READ-ONLY)

**Tanggal Audit**: 12 Oktober 2026  
**Platform**: Flutter Desktop (Windows) / Web / Mobile  
**Branch**: `ui/room-toolbar`  
**Baseline Commit**: `d07a215`  
**Prinsip Audit**: `sinarharapan-qa` (No Evidence, No Claim — Read-Only Mode)  
**Status Eksekusi Baseline**:
- `flutter analyze`: **0 issues found** (No errors, no warnings)
- `flutter test`: **148/148 tests passed** (100% lulus)

---

## 1. Inventaris Animasi yang Sudah Ada

| Komponen / Fitur | File : Baris | Widget Animasi | Durasi | Kurva | Reduced Motion Support | Dispose Lifecycle |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **Split-Door Transition (Overlay)** | `lib/features/auth/presentation/widgets/split_door_transition.dart:45-80` | `AnimationController` + `AnimatedBuilder` | 950 ms total (808 ms sliding) | `Curves.easeInOutCubic` | **YA** (bypass instan) | **YA** (`controller.dispose()`) |
| **Split-Door PageRoute** | `lib/features/auth/presentation/widgets/split_door_transition.dart:497` | `PageRouteBuilder` | ≤ 700 ms | Linear / Ease | **YA** | Managed by Navigator |
| **Status Badge** | `lib/features/shared_widgets/status_badge.dart:56-83` | `AnimatedContainer` (bg/border/dot) + `AnimatedDefaultTextStyle` | 180 ms | `Curves.easeInOut` | **YA** (`Duration.zero`) | N/A (Implicit animation) |
| **Room Card Scale (Press)** | `lib/features/room_management/presentation/room_card.dart:60-63` | `AnimatedScale` | 120 ms | `Curves.easeOutCubic` | **YA** (scale 1.0) | N/A (Implicit animation) |
| **Room Card Hover (Border/Shadow)** | `lib/features/room_management/presentation/room_card.dart:69-79, 149-160` | `AnimatedContainer` | 140 ms | Linear default | **TIDAK** (durasi tetap 140ms) | N/A (Implicit animation) |
| **Room Card Status Stripe** | `lib/features/room_management/presentation/room_card.dart:84-89, 165-170` | `AnimatedContainer` | 180 ms | `Curves.easeInOut` | **TIDAK** (durasi tetap 180ms) | N/A (Implicit animation) |
| **Room Grid Filter Transition** | `lib/features/room_management/presentation/room_grid_screen.dart:234-251` | `AnimatedSwitcher` + `FadeTransition` | 150 ms | `Curves.easeIn` / `Curves.easeOut` | **YA** (`Duration.zero`) | N/A (Implicit animation) |
| **Room Grid Dialog Transition** | `lib/features/room_management/presentation/room_grid_screen.dart:57-75` | `showGeneralDialog` + `Opacity` + `Transform.scale` | 180 ms | `Curves.easeOutCubic` | **YA** (fallback ke `showDialog`) | Managed by Navigator |
| **Room Occupancy Bar** | `lib/features/room_management/presentation/room_filter_bar.dart:456-463` | `TweenAnimationBuilder<double>` | 180 ms | `Curves.easeOutCubic` | **YA** (`Duration.zero`) | N/A (Implicit animation) |
| **Refresh Button Spin** | `lib/features/room_management/presentation/room_filter_bar.dart:32-47, 868` | `AnimationController` + `RotationTransition` | 800 ms (repeat) | Linear | **YA** (Ikon statis saat reduced motion) | **YA** (`_refreshController.dispose()`) |
| **TopBar Tamu Aktif Hover** | `lib/features/shared_widgets/app_header.dart:349` | `AnimatedContainer` | 150 ms | Linear | **TIDAK** | N/A (Implicit animation) |
| **Manager Portal CTA Hover** | `lib/features/shared_widgets/app_header.dart:510` | `AnimatedContainer` | 150 ms | Linear | **TIDAK** | N/A (Implicit animation) |
| **Logout Button Hover** | `lib/features/shared_widgets/app_header.dart:793` | `AnimatedContainer` | 150 ms | Linear | **TIDAK** | N/A (Implicit animation) |
| **Filter Chip Status Hover/Active** | `lib/features/room_management/presentation/room_filter_bar.dart:582` | `AnimatedContainer` | 150 ms | Linear | **TIDAK** | N/A (Implicit animation) |

---

## 2. Analisis 5 Area Target

### A. Tombol Check-in / Check-out
- **State yang Tersedia**:
  - Di `RoomCard`:
    - `RoomCard._buildActionButton` (`lib/features/room_management/presentation/room_card.dart:412-490`): Menampilkan `ElevatedButton.icon` (Check-in) dan `OutlinedButton.icon` (Check-out). Tombol di kartu hanya memiliki state **Normal** dan **Disabled** bawaan style Material, **TIDAK ADA** state Loading atau Sukses pada tombol kartu.
  - Di Form Dialog:
    - `CheckInModal` (`lib/features/reservation/presentation/check_in_modal.dart:440-512`): Mengklik konfirmasi check-in membuka `InvoicePreviewDialog` (`showDialog(barrierDismissible: false)`).
    - Di `InvoicePreviewDialog` (`lib/features/checkout/presentation/invoice_preview_dialog.dart:691-699`): Tombol `Konfirmasi Lunas & Masuk Kamar` langsung memanggil `Navigator.of(context).pop()` dan menjalankan `widget.onConfirmCheckIn!()`.
    - Di `CheckOutDialog` (`lib/features/checkout/presentation/check_out_dialog.dart:101-140`): Tombol check-out memanggil `_handleConfirmCheckOut()`.
- **Pencegahan Double-Submit**:
  - **TIDAK TERCEGAH DI LEVEL UI (FRONTEND GAPS)**:
    - Baik di `CheckInModal._executeFinalCheckIn` (`check_in_modal.dart:515`) maupun di `CheckOutDialog._handleConfirmCheckOut` (`check_out_dialog.dart:101`), **TIDAK ADA flag boolean `_isLoading` atau `_isSubmitting`**.
    - Tombol konfirmasi tidak dinonaktifkan (`onPressed: null`) saat proses transaksi asinkron sedang berlangsung.
    - Pencegahan double-submit hanya mengandalkan respons backend (HTTP 409 Conflict bila status kamar sudah berubah).
- **Titik `await` Pemanggilan Repository**:
  - Check-in: `await ref.read(roomListProvider.notifier).checkIn(...)` di `lib/features/reservation/presentation/check_in_modal.dart:525`.
  - Check-out: `await ref.read(roomListProvider.notifier).checkOut(...)` di `lib/features/checkout/presentation/check_out_dialog.dart:134`.

---

### B. Kartu Kamar (RoomCard)
- **Mekanisme Pembaruan Setelah Transaksi Sukses**:
  - Setelah `checkIn(...)` atau `checkOut(...)` selesai dieksekusi, notifier Riverpod memanggil `await loadRooms()` (`lib/features/room_management/presentation/room_controller.dart:166` dan `185`).
  - Di dalam `loadRooms()` (`room_controller.dart:93`), state diubah menjadi:
    `state = const AsyncValue.loading();`
    lalu `state = AsyncValue.data(rooms);`.
  - Akibatnya, `roomListAsync.when(...)` di `lib/features/room_management/presentation/room_grid_screen.dart:217` beralih sementara ke loading, memicu unmount seluruh grid kartu dan menampilkan `_RoomGridSkeleton()`.
- **Kestabilan Key per Kamar**:
  - **TIDAK ADA KEY STABIL**: Di `lib/features/room_management/presentation/room_grid_screen.dart:386-389`, pemanggilan `RoomCard` di dalam `GridView.builder` tidak menyertakan parameter `key`:
    ```dart
    return RoomCard(
      room: floorRooms[index],
      onTap: () => onTap(floorRooms[index]),
    );
    ```
    Karena tidak memiliki `key: ValueKey(room.id)`, Flutter mencocokkan widget berdasarkan posisi indeks. Ini menyebabkan animasi lokal kartu dapat ter-reset dan berisiko state leakage saat susunan kamar bergeser.
- **Konflik Gesture Antara Tap Kartu dan Tombol Anak**:
  - Pembungkus kartu menggunakan `GestureDetector(onTap: widget.onTap)` (`room_card.dart:59`).
  - Tombol anak (`ElevatedButton`/`OutlinedButton`) di bagian bawah kartu juga memanggil `onPressed: widget.onTap` (`room_card.dart:426, 447, 467`).
  - Keduanya mengarah ke callback yang sama, sehingga tidak terjadi benturan logika. Namun secara visual, tombol anak memiliki ripple bawaan Material sedangkan kartu memiliki animasi `AnimatedScale` (`_isPressed: 0.99`), menghasilkan dua feedback visual bersamaan saat tombol diklik.

---

### C. Badge Status (StatusBadge)
- **Komponen**:
  - Diimplementasikan di `lib/features/shared_widgets/status_badge.dart:10-97`.
  - Menggunakan `AnimatedContainer` untuk background dan border (durasi 180ms), `AnimatedContainer` lingkaran 6x6 untuk dot indikator warna, dan `AnimatedDefaultTextStyle` untuk teks label.
- **Dimensi dan Ukuran**:
  - **UKURAN TIDAK TETAP (BERUBAH MENGIKUTI TEKS)**:
    - Komponen menggunakan `Row(mainAxisSize: MainAxisSize.min)` dengan padding horizontal 8px (`status_badge.dart:61, 68`).
    - Panjang teks berbeda drastis antara status: `"Terisi"` (6 karakter), `"Tersedia"` (8 karakter), `"Kotor"` (5 karakter), dan `"Perawatan"` (9 karakter).
    - Karena tidak ada `constraints: BoxConstraints(minWidth: ...)` atau lebar tetap, badge melebar/menyempit secara horizontal saat status kamar berganti, menyebabkan layout shift pada elemen sekitarnya di header kartu.
- **Perubahan Status dari Luar Tindakan Staf**:
  - **YA, DAPAT BERUBAH SECARA OTOMATIS**:
    - Di `lib/features/room_management/presentation/room_controller.dart:54-65`, terdapat polling background periodik setiap 15 detik:
      ```dart
      _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollStatus());
      ```
    - Jika ada perubahan status dari staf lain (mis. housekeeping menandai kamar selesai dibersihkan), state provider akan diperbarui otomatis tanpa tindakan dari staf frontdesk.

---

### D. Dialog Check-in / Check-out
- **Jenis Transisi**:
  - **KUSTOM**: Dibuka menggunakan fungsi pembantu `_showRoomDialog` di `lib/features/room_management/presentation/room_grid_screen.dart:45-76`.
  - Menggunakan `showGeneralDialog` dengan transisi gabungan mikro-scale dan fade:
    - Durasi: `180 ms`
    - Kurva: `Curves.easeOutCubic`
    - Transformasi: `Opacity(0.0 -> 1.0)` dan `Transform.scale(0.985 -> 1.000)`.
    - Menghormati accessibility: jika `MediaQuery.maybeDisableAnimationsOf(context)` bernilai `true`, otomatis beralih ke `showDialog` standar instan.
- **Konfigurasi `barrierDismissible`**:
  - Diatur ke `barrierDismissible: false` secara eksplisit untuk `CheckInModal` (`room_grid_screen.dart:82`) dan `CheckOutDialog` (`room_grid_screen.dart:88`).
  - Menjamin formulir transaksi penting tidak sengaja tertutup saat staf mengeklik area gelap di luar modal.

---

### E. Hover & Interaksi Tekan Kartu
- **Hover**:
  - Sudah diimplementasikan menggunakan `MouseRegion` di `lib/features/room_management/presentation/room_card.dart:51-53`.
  - Memicu perubahan state `_isHovered = true/false`, menggerakkan `AnimatedContainer` (durasi 140ms) untuk menebalkan border menjadi `1.5px` (`AppColors.brandNavy`) dan memunculkan bayangan halus `AppElevation.subtle`.
- **Kursor**:
  - Dinamis: `cursor: room.isMaintenance ? SystemMouseCursors.basic : SystemMouseCursors.click` (`room_card.dart:54`).
- **Tekan (Press Feedback)**:
  - Menggunakan `GestureDetector` (`room_card.dart:55-58`) untuk mengubah `_isPressed = true/false`.
  - Memicu `AnimatedScale` mikro (durasi 120ms, kurva `Curves.easeOutCubic`, scale `0.99`).
- **Fokus Keyboard**:
  - **TIDAK ADA FOKUS KEYBOARD PADA KARTU**:
    - `RoomCard` tidak dibungkus `Focus` atau `FocusableActionDetector`.
    - Kartu tidak dapat ditavigasi atau dipilih menggunakan tombol Tab + Enter/Space dari keyboard. Hanya tombol anak (Check-in/Check-out) yang dapat menerima fokus karena merupakan widget `Button` Material.

---

## 3. Identifikasi & Klasifikasi Risiko

### [HIGH] Risiko 1: Tidak Ada In-Flight Guard (Double-Submit Vulnerability) pada Transaksi Check-In & Check-Out
- **File:Baris**: `lib/features/reservation/presentation/check_in_modal.dart:515-548` & `lib/features/checkout/presentation/check_out_dialog.dart:101-140`.
- **Dampak**: Jika koneksi jaringan lambat atau staf mengklik tombol konfirmasi secara cepat berturut-turut, pemanggilan API dapat terjadi berulang kali sebelum dialog tertutup.
- **Mitigasi**: Tambahkan state `_isSubmitting`, set `onPressed: _isSubmitting ? null : ...`, dan tampilkan loading spinner inline pada tombol aksi utama.

### [HIGH] Risiko 2: Ketiadaan `Key` Stabil pada `RoomCard` dalam Grid
- **File:Baris**: `lib/features/room_management/presentation/room_grid_screen.dart:386-389`.
- **Dampak**: Saat data kamar bertambah/berkurang atau difilter, widget kartu di-reuse berdasarkan posisi indeks array, bukan identitas kamar. Menyebabkan animasi atau state hover/press tertinggal pada kamar yang salah.
- **Mitigasi**: Pasang `key: ValueKey(floorRooms[index].id)` pada setiap instansiasi `RoomCard`.

### [MEDIUM] Risiko 3: Grid Rebuild Massal via `AsyncValue.loading()` Pasca Transaksi
- **File:Baris**: `lib/features/room_management/presentation/room_controller.dart:93, 166, 185`.
- **Dampak**: Setiap transaksi sukses memicu `state = const AsyncValue.loading()`, yang mengganti seluruh tampilan grid kamar menjadi skeleton selama beberapa milidetik sebelum menampilkan kartu kembali. Ini menghasilkan efek kedip (flash) visual yang mengganggu mata.
- **Mitigasi**: Lakukan optimasi in-place update pada item spesifik di list lokal sebelum re-fetch data di latar belakang, tanpa menyetel seluruh state list ke loading.

### [MEDIUM] Risiko 4: Rebuild Seluruh Header Setiap Detik oleh Jam Live
- **File:Baris**: `lib/features/shared_widgets/app_header.dart:43-47, 57-100`.
- **Dampak**: `Timer.periodic(Duration(seconds: 1))` memanggil `setState()` di level `_ReceptionistTopBarState`, menyebabkan seluruh topbar (termasuk tombol tamu aktif, profil, avatar, dan border) dirender ulang setiap 1000 ms.
- **Mitigasi**: Ekstrak tampilan teks jam ke dalam widget terisolasi (mis. `_LiveClockDisplay`) agar scope `setState` hanya mencakup teks jam saja.

### [LOW] Risiko 5: Layout Shift Horizontal pada `StatusBadge`
- **File:Baris**: `lib/features/shared_widgets/status_badge.dart:68-94`.
- **Dampak**: Lebar badge bervariasi antara 50px hingga 85px tergantung teks label status. Saat status berubah dari "Terisi" ke "Perawatan", lebar badge membesar dan menggeser elemen di sekitarnya.
- **Mitigasi**: Tambahkan `constraints: BoxConstraints(minWidth: 80)` atau tetapkan lebar minimum tetap pada badge.

---

## 4. Rekomendasi Implementasi Per Area (Architecture Guidance)

1. **Tombol Transaksi**:
   - Terapkan pola *In-Flight Guard* standar PMS: deklarasikan `bool _isSubmitting = false`, kunci tombol secara sinkron di baris pertama handler, gunakan `try ... finally { if (mounted) setState(() => _isSubmitting = false); }`, dan tampilkan `SizedBox(width: 14, height: 14, child: CircularProgressIndicator(...))` saat in-flight.
2. **Kestabilan List & Kartu**:
   - Tambahkan `key: ValueKey(room.id)` pada `RoomCard`.
   - Hindari reset ke `AsyncValue.loading()` pada `loadRooms()` jika state sudah memiliki data sebelumnya; gunakan silent background refresh agar transisi status kamar berjalan mulus tanpa skeleton flicker.
   - Tambahkan `FocusableActionDetector` atau `InkWell` dengan focus ring pada kartu agar mendukung keyboard accessibility (Tab + Space/Enter).
3. **Badge Status**:
   - Berikan `minWidth: 84` pada kontainer `StatusBadge` dan gunakan `AnimatedSwitcher` dengan transisi cross-fade teks berukuran fixed.
4. **Isolasi Jam Live**:
   - Bungkus widget jam di `ReceptionistTopBar` ke dalam komponen `LiveClockText` tersendiri agar widget induknya tidak ikut ter-rebuild setiap detik.

---

## 5. Daftar Hal NOT VERIFIED

- **Pengukuran Frame Time / Profiling GPU Realtime (Windows Profile Mode)**:
  - **Status**: **NOT VERIFIED**.
  - **Alasan**: Perintah `flutter run -d windows --profile` memerlukan sesi interaktif GUI Windows dengan jendela aktif dan koneksi DevTools/Trace profiler eksternal. Dalam eksekusi command line non-interaktif saat ini, pengukuran frame time rasterizer (ms per frame) tidak dapat dilakukan secara deterministik tanpa automasi driver grafik profil.
