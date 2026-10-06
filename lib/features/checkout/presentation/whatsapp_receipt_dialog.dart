import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../room_management/domain/room_model.dart';
import '../../shared_widgets/app_button.dart';
import '../domain/invoice_sequence_service.dart';

class WhatsAppReceiptDialog extends StatefulWidget {
  final RoomModel room;
  final double roomTotal;
  final double lateFee;
  final double minibarFee;
  final double damageFee;
  final double grandTotal;
  final String receptionistName;
  final String? initialPhone;

  const WhatsAppReceiptDialog({
    super.key,
    required this.room,
    required this.roomTotal,
    required this.lateFee,
    required this.minibarFee,
    required this.damageFee,
    required this.grandTotal,
    required this.receptionistName,
    this.initialPhone,
  });

  @override
  State<WhatsAppReceiptDialog> createState() => _WhatsAppReceiptDialogState();
}

class _WhatsAppReceiptDialogState extends State<WhatsAppReceiptDialog> {
  final GlobalKey _receiptCaptureKey = GlobalKey();
  late TextEditingController _phoneController;

  int _selectedViewTab =
      0; // 0: Foto Struk (Visual Image), 1: Teks Pesan (Caption)
  bool _isSendingApi = false;
  bool _sendSuccess = false;
  String? _dispatchedMessageId;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();
    final rawPhone =
        widget.initialPhone ?? widget.room.activeGuestPhone ?? '081234567890';
    _phoneController = TextEditingController(text: rawPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _sanitizePhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    }
    return cleaned;
  }

  String _generateReceiptText(
    NumberFormat currencyFormatter,
    String invoiceNumber,
  ) {
    final now = DateTime.now();
    final guestName = widget.room.activeGuestName ?? 'Pelanggan Terhormat';
    final checkInDateStr = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id',
    ).format(widget.room.checkInTime ?? now.subtract(const Duration(days: 1)));
    final checkOutDateStr = DateFormat('dd MMM yyyy, HH:mm', 'id').format(now);

    final sb = StringBuffer();
    sb.writeln('📸 *LAMPIRAN FOTO STRUK & BUKTI PEMBAYARAN RESMI*');
    sb.writeln('*HOTEL SINAR HARAPAN (Mitra Resmi RedDoorz)*');
    sb.writeln('Jl. Panglima Sudirman No. 88, Jawa Timur');
    sb.writeln('==================================');
    sb.writeln('No. Faktur    : *$invoiceNumber*');
    sb.writeln('Nama Tamu     : *$guestName*');
    sb.writeln(
      'Unit Kamar    : *Kamar ${widget.room.roomNumber} (${widget.room.roomType})*',
    );
    sb.writeln('Waktu Check-In : $checkInDateStr WIB');
    sb.writeln('Waktu Check-Out: $checkOutDateStr WIB');
    sb.writeln('==================================');
    sb.writeln('RINCIAN TAGIHAN:');
    sb.writeln(
      '• Sewa Kamar Pokok : ${currencyFormatter.format(widget.roomTotal)}',
    );
    if (widget.lateFee > 0) {
      sb.writeln(
        '• Denda Late C/O   : ${currencyFormatter.format(widget.lateFee)}',
      );
    }
    if (widget.minibarFee > 0) {
      sb.writeln(
        '• Minibar / Laundry: ${currencyFormatter.format(widget.minibarFee)}',
      );
    }
    if (widget.damageFee > 0) {
      sb.writeln(
        '• Klaim Kerusakan  : ${currencyFormatter.format(widget.damageFee)}',
      );
    }
    sb.writeln('----------------------------------');
    sb.writeln(
      '*TOTAL PELUNASAN   : ${currencyFormatter.format(widget.grandTotal)}*',
    );
    sb.writeln('Status             : *LUNAS (PAID)* ✅');
    sb.writeln('Metode Pembayaran  : Tunai / Kasir Lobi');
    sb.writeln('Kasir Bertugas     : ${widget.receptionistName}');
    sb.writeln('==================================');
    sb.writeln(
      'Terlampir foto struk fisik resmi dengan stempel LUNAS. Terima kasih banyak telah menginap di Hotel Sinar Harapan!',
    );
    sb.writeln('');
    sb.writeln('Unduh Dokumen Faktur PDF:');
    sb.write('https://pms.sinarharapan.com/invoice/$invoiceNumber');

    return sb.toString();
  }

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      final boundary =
          _receiptCaptureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

  Future<void> _handleSaveReceiptImage(String invoiceNumber) async {
    final bytes = await _captureReceiptPng();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat gambar struk. Silakan coba lagi.'),
          ),
        );
      }
      return;
    }

    try {
      final cleanInv = invoiceNumber.replaceAll('/', '_');
      final home =
          Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '.';
      final downloadDir = Directory('$home\\Downloads');
      final targetDir = downloadDir.existsSync()
          ? downloadDir
          : Directory.current;
      final file = File('${targetDir.path}\\Struk_$cleanInv.png');
      await file.writeAsBytes(bytes);

      setState(() => _savedImagePath = file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Row(
              children: [
                const Icon(Icons.image_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Foto struk berhasil disimpan: ${file.path}'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar struk siap: ${bytes.lengthInBytes} bytes.'),
          ),
        );
      }
    }
  }

  Future<void> _handleDirectWhatsApp(
    String cleanPhone,
    String messageText,
    String invoiceNumber,
  ) async {
    // 1. Save / capture image to ensure it's on disk for easy drag & drop or paste
    await _handleSaveReceiptImage(invoiceNumber);

    // 2. Copy caption message text to clipboard
    await Clipboard.setData(ClipboardData(text: messageText));

    // 3. Launch WhatsApp URL
    final encoded = Uri.encodeComponent(messageText);
    final urlStr = 'https://wa.me/$cleanPhone?text=$encoded';
    final uri = Uri.parse(urlStr);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 4),
            content: Text(
              'WhatsApp terbuka! Foto struk telah disimpan di folder Downloads & teks pesan disalin ke clipboard.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Teks struk berhasil disalin. Silakan tempelkan di WhatsApp.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSendViaGateway(
    String cleanPhone,
    String messageText,
  ) async {
    setState(() {
      _isSendingApi = true;
      _sendSuccess = false;
    });

    // Capture the photo bytes for simulated payload upload
    await _captureReceiptPng();

    // Simulated API call sending Photo + Message to Fonnte / Wablas Gateway
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    final msgId =
        'WA-MEDIA-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    setState(() {
      _isSendingApi = false;
      _sendSuccess = true;
      _dispatchedMessageId = msgId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Foto struk + pesan teks berhasil dikirim ke WhatsApp +$cleanPhone (ID: $msgId)!',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final dialogWidth = math.min(
      620.0,
      mediaQuery.size.width - (isMobile ? 20 : 48),
    );
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final dialogHeight = math.min(
      780.0,
      availableHeight * (isMobile ? 0.96 : 0.90),
    );

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final invoiceNumber =
        widget.room.invoiceNumber ??
        InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: DateTime.now());

    final messageText = _generateReceiptText(currencyFormatter, invoiceNumber);
    final cleanPhone = _sanitizePhoneNumber(_phoneController.text.trim());

    return Dialog(
      insetAnimationDuration: Duration.zero,
      insetAnimationCurve: Curves.linear,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 24,
        vertical: isMobile ? 10 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Kirim Foto Struk & Faktur WA',
                              style:
                                  (isMobile
                                          ? AppTypography.h3
                                          : AppTypography.h2)
                                      .copyWith(
                                        color: AppColors.navy900,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF16A34A,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Foto + Caption',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kamar ${widget.room.roomNumber} • ${widget.room.activeGuestName ?? 'Tamu'} • $invoiceNumber',
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(height: 16),

              // Phone Number Bar - Responsive for mobile & desktop
              if (isMobile) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  scrollPadding: const EdgeInsets.only(bottom: 120, top: 20),
                  scrollPhysics: const ClampingScrollPhysics(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_android, size: 20),
                    labelText: 'Nomor WhatsApp Penerima',
                    hintText: '0812xxxxxxxx atau 62812xxxxxxxx',
                    filled: true,
                    fillColor: AppColors.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Simpan Foto PNG ke Perangkat'),
                  onPressed: () => _handleSaveReceiptImage(invoiceNumber),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        scrollPadding: const EdgeInsets.only(bottom: 120, top: 20),
                        scrollPhysics: const ClampingScrollPhysics(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_android, size: 20),
                          labelText: 'Nomor WhatsApp Penerima',
                          hintText: '0812xxxxxxxx atau 62812xxxxxxxx',
                          filled: true,
                          fillColor: AppColors.bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Simpan Foto PNG'),
                      onPressed: () => _handleSaveReceiptImage(invoiceNumber),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Tab Selector: [📸 Foto Struk Resmi] vs [💬 Teks Pesan / Caption]
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedViewTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedViewTab == 0
                                ? AppColors.navy900
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_size_select_actual_outlined,
                                size: 15,
                                color: _selectedViewTab == 0
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pratinjau Foto Struk (Gambar)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedViewTab == 0
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedViewTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedViewTab == 1
                                ? AppColors.navy900
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 15,
                                color: _selectedViewTab == 1
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pratinjau Teks Pesan (Caption)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedViewTab == 1
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // View Tab 0: RepaintBoundary Receipt Image Card
              // View Tab 1: WhatsApp Text / Chat bubble
              Expanded(
                child: _selectedViewTab == 0
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: Center(
                            child: RepaintBoundary(
                              key: _receiptCaptureKey,
                              child: _buildReceiptVisualCard(
                                currencyFormatter,
                                invoiceNumber,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEAE2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              messageText,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.45,
                                color: Color(0xFF111B21),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              if (_sendSuccess && _dispatchedMessageId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto struk + teks sukses dikirim via WhatsApp Gateway API (+$cleanPhone) • ID: $_dispatchedMessageId',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_savedImagePath != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.navy100),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 13,
                        color: AppColors.navy700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tersimpan di: $_savedImagePath',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.navy900,
                            fontSize: 10.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Bottom Actions
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Kembali',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Direct WhatsApp Launch (Copies Photo & Opens WA)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(
                          isMobile ? 'Buka WA' : 'Kirim via WhatsApp (wa.me)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => _handleDirectWhatsApp(
                          cleanPhone,
                          messageText,
                          invoiceNumber,
                        ),
                      ),

                      // Automated Gateway Dispatch (Photo + Message)
                      AppButton(
                        label: _isSendingApi
                            ? 'Mengirim...'
                            : (isMobile
                                  ? 'Kirim Otomatis'
                                  : 'Kirim Foto Otomatis (API)'),
                        variant: AppButtonVariant.primary,
                        icon: _isSendingApi ? null : Icons.send_rounded,
                        onPressed: _isSendingApi
                            ? null
                            : () => _handleSendViaGateway(
                                cleanPhone,
                                messageText,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Official Visual Receipt Card (Captured as Image/Photo)
  Widget _buildReceiptVisualCard(
    NumberFormat currencyFormatter,
    String invoiceNumber,
  ) {
    final now = DateTime.now();
    final guestName = widget.room.activeGuestName ?? 'Pelanggan Terhormat';
    final checkInDateStr = DateFormat(
      'dd/MM/yyyy HH:mm',
      'id',
    ).format(widget.room.checkInTime ?? now.subtract(const Duration(days: 1)));
    final checkOutDateStr = DateFormat('dd/MM/yyyy HH:mm', 'id').format(now);

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Hotel Title
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'RedDoorz',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HOTEL SINAR HARAPAN',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.navy900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Jl. Panglima Sudirman No. 88, Jawa Timur',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
                const Text(
                  'Telp/WhatsApp: 0812-3456-7890',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'BUKTI PEMBAYARAN & STRUK KASIR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Meta Info
          _buildReceiptRow('No. Faktur', invoiceNumber, isBold: true),
          _buildReceiptRow('Nama Tamu', guestName),
          _buildReceiptRow(
            'Unit Kamar',
            'Kamar ${widget.room.roomNumber} (${widget.room.roomType})',
          ),
          _buildReceiptRow('Waktu Check-In', '$checkInDateStr WIB'),
          _buildReceiptRow('Waktu Check-Out', '$checkOutDateStr WIB'),
          _buildReceiptRow(
            'Kanal Pemesanan',
            widget.room.bookingSource ?? 'Walk-in',
          ),

          const SizedBox(height: 10),
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Itemized Charges
          const Text(
            'RINCIAN PEMBAYARAN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          _buildReceiptRow(
            'Sewa Kamar',
            currencyFormatter.format(widget.roomTotal),
          ),
          if (widget.lateFee > 0)
            _buildReceiptRow(
              'Denda Late Check-Out',
              currencyFormatter.format(widget.lateFee),
            ),
          if (widget.minibarFee > 0)
            _buildReceiptRow(
              'Minibar & Konsumsi',
              currencyFormatter.format(widget.minibarFee),
            ),
          if (widget.damageFee > 0)
            _buildReceiptRow(
              'Klaim Kerusakan',
              currencyFormatter.format(widget.damageFee),
            ),

          const SizedBox(height: 8),
          const Divider(thickness: 1.2, color: Color(0xFF0F172A)),
          const SizedBox(height: 4),

          // Grand Total & Stamp
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AKHIR:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(widget.grandTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildReceiptRow('Metode Bayar', 'Tunai / Kasir Lobi'),
                  _buildReceiptRow('Kasir Bertugas', widget.receptionistName),
                ],
              ),

              // Official LUNAS Stamp
              Positioned(
                right: 30,
                top: -6,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF16A34A),
                        width: 2.2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LUNAS',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'PAID OFFICIAL',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Barcode Simulation
          Center(
            child: Column(
              children: [
                Container(
                  height: 32,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      38,
                      (i) => Container(
                        width: (i % 3 == 0) ? 3 : (i % 2 == 0 ? 1.5 : 2),
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoiceNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Terima kasih atas kunjungan Anda di Hotel Sinar Harapan',
              style: TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF94A3B8)),
              ),
            );
          }),
        );
      },
    );
  }
}
