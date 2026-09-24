import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../room_management/domain/room_model.dart';
import '../../room_management/presentation/room_controller.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import 'invoice_preview_dialog.dart';

class CheckOutDialog extends ConsumerStatefulWidget {
  final RoomModel room;

  const CheckOutDialog({super.key, required this.room});

  @override
  ConsumerState<CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends ConsumerState<CheckOutDialog> {
  final _lateFeeController = TextEditingController(text: '0');
  final _minibarFeeController = TextEditingController(text: '0');
  final _damageFeeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  double _roomSubtotal = 0;
  bool _isLate = false;
  int _lateHours = 0;
  bool _sendWaReceipt = true;

  @override
  void initState() {
    super.initState();
    _calculateInitial();
  }

  void _calculateInitial() {
    // Default 1 night if checkInTime is missing
    final checkIn = widget.room.checkInTime ?? DateTime.now().subtract(const Duration(hours: 20));
    final expectedOut = widget.room.expectedCheckOutTime ?? DateTime.now().add(const Duration(hours: 2));

    final diffDays = expectedOut.difference(checkIn).inDays;
    final nights = diffDays > 0 ? diffDays : 1;
    _roomSubtotal = nights * widget.room.basePricePerNight;

    // Check if late checkout (FR-OUT-05)
    final now = DateTime.now();
    if (now.isAfter(expectedOut)) {
      _isLate = true;
      _lateHours = now.difference(expectedOut).inHours;
      if (_lateHours == 0) _lateHours = 1; // Round up to 1 hr
      // Standard late fee Rp 50.000 / hour
      _lateFeeController.text = (_lateHours * 50000).toString();
    }
  }

  @override
  void dispose() {
    _lateFeeController.dispose();
    _minibarFeeController.dispose();
    _damageFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _lateFee => double.tryParse(_lateFeeController.text.trim()) ?? 0;
  double get _minibarFee => double.tryParse(_minibarFeeController.text.trim()) ?? 0;
  double get _damageFee => double.tryParse(_damageFeeController.text.trim()) ?? 0;
  double get _additionalTotal => _lateFee + _minibarFee + _damageFee;
  double get _grandTotal => _roomSubtotal + _additionalTotal;

  void _handleConfirmCheckOut() async {
    final authState = ref.read(authStateProvider);
    final receptionistName = authState.user?.fullName ?? 'Siti Rahmawati';

    // Update room status to DIRTY (needs cleaning per FR-OUT-04)
    await ref.read(roomListProvider.notifier).checkOut(
          roomId: widget.room.id,
          additionalCharges: _additionalTotal,
        );

    if (mounted) {
      Navigator.of(context).pop();

      // Show Invoice Preview Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InvoicePreviewDialog(
          room: widget.room,
          roomTotal: _roomSubtotal,
          lateFee: _lateFee,
          minibarFee: _minibarFee,
          damageFee: _damageFee,
          grandTotal: _grandTotal,
          receptionistName: receptionistName,
          autoOpenWhatsApp: _sendWaReceipt,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final dialogWidth = math.min(620.0, mediaQuery.size.width - (isMobile ? 20 : 48));
    final dialogHeight = math.min(740.0, mediaQuery.size.height * (isMobile ? 0.95 : 0.90));

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusOccupied.withAlpha(25),
                            borderRadius: AppRadius.roundedSm,
                          ),
                          child: Text(
                            'Kamar ${widget.room.roomNumber}',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.statusOccupied,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Proses Check-Out Tamu',
                            style: (isMobile ? AppTypography.h3 : AppTypography.h2).copyWith(color: AppColors.navy900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Guest Card Summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.room.activeGuestName ?? 'Tamu Walk-in',
                                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.room.bookingSource == 'REDDOORZ'
                                        ? Colors.red.shade100
                                        : AppColors.navy100,
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Text(
                                    widget.room.bookingSource ?? 'WALK_IN',
                                    style: AppTypography.overline.copyWith(
                                      color: widget.room.bookingSource == 'REDDOORZ'
                                          ? Colors.red.shade800
                                          : AppColors.navy700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'WhatsApp: ${widget.room.activeGuestPhone ?? "-"} • Tipe: ${widget.room.roomType} (Lt. ${widget.room.floor})',
                              style: AppTypography.caption,
                            ),
                            if (widget.room.checkInTime != null)
                              Text(
                                'Check-in: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.room.checkInTime!)} WIB',
                                style: AppTypography.caption,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Late checkout alert if detected
                      if (_isLate)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.statusWarningBg,
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(color: const Color(0xFFD97706)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Terlambat check-out $_lateHours jam melebihi batas 12:00 WIB. Dikenakan denda late check-out otomatis.',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Biaya Tambahan / Insidental (Opsional)',
                        style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      if (isMobile) ...[
                        AppTextField(
                          label: 'Denda Late Check-Out (Rp)',
                          controller: _lateFeeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.access_time_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildQuickAddChip('+1 Jam (50rb)', () {
                              final cur = double.tryParse(_lateFeeController.text) ?? 0;
                              setState(() => _lateFeeController.text = (cur + 50000).toInt().toString());
                            }),
                            _buildQuickAddChip('+2 Jam (100rb)', () {
                              final cur = double.tryParse(_lateFeeController.text) ?? 0;
                              setState(() => _lateFeeController.text = (cur + 100000).toInt().toString());
                            }),
                            _buildQuickAddChip('Bebas Denda', () {
                              setState(() => _lateFeeController.text = '0');
                            }),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          label: 'Minibar / Laundry (Rp)',
                          controller: _minibarFeeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.local_bar_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildQuickAddChip('+Air Min. (5rb)', () {
                              final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                              setState(() => _minibarFeeController.text = (cur + 5000).toInt().toString());
                            }),
                            _buildQuickAddChip('+Snack (15rb)', () {
                              final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                              setState(() => _minibarFeeController.text = (cur + 15000).toInt().toString());
                            }),
                            _buildQuickAddChip('+Laundry (25rb)', () {
                              final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                              setState(() => _minibarFeeController.text = (cur + 25000).toInt().toString());
                            }),
                            _buildQuickAddChip('Reset', () {
                              setState(() => _minibarFeeController.text = '0');
                            }),
                          ],
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Denda Late Check-Out (Rp)',
                                    controller: _lateFeeController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.access_time_rounded,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildQuickAddChip('+1 Jam (50rb)', () {
                                        final cur = double.tryParse(_lateFeeController.text) ?? 0;
                                        setState(() => _lateFeeController.text = (cur + 50000).toInt().toString());
                                      }),
                                      _buildQuickAddChip('+2 Jam (100rb)', () {
                                        final cur = double.tryParse(_lateFeeController.text) ?? 0;
                                        setState(() => _lateFeeController.text = (cur + 100000).toInt().toString());
                                      }),
                                      _buildQuickAddChip('Bebas Denda', () {
                                        setState(() => _lateFeeController.text = '0');
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Minibar / Laundry (Rp)',
                                    controller: _minibarFeeController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.local_bar_outlined,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildQuickAddChip('+Air Min. (5rb)', () {
                                        final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                                        setState(() => _minibarFeeController.text = (cur + 5000).toInt().toString());
                                      }),
                                      _buildQuickAddChip('+Snack (15rb)', () {
                                        final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                                        setState(() => _minibarFeeController.text = (cur + 15000).toInt().toString());
                                      }),
                                      _buildQuickAddChip('+Laundry (25rb)', () {
                                        final cur = double.tryParse(_minibarFeeController.text) ?? 0;
                                        setState(() => _minibarFeeController.text = (cur + 25000).toInt().toString());
                                      }),
                                      _buildQuickAddChip('Reset', () {
                                        setState(() => _minibarFeeController.text = '0');
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: AppSpacing.md),

                      AppTextField(
                        label: 'Ganti Rugi Kerusakan Properti (Rp)',
                        controller: _damageFeeController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.handyman_outlined,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      AppTextField(
                        label: 'Catatan Kasir / Resepsionis',
                        hint: 'Contoh: Minibar 2 air mineral, kunci kamar diserahkan lengkap',
                        controller: _notesController,
                        maxLines: 2,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Grand Total Breakdown Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.navy100,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.navy500.withAlpha(50)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Sewa Kamar Pokok:', style: AppTypography.bodySm),
                                Text(
                                  currencyFormatter.format(_roomSubtotal),
                                  style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (_additionalTotal > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Biaya Tambahan:', style: AppTypography.bodySm),
                                  Text(
                                    currencyFormatter.format(_additionalTotal),
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.orange600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Tagihan Pelunasan:',
                                  style: AppTypography.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy900,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(_grandTotal),
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Direct WhatsApp Struk Option
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _sendWaReceipt,
                              activeColor: const Color(0xFF16A34A),
                              onChanged: (val) => setState(() => _sendWaReceipt = val ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'Kirim struk pelunasan otomatis ke WhatsApp tamu (${widget.room.activeGuestPhone ?? "No. WA terdaftar"}) saat check-out selesai',
                                style: AppTypography.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Footer - Responsive Wrap
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppButton(
                    label: 'Konfirmasi Check-Out & Cetak',
                    variant: AppButtonVariant.primary,
                    icon: Icons.receipt_long_rounded,
                    onPressed: _handleConfirmCheckOut,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppColors.navy50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navy900,
          ),
        ),
      ),
    );
  }
}
