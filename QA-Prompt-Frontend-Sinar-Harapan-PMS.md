# PANDUAN PENGUJIAN MUTU APLIKASI (QA) — Pengujian Tampilan Antarmuka Sinar Harapan Frontdesk & Pengelolaan Hotel (PMS)

**Untuk digunakan oleh:** Penguji mutu aplikasi (QA Engineer manusia atau asisten cerdas AI) yang ditugaskan menguji tampilan layar.  
**Dasar rujukan resmi:** [prd.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD) (dokumen kebutuhan produk v1.0), [arsitektur.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md) (dokumen rancangan teknis v1.0), [design.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md) (dokumen standar desain v1.0).  
**Sasaran aplikasi:** Sistem Pengelolaan Hotel (Property Management System / PMS) & Meja Resepsionis Sinar Harapan berbasis Flutter (Website, Komputer Desktop, dan Tablet).  

*(Keterangan singkatan umum: UI = Tampilan yang dilihat pengguna di layar; UX = Tingkat kenyamanan dan kemudahan pengguna saat memakai aplikasi; KTP = Kartu Tanda Penduduk; NIK = Nomor Induk Kependudukan; OCR = Pemindai dan pembaca tulisan otomatis dari foto; WhatsApp = Aplikasi pesan instan; API = Jembatan pertukaran data antar-program; JWT = Tanda bukti resmi berbentuk kode aman bahwa pengguna sudah berhasil masuk; PDF = Format berkas dokumen siap cetak; Excel = Format berkas lembar sebar perhitungan).*

---

## 1. Peran & Misi Anda

Anda adalah penguji mutu aplikasi (QA Engineer) senior. Anda bertanggung jawab penuh memastikan seluruh tampilan layar aplikasi bekerja dengan benar sebelum versi awal (MVP — versi produk siap pakai) resmi diluncurkan.

Aplikasi ini akan digunakan langsung di meja resepsionis hotel yang sibuk. Di meja depan, tamu datang silih berganti dan waktu pelayanan harus serba cepat. Aplikasi ini juga digunakan oleh manajer untuk mengambil keputusan bisnis penting dari angka-angka yang tertera di layar.

Kesalahan sistem (bug) atau ketidaksesuaian tampilan sekecil apa pun bukanlah hal sepele:
- Salah memberi warna pada kotak kamar bisa membuat resepsionis menjual kamar yang sebenarnya sedang ditempati tamu.
- Salah menghitung angka ringkasan kinerja (KPI) bisa membuat manajer salah mengambil keputusan keuangan hotel.
- Tombol yang ukurannya tidak sesuai panduan bisa membuat jari salah mengetuk (salah tap) di layar sentuh tablet.

**Prinsip kerja wajib Anda:**
1. **Uji sebagai dua orang berbeda.** Anda wajib benar-benar membuka akun (login) dan menguji sebagai peran resepsionis (RECEPTIONIST) serta manajer (MANAGER) secara terpisah. Uji dari awal masuk sampai keluar (logout). Jangan hanya menguji satu peran lalu mengira peran lain sudah pasti sama.
2. **Jangan mudah percaya pada tampilan layar — selalu periksa ke sumber aslinya.** Cocokkan setiap fitur dengan tiga dokumen acuan:
   - (a) Dokumen kebutuhan produk ([prd.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD) — perhatikan kode acuan kebutuhan fitur / FR-XXX).
   - (b) Dokumen rancangan teknis ([arsitektur.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md) — perhatikan alamat layanan data / endpoint API, susunan data, dan aturan logika).
   - (c) Dokumen standar desain ([design.md](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md) — perhatikan warna baku, bentuk huruf, jarak tepi, dan komponen tombol).  
   Laporkan setiap selisih. Walau hanya beda ukuran 1 piksel (1px), beda sedikit kepekatan warna, atau beda satu kata pada pesan peringatan.
3. **Uji jalur gagal, jangan cuma jalur lancar.** Pada setiap fitur, sengaja coba hal-hal yang salah atau tidak biasa:
   - Kosongkan isian yang wajib diisi.
   - Ketik huruf pada isian angka atau salah format.
   - Putuskan sambungan internet saat proses berlangsung.
   - Biarkan aplikasi diam hingga waktu sesi masuk habis.
   - Coba dua orang resepsionis memesan kamar yang sama di waktu yang nyaris bersamaan (uji tabrakan data / race condition).
   - Coba buka halaman atau tombol yang bukan menjadi hak akses peran Anda.
4. **Uji penyamaan data antar-perangkat.** Status kamar harus selalu berganti seketika (real-time, kode FR-ROOM-07). Buka dua peramban (browser) atau dua perangkat terpisah dengan akun berbeda. Pastikan perubahan status kamar langsung terlihat di layar kedua tanpa perlu menekan tombol muat ulang (refresh) secara manual.
5. **Laporkan saja, jangan perbaiki sendiri.** Tugas utama Anda adalah mencari, menguji, dan mencatat kesalahan sistem secara rinci, bukan mengubah isi kode program aplikasi.

---

## 2. Ringkasan Aplikasi (Konteks Cepat)

| Bagian | Rincian Penjelasan |
| :--- | :--- |
| **Pengguna Aplikasi** | Resepsionis (Frontdesk Officer) dan Manajer Hotel (Property Manager) — dua peran berbeda dengan satu pintu masuk akun yang sama. |
| **Sesi Masuk Akun** | Menggunakan tanda bukti masuk digital aman (JWT), waktu berlaku otomatis habis dalam 12 jam, langsung dialihkan ke halaman utama sesuai peran (kode FR-AUTH-03). |
| **Layar Utama** | Perangkat tablet posisi mendatar (landscape) ukuran 10 inci ke atas sebagai layar utama; komputer desktop (1920×1080) sebagai layar pendukung. |
| **Alur Menu Inti** | Buka Akun (Auth) → Denah Kamar Kotak-kotak (Room Grid) → Pemesanan & Tamu Masuk (Check-in) dengan Pemindai KTP (OCR) → Pengiriman Pesan WhatsApp Otomatis → Tamu Pulang (Check-out) & Cetak Faktur (Invoice) → Laporan Kinerja Manajer. |
| **Prinsip Desain** | Biru gelap pekat (Navy `#001B4E` / `#0A2A6E`) sebagai warna dasar utama bingkai dan menu; Jingga oranye cerah (`#FF6600`) sebagai satu-satunya penanda tombol aksi utama di layar; bergaya datar rapi (tanpa efek kaca tembus pandang, tanpa gradasi ramai, tanpa bayangan gelap tebal); status kamar hanya berupa garis warna tipis di samping kotak, bukan mewarnai seluruh kotak kamar. |

---

## 3. Prasyarat Pengujian

Sebelum memulai pengujian, siapkan hal-hal berikut:
1. **Minimal 2 akun uji resmi:** 1 akun resepsionis (`RECEPTIONIST`), 1 akun manajer (`MANAGER`) dengan nama akun dan kata sandi yang benar, ditambah 1 pasangan nama akun/kata sandi yang sengaja disalahkan untuk uji gagal masuk.
2. **Minimal 6 kamar uji:** Kamar harus mencakup keempat jenis status (Tersedia / `AVAILABLE`, Terisi / `OCCUPIED`, Kotor / `DIRTY`, Perbaikan / `MAINTENANCE`) dengan variasi tipe kamar dan lantai yang berbeda agar fitur penyaring (filter) bisa dicoba.
3. **Contoh foto KTP untuk pengujian:**
   - 1 foto KTP jelas dan terang.
   - 1 foto KTP buram, gelap, atau miring (untuk menguji apakah sistem beralih ke jalan cadangan saat tingkat keyakinan bacaan / confidence score di bawah 70%).
   - 1 foto tanpa wajah atau bukan KTP (untuk memastikan sistem menolak foto yang salah dan meminta input ketik manual).
4. **Nomor WhatsApp pengujian yang aktif:** Untuk memeriksa apakah pesan pengingat benar-benar masuk ke ponsel uji, bukan cuma tertulis "terkirim" di layar komputer.
5. **Dua perangkat atau dua peramban terpisah:** Masuk ke dalam akun secara bersamaan (misalnya 1 resepsionis + 1 manajer, atau 2 resepsionis di komputer berbeda) untuk menguji apakah pembaruan data berjalan langsung (real-time sync).
6. **Alat pemeriksa bawaan peramban (DevTools):** Buka bagian lalu lintas data (Network tab), layar catatan sistem (Console), serta bagian simpanan lokal (Application/Storage). Ini berguna untuk memeriksa isi data yang sebenarnya dikirim dan diterima dari sistem server, bukan hanya melihat tampilan luar layar.
7. **Uji tanpa internet:** Matikan sambungan jaringan lewat fitur simulasi peramban (pilihan *Offline* pada Network throttling) untuk menguji ketahanan aplikasi saat internet hotel tiba-tiba terputus (kode FR-RES-08).

---

## 4. Metodologi Pengujian

Untuk setiap butir pengujian di bawah ini, ikuti urutan langkah pencatatan berikut:
- **Keterlacakan Kebutuhan (Requirement Traceability):** Sebutkan kode acuan kebutuhan fitur yang diuji (misalnya `FR-RES-04`).
- **Cara Mengulang Kejadian (Steps to Reproduce):** Tulis urutan langkah yang jelas dan runtut agar orang lain bisa mengulang kejadian yang sama persis.
- **Yang Seharusnya Terjadi (Expected Result):** Tulis apa yang wajib terjadi berdasarkan dokumen aturan produk, dokumen teknis, atau dokumen standar desain. Cantumkan rujukan pasal dan kode warna atau ukurannya.
- **Yang Sebenarnya Terjadi (Actual Result):** Tulis apa yang sungguh-sungguh terjadi di layar saat Anda mengkliknya.
- **Status Akhir Pengujian:** Pilih salah satu:
  - **Lulus (Pass):** Berjalan sempurna sesuai aturan dokumen.
  - **Gagal (Fail):** Terjadi kesalahan atau tidak sesuai aturan.
  - **Sebagian (Partial):** Sebagian berhasil, tapi ada syarat yang belum terpenuhi penuh.
  - **Terhambat (Blocked):** Pengujian tidak bisa dilanjutkan karena ada fitur penghalang yang belum siap atau sistem server belum menyediakan layanannya.
- **Tingkat Keparahan Masalah (Severity jika Gagal):** Tentukan tingkat bahayanya mengacu pada panduan di Bagian 14.

**Gunakan metode periksa silang (cross-check) tiga dokumen:**  
Jika isi dokumen kebutuhan produk (PRD), dokumen rancangan teknis (Arsitektur), dan dokumen standar desain (Design System) saling bertolak belakang (misalnya beda istilah, beda angka batas waktu, atau beda kode warna), hal tersebut langsung dicatat sebagai temuan awal dokumen yang harus dilaporkan ke tim produk sebelum diambil kesimpulan mana yang paling benar. Lihat Bagian 15 untuk contoh perbedaan antar-dokumen yang sudah terdeteksi.

---

## 5. A — Modul Masuk & Sesi Akun (FR-AUTH-01 s/d FR-AUTH-05)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) | Perhatikan Juga |
| :---: | :--- | :--- | :--- |
| **A1** | Masuk akun (login) dengan data benar sebagai resepsionis (`RECEPTIONIST`) | Layar langsung berpindah secara otomatis ke halaman Denah Kamar Kotak-kotak (kode FR-AUTH-03). | Perhatikan waktu tunggu memuat halaman. Tidak boleh ada kedipan layar halaman lain sebelum berpindah. |
| **A2** | Masuk akun (login) dengan data benar sebagai manajer (`MANAGER`) | Layar langsung berpindah secara otomatis ke halaman Dasbor Analisis Kinerja Eksekutif. | Sama seperti kasus A1, perpindahan halaman harus mulus dan cepat. |
| **A3** | Masuk akun dengan kata sandi yang salah | Muncul tulisan pemberitahuan kesalahan yang mudah dipahami. Kotak isian kata sandi ditandai warna merah peringatan. Tulisan nama akun tidak terhapus (hanya kotak kata sandi yang dikosongkan). | Cocokkan warna kotak kesalahan dengan warna standar merah muda `#FEE2E2` (`color/status/error-bg`) pada dokumen desain §2.3. |
| **A4** | Masuk akun dengan nama akun yang belum terdaftar | Muncul pesan kesalahan yang umum dan tidak membocorkan apakah nama akun tersebut ada atau tidak di sistem (mencegah orang luar menebak-nebak nama akun yang terdaftar / enumerasi akun). | Ini saran pengamanan penting bila pesan membedakan secara gamblang antara "nama akun tidak ditemukan" dengan "kata sandi salah". |
| **A5** | Tulisan kata sandi disamarkan dengan tanda titik dan tidak terbaca terang-terangan di jaringan | Tulisan kata sandi selalu tersamar bintang/titik di layar. Saat dikirim lewat jaringan internet, data wajib disandikan aman (HTTPS) dan tidak boleh terbaca sebagai teks biasa di catatan peramban (FR-AUTH-05, Arsitektur §5). | Periksa isi balasan data dari sistem server. Pastikan kata sandi asli maupun kode sandi acak (`password_hash`) tidak pernah ikut terkirim balik ke layar komputer. |
| **A6** | Percobaan masuk gagal berturut-turut lebih dari 5 kali dalam 1 menit | Alat pembatas jumlah percobaan (rate limiter) langsung bekerja (Arsitektur §3.3). Muncul tulisan peringatan jeda waktu tunggu (cooldown) atau penghentian sementara. | Jika setelah salah 5 kali berturut-turut sistem tetap diam tanpa memberi peringatan jeda waktu, status kasus ini adalah **Gagal (Fail)**. |
| **A7** | Layar dibiarkan menganggur tanpa disentuh selama 12 jam (atau disimulasikan waktu sesi habis) | Pengguna otomatis dikeluarkan dari sistem (auto-logout). Layar dialihkan kembali ke pintu masuk akun disertai keterangan jelas bahwa waktu sesi telah berakhir (kode FR-AUTH-04). | Periksa apakah data formulir yang sedang diisi (misalnya isian tamu masuk) hilang mendadak tanpa ada simpanan cadangan. Kehilangan data tamu adalah masalah kenyamanan yang serius. |
| **A8** | Menekan tombol "Kembali" (Back) pada peramban setelah pengguna keluar (logout) | Layar tidak boleh bisa kembali membuka halaman dasbor tanpa memasukkan kata sandi lagi. Simpanan sementara peramban (cache) tidak boleh menyimpan hak akses yang sudah ditutup. | Wajib diuji pada akun resepsionis maupun akun manajer. |
| **A9** | Memuat ulang halaman peramban (menekan F5 atau Refresh) saat sesi masih aktif | Pengguna tetap berada di halaman kerjanya tanpa terlempar keluar ke halaman masuk akun. | Pengguna tidak perlu mengetik ulang kata sandinya. |
| **A10** | Kerapian tampilan layar masuk akun | Didominasi warna biru gelap (Navy). Hanya ada satu tombol masuk berwarna oranye terang sebagai tombol aksi utama. Bersih tanpa hiasan gambar atau foto yang tidak perlu (Dokumen Desain §7). | Periksa apakah ada warna oranye lain yang mencolok di layar selain tombol masuk utama (misalnya tautan "Lupa Kata Sandi" berwarna oranye, karena ini melanggar aturan "maksimal satu unsur oranye utama per layar"). |
| **A11** | Ukuran tombol "Masuk" sesuai standar kenyamanan jari | Tinggi tombol minimal 48 piksel (48px), jarak tepi kiri-kanan tombol 20 piksel (padding 20px), kelengkungan sudut 8 piksel (radius 8px / `radius/md`), dan ketebalan huruf 600 (Dokumen Desain §6.1). | Ukur ukuran pastinya menggunakan alat pemeriksa peramban (DevTools), jangan hanya mengira-ngira dengan mata. |

---

## 6. B — Modul Denah & Ketersediaan Kamar (FR-ROOM-01 s/d FR-ROOM-07)

### 6.1 Bagian Kerja Resepsionis (Fungsional)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **B1** | Tampilan denah kotak kamar saat halaman pertama kali dibuka | Semua unit kamar tampil rapi dalam susunan kotak denah. Waktu pemuatan halaman di bawah 1,5 detik pada kecepatan internet 10 Mbps (dokumen mutu non-fungsional NFR §4.1). Waktu ini diukur lewat bagian pemeriksa lalu lintas data di peramban. |
| **B2** | Warna penanda untuk 4 status kondisi kamar | **Hijau** = Kamar Tersedia (`AVAILABLE`), **Merah** = Kamar Terisi Tamu (`OCCUPIED`), **Kuning** = Kamar Kotor Butuh Dibersihkan (`DIRTY`), **Abu-abu** = Kamar Rusak / Dalam Perbaikan (`MAINTENANCE`) (kode FR-ROOM-02). Periksa kesesuaian nilai kode warna resminya pada Bagian 12 dan Bagian 15. |
| **B3** | Bentuk visual setiap kotak kamar | Latar belakang kotak kamar berwarna putih bersih atau abu-abu terang netral. Warna penanda status kamar hanya berupa garis tipis 4 piksel (4px) di sisi kiri kotak ditambah satu titik bulat kecil. **DILARANG KERAS** mengecat seluruh badan kotak kamar dengan warna penuh pekat (Standar Desain §6.2 dan larangan tegas pada §9). |
| **B4** | Tombol penyaring (filter) tipe kamar (Standard, Superior, Deluxe, Family) | Denah kamar langsung menyaring unit yang tampil sesuai pilihan jenis kamar. Jumlah kotak berkurang sesuai kriteria tanpa ada kedipan layar yang mengganggu atau pemuatan ulang seluruh halaman. |
| **B5** | Tombol penyaring (filter) nomor lantai | Denah kamar hanya menampilkan kamar-kamar yang berada di lantai yang dipilih. Cara kerjanya sama mulus seperti kasus B4. |
| **B6** | Mengklik kotak kamar bergaris Hijau (Tersedia) | Langsung memunculkan jendela sembul (modal) untuk pengisian data pemesanan dan penerimaan tamu masuk (lanjut ke Bagian 7). |
| **B7** | Mengklik kotak kamar bergaris Merah atau Kuning (Terisi atau Kotor) | Langsung membuka alur kepulangan tamu (check-out) dan rincian pelunasan biaya inap (lanjut ke Bagian 9). |
| **B8** | Mengklik kotak kamar bergaris Abu-abu (Dalam Perbaikan) | Tidak bisa dipakai untuk transaksi apa pun. Harus muncul tulisan penjelasan ramah bahwa kamar sedang diperbaiki, bukan diam saja tanpa tanggapan saat diklik. |
| **B9** | Pembaruan status kamar seketika (diuji pada 2 komputer resepsionis yang terbuka bersamaan) | Saat satu komputer mengubah status kamar, layar komputer resepsionis yang lain langsung ikut berubah seketika tanpa perlu menekan tombol muat ulang secara manual (kode FR-ROOM-07). |
| **B10** | Tanda lencana (badge) status pada kotak kamar | Memuat titik warna berukuran 8 piksel (8px) ditambah tulisan keterangan status yang jelas (Standar Desain §6.3). Warna tidak boleh menjadi satu-satunya penanda agar orang yang kesulitan membedakan warna tetap paham status kamar (Standar Aksesibilitas §8). |

### 6.2 Bagian Kerja Manajer (Pengelolaan Data Kamar / CRUD)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **B11** | Manajer melihat denah kotak kamar | Hanya bisa melihat saja (View Only). Pastikan tidak ada tombol atau pilihan untuk memasukkan tamu atau memulangkan tamu yang bisa diklik oleh manajer (Aturan Hak Akses Pengguna PRD §2.3). |
| **B12** | Menambah data unit kamar baru | Tersedia formulir berisi Nomor Kamar, Lantai, Tipe Kamar, Tarif Dasar per Malam, dan Fasilitas Kamar (kode FR-ROOM-04). Sistem menolak jika ada nomor kamar kembar (aturan pembatas data `UNIQUE` pada kolom database `rooms.room_number`). |
| **B13** | Mengubah tarif sewa kamar | Perubahan harga berhasil disimpan dan langsung terlihat pada perhitungan biaya kamar saat resepsionis melayani tamu berikutnya. |
| **B14** | Mengubah status kamar menjadi Perbaikan (Maintenance) saat masih ada tamu aktif menginap | Sistem server wajib menolak perubahan ini. Dokumen teknis (Arsitektur §4.3) menegaskan kamar tidak boleh diubah ke status perbaikan selama masih ada tamu menginap yang belum keluar (`actual_check_out_time IS NULL`). |
| **B15** | Menghapus unit kamar yang tidak memiliki riwayat tamu aktif | Unit kamar berhasil dihapus dengan aman melalui sistem hapus semu (soft-delete — data ditandai nonaktif di arsip database). |
| **B16** | Menghapus unit kamar yang sedang dihuni tamu aktif | Sistem menolak perintah hapus dan menampilkan tulisan peringatan yang jelas menerangkan bahwa kamar masih terisi tamu (kode FR-ROOM-06, Arsitektur §4.3). |
| **B17** | Format penulisan angka tarif sewa kamar | Ditulis dalam format mata uang Rupiah Indonesia (misalnya `Rp 350.000`), menggunakan bentuk angka lurus rata kanan saat ditampilkan di dalam tabel daftar kamar (Standar Desain §6.6). |

---

## 7. C — Modul Pemesanan & Penerimaan Tamu (Check-in) dengan Pemindai KTP (FR-RES-01 s/d FR-RES-08)

Ini adalah alur kerja yang paling penting bagi meja resepsionis. Kecepatan kerja diukur secara tegas: proses tamu masuk harus selesai di bawah 2 menit, dan pembacaan foto KTP harus selesai di bawah 3 detik. Uji bagian ini menggunakan pencatat waktu (stopwatch) sungguhan.

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **C1** | Jendela isian tamu terbuka saat mengklik kamar Hijau | Lebar jendela sembul maksimal 720 piksel (720px), sudut melengkung 12 piksel (`radius/lg`), memiliki bayangan lembut bertingkat (`elevation/2`), memiliki judul bagian atas yang jelas, serta tombol silang (X) penutup jendela di sudut kanan atas (Standar Desain §6.5). |
| **C2** | Memilih sumber pesanan dari mitra RedDoorz | Wajib mengisi Kode Pesanan Resmi RedDoorz. Tarif kamar otomatis terkunci mengikuti harga yang ditentukan oleh platform aplikasi mitra, bukan harga tarif umum hotel (kode FR-RES-02). |
| **C3** | Memilih sumber pesanan tamu langsung datang (Walk-in) | Tarif kamar otomatis mengambil harga sewa resmi hotel yang sedang berlaku saat itu (harga dinamis hasil pengaturan manajer — cocokkan dengan kasus B13). |
| **C4** | Memindai foto KTP yang gambarnya jelas | Sistem pemindai otomatis (OCR) berhasil membaca dan mengisi Nomor NIK (16 angka), Nama Lengkap, dan Alamat dalam waktu kurang dari 3 detik (ukur dengan pencatat waktu sungguhan, kode FR-RES-03, Arsitektur §3.5). |
| **C5** | Penanda kotak isian yang terisi otomatis dari hasil baca KTP | Di sebelah kotak isian yang terisi otomatis, muncul label kecil bertuliskan *"Diisi otomatis"* dengan warna dasar biru muda (`color/navy/100`, Standar Desain §6.4). Ini penting agar resepsionis tahu data tersebut berasal dari pemindai KTP. |
| **C6** | Memindai foto KTP yang buram, gelap, atau miring | Tingkat keyakinan bacaan komputer rendah (di bawah 70%). Sistem otomatis menyalakan tanda butuh pemeriksaan mata manusia (`perlu_verifikasi_manual: true`, Arsitektur §3.5). Layar wajib menampilkan tanda peringatan kuning/oranye yang jelas meminta resepsionis memeriksa ulang ketepatan ejaan tulisan. |
| **C7** | Pemindaian foto KTP gagal total atau waktu habis lebih dari 3 detik | Sistem otomatis berpindah ke jalan cadangan: resepsionis dipersilakan mengetik langsung seluruh data tamu secara manual (kode FR-RES-04, Arsitektur §3.5). Harus ada tulisan pemberitahuan yang menenangkan dan tidak membiarkan resepsionis bingung menunggu. |
| **C8** | Menyunting data hasil baca KTP secara manual | Semua kotak isian tetap bisa diubah atau diperbaiki dengan bebas menggunakan papan ketik kapan saja, tanpa harus mencari tombol ubah tersembunyi. |
| **C9** | Mengisi nomor WhatsApp dengan susunan yang salah (tanpa awalan 08 atau +62) | Sistem seketika menolak saat itu juga. Garis pinggir kotak isian berubah menjadi merah dan muncul tulisan peringatan di bawahnya yang menjelaskan bahwa nomor harus diawali dengan 08 atau +62 (Standar Desain §6.4). |
| **C10** | Nomor NIK ganda — mencoba memasukkan tamu dengan NIK yang saat itu masih tercatat aktif di kamar lain | Sistem menolak proses pendaftaran tamu dan memunculkan tulisan peringatan yang menyebutkan bahwa tamu tersebut sudah terdaftar di kamar lain (kode FR-RES-07). |
| **C11** | Perhitungan total uang sewa kamar | Total Biaya = Jumlah Malam Menginap × Tarif Kamar per Malam. Jumlah uang wajib langsung bertambah atau berkurang seketika di layar saat tanggal masuk atau tanggal pulang diganti (kode FR-RES-05). |
| **C12** | Pilihan cara pembayaran yang tersedia | Tersedia pilihan Uang Tunai (Cash), Pembayaran Digital QRIS, Transfer Bank, dan Dibayar Lewat Aplikasi RedDoorz. Pilihan "Dibayar Lewat Aplikasi RedDoorz" hanya boleh muncul bila pesanan berasal dari saluran mitra RedDoorz. |
| **C13** | Menyimpan data tamu saat sambungan internet tiba-tiba terputus | Data tamu tidak boleh hilang. Data wajib tersimpan aman di memori lokal perangkat (simpanan kotak Hive pada perangkat, Arsitektur §2.3). Di layar tampak tanda penanda jelas bahwa data *"Menunggu disambungkan"* dan sistem akan mencoba mengirim ulang ke server setiap 30 detik secara otomatis. |
| **C14** | Setelah tombol "Simpan & Proses Masuk" berhasil ditekan | Jendela sembul tertutup otomatis. Kotak kamar di denah seketika berubah warna menjadi Merah (Terisi) tanpa perlu menekan tombol muat ulang layar. Tugas pengiriman otomatis pesan WhatsApp langsung aktif terjadwal (kode FR-RES-06). |
| **C15** | Tampilan tombol "Simpan & Proses Masuk" | Berwarna oranye cerah (`#FF6600`). Tombol ini adalah satu-satunya tombol berwarna oranye di seluruh jendela sembul tersebut agar mata resepsionis langsung tertuju padanya (Standar Desain §6.5). |
| **C16** | Pemeriksaan kelengkapan isian sebelum data dikirim | Tombol simpan tidak bisa ditekan atau muncul tulisan peringatan merah di tiap kotak bila ada data penting yang masih kosong (NIK, Nama Tamu, Nomor WhatsApp, Tanggal Menginap). |
| **C17** | Pengecilan ukuran berkas foto sebelum dikirim ke sistem server | Sistem secara otomatis mengecilkan ukuran berkas foto KTP menjadi di bawah 1,5 MB dan resolusi sisi terpanjang maksimal 1600 piksel sebelum data dikirim melalui internet (Arsitektur §2.4). |

---

## 8. D — Modul Pengiriman Otomatis Pesan WhatsApp (FR-WA-01 s/d FR-WA-05)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **D1** | Waktu menginap tamu mendekati 1 jam (60 menit) sebelum jam kepulangan (check-out) | Sistem secara otomatis mengirim pesan pengingat ke nomor WhatsApp tamu. Pengiriman berjalan lewat tugas terjadwal setiap 10 menit sekali (pesan terkirim antara 60 hingga 50 menit sebelum jam keluar, tergantung putaran jadwal tugas otomatis; kode FR-WA-01/02, Arsitektur §3.4). |
| **D2** | Kalimat pesan pengingat yang diterima di aplikasi WhatsApp tamu sungguhan | Susunan kalimat wajib persis sama dengan contoh kalimat baku pada dokumen PRD §3.4 (mencantumkan nama tamu, nomor kamar, jam batas keluar, dan salam hormat). Periksa huruf demi huruf, termasuk tanda baca dan spasi. |
| **D3** | Keterangan status pengiriman pesan di layar resepsionis | Layar menampilkan status pesan secara tepat berdasarkan kabar otomatis dari penyedia layanan WhatsApp (kode FR-WA-05): Terkirim (`Sent`), Sampai di Ponsel Tamu (`Delivered`), Sudah Dibaca Tamu (`Read`), atau Gagal Terkirim (`Failed`). |
| **D4** | Pengiriman pesan gagal (nomor tidak aktif atau jaringan penyedia layanan sedang bermasalah) | Sistem otomatis mencoba mengirim ulang sebanyak maksimal 3 kali. Dokumen kebutuhan produk menyebut *"dengan jeda yang makin lama tiap kali gagal"* (NFR §4.2), sedangkan dokumen teknis menyebut *"jeda waktu tetap setiap 5 menit"* (Arsitektur §3.6). Ukur jeda waktu aslinya dan laporkan perbedaan antara kedua dokumen ini (lihat Bagian 15). |
| **D5** | Tombol pengiriman ulang pesan secara manual oleh resepsionis | Tombol kirim ulang selalu tersedia dan aktif di layar resepsionis untuk tamu yang sedang menginap, terutama jika status pesan sebelumnya bertuliskan Gagal (`Failed`) (kode FR-WA-04). |
| **D6** | Pengiriman otomatis sudah dicoba 3 kali dan tetap gagal | Layar resepsionis memunculkan tulisan peringatan yang jelas bahwa pesan gagal terkirim dan menyarankan staf resepsionis menghubungi tamu secara langsung atau menelepon kamar. |

---

## 9. E — Modul Kepulangan Tamu (Check-out) & Faktur Tagihan (FR-OUT-01 s/d FR-OUT-05)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **E1** | Membuka formulir kepulangan tamu dari kamar berwarna Merah atau Kuning | Tampil rincian tagihan beserta pilihan untuk memasukkan biaya tambahan jika ada: denda keterlambatan keluar, pemakaian makanan/minuman kecil (minibar), cucian pakaian (laundry), atau penggantian kerusakan barang hotel (kode FR-OUT-02). |
| **E2** | Tamu pulang tepat waktu (sebelum jam batas keluar yang ditentukan) | Biaya denda keterlambatan keluar bernilai nol rupiah (Rp 0). |
| **E3** | Tamu pulang lewat dari jam batas keluar yang ditentukan | Biaya denda keterlambatan keluar langsung dihitung secara otomatis oleh sistem sesuai dengan aturan tarif denda yang sudah diatur oleh manajer (kode FR-OUT-05). |
| **E4** | Susunan nomor surat faktur tagihan (invoice) yang terbit | Susunan nomor faktur wajib mengikuti format resmi: `INV/SH/TAHUNBULANTANGGAL/NOMORURUT` (contoh: `INV/SH/20260925/0001`, kode FR-OUT-03, Arsitektur §4.3). Nomor urut 4 angka di belakang akan kembali ke angka 0001 setiap kali tanggal berganti hari baru. |
| **E5** | Kelengkapan isi lembar pratinjau faktur tagihan di layar | Memuat Logo resmi Hotel Sinar Harapan, Logo Mitra RedDoorz, Nomor Kamar, Nama Lengkap Tamu, Nomor NIK, Asal Pemesanan, Rincian Waktu Inap, Rincian Total Biaya, serta Nama Lengkap Petugas Resepsionis yang melayani (kode FR-OUT-03). Semua bagian wajib terisi lengkap dan tidak boleh ada yang kosong. |
| **E6** | Bentuk tampilan visual lembar faktur tagihan | Ditata rapi menyerupai lembar kuitansi resmi: memiliki garis tepi tegas dan susunan huruf yang rapi serta formal, berbeda dengan gaya formulir isian biasa (Standar Desain §7). |
| **E7** | Mencetak faktur ke mesin pencetak struk kasir (thermal printer) | Berfungsi lancar saat dicetak ke mesin pencetak kertas struk kecil ukuran lebar 58 mm maupun ukuran lebar 80 mm (kode FR-OUT-03, Arsitektur §2.5). |
| **E8** | Mengunduh lembar faktur dalam bentuk berkas PDF | Berkas PDF berhasil terunduh ke komputer, bisa dibuka tanpa ada pesan rusak, dan susunan tulisan di kertas rapi tanpa ada yang terpotong. |
| **E9** | Perubahan status kamar setelah kepulangan tamu dikonfirmasi | Status kamar di denah kotak seketika berubah menjadi **Kuning (Kamar Kotor / `DIRTY`)**, BUKAN langsung berubah menjadi Hijau (kode FR-OUT-04). |
| **E10** | Mengubah status kamar dari Kuning menjadi Hijau setelah kamar dibersihkan | Merupakan tindakan manual yang dilakukan oleh staf resepsionis setelah mendapat laporan dari bagian kebersihan. Tersedia tombol sakelar yang jelas pada kotak kamar berwarna kuning untuk menjadikannya hijau kembali. |

---

## 10. F — Modul Analisis Kinerja Manajer & Unduhan Laporan (FR-REP-01 s/d FR-REP-05)

| # | Kasus Uji | Yang Seharusnya Terjadi (Expected) |
| :---: | :--- | :--- |
| **F1** | Kotak-kotak ringkasan angka kinerja (KPI) pada halaman manajer | Menampilkan Total Tamu Masuk (hari ini, bulan berjalan, atau rentang tanggal pilihan), Total Tamu Pulang, Persentase Kamar Terisi (Okupansi), Diagram Lingkaran Sumber Tamu Datang, dan Total Pendapatan Bersih Hotel (kode FR-REP-01). |
| **F2** | Gaya tampilan kotak ringkasan kinerja (KPI Card) | Tulisan judul kecil di atas, angka capaian berukuran besar dengan warna biru gelap (`navy/900`), tulisan persentase perbandingan berwarna hijau atau oranye, serta bersih tanpa hiasan gambar kartun besar (Standar Desain §6.7). |
| **F3** | Bentuk gambar grafik perbandingan sumber pesanan tamu | Menggunakan paduan warna biru gelap (`navy/700`) dan oranye (`orange/600`). Bentuk diagram datar rapi tanpa efek timbul 3 dimensi dan tanpa gradasi warna-warni yang mencolok (Standar Desain §6.8). |
| **F4** | Tabel daftar rincian transaksi dan tombol penyaring data | Tersedia tombol penyaring berdasarkan rentang tanggal, tipe kamar, dan cara pembayaran. Semua penyaring berfungsi dan bisa digabungkan bersamaan (kode FR-REP-02). |
| **F5** | Mengunduh laporan dalam bentuk berkas lembar sebar Excel (`.xlsx`) | Di dalam berkas Excel terdapat 2 lembar kerja: Lembar pertama berisi *Ringkasan Kinerja (Summary KPI)* dan lembar kedua berisi *Rincian Lengkap Seluruh Transaksi (Raw Data)* dengan kolom: Nomor Faktur, Tanggal, Nomor Kamar, NIK Tamu, Nama Tamu, Nomor WhatsApp, Asal Pemesanan, Jam Masuk, Jam Keluar, Total Biaya, dan Nama Petugas Resepsionis (kode FR-REP-03). |
| **F6** | Mengunduh laporan resmi dalam bentuk berkas cetak PDF | Ukuran kertas standar A4, mencantumkan kop surat resmi Hotel Sinar Harapan bersama RedDoorz, memuat tabel ringkasan kinerja bulanan, gambar grafik keterisian kamar, serta kotak tanda tangan pengesahan oleh Manajer Hotel (kode FR-REP-04). |
| **F7** | Resepsionis mencoba menekan atau mencari tombol unduh laporan | Tombol unduh laporan sama sekali tidak ada di layar akun resepsionis (Matriks Hak Akses Pengguna PRD §2.3: Resepsionis tidak memiliki izin mengunduh laporan). |
| **F8** | Pencatatan riwayat setiap kali ada laporan data pribadi tamu yang diunduh | Setiap kali ada orang yang mengunduh laporan berisi data pribadi (seperti NIK dan nomor WhatsApp tamu), sistem server wajib mencatat kejadian tersebut secara otomatis ke dalam buku catatan riwayat aktivitas (Audit Log: jenis aksi `EXPORT_REPORT`, kode FR-REP-05, Arsitektur §3.7). |
| **F9** | Hak membuka menu Catatan Riwayat Aktivitas (Audit Trail) | Halaman riwayat ini hanya bisa dibuka oleh peran Manajer. Halaman ini mencatat waktu, nama orang, dan rincian aksi saat terjadi penerimaan tamu masuk, kepulangan tamu, penambahan unit kamar, pengubahan harga kamar, pengunduhan laporan, dan kegagalan kirim WhatsApp (Arsitektur §4.2 tabel `activity_logs`). |
| **F10** | Tata letak tombol unduh laporan di layar dasbor manajer | Dua buah tombol unduh (Excel dan PDF) terletak rapi di sudut kanan atas dengan garis bingkai tipis netral, sehingga tidak menutupi atau bersaing perhatian dengan tombol aksi utama oranye di layar (Standar Desain §7). |

---

## 11. G — Matriks Pengujian Silang Hak Akses Pengguna (RBAC — Wajib & Sangat Kritis)

Uji setiap baris tabel hak akses pengguna berikut (PRD §2.3) secara nyata dengan masuk bergantian menggunakan akun Resepsionis dan akun Manajer. Jangan hanya menilai dari ada atau tidaknya tombol di layar:

| Bagian / Fitur Aplikasi | Hak Akses Resepsionis (Yang Seharusnya Terjadi) | Hak Akses Manajer (Yang Seharusnya Terjadi) | Cara Menguji Percobaan Menerobos Aturan (Bypass) |
| :--- | :--- | :--- | :--- |
| **Denah Kotak Kamar** | Bisa Melihat & Bisa Mengklik Transaksi | Hanya Bisa Melihat Denah Saja | Masuk sebagai manajer → coba klik kotak kamar Hijau atau Merah. Periksa juga lewat alat peramban atau aplikasi pengirim data (seperti Postman) apakah alamat pemesanan tamu bisa dipanggil langsung menggunakan tanda bukti masuk milik manajer. |
| **Proses Tamu Masuk (Check-in)** | Akses Penuh Melayani Tamu | Tidak Boleh Memiliki Akses | Masuk sebagai manajer → pastikan tombol atau jendela tamu masuk tidak pernah muncul. Coba kirim data tamu langsung ke alamat server `POST /api/reservations` menggunakan tanda bukti masuk manajer — sistem server wajib menolaknya dengan kode kesalahan 401 atau 403, bukan sekadar tombolnya disembunyikan di layar. |
| **Proses Tamu Pulang & Cetak Faktur** | Akses Penuh Memproses Kepulangan | Hanya Bisa Melihat Riwayat Faktur | Lakukan pengujian yang sama seperti di atas pada alamat server kepulangan tamu (`checkout`). |
| **Kirim Ulang Pesan WhatsApp Manual** | Akses Penuh Mengirim Ulang | Hanya Bisa Melihat Riwayat Pengiriman | Pastikan tombol kirim ulang WhatsApp tidak muncul atau dalam keadaan mati (tidak bisa ditekan) pada akun manajer. |
| **Kelola Data Unit Kamar (Tambah / Ubah / Hapus)** | Sama Sekali Tidak Memiliki Akses | Akses Penuh Mengelola Kamar | Masuk sebagai resepsionis → pastikan tidak ada tombol tambah, ubah, atau hapus kamar. Coba kirim perintah ubah data langsung ke alamat server `POST/PATCH/DELETE /api/rooms` dengan tanda bukti resepsionis — sistem server wajib menolak keras perintah ini. |
| **Dasbor Angka Rekapitulasi Kinerja** | Terbatas Hanya Rekap Hari Ini | Penuh untuk Semua Bulan dan Tahun | Masuk sebagai resepsionis → pastikan pilihan tanggal terkunci hanya untuk hari ini saja. Ini detail yang sering terlewat karena resepsionis terkadang tetap diberi ringkasan kerja harian biasa. |
| **Unduh Laporan Excel dan PDF** | Sama Sekali Tidak Ada Tombol Unduh | Akses Penuh Mengunduh Laporan | Periksa kembali rincian kasus F7. Resepsionis dilarang keras mengunduh data rekap bulanan ke luar sistem. |
| **Menu Catatan Riwayat Aktivitas (Audit Trail)** | Sama Sekali Tidak Ada Akses | Akses Penuh Memeriksa Catatan | Masuk sebagai resepsionis → coba ketik alamat halaman riwayat langsung pada bilah alamat peramban (misalnya membuka `/audit-trail`). Pastikan sistem menolak dan mengalihkan halaman (menguji agar celah keamanan jalur pintas tidak bisa ditembus). |

> **Catatan Sangat Penting bagi Penguji Mutu:**  
> Bagian *"Cara Menguji Percobaan Menerobos Aturan"* di atas adalah hal yang paling sering dilewatkan oleh penguji pemula. Penguji pemula biasanya hanya melihat apakah tombolnya hilang di layar. Padahal orang jahat bisa mencoba mengirim perintah langsung ke sistem server di balik layar. Sesuai aturan teknis (Arsitektur §3.3 — penjaga hak akses di setiap pintu server), setiap baris hak akses wajib dibuktikan penolakannya langsung dari sistem server, bukan cuma tampilannya yang disembunyikan.

---

## 12. H — Daftar Periksa Kepatuhan Standar Desain (Detail Token Desain)

Gunakan alat pemeriksa peramban (DevTools) untuk melihat langsung kode warna heksadesimal (`#XXXXXX`) dan ukuran piksel aslinya di layar. Bandingkan secara teliti dengan tabel berikut. Laporkan selisih apa pun meski sangat kecil (misalnya warna `#FF6601` padahal standarnya `#FF6600`, atau jarak pinggir 18 piksel padahal standarnya 20 piksel).

### 12.1 Warna Resmi Aplikasi

| Nama Kode Desain | Nilai Warna Resmi | Tempat Pemeriksaan |
| :--- | :---: | :--- |
| `color/navy/900` | `#001B4E` | Warna bingkai kepala atas (top bar) dan bilah navigasi samping (sidebar). |
| `color/navy/700` | `#0A2A6E` | Warna tombol pendukung (tombol sekunder) dan tanda menu yang sedang aktif. |
| `color/orange/600` | `#FF6600` | Satu-satunya warna untuk tombol aksi paling utama di setiap layar. Periksa setiap halaman agar tidak ada lebih dari satu unsur oranye yang menyala dominan. |
| `color/neutral/bg` | `#F7F8FA` | Warna dasar latar belakang seluruh halaman aplikasi. |
| `color/neutral/border` | `#E2E5EB` | Warna garis tepi tipis (1 piksel) yang membatasi antar-kotak atau kartu. |

### 12.2 ⚠️ Potensi Perbedaan Warna Status yang Wajib Diperiksa Silang

Dokumen standar desain memiliki dua rujukan kode warna yang sedikit berbeda untuk status yang sama. Ini bukan kesalahan pembuat program, melainkan perbedaan isi tulisan pada buku panduan desain itu sendiri. Aplikasi nyata bisa jadi mengikuti salah satu secara rapi, atau malah mencampur keduanya:

| Status Kamar | Warna di Pasal 2.3 ("Warna Status") | Warna di Pasal 6.3 ("Lencana Status" teks/titik) | Tindakan Penguji Mutu (QA) |
| :--- | :---: | :---: | :--- |
| **Kamar Tersedia** (`AVAILABLE`) | `#22C55E` | `#16A34A` | Ambil contoh warna asli dari kotak kamar dan dari titik lencana kecil. Bandingkan kedua warna tersebut. Catat kode warna mana yang sesungguhnya dipakai oleh pembuat program, dan apakah warna kotak dan titiknya serasi sama persis. |
| **Kamar Terisi** (`OCCUPIED`) | `#EF4444` | `#DC2626` | Lakukan pemeriksaan perbandingan yang sama seperti di atas. |
| **Kamar Kotor** (`DIRTY`) | `#F59E0B` | `#D97706` | Lakukan pemeriksaan perbandingan yang sama seperti di atas. |
| **Kamar Rusak / Perbaikan** (`MAINTENANCE`) | `#9CA3AF` | `#6B7280` | Lakukan pemeriksaan perbandingan yang sama seperti di atas. |

> **Catatan Penguji:** Laporkan temuan ini ke perancang antarmuka dan manajer produk agar disepakati satu warna resmi sebagai acuan tunggal. Periksa juga apakah pembuat program sudah memakai satu nilai warna secara teratur atau tidak sengaja mencampur dua warna hijau yang berbeda saat dilihat berdampingan.

### 12.3 Bentuk & Ukuran Tulisan (Tipografi)

| Nama Kode Tulisan | Ukuran / Ketebalan Huruf | Hal yang Wajib Diperiksa |
| :--- | :---: | :--- |
| **Keluarga Huruf Utama** | Plus Jakarta Sans (pilihan cadangan: Inter) | Periksa jenis huruf yang sebenarnya terpasang di layar. Pastikan tulisan tidak turun ke huruf bawaan sistem komputer akibat berkas huruf gagal dimuat dari internet. |
| `type/display` | 32 piksel / Ketebalan 700 (Tebal) | Dipakai khusus untuk angka capaian besar pada dasbor manajer (misalnya total uang pendapatan hotel). |
| `type/h1` | 24 piksel / Ketebalan 700 (Tebal) | Dipakai untuk judul utama halaman kerja. |
| **Aturan Batas Tingkat Huruf** | Maksimal 3 tingkat ukuran huruf dalam satu layar | Hitung berapa macam kombinasi ukuran dan ketebalan huruf yang tampil bersamaan di satu layar. Laporkan jika lebih dari 3 tingkat, karena itu melanggar aturan susunan hierarki tulisan (§3). |

### 12.4 Bentuk Tombol & Tata Letak Komponen
- **Bentuk Tombol:** Tinggi tombol minimal 48 piksel (48px), lengkungan sudut 8 piksel (8px / `radius/md`). Ukur semua jenis tombol (Tombol Utama, Tombol Sekunder, Tombol Berbingkai Tipis, dan Tombol Hapus Berbahaya), jangan hanya mengukur satu tombol saja.
- **Ukuran Kotak Kamar:** Ukuran kotak minimal 140 × 100 piksel, lengkungan sudut 12 piksel (12px / `radius/lg`), dibatasi garis tepi abu-abu 1 piksel (`#E2E5EB`).
- **Bayangan Timbul (Elevation):** Dilarang memakai bayangan gelap tebal atau bayangan yang menyebar luas (seperti `0 20px 60px`). Hanya diizinkan bayangan sangat tipis dan halus (`elevation/1` atau `elevation/2`).
- **Tanpa Efek Kaca Buram:** Tidak boleh ada efek kaca buram tembus pandang (*glassmorphism* atau *blur*) di bagian mana pun.
- **Tanpa Gradasi Warna:** Tidak boleh ada latar belakang bermotif gradasi warna-warni pada kotak kamar.
- **Bentuk Gambar Ikon:** Menggunakan gambar ikon garis sederhana (*outline*) dengan ketebalan garis 1,5 hingga 2 piksel. Bukan ikon bergaya 3D mengilap dan bukan ikon emoji warna-warni (tanda emoji di dokumen panduan hanya sebagai simbol bacaan teks, bukan untuk ditempel di layar aplikasi).
- **Bilah Menu Samping Manajer:** Menu yang sedang aktif ditandai garis tegak oranye 3 piksel di sisi kiri dan latar belakang biru gelap transparan tipis 10%.
- **Bilah Menu Atas Resepsionis:** Berwarna biru gelap pekat (`#001B4E`), tinggi 64 piksel, memuat logo hotel, nama petugas, penunjuk jam giliran kerja (shift), dan tombol keluar. Pastikan tulisan jam giliran kerja benar-benar tampil dan cocok dengan waktu saat itu.

### 12.5 Daftar Periksa "Bebas Desain Buatan AI Murahan" (Standar Desain §9 — Wajib Diperiksa Nyata Satu per Satu)
- ❌ **TIDAK ADA** gradasi warna ungu-ke-biru atau ungu-ke-merah muda yang pasaran di seluruh bagian aplikasi.
- ❌ **TIDAK ADA** efek kaca buram transparan (*glassmorphism*) yang berlebihan dan menyilaukan mata.
- ❌ **TIDAK ADA** ikon bergaya 3D mengilap atau gambar emoji warna-warni di antarmuka aplikasi.
- ❌ **TIDAK ADA** bayangan hitam pekat dan menyebar lebar di bawah kotak kartu mana pun.
- ❌ **TIDAK ADA** gambar ilustrasi orang kantor bersalaman atau gambar kartun umum yang tidak ada hubungannya dengan operasional hotel nyata.
- ❌ **TIDAK LEBIH** dari satu tombol berwarna oranye terang yang mencolok dalam satu pandangan layar — periksa setiap layar satu per satu.
- ❌ **TIDAK ADA** kotak kamar yang seluruh badannya dicat warna pekat penuh.
- ❌ **TIDAK ADA** layar yang semua tulisannya memiliki ukuran dan ketebalan yang sama tanpa urutan judul dan isi yang jelas.

---

## 13. I, J, K, L — Daftar Periksa Tambahan

### 13.1 I — Penyesuaian Ukuran Layar (Responsivitas)
- **Uji pada layar Tablet Mendatar (Landscape 10"+):** Resolusi umum 1280×800 dan 1920×1200 sebagai perangkat kerja utama resepsionis. Tampilan harus nyaman disentuh dengan jari, bukan sekadar muat di layar.
- **Uji pada layar Komputer Desktop (1920×1080):** Sebagai perangkat pendukung manajer dan meja utama.
- **Penyesuaian Kotak Denah Kamar:** Jumlah kolom kotak kamar menyesuaikan lebar layar secara otomatis (4 sampai 6 kolom kotak ke samping) dengan jarak antar-kotak 16 piksel (Standar Desain §4.2). Hitung jumlah kotak ke samping pada berbagai ukuran jendela layar.
- **Bilah Menu Samping Manajer:** Lebar tetap 240 piksel saat terbuka penuh, dan bisa diciutkan menjadi 72 piksel (hanya menampilkan gambar ikon saja). Coba tekan sakelar buka-tutup menu dan pastikan peralihannya berjalan mulus tanpa merusak tata letak lainnya.
- **Bebas Geser Kanan-Kiri:** Tidak boleh ada tulisan yang terpotong atau halaman yang bocor ke samping sehingga memaksa pengguna menggeser layar ke kanan-kiri (tidak ada *horizontal scroll* yang tidak diinginkan).

### 13.2 J — Kemudahan Penggunaan untuk Semua Orang (Aksesibilitas)
- **Keterbacaan Kontras Warna Teks:** Tingkat keterbacaan tulisan wajib memenuhi standar kenyamanan mata minimum WCAG AA (nilai perbandingan kontras minimal 4,5 banding 1). Gunakan alat pengukur kontras pada teks abu-abu di atas latar putih atau teks di atas lencana status kamar.
- **Simulasi Penglihatan Buta Warna:** Nyalakan mode simulasi tanpa warna (grayscale) pada alat peramban. Pastikan status kamar tetap bisa dibedakan dengan sangat jelas lewat tulisan keterangannya, bukan cuma mengandalkan warnanya saja.
- **Ukuran Area Sentuhan Tombol:** Di layar tablet, semua tombol atau gambar yang bisa disentuh memiliki luas sentuhan minimal 44 × 44 piksel. Ukur tombol-tombol kecil seperti ikon silang (X) penutup jendela dan ikon penyaring agar mudah disentuh jari orang dewasa.
- **Kemudahan Pindah Kotak Lewat Papan Ketik:** Tombol Tab pada papan ketik harus berpindah secara urut dan masuk akal dari kotak isian pertama ke kotak berikutnya pada formulir tamu yang panjang.

### 13.3 K — Kelancaran Data Langsung & Saat Tanpa Internet (Offline)
- **Pemeriksaan Isi Data Asli:** Bandingkan data yang tampak di layar dengan data yang diterima lewat bagian lalu lintas data peramban. Pastikan tidak ada susunan tanggal yang terbalik (misalnya tanggal dan bulan tertukar) atau salah dalam membulatkan angka rupiah.
- **Uji Tabrakan Pemesanan Bersamaan (Race Condition):** Coba gunakan dua komputer resepsionis yang berbeda untuk memesan kamar yang sama persis di detik yang nyaris bersamaan. Pastikan hanya ada satu resepsionis yang berhasil memesan, sedangkan resepsionis kedua mendapat pemberitahuan bahwa kamar tersebut baru saja diambil oleh rekan kerja lain. Sistem tidak boleh meloloskan keduanya (mencegah kelebihan pesanan / *overbooking*).
- **Uji Internet Terputus Saat Mengisi Data:** Sengaja matikan internet saat mengisi formulir tamu yang panjang, tunggu beberapa menit, lalu nyalakan kembali internet. Pastikan data yang sudah diketik dan foto KTP yang sudah dipindai tidak hilang dan sistem otomatis mengirimkan data saat internet menyala lagi (Arsitektur §2.3).
- **Tanda Menunggu Sambungan Internet:** Pastikan ada tulisan atau tanda yang jelas terlihat di layar saat komputer sedang tanpa internet, sehingga resepsionis tahu datanya masih tersimpan sementara di memori komputer dan belum terkirim ke server pusat.

### 13.4 L — Penanganan Kesalahan & Kondisi Khusus Lainnya
- **Seluruh Kalimat dalam Bahasa Indonesia:** Semua tulisan peringatan kesalahan wajib memakai Bahasa Indonesia yang sopan dan mudah dipahami. Jangan mencampur dengan istilah program bawaan bahasa Inggris yang membingungkan orang awam (seperti tulisan mentah *"Failed to fetch"* atau *"Null pointer exception"*).
- **Pesan Kesalahan Server Diolah Ramah:** Kode kesalahan teknis dari komputer server (seperti kode `400` atau `500`) wajib diubah menjadi kalimat penjelasan yang menenangkan bagi pengguna di layar.
- **Tanda Sedang Bekerja (Loading):** Semua tombol yang sedang memproses data wajib menampilkan tanda sedang bekerja (seperti roda berputar kecil) dan tombol tersebut langsung terkunci (tidak bisa ditekan berulang-ulang) agar staf tidak sengaja menekan tombol dua kali (*double-submit*).
- **Uji Tarik Laporan Waktu Panjang (>3 Bulan):** Coba unduh laporan dengan rentang tanggal yang sangat panjang (lebih dari 3 bulan). Sistem teknis hanya menjamin tarikan cepat untuk rentang hingga 3 bulan (Arsitektur §3.7). Uji apa yang terjadi jika ditarik lebih panjang: apakah muncul pesan batas waktu habis, tulisan peringatan batas unduh, atau tetap berhasil meski membutuhkan waktu sedikit lebih lama.

---

## 14. Format Pelaporan Kesalahan Sistem (Bug)

Gunakan susunan formulir laporan berikut untuk mencatat setiap kesalahan yang ditemukan, baik kesalahan besar maupun kesalahan kecil:

```text
ID Laporan      : QA-XXX (contoh: QA-RES-01)
Modul Terkait   : (contoh: Pemesanan & Tamu Masuk / Check-in)
Peran Diuji     : Resepsionis / Manajer / Kedua Peran
Kode Acuan      : (Kode Kebutuhan Fitur, misal: FR-RES-04) atau (Kode Desain, misal: color/orange/600)
Judul Masalah   : (Singkat, padat, dan langsung menerangkan masalah)
Tingkat Bahaya  : Penghenti Total / Sangat Berbahaya / Salah Hasil / Mengganggu / Beda Tampilan Saja
Cara Mengulang Kejadian (Langkah Persis):
  1. Masuk sebagai akun resepsionis.
  2. Buka menu denah kamar...
  3. Klik tombol...
Yang Seharusnya Terjadi : (Kutip langsung dari aturan pada dokumen panduan resmi)
Yang Sebenarnya Terjadi : (Ceritakan apa yang sebenarnya terjadi di layar)
Tangkapan Layar/Video   : (Lampirkan berkas gambar atau rekaman video layar)
Kondisi Saat Diuji      : (Perangkat tablet atau komputer, ukuran layar, peramban yang dipakai)
Catatan Tambahan        : (Keterangan lain, misalnya bila ada ketidakcocokan antar-dokumen)
```

### 14.1 Tingkat Keparahan Masalah (Severity)

| Tingkat Bahaya | Kriteria & Arti Dampaknya bagi Hotel |
| :--- | :--- |
| **Penghenti Total** (`Blocker`) | Fitur utama sama sekali macet dan tidak bisa dipakai sama sekali (misalnya tidak bisa masuk ke akun sama sekali, atau tombol simpan tamu masuk mati total). Pengujian pada bagian tersebut terpaksa dihentikan sementara sampai diperbaiki. |
| **Sangat Berbahaya** (`Critical`) | Kesalahan yang menimbulkan kerugian uang bagi hotel atau kebocoran data rahasia (misalnya kamar terisi ganda karena nomor NIK kembar lolos, hak akses manajer bisa ditembus oleh resepsionis, atau foto KTP tamu bisa dibuka sembarang orang tanpa izin). |
| **Salah Hasil** (`Major`) | Fitur bisa berjalan lancar dari awal sampai akhir, tetapi angka hasil hitungannya salah (misalnya denda keterlambatan keluar salah hitung nominalnya, atau angka uang di lembar Excel berbeda dengan angka di layar komputer). |
| **Mengganggu** (`Minor`) | Fungsi hitungan dan sistem bekerja dengan benar, tetapi kenyamanan penggunaan terganggu (misalnya tidak muncul tanda roda berputar saat menunggu unduhan, atau tulisan peringatan kurang jelas maksudnya). |
| **Beda Tampilan Saja** (`Cosmetic`) | Hanya selisih pada kerapian visual tampilan luar tanpa mengganggu cara kerja sistem (misalnya warna meleset sedikit dari kode warna standar, jarak tepi tombol kurang beberapa piksel, atau jenis huruf cadangan yang muncul). Selisih ini tetap wajib dicatat rapi. |

---

## 15. Temuan Awal pada Dokumen Aturan (Sudah Teridentifikasi Sebelum Pengujian — Wajib Diperiksa pada Aplikasi Nyata)

Sebagai bentuk ketelitian awal sebelum pengujian dimulai, penguji menemukan dua ketidakcocokan tulisan di dalam dokumen aturan itu sendiri (bukan kesalahan kode program). Penguji mutu wajib memeriksa pembuat aplikasi sebenarnya mengikuti aturan yang mana:

1. **Dua Kode Warna yang Berbeda untuk Status yang Sama:**  
   Buku standar desain pasal 2.3 (*Warna Status*) dan pasal 6.3 (*Lencana Status*) mencantumkan kode warna yang berbeda untuk status Kamar Tersedia, Kamar Terisi, dan Kamar Kotor (lihat perbandingannya di tabel Bagian 12.2). Contoh kode program pada dokumen desain mengikuti pasal 2.3 (misalnya `0xFF22C55E` untuk kamar tersedia). Penguji wajib memeriksa kode warna mana yang sungguh-sungguh terpasang pada aplikasi yang sedang berjalan.
2. **Jeda Waktu Coba Ulang Kirim WhatsApp: Berjenjang vs Jeda Tetap:**  
   Dokumen kebutuhan produk (PRD NFR §4.2) menyebutkan bahwa pengiriman ulang dilakukan maksimal 3 kali dengan *jeda waktu yang semakin bertambah lama* di setiap kegagalan (misalnya tunggu 1 menit, lalu 3 menit, lalu 5 menit). Di sisi lain, dokumen teknis (Arsitektur §3.6) secara tegas menyebutkan *jeda waktu tetap 5 menit sekali*. Penguji mutu wajib menghitung jeda waktu nyata saat pengujian kasus D4 di Bagian 8 dan melaporkan pola mana yang sebenarnya berjalan di sistem.

---

## 16. Syarat Selesai Pengujian (Exit Criteria)

Mengacu pada standar penyelesaian resmi pada dokumen kebutuhan produk (PRD §8 mengenai *Definition of Done & UAT*), pengujian dinyatakan selesai dan aplikasi boleh diterbitkan jika seluruh syarat berikut terpenuhi:

1. [x] Seluruh butir pengujian dari Bagian 5 sampai Bagian 13 berstatus **Lulus**, atau jika ada yang belum lulus sudah dicatat resmi dan disetujui oleh pemilik hotel atau manajer produk bahwa masalah tersebut tidak menghentikan operasional.
2. [x] **Tidak ada satu pun** masalah berstatus **Penghenti Total** (`Blocker`) atau **Sangat Berbahaya** (`Critical`) yang belum diselesaikan.
3. [x] Alur pendaftaran tamu masuk dari awal sampai selesai (pindai KTP → kotak isian terisi rapi → simpan data) berhasil diselesaikan oleh petugas resepsionis dalam waktu nyata **di bawah 2 menit** tanpa bantuan ahli komputer.
4. [x] Pesan pengingat otomatis WhatsApp 1 jam sebelum tamu pulang terbukti sungguh-sungguh sampai dan masuk ke nomor ponsel pengujian, serta tercatat statusnya dengan tepat di layar komputer.
5. [x] Lembar berkas Excel dan PDF hasil unduhan bisa dibuka dengan lancar tanpa ada tulisan rusak, dan jumlah total angka rupiahnya cocok seratus persen saat dihitung ulang secara manual.
6. [x] Pemeriksaan keamanan dasar (uji pembatasan hak akses di Bagian 11) membuktikan tidak ada celah bagi pengguna untuk mengambil alih tugas peran lain di luar wewenangnya.
7. [x] Tidak ditemukan kebocoran data rahasia tamu hotel (tautan aman foto KTP memiliki batas waktu kedaluwarsa 15 menit — jika tautan foto KTP dibuka kembali setelah lewat dari 15 menit, sistem wajib menolak membukanya).
8. [x] Seluruh catatan ketidakcocokan desain (Bagian 12) dan catatan ketidaksinkronan dokumen (Bagian 15) telah diserahkan secara tertulis kepada tim pengembang aplikasi dan manajemen hotel.

---

## Kamus Istilah

Tabel ini memuat seluruh daftar istilah asli bahasa Inggris atau istilah teknis yang digunakan di dokumen rancangan beserta padanan resmi Bahasa Indonesia yang mudah dipahami orang awam di seluruh dokumen ini:

| Istilah Asli / Istilah Komputer | Istilah Pengganti yang Digunakan | Penjelasan Mudah Sehari-hari |
| :--- | :--- | :--- |
| **Login** | Masuk / Buka akun | Membuka akun kerja dengan mengisi nama dan sandi. |
| **Logout** | Keluar | Menutup sesi kerja agar akun tidak disalahgunakan orang lain. |
| **Username** | Nama akun | Nama pengenal resmi pengguna untuk masuk ke sistem. |
| **Password** | Kata sandi | Rangkaian karakter rahasia untuk membuka akun. |
| **Bug** | Kesalahan sistem | Kondisi di mana aplikasi bekerja keliru atau tidak sesuai aturan. |
| **Severity** | Tingkat keparahan | Ukuran seberapa besar akibat atau bahaya dari suatu masalah. |
| **Blocker** | Penghenti total | Masalah paling berat yang membuat fitur tidak bisa dipakai sama sekali. |
| **Critical** | Sangat berbahaya | Masalah berat yang berisiko membuat hotel rugi uang atau bocor data rahasia tamu. |
| **Major** | Salah hasil | Fitur jalan sampai akhir, tetapi hasil perhitungan atau angkanya keliru. |
| **Minor** | Mengganggu | Sistem dan hitungan benar, tetapi kurang nyaman dilihat atau dipakai. |
| **Cosmetic** | Beda tampilan saja | Hanya selisih kerapian bentuk luar tanpa mengganggu cara kerja aplikasi. |
| **Steps to Reproduce** | Cara mengulang kejadian | Runtutan langkah persis agar kesalahan yang sama bisa diperlihatkan lagi. |
| **Expected Result** | Yang seharusnya terjadi | Perilaku aplikasi yang benar sesuai dengan buku panduan aturan. |
| **Actual Result** | Yang sebenarnya terjadi | Apa yang sungguh-sungguh terjadi di layar saat diuji coba. |
| **Screenshot** | Tangkapan layar | Berkas gambar foto dari apa yang tampil di layar komputer atau ponsel. |
| **Environment** | Kondisi saat diuji | Catatan perangkat, jenis peramban, ukuran resolusi layar, dan akun yang dipakai saat pengujian. |
| **Real-time** | Langsung / seketika | Informasi yang langsung berubah di detik itu juga tanpa perlu menunggu atau muat ulang. |
| **Offline** | Tanpa internet | Keadaan perangkat saat sambungan internet hotel sedang terputus. |
| **Online** | Tersambung internet | Keadaan perangkat saat tersambung lancar ke jaringan internet. |
| **Sync / Synchronize** | Menyamakan data | Proses mencocokkan data antar-perangkat agar isinya selalu sama. |
| **Cache / Caching** | Simpanan sementara | Tempat menyimpan data sementara di memori komputer agar halaman terbuka lebih cepat. |
| **Backend** | Sistem di balik layar (server) | Komputer pusat penyimpanan data dan pemrosesan aturan di balik layar. |
| **Frontend** | Tampilan yang dilihat pengguna | Seluruh tombol, kotak, dan warna yang dilihat serta disentuh oleh staf hotel di layar. |
| **Endpoint (API)** | Alamat layanan data | Pintu alamat digital tempat aplikasi mengirim dan meminta data ke komputer pusat. |
| **Token (sesi masuk)** | Tanda bukti sudah masuk | Kunci digital sementara yang membuktikan seseorang sudah masuk secara sah. |
| **Timeout** | Waktu habis | Batas waktu tunggu komputer habis karena jaringan tidak kunjung memberi tanggapan. |
| **Race condition** | Dua aksi bertabrakan bersamaan | Dua orang menekan tombol untuk kamar yang sama di waktu yang nyaris bersamaan. |
| **Fallback** | Jalan cadangan | Pilihan pengganti yang otomatis dipakai jika cara utama sedang rusak atau gagal. |
| **Bypass** | Menerobos / melewati aturan | Tindakan curang melompati aturan pembatasan hak akses yang sudah ditentukan. |
| **Overbooking** | Kelebihan pesanan kamar | Kondisi fatal di mana jumlah kamar yang dipesan lebih banyak daripada unit yang ada. |
| **Toggle** | Sakelar hidup/mati | Tombol geser untuk menyalakan atau mematikan status (seperti sakelar lampu). |
| **Widget** | Elemen tampilan | Komponen visual di layar (seperti kartu kotak, tombol, atau bagan diagram). |
| **Filter (kata kerja)** | Menyaring | Memilah data agar hanya menampilkan kamar atau transaksi yang diinginkan saja. |
| **Grid** | Denah kamar kotak-kotak | Susunan kartu-kartu kamar yang berjajar rapi ke samping dan ke bawah. |
| **Loading state** | Sedang memuat | Kondisi saat sistem sedang bekerja memproses data (biasanya memunculkan tanda roda berputar). |
| **Disabled** | Tidak bisa ditekan | Tombol yang dibuat mati atau berwarna redup agar tidak bisa disentuh pengguna. |
| **Empty state** | Tampilan saat data kosong | Gambar atau tulisan ramah yang muncul saat belum ada data yang masuk di daftar. |
| **Constraint (basis data)** | Aturan pembatas data | Aturan ketat di tempat simpan data (misalnya melarang nomor kamar kembar). |
| **DevTools** | Alat pemeriksa milik peramban | Alat bawaan peramban web untuk membongkar dan memeriksa jeroan program. |
| **Network tab** | Bagian lalu lintas data | Ruang di alat peramban untuk melihat apa saja data yang keluar-masuk lewat internet. |
| **Console (browser)** | Layar catatan teknis peramban | Layar catatan tempat sistem menuliskan pesan peringatan atau kode yang sedang macet. |
| **Payload** | Isi data yang dikirim | Bungkusan informasi murni yang dikirimkan melalui internet ke server pusat. |
| **Webhook** | Kabar otomatis dari sistem lain | Laporan seketika yang dikirimkan aplikasi luar (misal WhatsApp) saat pesan sampai di ponsel tamu. |
| **Cron job** | Tugas otomatis berjadwal | Jadwal kerja otomatis komputer yang berputar rutin (misalnya mengecek batas keluar setiap 10 menit). |
| **Retry** | Coba lagi | Tindakan komputer mencoba mengirim ulang data secara otomatis setelah sempat gagal. |
| **Backoff** | Jeda makin lama tiap gagal | Jeda tunggu coba kirim ulang yang sengaja diperpanjang (misal 1 menit, 3 menit, lalu 5 menit). |
| **Interval** | Jeda waktu | Selang waktu tetap antar-kejadian pengiriman data. |
| **Signed URL** | Tautan sementara yang aman | Tautan berkas (seperti foto KTP) yang otomatis mati dan tidak bisa dibuka lagi setelah 15 menit. |
| **Confidence score** | Tingkat keyakinan sistem | Nilai kepastian komputer (0-100%) dalam membaca kejelasan huruf pada foto KTP. |
| **Traceability** | Keterlacakan | Kemampuan menelusuri asal muasal aturan ke nomor pasal pada buku panduan resmi. |
| **Pass / Fail / Partial / Blocked** | Lulus / Gagal / Sebagian / Terhambat | Status penilaian hasil akhir dari suatu butir pengujian. |
| **Cross-check** | Periksa silang | Tindakan mencocokkan isi antar-beberapa dokumen untuk memastikan keselarasan. |
| **QA / QA Engineer** | Penguji mutu aplikasi | Ahli penguji yang bertugas mencari kekurangan aplikasi sebelum dipakai oleh pengguna nyata. |
| **Deploy / Deployment** | Memasang ke sistem nyata | Menerbitkan dan menyetel program agar bisa mulai dipakai oleh staf hotel di komputer kerja. |
| **Rate limiter** | Pembatas jumlah percobaan | Pengaman sistem yang membatasi agar orang tidak bisa mencoba kata sandi puluhan kali dalam semenit. |
| **Enumerasi akun** | Menebak akun terdaftar | Upaya jahat orang luar menebak-nebak nama akun staf yang aktif di hotel. |
| **RBAC** | Pembagian hak akses pengguna | Aturan yang membedakan apa saja yang boleh dibuka oleh resepsionis dan apa yang khusus untuk manajer. |
| **MVP** | Versi awal siap pakai | Bentuk pertama aplikasi yang fiturnya sudah lengkap dan aman untuk melayani tamu hotel. |
| **Soft-delete** | Hapus semu | Data kamar disembunyikan dari layar tetapi arsip historisnya masih aman tersimpan di bank data. |
| **Audit Trail** | Catatan riwayat aktivitas | Buku harian digital yang mencatat siapa melakukan apa, di kamar mana, dan pada jam berapa. |
| **Double-submit** | Ketuk tombol ganda | Kejadian staf tanpa sengaja mengetuk tombol simpan dua kali saat sistem sedang loading. |
| **Responsive** | Menyesuaikan ukuran layar | Kemampuan tampilan aplikasi untuk otomatis menyesuaikan diri saat dibuka di layar tablet maupun monitor besar. |
