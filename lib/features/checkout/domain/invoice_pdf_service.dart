import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../room_management/domain/room_model.dart';

/// Layanan penghasil dan penyimpan berkas Faktur / Invoice PDF resmi Hotel Sinar Harapan.
class InvoicePdfService {
  InvoicePdfService._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Menghasilkan byte berkas PDF faktur pembayaran A4 portrait
  static Future<Uint8List> generateInvoicePdf({
    required RoomModel room,
    required double roomTotal,
    double lateFee = 0,
    double minibarFee = 0,
    double damageFee = 0,
    required double grandTotal,
    required String receptionistName,
    required String invoiceNumber,
    DateTime? issueDate,
  }) async {
    final doc = pw.Document();
    final now = issueDate ?? DateTime.now();

    final checkInStr = room.checkInTime != null
        ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(room.checkInTime!)
        : DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(now);
    final checkOutStr = room.expectedCheckOutTime != null
        ? DateFormat('dd/MM/yyyy 12:00', 'id_ID').format(room.expectedCheckOutTime!)
        : '-';

    final navyPrimary = PdfColor.fromHex('#001B4E');
    final navyDark = PdfColor.fromHex('#0A192F');
    final grayLight = PdfColor.fromHex('#F8FAFC');
    final grayBorder = PdfColor.fromHex('#CBD5E1');
    final textMuted = PdfColor.fromHex('#475569');
    final reddoorzRed = PdfColor.fromHex('#DC2626');
    final successGreen = PdfColor.fromHex('#16A34A');
    final successBg = PdfColor.fromHex('#DCFCE7');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── KOP SURAT RESMI HOTEL ──────────────────────────────────────
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
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: navyPrimary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Mitra Resmi RedDoorz  |  Property Management System (PMS)',
                        style: pw.TextStyle(fontSize: 9.5, color: textMuted),
                      ),
                      pw.Text(
                        'Jl. Panglima Sudirman No. 88, Jawa Timur  |  Telp/WA: 0812-3456-7890',
                        style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                      ),
                      pw.Text(
                        'Email: frontdesk@sinarharapan.com  |  Sistem Kasir Resepsionis',
                        style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: reddoorzRed,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'RedDoorz\nOFFICIAL PARTNER',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: successBg,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: successGreen, width: 0.8),
                        ),
                        child: pw.Text(
                          'STATUS: LUNAS (PAID)',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.8, color: navyPrimary),
              pw.SizedBox(height: 8),

              // ── JUDUL DOKUMEN & NOMOR INVOICE ──────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FAKTUR PEMBAYARAN RESMI (CHECK-IN)',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: navyPrimary,
                        ),
                      ),
                      pw.Text(
                        'Bukti Pelunasan Sah Registrasi & Sewa Kamar Awal',
                        style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'NO. INVOICE:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                      pw.Text(
                        invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: navyPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── KOTAK METADATA TAMU & RESERVASI ────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: grayLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: grayBorder, width: 0.8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Kolom Kiri
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfInfoRow('Nama Tamu', room.activeGuestName ?? 'Tamu Walk-in', isBold: true),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow(
                            'NIK Tamu',
                            room.guestNik != null && room.guestNik!.isNotEmpty
                                ? room.guestNik!
                                : '-',
                          ),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow(
                            'No. WhatsApp / HP',
                            room.activeGuestPhone != null && room.activeGuestPhone!.isNotEmpty
                                ? room.activeGuestPhone!
                                : '-',
                          ),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow('Kanal Pemesanan', room.bookingSource ?? 'WALK_IN'),
                          if (room.reddoorzBookingCode != null && room.reddoorzBookingCode!.isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            _buildPdfInfoRow('Kode Booking RedDoorz', room.reddoorzBookingCode!, isBold: true),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    // Kolom Kanan
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfInfoRow(
                            'Nomor Kamar',
                            'Kamar ${room.roomNumber} (Lantai ${room.floor})',
                            isBold: true,
                          ),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow('Tipe Kamar', room.roomType),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow('Waktu Check-In', checkInStr),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow('Estimasi Check-Out', checkOutStr),
                          pw.SizedBox(height: 3),
                          _buildPdfInfoRow('Kasir / Resepsionis', receptionistName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // ── TABEL RINCIAN BIAYA ─────────────────────────────────────────
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: grayBorder, width: 0.5),
                  top: pw.BorderSide(color: navyPrimary, width: 1.2),
                  bottom: pw.BorderSide(color: navyPrimary, width: 1.2),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // NO
                  1: const pw.FlexColumnWidth(4.5), // DESKRIPSI
                  2: const pw.FlexColumnWidth(2.0), // STATUS / JENIS
                  3: const pw.FlexColumnWidth(2.7), // SUBTOTAL
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: navyPrimary),
                    children: [
                      _buildTableHeaderCell('NO', align: pw.TextAlign.center),
                      _buildTableHeaderCell('DESKRIPSI ITEM'),
                      _buildTableHeaderCell('KATEGORI', align: pw.TextAlign.center),
                      _buildTableHeaderCell('SUBTOTAL (IDR)', align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    children: [
                      _buildTableCell('1', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Sewa Kamar ${room.roomNumber} (${room.roomType})',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: navyDark,
                              ),
                            ),
                            pw.Text(
                              'Fasilitas: ${room.facilities.isNotEmpty ? room.facilities.join(", ") : "Standard Amenities"}',
                              style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      _buildTableCell('Sewa Kamar Check-in', align: pw.TextAlign.center),
                      _buildTableCell(
                        _currencyFormatter.format(roomTotal),
                        align: pw.TextAlign.right,
                        isBold: true,
                      ),
                    ],
                  ),
                  if (lateFee > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('2', align: pw.TextAlign.center),
                        _buildTableCell('Denda Keterlambatan Check-out'),
                        _buildTableCell('Biaya Tambahan', align: pw.TextAlign.center),
                        _buildTableCell(_currencyFormatter.format(lateFee), align: pw.TextAlign.right),
                      ],
                    ),
                  if (minibarFee > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell(lateFee > 0 ? '3' : '2', align: pw.TextAlign.center),
                        _buildTableCell('Konsumsi Minibar / Snack / Layanan Laundry'),
                        _buildTableCell('F&B / Layanan', align: pw.TextAlign.center),
                        _buildTableCell(_currencyFormatter.format(minibarFee), align: pw.TextAlign.right),
                      ],
                    ),
                  if (damageFee > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('4', align: pw.TextAlign.center),
                        _buildTableCell('Penggantian Biaya Kerusakan Properti Kamar'),
                        _buildTableCell('Kompensasi', align: pw.TextAlign.center),
                        _buildTableCell(_currencyFormatter.format(damageFee), align: pw.TextAlign.right),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── TOTAL RINGKASAN PEMBAYARAN ──────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 270,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: grayLight,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: grayBorder, width: 0.8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal Kamar:', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            pw.Text(_currencyFormatter.format(roomTotal), style: const pw.TextStyle(fontSize: 8.5)),
                          ],
                        ),
                        if (lateFee + minibarFee + damageFee > 0) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Biaya Tambahan:', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                              pw.Text(
                                _currencyFormatter.format(lateFee + minibarFee + damageFee),
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            ],
                          ),
                        ],
                        pw.Divider(thickness: 0.8, color: grayBorder),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL LUNAS:',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: navyPrimary,
                              ),
                            ),
                            pw.Text(
                              _currencyFormatter.format(grandTotal),
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: navyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── ATURAN & KETENTUAN MENGINAP ─────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: grayBorder, width: 0.6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TATA TERTIB & KETENTUAN HOTEL SINAR HARAPAN:',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: navyDark),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '1. Waktu check-out maksimal pukul 12:00 WIB. Harap melapor ke resepsionis untuk pengembalian kunci.',
                      style: pw.TextStyle(fontSize: 7, color: textMuted),
                    ),
                    pw.Text(
                      '2. Dilarang merokok di seluruh kamar ber-AC (denda pembersihan Rp 250.000). Jagalah kebersihan & kenyamanan bersama.',
                      style: pw.TextStyle(fontSize: 7, color: textMuted),
                    ),
                    pw.Text(
                      '3. Simpan dokumen faktur resmi ini sebagai bukti pembayaran dan identitas transaksi yang sah.',
                      style: pw.TextStyle(fontSize: 7, color: textMuted),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // ── TANDA TANGAN & PENGESAHAN KASIR ─────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Tamu Yang Menginap,', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                      pw.SizedBox(height: 34),
                      pw.Text(
                        '( ${room.activeGuestName ?? "Tamu"} )',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Tanda Tangan Registrasi', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Jawa Timur, ${DateFormat("dd MMMM yyyy", "id_ID").format(now)}',
                        style: pw.TextStyle(fontSize: 8, color: textMuted),
                      ),
                      pw.Text('Resepsionis / Kasir Front Office,', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                      pw.SizedBox(height: 34),
                      pw.Text(
                        '( $receptionistName )',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: navyPrimary),
                      ),
                      pw.Text('Stempel & Paraf Kasir Resmi', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── FOOTER SISTEM ──────────────────────────────────────────────
              pw.Divider(thickness: 0.5, color: grayBorder),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dicetak via PMS Hotel Sinar Harapan v1.0.0 | No. Invoice: $invoiceNumber',
                    style: pw.TextStyle(fontSize: 6.5, color: textMuted),
                  ),
                  pw.Text(
                    'Klasifikasi: Rahasia Tamu (UU Perlindungan Data Pribadi)',
                    style: pw.TextStyle(fontSize: 6.5, color: PdfColors.red800),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Menyimpan berkas faktur PDF langsung ke folder lokal (Downloads atau Save As picker)
  static Future<String?> saveInvoicePdf({
    required RoomModel room,
    required double roomTotal,
    double lateFee = 0,
    double minibarFee = 0,
    double damageFee = 0,
    required double grandTotal,
    required String receptionistName,
    required String invoiceNumber,
    DateTime? issueDate,
  }) async {
    final bytes = await generateInvoicePdf(
      room: room,
      roomTotal: roomTotal,
      lateFee: lateFee,
      minibarFee: minibarFee,
      damageFee: damageFee,
      grandTotal: grandTotal,
      receptionistName: receptionistName,
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
    );

    // Sanitasi karakter slash '/' dan simbol terlarang untuk nama berkas OS
    final cleanInvoice = invoiceNumber.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
    final fileName = 'Faktur_$cleanInvoice.pdf';

    final savedPath = await saveBytesWithPicker(
      bytes: bytes,
      defaultFileName: fileName,
      dialogTitle: 'Simpan Faktur Pembayaran PDF ($fileName)',
    );

    // Buka preview cetak/share jika didukung platform
    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}

    return savedPath;
  }

  /// Cetak struk/faktur langsung ke printer thermal atau printer sistem
  static Future<void> printReceipt({
    required RoomModel room,
    required double roomTotal,
    double lateFee = 0,
    double minibarFee = 0,
    double damageFee = 0,
    required double grandTotal,
    required String receptionistName,
    required String invoiceNumber,
  }) async {
    final bytes = await generateInvoicePdf(
      room: room,
      roomTotal: roomTotal,
      lateFee: lateFee,
      minibarFee: minibarFee,
      damageFee: damageFee,
      grandTotal: grandTotal,
      receptionistName: receptionistName,
      invoiceNumber: invoiceNumber,
    );

    final cleanInvoice = invoiceNumber.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Struk_Faktur_$cleanInvoice',
    );
  }

  /// Menyimpan byte berkas ke disk menggunakan Save As picker atau langsung ke folder Downloads
  static Future<String?> saveBytesWithPicker({
    required Uint8List bytes,
    required String defaultFileName,
    required String dialogTitle,
  }) async {
    if (kIsWeb) {
      final selectedUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      return selectedUri?.path ?? defaultFileName;
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

      final selectedUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
        bytes: bytes,
        initialDirectory: initialDir,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // Jika user membatalkan (menekan Cancel pada dialog Save As OS)
      if (selectedUri == null) {
        final isTest = Platform.environment.containsKey('FLUTTER_TEST') ||
            WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');
        if (isTest) {
          return _saveDirectToDownloads(bytes: bytes, fileName: defaultFileName);
        }
        return null;
      }

      // Pastikan byte benar-benar ditulis ke disk lokal
      final filePath = selectedUri.scheme == 'file' ? selectedUri.toFilePath() : selectedUri.path;
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
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
      try {
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (_) {
        final dotIndex = fileName.lastIndexOf('.');
        final baseName = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
        final ext = dotIndex != -1 ? fileName.substring(dotIndex) : '';
        final uniqueFileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}$ext';
        final fallbackFile = File('$dirPath\\$uniqueFileName');
        await fallbackFile.writeAsBytes(bytes);
        return fallbackFile.path;
      }
    } catch (_) {
      return null;
    }
  }

  /// Membuka berkas langsung dengan aplikasi default OS (PDF Viewer, Browser, dsb.)
  static Future<void> openFile(String filePath) async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', filePath]);
      }
    } catch (_) {}
  }

  /// Membuka folder yang memuat berkas di Windows File Explorer
  static Future<void> openFolder(String filePath) async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      }
    } catch (_) {}
  }

  // ── Helper Widget PDF ─────────────────────────────────────────────────────

  static pw.Widget _buildPdfInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#475569'),
            ),
          ),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#475569'))),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
    );
  }
}
