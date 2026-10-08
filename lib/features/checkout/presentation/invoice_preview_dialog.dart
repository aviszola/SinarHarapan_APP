import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../room_management/domain/room_model.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_feedback.dart';
import '../domain/invoice_pdf_service.dart';
import '../domain/invoice_sequence_service.dart';
import 'whatsapp_receipt_dialog.dart';

class InvoicePreviewDialog extends StatefulWidget {
  final RoomModel room;
  final double roomTotal;
  final double lateFee;
  final double minibarFee;
  final double damageFee;
  final double grandTotal;
  final String receptionistName;
  final bool autoOpenWhatsApp;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback? onConfirmCheckIn;

  const InvoicePreviewDialog({
    super.key,
    required this.room,
    required this.roomTotal,
    this.lateFee = 0,
    this.minibarFee = 0,
    this.damageFee = 0,
    required this.grandTotal,
    required this.receptionistName,
    this.autoOpenWhatsApp = false,
    this.customTitle,
    this.customSubtitle,
    this.onConfirmCheckIn,
  });

  @override
  State<InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<InvoicePreviewDialog> {
  bool _isDownloadingPdf = false;
  bool _isPrinting = false;

  Future<void> _handleDownloadPdf(String invoiceNumber) async {
    if (_isDownloadingPdf) return;
    setState(() => _isDownloadingPdf = true);

    try {
      final savedPath = await InvoicePdfService.saveInvoicePdf(
        room: widget.room,
        roomTotal: widget.roomTotal,
        lateFee: widget.lateFee,
        minibarFee: widget.minibarFee,
        damageFee: widget.damageFee,
        grandTotal: widget.grandTotal,
        receptionistName: widget.receptionistName,
        invoiceNumber: invoiceNumber,
      );

      if (!mounted) return;

      if (savedPath == null) {
        AppFeedback.showInfo(
          context,
          title: 'Pengunduhan Dibatalkan',
          message: 'Penyimpanan dokumen faktur PDF dibatalkan oleh pengguna.',
        );
        return;
      }

      final fileName = savedPath.split(RegExp(r'[\\/]')).last;

      _showDownloadSuccessDialog(savedPath, fileName);

      AppFeedback.showSuccess(
        context,
        title: 'Faktur PDF Tersimpan',
        message: fileName,
        actionLabel: 'BUKA',
        onAction: () => InvoicePdfService.openFile(savedPath),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Gagal Mengunduh PDF',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  Future<void> _handlePrint(String invoiceNumber) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await InvoicePdfService.printReceipt(
        room: widget.room,
        roomTotal: widget.roomTotal,
        lateFee: widget.lateFee,
        minibarFee: widget.minibarFee,
        damageFee: widget.damageFee,
        grandTotal: widget.grandTotal,
        receptionistName: widget.receptionistName,
        invoiceNumber: invoiceNumber,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Gagal Membuka Printer',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showDownloadSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.availableBg,
                borderRadius: AppRadius.rounded,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.statusAvailable, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Faktur PDF Tersimpan!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dokumen faktur resmi berhasil diunduh dan tersimpan ke perangkat lokal Anda:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: AppRadius.rounded,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filePath,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: const Text('Buka Folder'),
            onPressed: () {
              InvoicePdfService.openFolder(filePath);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy700,
              foregroundColor: AppColors.white,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Buka Berkas PDF'),
            onPressed: () {
              InvoicePdfService.openFile(filePath);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final dialogWidth = math.min(600.0, mediaQuery.size.width - (isMobile ? 20 : 48));
    final dialogHeight = math.min(760.0, mediaQuery.size.height * (isMobile ? 0.95 : 0.88));

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final now = DateTime.now();
    final invoiceNumber = widget.room.invoiceNumber ??
        InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: now);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: dialogHeight),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.customTitle ?? 'Faktur Pembayaran & Struk Kasir (Check-In)',
                      style: (isMobile ? AppTypography.h3 : AppTypography.h2).copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(height: 16),

              // WhatsApp Prompt Banner if autoOpenWhatsApp is true
              if (widget.autoOpenWhatsApp) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.availableBg,
                    borderRadius: AppRadius.rounded,
                    border: Border.all(color: AppColors.statusAvailable.withValues(alpha: 0.4)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mark_chat_read_rounded, color: AppColors.statusAvailable, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Struk Digital Siap Dikirim ke WhatsApp Tamu',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.availableText),
                              ),
                              Text(
                                'Kirim bukti bayar resmi ke ${widget.room.activeGuestPhone ?? "kontak WhatsApp tamu"}.',
                                style: const TextStyle(fontSize: 11, color: AppColors.availableDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusAvailable,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 13),
                        label: const Text('Kirim Sekarang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => WhatsAppReceiptDialog(
                              room: widget.room,
                              roomTotal: widget.roomTotal,
                              lateFee: widget.lateFee,
                              minibarFee: widget.minibarFee,
                              damageFee: widget.damageFee,
                              grandTotal: widget.grandTotal,
                              receptionistName: widget.receptionistName,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Printable Formal Thermal/Invoice Box
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.navy900, width: 1.5),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Official Letterhead
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOTEL SINAR HARAPAN',
                                  style: AppTypography.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: AppColors.navy900,
                                  ),
                                ),
                                Text(
                                  'Jl. Panglima Sudirman No. 88, Jawa Timur',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  'Telp/WA: 0812-3456-7890 • frontdesk@sinarharapan.com',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandOrange,
                                borderRadius: AppRadius.roundedSm,
                              ),
                              child: const Text(
                                'RedDoorz\nOFFICIAL PARTNER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(thickness: 1.5, color: AppColors.border),
                        const SizedBox(height: 8),

                        // Metadata Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NO. INVOICE:', style: AppTypography.overline),
                                  Text(
                                    invoiceNumber,
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('NAMA TAMU:', style: AppTypography.overline),
                                  Text(
                                    widget.room.activeGuestName ?? 'Tidak tercatat',
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('TANGGAL CETAK:', style: AppTypography.overline),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(now),
                                    style: AppTypography.bodySm,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('KAMAR & KANAL:', style: AppTypography.overline),
                                  Text(
                                    'Kamar ${widget.room.roomNumber} (${widget.room.bookingSource ?? 'WALK_IN'})',
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(thickness: 1, color: AppColors.border),

                        // Itemized Table Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('DESKRIPSI ITEM', style: AppTypography.overline),
                              Text('SUBTOTAL', style: AppTypography.overline),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, color: AppColors.border),

                        // Item 1: Room Rent
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sewa Kamar ${widget.room.roomNumber} (${widget.room.roomType})',
                                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Check-in: ${widget.room.checkInTime != null ? DateFormat('dd/MM HH:mm').format(widget.room.checkInTime!) : "-"}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                              Text(
                                currencyFormatter.format(widget.roomTotal),
                                style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // Item 2: Late Fee
                        if (widget.lateFee > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Denda Keterlambatan Check-out',
                                  style: AppTypography.bodySm,
                                ),
                                Text(
                                  currencyFormatter.format(widget.lateFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        // Item 3: Minibar
                        if (widget.minibarFee > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Konsumsi Minibar / Snack / Laundry',
                                  style: AppTypography.bodySm,
                                ),
                                Text(
                                  currencyFormatter.format(widget.minibarFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        // Item 4: Damage Fee
                        if (widget.damageFee > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Penggantian Kerusakan Properti',
                                  style: AppTypography.bodySm,
                                ),
                                Text(
                                  currencyFormatter.format(widget.damageFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        const Divider(thickness: 1.5, color: AppColors.border),

                        // Grand Total
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'TOTAL PEMBAYARAN',
                                  style: (isMobile ? AppTypography.bodySm : AppTypography.h3).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currencyFormatter.format(widget.grandTotal),
                                style: (isMobile ? AppTypography.h3 : AppTypography.h2).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Payment Status Stamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccessBg,
                            borderRadius: AppRadius.roundedSm,
                            border: Border.all(color: AppColors.statusAvailable),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.statusAvailable),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'STATUS: LUNAS (PAID) • Biaya sewa kamar dibayar saat check-in • Resepsionis: ${widget.receptionistName}',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.statusAvailable,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Terima kasih telah memilih Hotel Sinar Harapan & RedDoorz.\nSemoga perjalanan Anda menyenangkan!',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons - Responsive Wrap for mobile, iPad, and desktop
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: widget.onConfirmCheckIn != null ? 'Kembali ke Form' : 'Tutup',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // WhatsApp Struk Dispatch CTA
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsapp,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.rounded),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text(
                          'Kirim ke WA',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => WhatsAppReceiptDialog(
                              room: widget.room,
                              roomTotal: widget.roomTotal,
                              lateFee: widget.lateFee,
                              minibarFee: widget.minibarFee,
                              damageFee: widget.damageFee,
                              grandTotal: widget.grandTotal,
                              receptionistName: widget.receptionistName,
                            ),
                          );
                        },
                      ),

                      AppButton(
                        label: 'Thermal Printer',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.print_outlined,
                        isLoading: _isPrinting,
                        onPressed: _isPrinting ? null : () => _handlePrint(invoiceNumber),
                      ),

                      // Download PDF (Menyimpan berkas PDF faktur ke penyimpanan lokal)
                      AppButton(
                        label: 'Unduh PDF',
                        variant: widget.onConfirmCheckIn != null ? AppButtonVariant.secondary : AppButtonVariant.primary,
                        icon: Icons.picture_as_pdf_outlined,
                        isLoading: _isDownloadingPdf,
                        onPressed: _isDownloadingPdf ? null : () => _handleDownloadPdf(invoiceNumber),
                      ),

                      // If check-in confirmation flow
                      if (widget.onConfirmCheckIn != null)
                        AppButton(
                          label: 'Konfirmasi Lunas & Masuk Kamar',
                          variant: AppButtonVariant.primary,
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onConfirmCheckIn!();
                          },
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
}
