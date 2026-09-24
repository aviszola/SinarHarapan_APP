import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../room_management/domain/room_model.dart';
import '../../shared_widgets/app_button.dart';
import 'whatsapp_receipt_dialog.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final RoomModel room;
  final double roomTotal;
  final double lateFee;
  final double minibarFee;
  final double damageFee;
  final double grandTotal;
  final String receptionistName;
  final bool autoOpenWhatsApp;

  const InvoicePreviewDialog({
    super.key,
    required this.room,
    required this.roomTotal,
    required this.lateFee,
    required this.minibarFee,
    required this.damageFee,
    required this.grandTotal,
    required this.receptionistName,
    this.autoOpenWhatsApp = false,
  });

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
    final invoiceNumber = room.invoiceNumber ??
        'INV/SH/${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}/${room.roomNumber}';

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
                      'Faktur Pelunasan & Struk Kasir',
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
              if (autoOpenWhatsApp) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
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
                          const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Struk Digital Siap Dikirim ke WhatsApp Tamu',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF16A34A)),
                              ),
                              Text(
                                'Kirim bukti bayar resmi ke ${room.activeGuestPhone ?? "kontak WhatsApp tamu"}.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 13),
                        label: const Text('Kirim Sekarang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => WhatsAppReceiptDialog(
                              room: room,
                              roomTotal: roomTotal,
                              lateFee: lateFee,
                              minibarFee: minibarFee,
                              damageFee: damageFee,
                              grandTotal: grandTotal,
                              receptionistName: receptionistName,
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
                      color: Colors.white,
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
                                color: Colors.red.shade700,
                                borderRadius: AppRadius.roundedSm,
                              ),
                              child: const Text(
                                'RedDoorz\nOFFICIAL PARTNER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(thickness: 1.5, color: Colors.black54),
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
                                    room.activeGuestName ?? 'Tamu Walk-in',
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
                                    'Kamar ${room.roomNumber} (${room.bookingSource ?? 'WALK_IN'})',
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
                                    'Sewa Kamar ${room.roomNumber} (${room.roomType})',
                                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Check-in: ${room.checkInTime != null ? DateFormat('dd/MM HH:mm').format(room.checkInTime!) : "-"}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                              Text(
                                currencyFormatter.format(roomTotal),
                                style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // Item 2: Late Fee
                        if (lateFee > 0)
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
                                  currencyFormatter.format(lateFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        // Item 3: Minibar
                        if (minibarFee > 0)
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
                                  currencyFormatter.format(minibarFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        // Item 4: Damage Fee
                        if (damageFee > 0)
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
                                  currencyFormatter.format(damageFee),
                                  style: AppTypography.bodySm,
                                ),
                              ],
                            ),
                          ),

                        const Divider(thickness: 1.5, color: Colors.black54),

                        // Grand Total
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL PELUNASAN',
                                style: AppTypography.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy900,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(grandTotal),
                                style: AppTypography.h2.copyWith(
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
                            border: Border.all(color: const Color(0xFF16A34A)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'STATUS: LUNAS (PAID) • Resepsionis: $receptionistName',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF16A34A),
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
                    label: 'Tutup',
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
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              room: room,
                              roomTotal: roomTotal,
                              lateFee: lateFee,
                              minibarFee: minibarFee,
                              damageFee: damageFee,
                              grandTotal: grandTotal,
                              receptionistName: receptionistName,
                            ),
                          );
                        },
                      ),

                      AppButton(
                        label: 'Thermal Printer',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.print_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perintah cetak struk thermal 80mm dikirim ke printer kasir USB/Bluetooth...'),
                            ),
                          );
                        },
                      ),

                      // Exactly ONE primary orange CTA
                      AppButton(
                        label: 'Unduh Berkas PDF',
                        variant: AppButtonVariant.primary,
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.navy700,
                              content: Text('Mengunduh faktur resmi $invoiceNumber.pdf...'),
                            ),
                          );
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
