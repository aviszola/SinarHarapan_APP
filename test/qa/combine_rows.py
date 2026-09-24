import json
import re

# Load existing 79 rows
with open("test/qa/sec4_rows.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

# Apply updates to existing 79 rows
for r in rows:
    rid = r["id"]
    if rid == "D1":
        r["status"] = "PARTIAL"
        r["actual"] += " (Catatan Integritas: Pass semu berbasis data mock; integrasi gateway WA riil belum diuji)"
    elif rid == "F8":
        r["status"] = "PARTIAL"
        r["actual"] += " (Catatan Integritas: Angka KPI berbasis array statis mock di memori, bukan agregasi database riil)"
    elif rid == "A11":
        r["status"] = "PASS"
        r["method"] = "EXECUTED"
        r["bug_id"] = "-"
        r["evidence"] = "[qa_verification_test.dart:32](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L32)"
        r["actual"] = "Tinggi tombol terukur 50.0px via tester.getSize (memenuhi syarat min 48px; QA-DS-03 dihapus)"
    elif rid == "A3":
        r["status"] = "PARTIAL"
        r["actual"] += " (Banner error tampil & username tersimpan, namun visual highlight border merah tidak terbukti)"
    elif rid == "A5":
        r["status"] = "PARTIAL"
        r["actual"] += " (Toggle mata berfungsi, namun enkripsi transit TLS tidak dapat dibuktikan pada client lokal)"
    elif rid == "A6":
        r["actual"] = "UI umpan balik belum ada (FAIL frontend). Logika server rate limiting terpisah statusnya sebagai BLOCKED."
    elif rid == "B17":
        r["status"] = "PARTIAL"
        r["actual"] += " (Scroll grid berjalan, batas responsivitas scrollbar desktop belum dibuktikan)"
    elif rid == "B3":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:73](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L73)"
    elif rid == "B11":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L214)"
    elif rid == "C5":
        r["status"] = "FAIL"
        r["bug_id"] = "QA-RES-03"
        r["expected"] = "Otomatis dihitung: tarif dasar x durasi malam ([PRD.MD:132](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L132))"
        r["actual"] = "Field total tarif dapat disunting manual bebas tanpa otorisasi manajer. [Perlu konfirmasi Product Owner: kode memuat catatan 'diskon khusus/negosiasi']"
    elif rid == "D4":
        r["actual"] = "UI frontend tombol/indikator retry belum ada (FAIL frontend). Daemon retry server terpisah sebagai BLOCKED."
    elif rid == "D6":
        r["actual"] = "UI peringatan gagal kirim belum ada (FAIL frontend). Notifikasi cron server terpisah sebagai BLOCKED."
    elif rid == "E5":
        r["bug_id"] = "QA-OUT-02"
        r["status"] = "FAIL"
        r["actual"] = "Tarif denda keterlambatan di-hardcode Rp 50.000/jam tanpa panel konfigurasi manajer"
    elif rid == "E7":
        r["status"] = "PARTIAL"
    elif rid == "E8":
        r["status"] = "PARTIAL"
    elif rid == "F5":
        r["status"] = "PARTIAL"
    elif rid == "F6":
        r["status"] = "PARTIAL"
    elif rid == "G4":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:163](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L163)"
    elif rid == "G5":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L214)"

# New rows
new_rows = [
    {
        "id": "H1", "title": "Verifikasi BackdropFilter", "req": "Anti AI-Slop ([design.md:268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268))",
        "expected": "Tidak menggunakan backdrop-filter blur atau glassmorphism ([design.md:268](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L268))",
        "actual": "Grep BackdropFilter pada lib/ menghasilkan 0 hit (bersih)",
        "method": "STATIC", "evidence": "grep BackdropFilter lib/ (0 hit)", "status": "PASS", "bug_id": "-"
    },
    {
        "id": "H2", "title": "Verifikasi Gradient", "req": "Anti AI-Slop ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215))",
        "expected": "Palet grafik: navy/700 dan orange/600 flat solid, dilarang gradient ([design.md:215](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L215))",
        "actual": "Ditemukan LinearGradient di area bawah kurva grafik tren",
        "method": "STATIC", "evidence": "[executive_trend_chart.dart:607](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/widgets/executive_trend_chart.dart#L607)", "status": "FAIL", "bug_id": "QA-DS-04"
    },
    {
        "id": "H3", "title": "Verifikasi BoxShadow", "req": "Elevasi Token ([design.md:135](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L135))",
        "expected": "Hanya menggunakan token AppElevation (parafrase dari prompt QA)",
        "actual": "Ditemukan inline BoxShadow hardcoded di dialog resi WA",
        "method": "STATIC", "evidence": "[whatsapp_receipt_dialog.dart:637](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/whatsapp_receipt_dialog.dart#L637)", "status": "FAIL", "bug_id": "QA-DS-05"
    },
    {
        "id": "H4", "title": "Verifikasi Non-Token Colors", "req": "Palet Warna ([design.md:28](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L28))",
        "expected": "Semua warna merujuk pada kelas token AppColors (parafrase dari prompt QA)",
        "actual": "Ditemukan Colors.red.shade700, Color(0xFF25D366) non-token",
        "method": "STATIC", "evidence": "[whatsapp_receipt_dialog.dart:637](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/checkout/presentation/whatsapp_receipt_dialog.dart#L637)", "status": "FAIL", "bug_id": "QA-REP-02"
    },
    {
        "id": "H5", "title": "Ukuran Varian Tombol", "req": "Tombol Button ([design.md:150](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L150))",
        "expected": "Tinggi tombol min 48px pada desktop/tablet ([design.md:150](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L150))",
        "actual": "Semua varian tombol terukur 50.0px via tester.getSize (>= 48px)",
        "method": "EXECUTED", "evidence": "[qa_verification_test.dart:32](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L32)", "status": "PASS", "bug_id": "-"
    },
    {
        "id": "I1", "title": "Font pubspec & ThemeData", "req": "Tipografi ([design.md:115](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L115))",
        "expected": "Font sans-serif sistem / Inter / Roboto ([design.md:115](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L115))",
        "actual": "pubspec menyertakan google_fonts, ThemeData default sans-serif",
        "method": "STATIC", "evidence": "[pubspec.yaml:39](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/pubspec.yaml#L39)", "status": "PASS", "bug_id": "-"
    },
    {
        "id": "I2", "title": "Kartu Kamar 140x100 & Overflow", "req": "Kartu Kamar ([design.md:158](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L158))",
        "expected": "Ukuran kartu proporsional ~140x100px tanpa overflow (parafrase dari prompt QA)",
        "actual": "mainAxisExtent 126px; Column overflow 66px pada viewport sempit",
        "method": "STATIC", "evidence": "[room_card.dart:83](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/room_management/presentation/room_card.dart#L83)", "status": "FAIL", "bug_id": "QA-DS-01"
    },
    {
        "id": "I3", "title": "Jumlah Kolom Grid 1280 & 1920", "req": "Layout Grid ([PRD.MD:116](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L116))",
        "expected": "Grid responsif menyesuaikan lebar desktop (parafrase dari prompt QA)",
        "actual": "Terbukti terotomasi: tepat 5 kolom (1280px) dan 6 kolom (1920px)",
        "method": "EXECUTED", "evidence": "[qa_verification_test.dart:73](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L73)", "status": "PASS", "bug_id": "-"
    },
    {
        "id": "J1", "title": "Top Bar 64px & Shift Time", "req": "Navigasi ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223))",
        "expected": "Top bar 64px menampilkan nama dan jam shift bertugas ([design.md:223](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L223))",
        "actual": "Tinggi 64px terpasang, namun jam shift bertugas tidak ditampilkan (0 hit)",
        "method": "STATIC", "evidence": "[app_header.dart:61](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/shared_widgets/app_header.dart#L61)", "status": "FAIL", "bug_id": "QA-DS-06"
    },
    {
        "id": "J2", "title": "Sidebar 240/72", "req": "Sidebar ([design.md:224](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L224))",
        "expected": "Sidebar 240px, collapse 72px pada tablet ([design.md:224](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L224))",
        "actual": "Sidebar fixed 240px; transisi collapse 72px belum ada",
        "method": "STATIC", "evidence": "[manager_dashboard_screen.dart:698](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L698)", "status": "PARTIAL", "bug_id": "QA-REP-01"
    },
    {
        "id": "J3", "title": "Tap Target 44x44px", "req": "Aksesibilitas ([design.md:150](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L150))",
        "expected": "Target sentuh elemen interaktif minimal 44x44px (parafrase dari prompt QA)",
        "actual": "Ditemukan icon button 20px padding 8 = 36px (< 44px)",
        "method": "STATIC", "evidence": "[app_header.dart:117](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/shared_widgets/app_header.dart#L117)", "status": "FAIL", "bug_id": "QA-DS-02"
    },
    {
        "id": "K1", "title": "Urutan Tab Form Check-In", "req": "Form Keyboard ([design.md:182](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/design.md#L182))",
        "expected": "Navigasi Tab logis: Identitas -> Inap -> Bayar (parafrase dari prompt QA)",
        "actual": "Form tidak mengonfigurasi FocusNode / TraversalGroup khusus",
        "method": "STATIC", "evidence": "[check_in_modal.dart:142](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L142)", "status": "FAIL", "bug_id": "QA-RES-01"
    },
    {
        "id": "K2", "title": "String Error Bahasa Inggris", "req": "Lokalisasi ([PRD.MD:109](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L109))",
        "expected": "Pesan error disajikan dalam Bahasa Indonesia (parafrase dari prompt QA)",
        "actual": "Exception mentah Dart berbahasa Inggris diekspos ke UI",
        "method": "STATIC", "evidence": "[auth_controller.dart:50](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L50)", "status": "FAIL", "bug_id": "QA-AUTH-04"
    },
    {
        "id": "K3", "title": "DateFormat & NumberFormat id_ID", "req": "Format Finansial ([PRD.MD:132](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L132))",
        "expected": "Format Rp X.XXX dan tanggal Indonesia (parafrase dari prompt QA)",
        "actual": "DateFormat id dan NumberFormat.currency id_ID diterapkan konsisten",
        "method": "STATIC", "evidence": "[app_header.dart:57](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/shared_widgets/app_header.dart#L57)", "status": "PASS", "bug_id": "-"
    },
    {
        "id": "L1", "title": "Penanganan Ekspor > 3 Bulan", "req": "Kinerja Ekspor ([PRD.MD:179](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L179))",
        "expected": "Proteksi query rentang waktu > 3 bulan (parafrase dari prompt QA)",
        "actual": "UI mock belum membatasi rentang tanggal ekspor",
        "method": "STATIC", "evidence": "[manager_dashboard_screen.dart:82](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reporting/presentation/manager_dashboard_screen.dart#L82)", "status": "PARTIAL", "bug_id": "QA-REP-03"
    },
    {
        "id": "L2", "title": "Double Submit Aksi Async", "req": "Integritas Transaksi ([PRD.MD:133](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L133))",
        "expected": "Tombol submit disabled saat async berjalan (parafrase dari prompt QA)",
        "actual": "Tombol 'Simpan & Check-In' tidak mengikat isLoading, rawan penekanan ganda",
        "method": "STATIC", "evidence": "[check_in_modal.dart:736](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L736)", "status": "FAIL", "bug_id": "QA-RES-06"
    },
    {
        "id": "L3", "title": "Suite Uji Otomatis Bawaan", "req": "Definisi Selesai ([PRD.MD:285](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L285))",
        "expected": "Suite uji widget bawaan lulus tanpa error (parafrase dari prompt QA)",
        "actual": "widget_test.dart bawaan gagal karena pencarian teks judul login tidak cocok",
        "method": "STATIC", "evidence": "[widget_test.dart:18](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/widget_test.dart#L18)", "status": "FAIL", "bug_id": "QA-TEST-01"
    },
    {
        "id": "Sec-1", "title": "Kredensial Hardcoded di Client", "req": "Keamanan Data ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110))",
        "expected": "Password tidak disimpan plain text di client ([PRD.MD:110](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L110))",
        "actual": "Username receptionist & manager serta password123 hardcoded di AuthRepository",
        "method": "STATIC", "evidence": "[auth_repository.dart:8](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/data/auth_repository.dart#L8)", "status": "FAIL", "bug_id": "QA-SEC-01"
    },
    {
        "id": "Sec-2", "title": "Sesi Tanpa Secure Storage", "req": "Sesi Aman ([Arsitektur.md:218](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/Arsitektur.md#L218))",
        "expected": "Token JWT disimpan secure storage / HttpOnly cookie (parafrase dari prompt QA)",
        "actual": "Token disimpan di memory RAM StateNotifier tanpa proteksi terenkripsi",
        "method": "STATIC", "evidence": "[auth_controller.dart:76](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/auth/presentation/auth_controller.dart#L76)", "status": "FAIL", "bug_id": "QA-SEC-02"
    }
]

all_rows = rows + new_rows
print(f"Total all rows: {len(all_rows)}")

# Collect all bug IDs from table
table_bugs = set()
for r in all_rows:
    b = r["bug_id"].strip()
    if b and b != "-" and b != "":
        table_bugs.add(b)

print(f"Unique Bug IDs in table: {len(table_bugs)}")
print("Table Bug IDs:", sorted(list(table_bugs)))

with open("test/qa/all_rows_v3.json", "w", encoding="utf-8") as out:
    json.dump(all_rows, out, indent=2, ensure_ascii=False)
