import json
import os

transcript_path = r"C:\Users\LOQ 25\.gemini\antigravity-ide\brain\04ae321b-2853-4457-9f4e-e543bb5e09a7\.system_generated\logs\transcript_full.jsonl"
with open(transcript_path, "r", encoding="utf-8") as f:
    for i, line in enumerate(f):
        if i == 1901:  # 0-indexed line 1901 is line 1902
            data = json.loads(line)
            content = data.get("content", "")
            print("Length of previous response:", len(content))
            with open("previous_report_v2.md", "w", encoding="utf-8") as out:
                out.write(content)
            print("Wrote previous_report_v2.md successfully!")
            break
