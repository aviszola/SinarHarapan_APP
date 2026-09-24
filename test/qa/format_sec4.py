import json
import re
import os

print("Building complete LAPORAN_QA_v3.md...")

# Load rows from test/qa/all_rows_v3.json
with open("test/qa/all_rows_v3.json", "r", encoding="utf-8") as f:
    all_rows = json.load(f)

# Fix C9 row
for r in all_rows:
    if r["id"] == "C9":
        r["title"] = "Validasi nomor WA"
        r["req"] = "FR-RES-04 ([PRD.MD:131](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L131))"
        r["expected"] = "Wajib mengisi nomor WhatsApp aktif tamu (validasi format +62 atau 08...) ([PRD.MD:131](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L131))"
        r["actual"] = "Validator form memverifikasi awalan '08' atau '+62' dengan panjang 10-15 digit"
        r["method"] = "STATIC"
        r["evidence"] = "[check_in_modal.dart:550](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/lib/features/reservation/presentation/check_in_modal.dart#L550)"
        r["status"] = "PASS"
        r["bug_id"] = "-"
    # Normalize bug_id
    b = r["bug_id"].strip()
    if not b.startswith("QA-"):
        r["bug_id"] = "-"

print(f"Processed {len(all_rows)} table rows.")

# Group rows by Module:
# Modul A (A1-A11)
# Modul B (B1-B17)
# Modul C (C1-C17)
# Modul D (D1-D6)
# Modul E (E1-E10)
# Modul F (F1-F10)
# Modul G (G1-G8)
# Modul H (H1-H5)
# Modul I (I1-I3)
# Modul J (J1-J3)
# Modul K (K1-K3)
# Modul L (L1-L3)
# Modul Sec (Sec-1, Sec-2)

modules = [
    ("4.1 Modul A — Autentikasi & Sesi (FR-AUTH-01 s/d 05)", lambda r: r["id"].startswith("A")),
    ("4.2 Modul B — Denah & Ketersediaan Kamar (FR-ROOM-01 s/d 07)", lambda r: r["id"].startswith("B")),
    ("4.3 Modul C — Reservasi & Check-in OCR KTP (FR-RES-01 s/d 08)", lambda r: r["id"].startswith("C")),
    ("4.4 Modul D — Otomasi Notifikasi WhatsApp (FR-WA-01 s/d 05)", lambda r: r["id"].startswith("D")),
    ("4.5 Modul E — Check-Out & Faktur/Invoice (FR-OUT-01 s/d 05)", lambda r: r["id"].startswith("E")),
    ("4.6 Modul F — Analitik Manajerial & Ekspor Laporan (FR-REP-01 s/d 05)", lambda r: r["id"].startswith("F")),
    ("4.7 Modul G — Matriks Pengujian Silang RBAC (§11)", lambda r: r["id"].startswith("G")),
    ("4.8 Modul H — Design System & Anti-AI Slop (§6.1, §6.8, §9)", lambda r: r["id"].startswith("H")),
    ("4.9 Modul I — Tipografi, Spacing & Layout Grid Denah (§6.2)", lambda r: r["id"].startswith("I")),
    ("4.10 Modul J — Responsivitas, Top Bar, Sidebar & Touch Target (§6.9)", lambda r: r["id"].startswith("J")),
    ("4.11 Modul K — Interaksi Form, Tab Order, Validasi & Lokalisasi (§6.4)", lambda r: r["id"].startswith("K")),
    ("4.12 Modul L — Ketahanan Async, Integritas Transaksi & Edge Cases", lambda r: r["id"].startswith("L")),
    ("4.13 Modul Sec — Audit Keamanan Kredensial & Manajemen Sesi", lambda r: r["id"].startswith("Sec")),
]

def format_table_module(title, filter_fn):
    mod_rows = [r for r in all_rows if filter_fn(r)]
    md = f"### {title}\n\n"
    md += "| ID | Kasus Uji | Requirement | Expected (Kutipan Resmi + Path) | Actual (Kondisi Kode & Lingkungan) | METODE | Bukti Konkret | Status | Bug ID |\n"
    md += "| :--- | :--- | :--- | :--- | :--- | :---: | :--- | :---: | :---: |\n"
    for r in mod_rows:
        md += f"| **{r['id']}** | {r['title']} | {r['req']} | {r['expected']} | {r['actual']} | **{r['method']}** | {r['evidence']} | **{r['status']}** | {r['bug_id']} |\n"
    md += "\n"
    return md

sec4_content = "## 4. Tabel Kasus Uji Lengkap (Traceability Seluruh Modul A-L & Security)\n\n"
for title, fn in modules:
    sec4_content += format_table_module(title, fn)

with open("test/qa/sec4_formatted.md", "w", encoding="utf-8") as out:
    out.write(sec4_content)

print("Section 4 formatted table written to test/qa/sec4_formatted.md")
