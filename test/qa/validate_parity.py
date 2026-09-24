import json
import re

with open("test/qa/all_rows_v3.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

with open("test/qa/sec5_formatted.md", "r", encoding="utf-8") as f:
    sec5_text = f.read()

# 1. Bug IDs in table
table_bugs = set()
for r in rows:
    b = r["bug_id"].strip()
    if b.startswith("QA-"):
        table_bugs.add(b)

# 2. Bug IDs in Section 5
sec5_bugs = set(re.findall(r"###\s+(QA-[A-Za-z0-9_-]+):", sec5_text))

print("=== AUDIT PARITAS BUG ID DUA ARAH ===")
print(f"Total Baris Kasus Uji di Tabel: {len(rows)}")
print(f"Total Unique Bug ID di Tabel  : {len(table_bugs)}")
print(f"Total Unique Bug ID di §5     : {len(sec5_bugs)}")

# (a) Check orphan table IDs (in table but not in §5)
orphan_table_ids = table_bugs - sec5_bugs
print(f"\n(a) ID Yatim di Tabel (Ada di tabel tapi tidak ada entri di §5): {len(orphan_table_ids)}")
if orphan_table_ids:
    for b in sorted(list(orphan_table_ids)):
        print(f"  - {b}")
else:
    print("  [OK] SEMPURNA: 0 ID yatim di tabel!")

# (b) Check orphan §5 bugs (in §5 but not in table)
orphan_sec5_bugs = sec5_bugs - table_bugs
print(f"\n(b) Bug di §5 Tanpa Baris Tabel (Ada di §5 tapi tidak muncul di tabel): {len(orphan_sec5_bugs)}")
if orphan_sec5_bugs:
    for b in sorted(list(orphan_sec5_bugs)):
        print(f"  - {b}")
else:
    print("  [OK] SEMPURNA: 0 bug tanpa baris tabel!")

if not orphan_table_ids and not orphan_sec5_bugs:
    print("\n>>> KONSISTENSI DUA ARAH 100% VALID DAN TERVERIFIKASI! <<<")
