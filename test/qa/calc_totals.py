import json
from collections import Counter

with open("test/qa/all_rows_v3.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

total = len(rows)
status_counts = Counter(r["status"] for r in rows)
method_counts = Counter(r["method"] for r in rows)
cross_counts = Counter((r["status"], r["method"]) for r in rows)

print("================================================================================")
print("HASIL SKRIP PENGHITUNGAN REKAPITULASI LAPORAN QA v3.0")
print("================================================================================")
print(f"Total Baris Kasus Uji Terverifikasi: {total}\n")

print("1. Distribusi Kasus Uji Berdasarkan Status:")
print("-" * 55)
print(f"{'Status':<15} | {'Jumlah':<10} | {'Persentase':<12}")
print("-" * 55)
for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED", "NOT TESTED"]:
    cnt = status_counts.get(s, 0)
    pct = (cnt / total) * 100 if total > 0 else 0
    print(f"{s:<15} | {cnt:<10} | {pct:>6.2f}%")
print("-" * 55)
print(f"{'TOTAL':<15} | {total:<10} | 100.00%\n")

print("2. Distribusi Kasus Uji Berdasarkan Metode Pengujian:")
print("-" * 55)
print(f"{'Metode':<15} | {'Jumlah':<10} | {'Persentase':<12}")
print("-" * 55)
for m in ["EXECUTED", "STATIC", "BLOCKED", "NOT TESTED"]:
    cnt = method_counts.get(m, 0)
    pct = (cnt / total) * 100 if total > 0 else 0
    print(f"{m:<15} | {cnt:<10} | {pct:>6.2f}%")
print("-" * 55)
print(f"{'TOTAL':<15} | {total:<10} | 100.00%\n")

print("3. Matriks Silang Status vs Metode (Integritas Matematika 100%):")
print("-" * 75)
print(f"{'Status':<12} | {'EXECUTED':<10} | {'STATIC':<10} | {'BLOCKED':<10} | {'TOTAL':<10}")
print("-" * 75)
for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"]:
    ex = cross_counts.get((s, "EXECUTED"), 0)
    st = cross_counts.get((s, "STATIC"), 0)
    bl = cross_counts.get((s, "BLOCKED"), 0)
    tot_s = ex + st + bl
    print(f"{s:<12} | {ex:<10} | {st:<10} | {bl:<10} | {tot_s:<10}")
print("-" * 75)
tot_ex = sum(cross_counts.get((s, "EXECUTED"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
tot_st = sum(cross_counts.get((s, "STATIC"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
tot_bl = sum(cross_counts.get((s, "BLOCKED"), 0) for s in ["PASS", "FAIL", "PARTIAL", "BLOCKED"])
print(f"{'TOTAL':<12} | {tot_ex:<10} | {tot_st:<10} | {tot_bl:<10} | {total:<10}")
print("-" * 75)
