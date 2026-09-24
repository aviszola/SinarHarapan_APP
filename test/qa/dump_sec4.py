import re
import json

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    text = f.read()

# Extract lines between "## 4." and "## 5."
sec4_match = re.search(r"## 4\..*?(?=## 5\.)", text, re.DOTALL)
if not sec4_match:
    print("Could not find section 4")
    exit(1)

sec4_text = sec4_match.group(0)

rows = []
for line in sec4_text.splitlines():
    line = line.strip()
    if not line.startswith("|"):
        continue
    cols = [c.strip() for c in line.split("|")[1:-1]]
    if not cols:
        continue
    id_clean = re.sub(r'[*_]', '', cols[0]).strip()
    if re.match(r'^[A-Z][0-9]+', id_clean):
        rows.append({
            "id": id_clean,
            "raw_id": cols[0],
            "title": cols[1],
            "req": cols[2],
            "expected": cols[3],
            "actual": cols[4],
            "method": re.sub(r'[*_]', '', cols[5]).strip(),
            "evidence": cols[6],
            "status": re.sub(r'[*_]', '', cols[7]).strip(),
            "bug_id": re.sub(r'[*_]', '', cols[8]).strip() if len(cols) > 8 else "-"
        })

print(f"Extracted {len(rows)} test case rows from Section 4.")
with open("test/qa/sec4_rows.json", "w", encoding="utf-8") as out:
    json.dump(rows, out, indent=2, ensure_ascii=False)
print("Saved to test/qa/sec4_rows.json")
