import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

ROOT = r"c:\Sinar Harapan APP\sinarharapan_app"

def grep_files(pattern, folder="lib", file_ext=(".dart",), case_sensitive=True):
    results = []
    regex = re.compile(pattern if case_sensitive else pattern, 0 if case_sensitive else re.IGNORECASE)
    search_dir = os.path.join(ROOT, folder) if folder else ROOT
    for root, dirs, files in os.walk(search_dir):
        for f in files:
            if any(f.endswith(ext) for ext in file_ext):
                filepath = os.path.join(root, f)
                relpath = os.path.relpath(filepath, ROOT).replace("\\", "/")
                try:
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as file:
                        for idx, line in enumerate(file, start=1):
                            if regex.search(line):
                                results.append(f"{relpath}:{idx}: {line.strip()}")
                except Exception as e:
                    pass
    return results

audits = [
    ("BackdropFilter", r"BackdropFilter", "lib", (".dart",)),
    ("Semua Gradient", r"Gradient", "lib", (".dart",)),
    ("BoxShadow", r"BoxShadow", "lib", (".dart",)),
    ("Color(0x...)", r"Color\(0x", "lib", (".dart",)),
    ("Colors.* Non-Token", r"Colors\.(?!white|transparent|black\b)", "lib", (".dart",)),
    ("Font di pubspec.yaml", r"fonts:", "", (".yaml",)),
    ("Font di ThemeData", r"fontFamily", "lib", (".dart",)),
    ("Shift Time di Top Bar", r"shift", "lib", (".dart",)),
    ("Sidebar width 240 / 72", r"\b(240|72)\b", "lib/features/reporting", (".dart",)),
    ("Kartu Kamar 140x100 (mainAxisExtent / size)", r"mainAxisExtent|140", "lib/features/room_management", (".dart",)),
    ("Touch Target 44x44 (Icon button sizes)", r"IconButton|iconSize|size:\s*(?:1[0-9]|2[0-9]|3[0-9])\b", "lib/features/shared_widgets", (".dart",)),
    ("Urutan Tab Form Check-In (FocusNode)", r"FocusNode|FocusScope|focusTraversalGroup", "lib/features/reservation", (".dart",)),
    ("String Error Berbahasa Inggris", r"Exception:|Failed to|Invalid|Error", "lib/features/auth", (".dart",)),
    ("DateFormat & NumberFormat id_ID", r"DateFormat|NumberFormat", "lib", (".dart",)),
    ("Penanganan Ekspor > 3 Bulan", r"3 bulan|90 hari|startDate|endDate", "lib/features/reporting", (".dart",)),
    ("Double Submit Tiap Aksi Async (isLoading pada AppButton submit)", r"Simpan & Check-In|Proses Check-out|Kirim Ulang", "lib", (".dart",)),
]

with open("test/qa/grep_results.txt", "w", encoding="utf-8") as out:
    out.write("================================================================================\n")
    out.write("HASIL GREP MENTAH LENGKAP AUDIT KODE SUMBER LIB/ (BAGIAN H - L)\n")
    out.write("================================================================================\n")
    for title, pat, folder, ext in audits:
        out.write(f"\n>>> [GREP] {title}\n")
        out.write(f"Pattern: {pat} | Target: {folder or 'root'} {ext}\n")
        hits = grep_files(pat, folder if folder else "", ext)
        if not hits:
            out.write("HASIL: 0 hit (Bersih / Tidak Ditemukan)\n")
        else:
            out.write(f"HASIL: {len(hits)} hit ditemukan:\n")
            for h in hits:
                out.write(f"  {h}\n")

print("Saved grep results to test/qa/grep_results.txt")
