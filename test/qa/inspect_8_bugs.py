import re

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    text = f.read()

target_bugs = ['QA-RES-03', 'QA-OUT-02', 'QA-SEC-01', 'QA-TEST-01', 'QA-RES-06', 'QA-DS-04', 'QA-DS-05', 'QA-DS-06']

for b in target_bugs:
    match = re.search(r"###\s+" + re.escape(b) + r":.*?(?=(###|\Z|##\s+6))", text, re.DOTALL)
    if match:
        lines = [line.strip() for line in match.group(0).splitlines() if line.strip()]
        print("====================")
        print("\n".join(lines[:6]))
