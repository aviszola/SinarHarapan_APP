import re

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    text = f.read()

missing_ids = ['QA-RES-04', 'QA-RES-05', 'QA-WA-02', 'QA-WA-03', 'QA-OUT-03', 'QA-OUT-04', 'QA-REP-02', 'QA-REP-03', 'QA-REP-04']

for mid in missing_ids:
    for line in text.splitlines():
        if mid in line and line.strip().startswith('|'):
            print(f"{mid}: {line.strip()}")
