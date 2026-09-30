import os, glob, zipfile, re

downloads = os.path.expanduser('~/Downloads')
files = glob.glob(os.path.join(downloads, 'Laporan_Transaksi_September_2026*.xlsx'))
files.sort(key=os.path.getmtime, reverse=True)
latest = files[0]

with zipfile.ZipFile(latest, 'r') as z:
    styles_xml = z.read('xl/styles.xml').decode('utf-8')

def add_apply_border(match):
    xf = match.group(0)
    m_b = re.search(r'borderId="(\d+)"', xf)
    if m_b and m_b.group(1) != "0" and 'applyBorder' not in xf:
        if xf.endswith('/>'):
            xf = xf[:-2] + ' applyBorder="1"/>'
        elif xf.endswith('>'):
            xf = xf[:-1] + ' applyBorder="1">'
    return xf

new_styles = re.sub(r'<xf [^>]+>', add_apply_border, styles_xml)
print('Before has applyBorder:', 'applyBorder' in styles_xml)
print('After has applyBorder:', 'applyBorder' in new_styles)
matches = re.findall(r'<xf [^>]*applyBorder="1"[^>]*>', new_styles)
print(f'Total xf with applyBorder=1: {len(matches)}')
for m in matches[:5]:
    print(' ', m)
