import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../auth/domain/user_model.dart';

/// Modal Konfirmasi Logout Eksplisit (Anti AI-Slop)
/// Mengikuti arahan design.md v1.0 & design-taste-frontend:
/// - Flat, border-based structure (tanpa glassmorphism/gradient ungu generik)
/// - Palet korporat Sinar Harapan (Navy900, Navy700, Error Red #DC2626)
/// - Menampilkan konteks akun aktif (Nama, Avatar Initials, Role Badge)
/// - Touch-first target minimum 48px (tablet & desktop compliance)
/// - WCAG AA compliant contrast ratio pada seluruh label & tombol
class AppLogoutDialog extends StatelessWidget {
  final UserModel? user;

  const AppLogoutDialog({
    super.key,
    this.user,
  });

  /// Helper statis untuk memanggil dialog konfirmasi logout
  static Future<bool> show(
    BuildContext context, {
    UserModel? user,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.navy900.withAlpha(130),
      builder: (ctx) => AppLogoutDialog(user: user),
    );
    return result ?? false;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (user?.username.isNotEmpty == true ? user!.username : 'Pengguna Aktif');
    final initials = _getInitials(displayName);
    final isManager = user?.isManager == true;
    final roleLabel = isManager ? 'MANAJER' : 'RESEPSIONIS';

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.rounded,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header: Icon + Title + Close Button ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: AppRadius.rounded,
                      border: Border.all(
                        color: AppColors.error.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keluar dari Sistem?',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Konfirmasi pengakhiran sesi kerja aktif',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Tutup',
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 2. Active Session Card (Context Indicator) ────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.navy900,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sesi aktif Frontdesk PMS',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isManager ? AppColors.orange100 : AppColors.navy50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isManager
                              ? AppColors.orange800.withAlpha(40)
                              : AppColors.navy700.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isManager
                              ? AppColors.orange800
                              : AppColors.navy700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Operational Advisory Message ───────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.navy100,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.navy700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pastikan seluruh transaksi check-in, check-out, atau perubahan status kamar telah selesai disimpan sebelum Anda keluar.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.navy900,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 4. Action Buttons (Touch Target >= 48px) ───────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy900,
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Keluar Akun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
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
