import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_icons.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import '../domain/user_model.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authStateProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      final user = ref.read(authStateProvider).user!;
      if (user.isManager) {
        context.go('/manager/dashboard');
      } else {
        context.go('/receptionist/rooms');
      }
    }
  }

  void _handleQuickLogin(UserRole role) async {
    final success = await ref.read(authStateProvider.notifier).quickLogin(role);
    if (success && mounted) {
      if (role == UserRole.manager) {
        context.go('/manager/dashboard');
      } else {
        context.go('/receptionist/rooms');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Row(
          children: [
            // Panel Kiri: Identitas Hotel yang Tenang & Kokoh
            Expanded(
              flex: 5,
              child: _LeftBrandPanel(),
            ),

            // Panel Kanan: Form Login Proporsional
            Expanded(
              flex: 6,
              child: Container(
                height: double.infinity,
                color: AppColors.bg,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildFormCard(context, authState, isDesktop: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Layar Tablet / Mobile
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MobileBrandHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildFormCard(context, authState, isDesktop: false),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Hotel Sinar Harapan · Frontdesk PMS v1.0',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AuthState authState, {
    required bool isDesktop,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rounded,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masuk ke Sistem',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.brandNavyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Masukkan akun staf untuk membuka sistem PMS.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inline Error Banner
            if (authState.errorMessage != null) ...[
              _ErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],

            // Input Nama Pengguna (tanpa ikon dekoratif)
            AppTextField(
              label: 'Nama Pengguna',
              hint: 'Contoh: resepsionis01',
              controller: _usernameController,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama pengguna wajib diisi'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Input Kata Sandi (tanpa ikon dekoratif, aksi visibilitas tetap ada)
            AppTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi staf',
              controller: _passwordController,
              isPassword: true,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tombol Utama Masuk
            AppButton(
              label: 'Masuk ke Sistem',
              variant: AppButtonVariant.primary,
              icon: AppIcons.login,
              isLoading: authState.isLoading,
              onPressed: _handleLogin,
            ),

            // Akses Cepat Evaluasi (Hanya aktif dalam Mode Pengembangan / kDebugMode)
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.lg),
              const _DividerLabel(label: 'Mode Pengembangan'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Resepsionis',
                      variant: AppButtonVariant.outline,
                      onPressed: authState.isLoading
                          ? null
                          : () => _handleQuickLogin(UserRole.receptionist),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Manajer Hotel',
                      variant: AppButtonVariant.outline,
                      onPressed: authState.isLoading
                          ? null
                          : () => _handleQuickLogin(UserRole.manager),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Left Panel (Desktop) ───────────────────────────────────────────
class _LeftBrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandNavyDark,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Mark SH
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandOrange,
              borderRadius: AppRadius.rounded,
            ),
            child: Center(
              child: Text(
                'SH',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hotel Sinar Harapan',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Frontdesk & Property Management System',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.brandNavyTint.withAlpha(220),
            ),
          ),
          const Spacer(),
          // Modul Operasional Hotel
          _ModuleItem(
            icon: AppIcons.room,
            title: 'Operasional Kamar',
            subtitle: 'Pemantauan status 3 kamar, check-in, dan check-out cepat.',
          ),
          const SizedBox(height: 18),
          _ModuleItem(
            icon: AppIcons.reception,
            title: 'Verifikasi Tamu & KTP',
            subtitle: 'Pencatatan data identitas tamu walk-in maupun channel.',
          ),
          const SizedBox(height: 18),
          _ModuleItem(
            icon: AppIcons.report,
            title: 'Laporan Keuangan',
            subtitle: 'Rekapitulasi pendapatan harian dan riwayat transaksi.',
          ),
          const Spacer(),
          // Status Keamanan Sistem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandNavy,
              borderRadius: AppRadius.rounded,
              border: Border.all(color: AppColors.white.withAlpha(20), width: 1),
            ),
            child: Row(
              children: [
                const AppIcon.small(
                  AppIcons.shield,
                  color: AppColors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Koneksi lokal aman untuk staf hotel.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModuleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: AppIcon(
            icon,
            size: AppIconSize.medium,
            color: AppColors.brandOrange,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandNavyTint.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile Header ───────────────────────────────────────────────────
class _MobileBrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandNavyDark,
        borderRadius: AppRadius.rounded,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandOrange,
              borderRadius: AppRadius.rounded,
            ),
            child: Center(
              child: Text(
                'SH',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
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
                  'Hotel Sinar Harapan',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Frontdesk PMS',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandNavyTint.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadius.rounded,
        border: Border.all(color: AppColors.error.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          const AppIcon.small(
            AppIcons.error,
            color: AppColors.errorText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.errorText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider with Label ────────────────────────────────────────────
class _DividerLabel extends StatelessWidget {
  final String label;
  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
