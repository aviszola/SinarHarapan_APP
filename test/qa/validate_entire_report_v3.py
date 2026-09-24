import re
from collections import Counter

report_path = "LAPORAN_QA_v3.md"
with open(report_path, "r", encoding="utf-8") as f:
    text = f.read()

# 1. Parse Section 4 Table
sec4_match = re.search(r"## 4\..*?(?=## 5\.)", text, re.DOTALL)
if not sec4_match:
    print("Error: Section 4 not found!")
    exit(1)

sec4_text = sec4_match.group(0)

table_rows = []
for line in sec4_text.splitlines():
    line = line.strip()
    if not line.startswith("|"):
        continue
    cols = [c.strip() for c in line.split("|")[1:-1]]
    if not cols:
        continue
    id_clean = re.sub(r'[*_]', '', cols[0]).strip()
    if re.match(r'^[A-Z][0-9]+', id_clean) or re.match(r'^Sec-[0-9]+', id_clean):
        status = re.sub(r'[*_]', '', cols[7]).strip()
        method = re.sub(r'[*_]', '', cols[5]).strip()
        bug_id = re.sub(r'[*_]', '', cols[8]).strip() if len(cols) > 8 else "-"
        table_rows.append({
            "id": id_clean,
            "status": status,
            "method": method,
            "bug_id": bug_id
        })

# 2. Parse Section 5 Bugs
sec5_match = re.search(r"## 5\..*?(?=## 6\.)", text, re.DOTALL)
if not sec5_match:
    print("Error: Section 5 not found!")
    exit(1)

sec5_text = sec5_match.group(0)
sec5_bugs = set(re.findall(r"###\s+(QA-[A-Za-z0-9_-]+):", sec5_text))

table_bugs = set(r["bug_id"] for r in table_rows if r["bug_id"].startswith("QA-"))

print("================================================================================")
print("SKRIP VALIDASI & AUDIT PARITAS LAPORAN_QA_v3.md")
print("================================================================================")
print(f"Total Baris Kasus Uji Diparsing dari Markdown: {len(table_rows)}")
print(f"Total Unique Bug ID di Tabel Markdown        : {len(table_bugs)}")
print(f"Total Unique Bug ID di §5 Markdown           : {len(sec5_bugs)}")

# Parity Checks
orphan_table = table_bugs - sec5_bugs
orphan_sec5 = sec5_bugs - table_bugs

print("\n--- HASIL PENGECEKAN PARITAS DUA ARAH ---")
print(f"1. Bug ID di Tabel tanpa entri di §5 (ID Yatim) : {len(orphan_table)}")
if orphan_table:
    for b in sorted(orphan_table):
        print(f"   [FAIL] {b}")
else:
    print("   [OK] SEMPURNA (0 ID yatim)")

print(f"2. Bug di §5 tanpa kemunculan di baris tabel   : {len(orphan_sec5)}")
if orphan_sec5:
    for b in sorted(orphan_sec5):
        print(f"   [FAIL] {b}")
else:
    print("   [OK] SEMPURNA (0 bug tanpa baris tabel)")

# Calculations
total = len(table_rows)
status_counts = Counter(r["status"] for r in table_rows)
method_counts = Counter(r["method"] for r in table_rows)
cross_counts = Counter((r["status"], r["method"]) for r in table_rows)

print("\n--- DISTRIBUSI KASUS UJI BERDASARKAN STATUS ---")
for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"]:
    cnt = status_counts[s]
    pct = (cnt / total) * 100
    print(f"  {s:<10}: {cnt:>2} baris ({pct:>5.2f}%)")
print(f"  {'TOTAL':<10}: {total:>2} baris (100.00%)")

print("\n--- DISTRIBUSI KASUS UJI BERDASARKAN METODE ---")
for m in ["EXECUTED", "STATIC", "BLOCKED"]:
    cnt = method_counts[m]
    pct = (cnt / total) * 100
    print(f"  {m:<10}: {cnt:>2} baris ({pct:>5.2f}%)")
print(f"  {'TOTAL':<10}: {total:>2} baris (100.00%)")

print("\n--- MATRIKS SILANG (STATUS x METODE) ---")
print(f"{'Status':<10} | {'EXECUTED':<10} | {'STATIC':<10} | {'BLOCKED':<10} | {'TOTAL':<10}")
print("-" * 55)
for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"]:
    ex = cross_counts.get((s, "EXECUTED"), 0)
    st = cross_counts.get((s, "STATIC"), 0)
    bl = cross_counts.get((s, "BLOCKED"), 0)
    print(f"{s:<10} | {ex:>10} | {st:>10} | {bl:>10} | {ex+st+bl:>10}")
print("-" * 55)
tot_ex = sum(cross_counts.get((s, "EXECUTED"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
tot_st = sum(cross_counts.get((s, "STATIC"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
tot_bl = sum(cross_counts.get((s, "BLOCKED"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
print(f"{'TOTAL':<10} | {tot_ex:>10} | {tot_st:>10} | {tot_bl:>10} | {total:>10}")
print("================================================================================")
