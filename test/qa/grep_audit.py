# Script to verify all grep outputs and generate raw grep logs
import subprocess
import os

print("=== RUNNING RAW GREP AUDIT FOR H-L ===")

def run_grep(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=r"c:\Sinar Harapan APP\sinarharapan_app")
        out = (res.stdout + res.stderr).strip()
        return out if out else "(0 hit / tidak ditemukan)"
    except Exception as e:
        return str(e)

grep_tasks = {
    "1. BackdropFilter": 'git grep -n "BackdropFilter" lib/',
    "2. Gradient": 'git grep -n "Gradient" lib/',
    "3. BoxShadow": 'git grep -n "BoxShadow" lib/',
    "4a. Non-token Colors.*": 'git grep -n "Colors\." lib/ | grep -v "Colors\.white" | grep -v "Colors\.transparent"',
    "4b. Color(0x...)": 'git grep -n "Color(0x" lib/',
    "5. Fonts di pubspec & ThemeData": 'git grep -n "fonts:" pubspec.yaml',
    "6. Shift time di top bar": 'git grep -n -i "shift" lib/',
    "7. Sidebar 240/72": 'git grep -n "240" lib/features/reporting/presentation/',
    "8. Double submit check-in": 'git grep -n "Simpan & Check-In" lib/',
    "9. Error string Inggris": 'git grep -n "replaceAll(\'Exception: \'" lib/'
}

for name, cmd in grep_tasks.items():
    print(f"\n--- {name} ---")
    print(f"Command: {cmd}")
    print("Output:")
    print(run_grep(cmd))
