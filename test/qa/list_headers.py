import re

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    text = f.read()

headers = re.findall(r"^##\s+.*", text, re.MULTILINE)
for h in headers:
    print(h)
