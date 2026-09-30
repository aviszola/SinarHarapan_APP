import os, glob, zipfile, re

downloads = os.path.expanduser('~/Downloads')
files = glob.glob(os.path.join(downloads, 'Laporan_Transaksi_September_2026*.xlsx'))
files.sort(key=os.path.getmtime, reverse=True)
latest = files[0]

with zipfile.ZipFile(latest, 'r') as z:
    s2_xml = z.read('xl/worksheets/sheet2.xml').decode('utf-8')
    styles_xml = z.read('xl/styles.xml').decode('utf-8')
    print('--- STYLES XML BORDERS ---')
    b_start = styles_xml.find('<borders')
    b_end = styles_xml.find('</borders>') + 10
    print(styles_xml[b_start:b_end])
    
    print('\n--- STYLES XML CELLXFS ---')
    xfs_start = styles_xml.find('<cellXfs')
    xfs_end = styles_xml.find('</cellXfs>') + 10
    print(styles_xml[xfs_start:xfs_end])
    
    print('\n--- SHEET 2 ROWS 4 TO 10 ---')
    rows = re.findall(r'<row r="[4-9]".*?</row>', s2_xml)
    for r in rows[:6]:
        print(r)
