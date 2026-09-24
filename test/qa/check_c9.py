import json
with open("test/qa/sec4_rows.json", "r", encoding="utf-8") as f:
    rows = json.load(f)
for r in rows:
    if r["id"] == "C9":
        print(r)
