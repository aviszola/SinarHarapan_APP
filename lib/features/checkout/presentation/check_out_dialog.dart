import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../room_management/domain/room_model.dart';
import '../../room_management/presentation/room_controller.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';

class CheckOutDialog extends ConsumerStatefulWidget {
  final RoomModel room;

  const CheckOutDialog({super.key, required this.room});

  @override
  ConsumerState<CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends ConsumerState<CheckOutDialog> {
  late RoomModel _currentRoom;

  final _lateFeeController = TextEditingController(text: '0');
  final _minibarFeeController = TextEditingController(text: '0');
  final _damageFeeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  bool _isCustomLateFee = false;
  bool _isCustomMinibarFee = false;
  bool _isCustomDamageFee = false;

  double _roomSubtotal = 0;
  bool _isLate = false;
  int _lateHours = 0;
  bool _sendWaReceipt = true;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _calculateInitial();
    if (_currentRoom.activeReservationId == null) {
      _loadRoomDetail();
    }
  }

  Future<void> _loadRoomDetail() async {
    try {
      final detail = await ref.read(roomRepositoryProvider).getRoomById(widget.room.id);
      if (detail != null && mounted) {
        setState(() {
          _currentRoom = detail;
          _calculateInitial();
        });
      }
    } catch (_) {}
  }

  void _calculateInitial() {
    // Default 1 night if checkInTime is missing
    final checkIn = _currentRoom.checkInTime ?? DateTime.now().subtract(const Duration(hours: 20));
    final expectedOut = _currentRoom.expectedCheckOutTime ?? DateTime.now().add(const Duration(hours: 2));

    final diffDays = expectedOut.difference(checkIn).inDays;
    final nights = diffDays > 0 ? diffDays : 1;
    _roomSubtotal = nights * _currentRoom.basePricePerNight;

    // Check if late checkout (FR-OUT-05)
    final now = DateTime.now();
    if (now.isAfter(expectedOut)) {
      _isLate = true;
      _lateHours = now.difference(expectedOut).inHours;
      if (_lateHours == 0) _lateHours = 1; // Round up to 1 hr
      // Standard late fee Rp 50.000 / hour
      _lateFeeController.text = (_lateHours * 50000).toString();
      if (_lateHours > 3) {
        _isCustomLateFee = true;
      }
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
    // Pastikan reservasi ID aktif tersedia dari backend
    String? resId = _currentRoom.activeReservationId;
    if (resId == null || resId.isEmpty) {
      try {
        final detail = await ref.read(roomRepositoryProvider).getRoomById(_currentRoom.id);
        resId = detail?.activeReservationId;
        if (detail != null && mounted) {
          setState(() {
            _currentRoom = detail;
          });
        }
      } catch (_) {}
    }

    if (resId == null || resId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.statusOccupied,
            content: Text('Gagal checkout: data reservasi aktif tidak ditemukan untuk kamar ini.'),
          ),
        );
      }
      return;
    }

    final additional = _additionalTotal;
    final chargesList = <Map<String, dynamic>>[];
    if (_lateFee > 0) chargesList.add({'label': 'Denda Late Check-out', 'amount': _lateFee});
    if (_minibarFee > 0) chargesList.add({'label': 'Minibar / Laundry', 'amount': _minibarFee});
    if (_damageFee > 0) chargesList.add({'label': 'Ganti Rugi Kerusakan', 'amount': _damageFee});

    try {
      await ref.read(roomListProvider.notifier).checkOut(
            reservationId: resId,
            additionalCharges: chargesList,
          );

      if (mounted) {
        Navigator.of(context).pop();

        if (additional > 0) {
          _showAdditionalChargesReceiptDialog(_currentRoom, additional);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusDirty,
              content: Row(
                children: [
                  const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Check-Out Kamar ${_currentRoom.roomNumber} selesai tanpa biaya tambahan. Status kamar beralih ke Dirty.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOccupied,
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOccupied,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _showAdditionalChargesReceiptDialog(RoomModel room, double additionalTotal) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: Row(
          children: [
            const Icon(Icons.receipt_outlined, color: AppColors.navy700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tanda Terima Biaya Tambahan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kamar: ${room.roomNumber} • Tamu: ${room.activeGuestName ?? "-"}'),
            Text('No. Invoice Awal: ${room.invoiceNumber ?? "-"} (Telah Lunas di Check-in)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Divider(height: 20),
            if (_lateFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Denda Late Check-out:'),
                  Text(currencyFormatter.format(_lateFee), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            if (_minibarFee > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Minibar / Laundry:'),
                  Text(currencyFormatter.format(_minibarFee), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            if (_damageFee > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ganti Rugi Kerusakan:'),
                  Text(currencyFormatter.format(_damageFee), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Biaya Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  currencyFormatter.format(additionalTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.orange600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan: Biaya ini dicatat pada data reservasi yang sama, bukan merupakan invoice baru.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Cetak Struk'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mencetak struk rincian biaya tambahan ke thermal printer...'),
                ),
              );
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
    final dialogWidth = math.min(620.0, mediaQuery.size.width - (isMobile ? 20 : 48));
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final dialogHeight = math.min(740.0, availableHeight * (isMobile ? 0.96 : 0.90));

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
                            'Kamar ${_currentRoom.roomNumber}',
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
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  _currentRoom.activeGuestName ?? 'Tamu Walk-in',
                                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _currentRoom.bookingSource == 'REDDOORZ'
                                        ? Colors.red.shade100
                                        : AppColors.navy100,
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Text(
                                    _currentRoom.bookingSource ?? 'WALK_IN',
                                    style: AppTypography.overline.copyWith(
                                      color: _currentRoom.bookingSource == 'REDDOORZ'
                                          ? Colors.red.shade800
                                          : AppColors.navy700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'WhatsApp: ${_currentRoom.activeGuestPhone ?? "-"} • Tipe: ${_currentRoom.roomType} (Lt. ${_currentRoom.floor})',
                              style: AppTypography.caption,
                            ),
                            if (_currentRoom.checkInTime != null)
                              Text(
                                'Check-in: ${DateFormat('dd MMM yyyy, HH:mm').format(_currentRoom.checkInTime!)} WIB',
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
                            border: Border.all(color: AppColors.statusDirty),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.statusDirty, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Terlambat check-out $_lateHours jam melebihi batas 12:00 WIB. Dikenakan denda late check-out otomatis.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.statusDirty,
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
                        _buildLateFeeSection(),
                        const SizedBox(height: AppSpacing.md),
                        _buildMinibarFeeSection(),
                        const SizedBox(height: AppSpacing.md),
                        _buildDamageFeeSection(),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLateFeeSection()),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildMinibarFeeSection()),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildDamageFeeSection(),
                      ],

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
                                Expanded(
                                  child: Text(
                                    'Total Tagihan Pelunasan:',
                                    style: (isMobile ? AppTypography.bodySm : AppTypography.h3).copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormatter.format(_grandTotal),
                                  style: (isMobile ? AppTypography.h3 : AppTypography.h2).copyWith(
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
                          color: AppColors.whatsapp.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.statusAvailable.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _sendWaReceipt,
                              activeColor: AppColors.statusAvailable,
                              onChanged: (val) => setState(() => _sendWaReceipt = val ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'Kirim struk pelunasan otomatis ke WhatsApp tamu (${_currentRoom.activeGuestPhone ?? "No. WA terdaftar"}) saat check-out selesai',
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
                    label: _additionalTotal > 0
                        ? 'Selesaikan Check-Out & Cetak Struk Tambahan'
                        : 'Selesaikan Check-Out (Tanpa Biaya)',
                    variant: AppButtonVariant.primary,
                    icon: _additionalTotal > 0 ? Icons.receipt_long_rounded : Icons.check_circle_outline_rounded,
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

  Widget _buildLateFeeSection() {
    final fee = int.tryParse(_lateFeeController.text) ?? 0;
    final int selectedValue = _isCustomLateFee
        ? -1
        : (fee == 0 || fee == 50000 || fee == 100000 || fee == 150000 ? fee : -1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Denda Late Check-Out (Rp)',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCustomLateFee ? AppColors.navy700 : AppColors.border,
              width: _isCustomLateFee ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy700, size: 20),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusAvailable),
                      const SizedBox(width: 8),
                      Text('Bebas Denda (Rp 0)', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 50000,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('+1 Jam — Rp 50.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 100000,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('+2 Jam — Rp 100.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 150000,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('+3 Jam — Rp 150.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: -1,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.orange600),
                      const SizedBox(width: 8),
                      Text(
                        _isCustomLateFee ? 'Isi Sendiri (Rp $fee)' : 'Isi Sendiri (Manual)...',
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: selectedValue == -1 ? FontWeight.w700 : FontWeight.w600,
                          color: _isCustomLateFee ? AppColors.navy900 : AppColors.orange600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == -1) {
                  setState(() => _isCustomLateFee = true);
                } else {
                  setState(() {
                    _isCustomLateFee = false;
                    _lateFeeController.text = val.toString();
                  });
                }
              },
            ),
          ),
        ),
        if (_isCustomLateFee) ...[
          const SizedBox(height: 8),
          _buildCustomFeeField(_lateFeeController, 'Ketik nominal denda late checkout...'),
        ],
      ],
    );
  }

  Widget _buildMinibarFeeSection() {
    final fee = int.tryParse(_minibarFeeController.text) ?? 0;
    final int selectedValue = _isCustomMinibarFee
        ? -1
        : (fee == 0 || fee == 5000 || fee == 10000 || fee == 15000 || fee == 25000 || fee == 40000 ? fee : -1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minibar / Laundry (Rp)',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCustomMinibarFee ? AppColors.navy700 : AppColors.border,
              width: _isCustomMinibarFee ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy700, size: 20),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusAvailable),
                      const SizedBox(width: 8),
                      Text('Tidak Ada (Rp 0)', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 5000,
                  child: Row(
                    children: [
                      const Icon(Icons.local_drink_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Air Mineral — Rp 5.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 10000,
                  child: Row(
                    children: [
                      const Icon(Icons.local_drink_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('2x Air Mineral — Rp 10.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 15000,
                  child: Row(
                    children: [
                      const Icon(Icons.fastfood_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Snack / Camilan — Rp 15.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 25000,
                  child: Row(
                    children: [
                      const Icon(Icons.local_laundry_service_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Laundry Standar — Rp 25.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 40000,
                  child: Row(
                    children: [
                      const Icon(Icons.local_bar_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Minibar + Laundry — Rp 40.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: -1,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.orange600),
                      const SizedBox(width: 8),
                      Text(
                        _isCustomMinibarFee ? 'Isi Sendiri (Rp $fee)' : 'Isi Sendiri (Manual)...',
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: selectedValue == -1 ? FontWeight.w700 : FontWeight.w600,
                          color: _isCustomMinibarFee ? AppColors.navy900 : AppColors.orange600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == -1) {
                  setState(() => _isCustomMinibarFee = true);
                } else {
                  setState(() {
                    _isCustomMinibarFee = false;
                    _minibarFeeController.text = val.toString();
                  });
                }
              },
            ),
          ),
        ),
        if (_isCustomMinibarFee) ...[
          const SizedBox(height: 8),
          _buildCustomFeeField(_minibarFeeController, 'Ketik nominal minibar / laundry...'),
        ],
      ],
    );
  }

  Widget _buildDamageFeeSection() {
    final fee = int.tryParse(_damageFeeController.text) ?? 0;
    final int selectedValue = _isCustomDamageFee
        ? -1
        : (fee == 0 || fee == 50000 || fee == 100000 || fee == 200000 ? fee : -1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ganti Rugi Kerusakan Properti (Rp)',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCustomDamageFee ? AppColors.navy700 : AppColors.border,
              width: _isCustomDamageFee ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy700, size: 20),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusAvailable),
                      const SizedBox(width: 8),
                      Text('Tidak Ada Kerusakan (Rp 0)', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 50000,
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Hilang Kunci / Kartu — Rp 50.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 100000,
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Noda Sprei / Handuk Rusak — Rp 100.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 200000,
                  child: Row(
                    children: [
                      const Icon(Icons.handyman_outlined, size: 18, color: AppColors.navy700),
                      const SizedBox(width: 8),
                      Text('Peralatan Kamar Rusak — Rp 200.000', style: AppTypography.bodySm.copyWith(color: AppColors.navy900)),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: -1,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.orange600),
                      const SizedBox(width: 8),
                      Text(
                        _isCustomDamageFee ? 'Isi Sendiri (Rp $fee)' : 'Isi Sendiri (Manual)...',
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: selectedValue == -1 ? FontWeight.w700 : FontWeight.w600,
                          color: _isCustomDamageFee ? AppColors.navy900 : AppColors.orange600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == -1) {
                  setState(() => _isCustomDamageFee = true);
                } else {
                  setState(() {
                    _isCustomDamageFee = false;
                    _damageFeeController.text = val.toString();
                  });
                }
              },
            ),
          ),
        ),
        if (_isCustomDamageFee) ...[
          const SizedBox(height: 8),
          _buildCustomFeeField(_damageFeeController, 'Ketik nominal ganti rugi kerusakan...'),
        ],
      ],
    );
  }

  Widget _buildCustomFeeField(TextEditingController controller, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navy700, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Text('Rp', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy700, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              scrollPadding: const EdgeInsets.only(bottom: 120, top: 20),
              scrollPhysics: const ClampingScrollPhysics(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTypography.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
