import re

with open("previous_report_v2.md", "r", encoding="utf-8") as f:
    text = f.read()

# Section 5 is between "## 5." and "## 6."
sec5_match = re.search(r"## 5\..*?(?=## 6\.)", text, re.DOTALL)
if sec5_match:
    sec5_text = sec5_match.group(0)
    # Find all bug titles: ### QA-... or similar
    bugs = re.findall(r"###\s+([A-Za-z0-9_-]+):", sec5_text)
    print("Bugs in §5:", bugs)
    print(f"Total bugs in §5: {len(bugs)}")
else:
    print("Could not find Section 5")
