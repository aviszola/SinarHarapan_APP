import os, glob, zipfile

downloads = os.path.expanduser('~/Downloads')
files = glob.glob(os.path.join(downloads, 'Laporan_Transaksi_September_2026*.xlsx'))
files.sort(key=os.path.getmtime, reverse=True)
latest = files[0]

with zipfile.ZipFile(latest, 'r') as z:
    s1 = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
    s2 = z.read('xl/worksheets/sheet2.xml').decode('utf-8')
    print('Sheet 1 showGridLines:', 'showGridLines="1"' in s1)
    print('Sheet 1 autoFilter:', '<autoFilter' in s1)
    if '<autoFilter' in s1:
        f_idx = s1.find('<autoFilter')
        print('  ->', s1[f_idx:f_idx+50])
        
    print('Sheet 2 showGridLines:', 'showGridLines="1"' in s2)
    print('Sheet 2 autoFilter:', '<autoFilter' in s2)
    if '<autoFilter' in s2:
        f_idx = s2.find('<autoFilter')
        print('  ->', s2[f_idx:f_idx+50])
