import os, glob, zipfile, re

downloads = os.path.expanduser('~/Downloads')
files = glob.glob(os.path.join(downloads, 'Laporan_Transaksi_September_2026*.xlsx'))
files.sort(key=os.path.getmtime, reverse=True)

print(f'Latest generated files in Downloads (Total: {len(files)}):')
for f in files[:4]:
    print(' ', os.path.basename(f), 'Size:', os.path.getsize(f), 'bytes')

latest = files[0]
print(f'\n=== INSPECTING LATEST EXPORT: {os.path.basename(latest)} ===')
with zipfile.ZipFile(latest, 'r') as z:
    s1_xml = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
    strings_xml = z.read('xl/sharedStrings.xml').decode('utf-8')
    
    strings = re.findall(r'<t[^>]*>(.*?)</t>', strings_xml)
    print(f'Total shared strings: {len(strings)}')
    
    invoices = [s for s in strings if 'INV' in s]
    print('\nInvoices found in sharedStrings:')
    for inv in invoices:
        print('  ->', inv)
        
    rows = re.findall(r'<row r="(\d+)"', s1_xml)
    print(f'\nRows present in sheet1: {rows}')
    
    formulas = re.findall(r'<f>(.*?)</f>', s1_xml)
    print(f'Formulas found in sheet1: {formulas}')
    
    if '<pane' in s1_xml:
        start = s1_xml.find('<sheetViews>')
        end = s1_xml.find('</sheetViews>') + 13
        print('\nFreeze Pane XML in Sheet 1:')
        print(s1_xml[start:end])
        
    if '<cols>' in s1_xml:
        start = s1_xml.find('<cols>')
        end = s1_xml.find('</cols>') + 7
        print('\nColumn Widths XML in Sheet 1:')
        print(s1_xml[start:end])
