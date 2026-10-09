import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../theme/app_icons.dart';
import '../../checkout/presentation/check_out_dialog.dart';
import '../../room_management/domain/room_model.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_feedback.dart';

class ActiveGuestsModal extends StatefulWidget {
  final List<RoomModel> occupiedRooms;

  const ActiveGuestsModal({super.key, required this.occupiedRooms});

  @override
  State<ActiveGuestsModal> createState() => _ActiveGuestsModalState();
}

class _ActiveGuestsModalState extends State<ActiveGuestsModal> {
  final Map<String, String> _waStatusOverrides = {};
  final Set<String> _resendingIds = {};

  Future<void> _handleDirectWa(RoomModel room) async {
    final phone = room.activeGuestPhone;
    if (phone == null || phone.isEmpty) return;
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    }

    final message = 'Halo Bapak/Ibu ${room.activeGuestName ?? ""}, ini Resepsionis Hotel Sinar Harapan terkait reservasi Kamar ${room.roomNumber}.';
    final uri = Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Gagal Membuka WhatsApp',
          message: 'Tidak dapat membuka aplikasi WhatsApp.',
        );
      }
    }
  }

  void _handleResendWa(RoomModel room) async {
    setState(() => _resendingIds.add(room.id));

    // Simulate WhatsApp Gateway (Fonnte/Wablas) API dispatch
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _resendingIds.remove(room.id);
      _waStatusOverrides[room.id] = 'DELIVERED';
    });

    if (mounted) {
      AppFeedback.showSuccess(
        context,
        title: 'Pengingat Terkirim',
        message:
            'Pengingat check-out terkirim ke WhatsApp ${room.activeGuestPhone} (${room.activeGuestName})!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 768;
    // Lebarkan modal agar layout flex leluasa dan tidak menabrak batas
    final dialogWidth = math.min(1160.0, screenWidth - (isMobile ? 16 : 48));
    final dialogHeight = math.min(760.0, mediaQuery.size.height * (isMobile ? 0.95 : 0.90));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Monitor Tamu Aktif & WhatsApp',
                      style: (isMobile ? AppTypography.bodyLg : AppTypography.h2).copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    icon: const AppIcon.medium(AppIcons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sistem cron-job memeriksa jadwal dan otomatis mengirim pesan WA pengingat pada H-60 menit sebelum batas jam check-out (12:00 WIB).',
                style: AppTypography.caption,
              ),

              const Divider(height: 20),

              Expanded(
                child: widget.occupiedRooms.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada kamar yang sedang terisi saat ini.',
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: widget.occupiedRooms.length,
                        separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final room = widget.occupiedRooms[index];
                          final waStatus = _waStatusOverrides[room.id] ?? (room.waReminderStatus ?? 'PENDING');
                          final isResending = _resendingIds.contains(room.id);

                          Color waColor;
                          switch (waStatus) {
                            case 'DELIVERED':
                            case 'READ':
                              waColor = AppColors.statusAvailable;
                              break;
                            case 'SENT':
                              waColor = AppColors.navy700;
                              break;
                            case 'FAILED':
                              waColor = AppColors.statusOccupied;
                              break;
                            default:
                              waColor = AppColors.textSecondary;
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = isMobile || constraints.maxWidth < 880;

                              if (isCompact) {
                                return Container(
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
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.navy700,
                                              borderRadius: AppRadius.roundedSm,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              room.roomNumber,
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  room.activeGuestName ?? '-',
                                                  style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                                Text(
                                                  'WA: ${room.activeGuestPhone ?? "-"} · ${room.bookingSource == "REDDOORZ" ? "RedDoorz" : "Langsung"}',
                                                  style: AppTypography.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Chat WhatsApp Langsung',
                                            icon: const AppIcon.medium(AppIcons.chat, color: AppColors.statusAvailable),
                                            onPressed: () => _handleDirectWa(room),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Batas C/O: ${room.expectedCheckOutTime != null ? DateFormat('dd MMM, HH:mm').format(room.expectedCheckOutTime!) : "12:00 WIB"}',
                                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: waColor.withAlpha(20),
                                              borderRadius: AppRadius.roundedSm,
                                              border: Border.all(color: waColor.withAlpha(60)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AppIcon.small(AppIcons.success, color: waColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'WA: $waStatus',
                                                  style: AppTypography.caption.copyWith(
                                                    color: waColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          AppButton(
                                            label: isResending ? 'Mengirim...' : 'Kirim Ulang WA',
                                            variant: AppButtonVariant.outline,
                                            icon: AppIcons.send,
                                            isLoading: isResending,
                                            onPressed: isResending ? null : () => _handleResendWa(room),
                                          ),
                                          AppButton(
                                            label: 'Check-Out',
                                            variant: AppButtonVariant.primary,
                                            icon: AppIcons.checkOut,
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => CheckOutDialog(room: room),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: AppRadius.roundedMd,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.navy700,
                                        borderRadius: AppRadius.roundedSm,
                                      ),
                                      child: Center(
                                        child: Text(
                                          room.roomNumber,
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            room.activeGuestName ?? '-',
                                            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'WA: ${room.activeGuestPhone ?? "-"} • ${room.bookingSource == "REDDOORZ" ? "RedDoorz" : "Langsung"}',
                                            style: AppTypography.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Batas Check-Out:',
                                            style: AppTypography.overline,
                                          ),
                                          Text(
                                            room.expectedCheckOutTime != null
                                                ? DateFormat('dd MMM, HH:mm').format(room.expectedCheckOutTime!)
                                                : 'Hari ini 12:00 WIB',
                                            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    // WA status pill with intrinsic width
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: waColor.withAlpha(20),
                                        borderRadius: AppRadius.roundedSm,
                                        border: Border.all(color: waColor.withAlpha(60)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppIcon.small(AppIcons.success, color: waColor),
                                          const SizedBox(width: 5),
                                          Text(
                                            'WA: $waStatus',
                                            style: AppTypography.caption.copyWith(
                                              color: waColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: AppSpacing.xs),

                                    IconButton(
                                      tooltip: 'Buka Chat WhatsApp',
                                      icon: const AppIcon.medium(AppIcons.chat, color: AppColors.statusAvailable),
                                      onPressed: () => _handleDirectWa(room),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppButton(
                                          label: isResending ? 'Mengirim...' : 'Kirim Ulang WA',
                                          variant: AppButtonVariant.outline,
                                          icon: AppIcons.send,
                                          isLoading: isResending,
                                          onPressed: isResending ? null : () => _handleResendWa(room),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        AppButton(
                                          label: 'Check-Out',
                                          variant: AppButtonVariant.primary,
                                          icon: AppIcons.checkOut,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => CheckOutDialog(room: room),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Tutup',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
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
