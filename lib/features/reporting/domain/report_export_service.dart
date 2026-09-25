import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../room_management/domain/room_model.dart';

class TransactionExportItem {
  final String invoice;
  final String roomNumber;
  final String roomType;
  final String guestName;
  final String phone;
  final String source;
  final double totalAmount;
  final String status;
  final String date;

  TransactionExportItem({
    required this.invoice,
    required this.roomNumber,
    required this.roomType,
    required this.guestName,
    required this.phone,
    required this.source,
    required this.totalAmount,
    required this.status,
    required this.date,
  });
}

class ReportExportService {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static List<TransactionExportItem> buildTransactionItems(List<RoomModel> rooms) {
    final list = <TransactionExportItem>[];
    for (int index = 0; index < rooms.length; index++) {
      final room = rooms[index];
      final invoice = room.invoiceNumber ?? 'INV/SH/20260924/00${index + 1}';
      final guest = room.activeGuestName ?? 'Tamu Walk-in';
      final phone = room.activeGuestPhone ?? '081234567890';
      final source = room.bookingSource ?? (index % 2 == 0 ? 'REDDOORZ' : 'WALK_IN');
      final total = room.basePricePerNight * (index % 3 + 1);
      final status = room.isOccupied ? 'Menginap' : 'Selesai';
      final date = '24/09/2026';

      list.add(
        TransactionExportItem(
          invoice: invoice,
          roomNumber: room.roomNumber,
          roomType: room.roomType,
          guestName: guest,
          phone: phone,
          source: source,
          totalAmount: total,
          status: status,
          date: date,
        ),
      );
    }
    return list;
  }

  static String formatDate(DateTime dt, {bool withTime = false}) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    if (withTime) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year $hour:$minute';
    }
    return '$day $month $year';
  }

  /// Ekspor ke berkas Excel (.xlsx) dengan 2 Sheet
  static Future<String?> exportToExcel({
    required List<RoomModel> rooms,
    String periodName = 'September 2026',
  }) async {
    final items = buildTransactionItems(rooms);
    final excel = Excel.createExcel();

    // ── Sheet 1: Rekap Transaksi ──────────────────────────────────────────
    final transSheetName = 'Rekap Transaksi';
    final transSheet = excel[transSheetName];
    excel.setDefaultSheet(transSheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Title rows
    transSheet.appendRow([TextCellValue('HOTEL SINAR HARAPAN (MITRA RESMI REDDOORZ)')]);
    transSheet.appendRow([TextCellValue('LAPORAN REKAPITULASI TRANSAKSI & PENDAPATAN')]);
    transSheet.appendRow([TextCellValue('Periode: $periodName | Tanggal Ekspor: ${formatDate(DateTime.now(), withTime: true)} WIB')]);
    transSheet.appendRow([TextCellValue('')]); // empty line

    // Header Table
    transSheet.appendRow([
      TextCellValue('NO'),
      TextCellValue('NO. INVOICE'),
      TextCellValue('KAMAR'),
      TextCellValue('TIPE KAMAR'),
      TextCellValue('NAMA TAMU'),
      TextCellValue('NO. WHATSAPP'),
      TextCellValue('KANAL RESERVASI'),
      TextCellValue('TOTAL BIAYA (RP)'),
      TextCellValue('STATUS'),
      TextCellValue('TANGGAL'),
    ]);

    double grandTotal = 0;
    int reddoorzCount = 0;
    int walkInCount = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      grandTotal += item.totalAmount;
      if (item.source == 'REDDOORZ') {
        reddoorzCount++;
      } else {
        walkInCount++;
      }

      transSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.invoice),
        TextCellValue('Kamar ${item.roomNumber}'),
        TextCellValue(item.roomType),
        TextCellValue(item.guestName),
        TextCellValue(item.phone),
        TextCellValue(item.source),
        DoubleCellValue(item.totalAmount),
        TextCellValue(item.status),
        TextCellValue(item.date),
      ]);
    }

    // Summary row
    transSheet.appendRow([
      TextCellValue(''),
      TextCellValue('TOTAL PENDAPATAN'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    // ── Sheet 2: Ringkasan KPI ───────────────────────────────────────────
    final kpiSheet = excel['Ringkasan KPI'];
    kpiSheet.appendRow([TextCellValue('INDIKATOR KINERJA HOTEL (KPI)')]);
    kpiSheet.appendRow([TextCellValue('Periode: $periodName')]);
    kpiSheet.appendRow([TextCellValue('')]);
    kpiSheet.appendRow([TextCellValue('Metrik'), TextCellValue('Nilai')]);
    kpiSheet.appendRow([TextCellValue('Total Transaksi'), IntCellValue(items.length)]);
    kpiSheet.appendRow([TextCellValue('Total Pendapatan Terdata'), DoubleCellValue(grandTotal)]);
    kpiSheet.appendRow([TextCellValue('Transaksi Kanal RedDoorz'), IntCellValue(reddoorzCount)]);
    kpiSheet.appendRow([TextCellValue('Transaksi Kanal Walk-In'), IntCellValue(walkInCount)]);
    kpiSheet.appendRow([TextCellValue('Tingkat Okupansi'), TextCellValue('${(items.where((x) => x.status == "Menginap").length / (items.isNotEmpty ? items.length : 1) * 100).round()}%')]);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal membuat binary file Excel.');

    final fileName = 'Laporan_Transaksi_September_2026.xlsx';
    return saveWithPicker(
      bytes: Uint8List.fromList(bytes),
      defaultFileName: fileName,
      fileExtension: 'xlsx',
      dialogTitle: 'Simpan Rekapitulasi Transaksi Excel (.xlsx)',
    );
  }

  /// Ekspor ke berkas PDF Resmi A4
  static Future<String?> exportToPdf({
    required List<RoomModel> rooms,
    String periodName = 'September 2026',
    String managerName = 'Hendra Wijaya',
  }) async {
    final items = buildTransactionItems(rooms);
    final doc = pw.Document();

    double grandTotal = 0;
    int reddoorzCount = 0;
    int walkInCount = 0;

    for (final item in items) {
      grandTotal += item.totalAmount;
      if (item.source == 'REDDOORZ') {
        reddoorzCount++;
      } else {
        walkInCount++;
      }
    }

    final dateStr = formatDate(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // ── Kop Surat Resmi ──────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HOTEL SINAR HARAPAN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#001B4E'),
                      ),
                    ),
                    pw.Text(
                      'Mitra Resmi RedDoorz | Property Management System (PMS)',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#4B5563')),
                    ),
                    pw.Text(
                      'Jl. Raya Sinar Harapan No. 88, Jawa Timur | Telp: (031) 8876543',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#6B7280')),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E6EBF7'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'DOKUMEN RESMI MANAJEMEN',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#001B4E'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Tanggal Cetak: $dateStr WIB', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Klasifikasi: Rahasia (UU PDP)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.red800)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#001B4E')),
            pw.SizedBox(height: 8),

            // ── Judul & KPI Cards ───────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'LAPORAN REKAPITULASI TRANSAKSI - $periodName',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Pendapatan: ${_currency.format(grandTotal)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#001B4E'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // KPI Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColor.fromHex('#E2E5EB')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total Transaksi: ${items.length}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('RedDoorz: $reddoorzCount unit', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('Walk-In: $walkInCount unit', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('Tamu Menginap: ${items.where((x) => x.status == "Menginap").length}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('Selesai Check-out: ${items.where((x) => x.status == "Selesai").length}', style: const pw.TextStyle(fontSize: 9.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Data Table ───────────────────────────────────────────────────
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E5EB'), width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#001B4E')),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headers: [
                'NO',
                'INVOICE',
                'KAMAR',
                'TIPE',
                'NAMA TAMU',
                'NO. WHATSAPP',
                'KANAL',
                'TOTAL BIAYA',
                'STATUS',
              ],
              data: items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return [
                  idx.toString(),
                  item.invoice,
                  'Kamar ${item.roomNumber}',
                  item.roomType,
                  item.guestName,
                  item.phone,
                  item.source,
                  _currency.format(item.totalAmount),
                  item.status,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 14),

            // ── Tanda Tangan & Pengesahan ─────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 320,
                  child: pw.Text(
                    'Catatan Hukum: Berkas ini sah dicetak dari Sinar Harapan Frontdesk & PMS. Data tamu dilindungi sesuai UU Perlindungan Data Pribadi (UU PDP).',
                    style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#6B7280'), fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mengetahui & Menyetujui,', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Property Manager Hotel Sinar Harapan', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 32),
                    pw.Text('( $managerName )', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('NIP: SH-MGR-2024-001', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    final fileName = 'Laporan_Resmi_Sinar_Harapan_September_2026.pdf';

    final savedPath = await saveWithPicker(
      bytes: bytes,
      defaultFileName: fileName,
      fileExtension: 'pdf',
      dialogTitle: 'Simpan Laporan Resmi Sinar Harapan PDF (.pdf)',
    );

    // Buka preview cetak jika didukung platform
    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}

    return savedPath;
  }

  /// Menyimpan berkas menggunakan dialog "Save As" OS atau fallback direktori Downloads
  static Future<String?> saveWithPicker({
    required Uint8List bytes,
    required String defaultFileName,
    required String fileExtension,
    required String dialogTitle,
  }) async {
    if (kIsWeb) {
      final uri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );
      return uri?.path ?? defaultFileName;
    }

    try {
      String? initialDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloads = Directory('$userProfile\\Downloads');
          if (downloads.existsSync()) {
            initialDir = downloads.path;
          }
        }
      }

      final uri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
        bytes: bytes,
        initialDirectory: initialDir,
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );

      // Jika user membatalkan (menekan Cancel pada dialog Save As)
      if (uri == null) {
        return null;
      }

      return uri.scheme == 'file' ? uri.toFilePath() : uri.path;
    } catch (_) {
      // Fallback jika dialog picker tidak didukung lingkungan headless/test
      return _saveDirectToDownloads(bytes: bytes, fileName: defaultFileName);
    }
  }

  static Future<String?> _saveDirectToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      String? dirPath;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloads = Directory('$userProfile\\Downloads');
          if (downloads.existsSync()) {
            dirPath = downloads.path;
          }
        }
      }
      dirPath ??= Directory.current.path;
      final file = File('$dirPath\\$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Membuka berkas langsung dengan aplikasi sistem default (Excel, PDF Viewer, dsb.)
  static Future<void> openFile(String filePath) async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', filePath]);
      }
    } catch (_) {}
  }

  /// Membuka folder yang memuat berkas di Windows Explorer
  static Future<void> openFolder(String filePath) async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      }
    } catch (_) {}
  }
}
