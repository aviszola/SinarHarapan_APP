import re

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    lines = [l.strip() for l in f if l.strip().startswith('|')]

rows = []
for l in lines:
    cols = [c.strip() for c in l.split('|')[1:-1]]
    if not cols:
        continue
    id_clean = re.sub(r'[*_]', '', cols[0]).strip()
    if re.match(r'^[A-Z][0-9]+', id_clean) or re.match(r'^Sec-[0-9]+', id_clean):
        rows.append((id_clean, cols))

print(f"Total test case rows found: {len(rows)}")
for r in rows:
    status = re.sub(r'[*_]', '', r[1][7]).strip() if len(r[1]) > 7 else 'N/A'
    method = re.sub(r'[*_]', '', r[1][5]).strip() if len(r[1]) > 5 else 'N/A'
    bug = re.sub(r'[*_]', '', r[1][8]).strip() if len(r[1]) > 8 else 'N/A'
    print(f"{r[0]:<6} | {method:<10} | {status:<8} | {bug}")

