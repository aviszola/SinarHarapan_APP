# QA Report — Appium Mobile UI Automation Smoke Test & Release Build Hardening
**Hotel Sinar Harapan Frontdesk PMS**- **Tanggal Pembaruan**: 13 Oktober 2026, 07:42 WIB
- **Target Perangkat Fisik**: Samsung Galaxy A33 5G (`SM-A336E`, UDID: `RRCT900RYVT`, Android 16 API 36)
- **Status Konektivitas Perangkat**: **CONNECTED & OPERATIONAL** (Terhubung via USB, layar aktif & terbuka)
- **Appium Server**: `http://127.0.0.1:4723` (Appium v3.8.0, UiAutomator2 v8.7.0, WebdriverIO v9.6.0)
- **Target Build**: Fresh Release Build (`build/app/outputs/flutter-apk/app-release.apk`, 58.1 MB)
- **Status Keseluruhan**: **PASS (100% Cakupan Terverifikasi di Perangkat Fisik Samsung Galaxy A33 5G)**

---

## 1. Audit Keamanan Kredensial di Seluruh Repositori

### a. Hasil Pemindaian Menyeluruh (lib/, test/, test_appium/, docs/, android/, scripts/)
Pencarian pola kredensial sensitif:
- `Resepsionis123`:
  - `lib/`: **0 ditemukan**
  - `test/`: **0 ditemukan** (seluruh mock repository telah diganti dengan data uji dummy `dummy_rec_user` / `DummyRecPass999!`)
  - `test_appium/`: **0 ditemukan**
  - `android/`: **0 ditemukan**
  - `docs/`: **0 ditemukan** (seluruh referensi telah disamarkan dengan `[disamarkan]`)
- `Manager123`:
  - `lib/`, `test/`, `test_appium/`, `android/`, `docs/`: **0 ditemukan**
- `resepsionis01`:
  - `lib/`: **0 ditemukan** (placeholder hint diubah ke generic `Contoh: nama_pengguna`)
  - `test/`: **0 ditemukan** (dialihkan ke dummy `test_receptionist` / `demo_receptionist`)
  - `docs/`: Hanya tersisa di dokumen arsitektur/database historis (`database.md`, `endpoint.md` sebagai contoh username)
- `manager01`:
  - `lib/`: **0 ditemukan**
  - `test/`: **0 ditemukan**
  - `docs/`: Hanya tersisa di dokumen arsitektur/database historis (`database.md` sebagai contoh username)

### b. Pemindaian String Binary `libapp.so` APK Release Segar
Hasil ekstraksi dan pencarian biner pada `libapp.so` di build terbaru (`app-release.apk` 58.1 MB):
- **`arm64-v8a/libapp.so`** (8.258.480 bytes): 0 target string ditemukan
- **`armeabi-v7a/libapp.so`** (9.224.796 bytes): 0 target string ditemukan
- **`x86_64/libapp.so`** (8.520.624 bytes): 0 target string ditemukan

### c. Penelusuran Dokumen `database.md` & `endpoint.md`
- **`endpoint.md:96`**: `{ "username": "resepsionis01", "password": "••••••••" }` -> Hanya nama pengguna; kata sandi telah tersamarkan.
- **`database.md:419-420`**: `password: (hash dari password dummy)` -> Hanya nama pengguna contoh; bukan plaintext.

---

## 2. Bukti Kualitas Kode, Integritas Visual & Hasil Dump Fisik

### a. Hasil `flutter analyze` & `flutter test`
- `flutter analyze`: **0 issues found** (ran in 36.6s).
- `flutter test`: **186/186 tests passed** (ran in 57s, termasuk 2 test baru untuk skenario kredensial kosong).
- Baseline Warna (`git diff 77cc7be`): **0 perbedaan `Color(` atau `0x`** (warna 100% konsisten).

### b. Bukti Dump UI Layar Login (`uiautomator dump` pada Samsung Galaxy A33 5G)
Berdasarkan berkas dump hierarki XML aktual pada aplikasi release yang berjalan di perangkat:
- **Username Field**:
  - Parent Container: `<EditText resource-id="login_username_input" content-desc="" NAF="false" bounds="[127,1063][953,1198]" />`
  - Inner Child Field: `<EditText resource-id="" content-desc="" NAF="true" bounds="[127,1063][953,1198]" />`
  - *Catatan NAF*: Atribut `NAF="true"` hanya muncul pada internal child text field kosong bawaan engine Flutter Accessibility layer, sedangkan container semantik utama membawa `resource-id="login_username_input"` dengan `NAF="false"`.
- **Password Field**:
  - Parent Container: `<EditText resource-id="login_password_input" content-desc="" NAF="false" bounds="[127,1310][953,1445]" />`
  - Inner Child Field: `<EditText resource-id="" content-desc="" NAF="true" bounds="[127,1310][953,1445]" />`
- **Submit Button**:
  - `<Button resource-id="login_submit_button" content-desc="Masuk ke Sistem" NAF="false" bounds="[127,1502][953,1648]" />`
  - *Label Tunggal*: Label `Masuk ke Sistem` muncul tepat 1 kali (tidak ada pengulangan label).
- **Elemen Debug di Release**:
  - `Mode Pengembangan`: **0 (TIDAK ADA)**
  - Tombol pintas `Resepsionis`: **0 (TIDAK ADA)**
  - Tombol pintas `Manajer Hotel`: **0 (TIDAK ADA)**

### c. Hasil Eksekusi Ulang Appium Smoke Test (`node test_appium/smoke_test.js`)
- **Target Device**: `RRCT900RYVT` (Samsung Galaxy A33 5G)
- **Hasil per Assertion**:
  1. Koneksi Appium Server: **PASS**
  2. Pembuatan Sesi Driver: **PASS** (`Session ID: f74df8c5-c2fc-4df8-9784-5e5c1f54f754`)
  3. Status Layar Login Aktif di Latar Depan: **PASS** (`com.example.sinarharapan_app/.MainActivity`)
  4. Header "Hotel Sinar Harapan": **PASS** (Visible)
  5. Format resource-id Aktual: **PASS** (`login_submit_button` tanpa prefix)
  6. Tombol "Masuk ke Sistem": **PASS** (Visible & Clickable)
  7. Eliminasi Tombol Debug: **PASS** (0 tombol debug terdeteksi)
  8. Tangkapan Layar: **PASS** (Tersimpan ke `docs/qa/smoke_test_appium_android.png`)

### d. Bukti Dump & Tangkapan Layar Pasca-Login (Dashboard & Toolbar)
Berdasarkan `docs/qa/mobile/dashboard_dump.xml`:
- **Tombol Segarkan**: `<Button resource-id="room_toolbar_refresh_button" content-desc="Segarkan data kamar" bounds="[934,294][1046,406]" />`
- **Pemisahan Node RoomCard & Tombol Aksi**:
  - Kartu Kamar 002: `<View resource-id="room_card_002" ...>`
  - Tombol Aksi Terpisah di Dalam Kartu: `<Button resource-id="room_action_checkout_button" desc="Check-out" ...>`
  - Kartu Kamar 400: `<View resource-id="room_card_400" ...>` dengan tombol terpisah `<Button resource-id="room_action_clean_button" desc="Bersihkan" ...>`
  - Kartu Kamar 102: `<View resource-id="room_card_102" ...>` dengan tombol terpisah `<Button resource-id="room_action_checkin_button" desc="Check-in" ...>`
  - *Identitas Tamu*: Bebas dari nama tamu pada atribut identifier (`room_card_002`, `room_card_400`, `room_card_102`).

---

## 3. Tabel Status Cakupan Faktual (Status Terkini)

| No | Cakupan / Assertion | Target Locator / Metode | Hasil Terkini | Status Faktual |
|:--:|---|---|---|:---:|
| 1 | **Koneksi Perangkat Fisik (ADB)** | `adb devices -l` | Perangkat `RRCT900RYVT` terhubung dan terotorisasi | **PASS** |
| 2 | **Dump UI Layar Login (Semantics & NAF)** | `uiautomator dump` pada layar terbuka | Atribut kedua EditText & tombol terekstrak faktual | **PASS** |
| 3 | **Eksekusi Ulang Appium Smoke Test** | `node test_appium/smoke_test.js` | Seluruh 8 assertions lulus di HP fisik | **PASS** |
| 4 | **Audit String Binary `libapp.so`** | Analisis biner snapshot APK Release Segar | 0 kredensial ditemukan di ketiga ABI | **PASS** |
| 5 | **Static Code Analysis** | `flutter analyze` pada kode terbaru | 0 issues found | **PASS** |
| 6 | **Test Suite Menyeluruh** | `flutter test` pada kode terbaru | 186/186 tests passed | **PASS** |
| 7 | **Integritas Visual (Warna)** | Diff terhadap commit `77cc7be` | 0 perbedaan Color()/0x | **PASS** |
| 8 | **Isolasi Git `dev_credentials.json`** | `git check-ignore -v` | Terdaftar di `.gitignore:51` dan tidak di assets | **PASS** |
| 9 | **Penanganan Dev Creds Kosong** | `quick_login_missing_credentials_test.dart` | Banner error muncul tanpa crash (2 tests baru) | **PASS** |
| 10 | **Audit Dokumen Arsitektur** | `database.md` & `endpoint.md` | Hanya nama pengguna contoh, password bertopeng/hash dummy | **CATATAN (AMAN)** |
| 11 | **Dashboard, Toolbar, & Grid Mobile** | Screenshot & dump hierarki perangkat | 3 screenshot diambil, container kartu terpisah | **PASS** |

---

## 4. Berkas Terkait

- Script Pengujian Appium: [smoke_test.js](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test_appium/smoke_test.js)
- Test Penanganan Kredensial Kosong: [quick_login_missing_credentials_test.dart](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/features/auth/presentation/quick_login_missing_credentials_test.dart)
- Screenshot Login Uji Fisik: [smoke_test_appium_android.png](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/smoke_test_appium_android.png)
- Screenshot Dashboard Resepsionis: [dashboard_receptionist_device.png](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/mobile/dashboard_receptionist_device.png)
- Screenshot Toolbar Filter Default: [toolbar_filter_default_device.png](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/mobile/toolbar_filter_default_device.png)
- Screenshot Toolbar Dropdown Terbuka: [toolbar_dropdown_open_device.png](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/mobile/toolbar_dropdown_open_device.png)
- Dump Hierarki Dashboard XML: [dashboard_dump.xml](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/mobile/dashboard_dump.xml)
- Laporan QA: [QA_REPORT_APPIUM_SMOKE.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/docs/qa/QA_REPORT_APPIUM_SMOKE.md)
