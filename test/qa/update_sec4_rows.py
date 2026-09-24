import json
import re

# Load existing 79 rows from sec4_rows.json
with open("test/qa/sec4_rows.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

# Update existing rows per instruction 5:
# - D1: change to PARTIAL (mock data)
# - F8: change to PARTIAL (mock data)
# - A11: change to PASS, bug_id = "-" (remove QA-DS-03), method = "EXECUTED"
# - A3: change to PARTIAL
# - A5: change to PARTIAL
# - B17: change to PARTIAL
# - B3: method = "EXECUTED" (verified by QA-2 in qa_verification_test.dart)
# - B11: method = "EXECUTED" (verified by QA-4 in qa_verification_test.dart)
# - C5: bug_id = "QA-RES-03", status = "FAIL", actual note about PO confirmation
# - E7: status = "PARTIAL"
# - E8: status = "PARTIAL"
# - F5: status = "PARTIAL"
# - F6: status = "PARTIAL"
# - G4: method = "EXECUTED" (verified by QA-3 in qa_verification_test.dart)
# - G5: method = "EXECUTED" (verified by QA-4 in qa_verification_test.dart)

for r in rows:
    rid = r["id"]
    if rid == "D1":
        r["status"] = "PARTIAL"
        r["actual"] += " (Catatan Integritas: Pass semu berbasis data mock; integrasi gateway WA riil belum diuji)"
    elif rid == "F8":
        r["status"] = "PARTIAL"
        r["actual"] += " (Catatan Integritas: Angka KPI berbasis array statis mock di memori, bukan agregasi database riil)"
    elif rid == "A11":
        r["status"] = "PASS"
        r["method"] = "EXECUTED"
        r["bug_id"] = "-"
        r["evidence"] = "[qa_verification_test.dart:32](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L32)"
        r["actual"] = "Tinggi tombol terukur 50.0px via tester.getSize (memenuhi syarat min 48px; QA-DS-03 dihapus)"
    elif rid == "A3":
        r["status"] = "PARTIAL"
        r["actual"] += " (Banner error tampil & username tersimpan, namun visual highlight border merah tidak terbukti)"
    elif rid == "A5":
        r["status"] = "PARTIAL"
        r["actual"] += " (Toggle mata berfungsi, namun enkripsi transit TLS tidak dapat dibuktikan pada client lokal)"
    elif rid == "B17":
        r["status"] = "PARTIAL"
        r["actual"] += " (Scroll grid berjalan, batas responsivitas scrollbar desktop belum dibuktikan)"
    elif rid == "B3":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:73](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L73)"
    elif rid == "B11":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L214)"
    elif rid == "C5":
        r["status"] = "FAIL"
        r["bug_id"] = "QA-RES-03"
        r["expected"] = "Otomatis dihitung: tarif dasar x durasi malam ([PRD.MD:132](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/PRD.MD#L132))"
        r["actual"] = "Field total tarif dapat disunting manual bebas tanpa otorisasi manajer. [Perlu konfirmasi Product Owner: kode memuat catatan 'diskon khusus/negosiasi']"
    elif rid == "E7":
        r["status"] = "PARTIAL"
    elif rid == "E8":
        r["status"] = "PARTIAL"
    elif rid == "F5":
        r["status"] = "PARTIAL"
    elif rid == "F6":
        r["status"] = "PARTIAL"
    elif rid == "G4":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:163](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L163)"
    elif rid == "G5":
        r["method"] = "EXECUTED"
        r["evidence"] = "[qa_verification_test.dart:214](file:///c:/Sinar%20Harapan%20APP/sinarharapan_app/test/qa/qa_verification_test.dart#L214)"

print("Updated existing 79 rows successfully.")
