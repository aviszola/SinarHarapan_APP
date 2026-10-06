import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import '../domain/user_model.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authStateProvider.notifier).clearError();
      }
    });
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Row(
        children: [
          // ── Left Panel: Brand Identity ──────────────────────────
          if (size.width > 900)
            Expanded(
              flex: 5,
              child: _LeftBrandPanel(),
            ),

          // ── Right Panel: Login Form ─────────────────────────────
          Expanded(
            flex: size.width > 900 ? 4 : 10,
            child: Container(
              height: double.infinity,
              color: AppColors.surface,
              child: SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width > 900 ? 48 : (size.width < 400 ? 20 : 28),
                          vertical: size.width < 600 ? 20 : 40,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Mobile-only logo
                                if (size.width <= 900) ...[
                                  _MobileLogo(),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

                                // Section heading
                                Text(
                                  'Masuk ke Sistem',
                                  style: (size.width < 400 ? AppTypography.h2 : AppTypography.h1).copyWith(
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Masukkan kredensial akun staf Anda untuk melanjutkan.',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: size.width < 400 ? 13.5 : 15,
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.xl),

                                // Error Banner
                                if (authState.errorMessage != null) ...[
                                  _ErrorBanner(message: authState.errorMessage!),
                                  const SizedBox(height: AppSpacing.md),
                                ],

                                // Username
                                AppTextField(
                                  label: 'Nama Pengguna',
                                  hint: 'resepsionis01 atau manager01',
                                  controller: _usernameController,
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Username wajib diisi'
                                      : null,
                                ),

                                const SizedBox(height: AppSpacing.md),

                                // Password
                                AppTextField(
                                  label: 'Kata Sandi',
                                  hint: 'Masukkan kata sandi',
                                  controller: _passwordController,
                                  isPassword: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                                  onSubmitted: (_) => _handleLogin(),
                                ),

                                const SizedBox(height: AppSpacing.xl),

                                // Primary CTA
                                AppButton(
                                  label: 'Masuk ke Sistem',
                                  variant: AppButtonVariant.primary,
                                  icon: Icons.login_rounded,
                                  isLoading: authState.isLoading,
                                  onPressed: _handleLogin,
                                ),

                                const SizedBox(height: AppSpacing.xl),

                                // Divider
                                _DividerLabel(label: 'Akses Cepat Evaluasi'),

                                const SizedBox(height: AppSpacing.md),

                                // Quick login buttons (stacked on narrow mobile screens)
                                if (size.width < 380) ...[
                                  AppButton(
                                    label: 'Resepsionis',
                                    variant: AppButtonVariant.outline,
                                    icon: Icons.badge_outlined,
                                    onPressed: authState.isLoading
                                        ? null
                                        : () => _handleQuickLogin(UserRole.receptionist),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppButton(
                                    label: 'Manajer Hotel',
                                    variant: AppButtonVariant.secondary,
                                    icon: Icons.admin_panel_settings_outlined,
                                    onPressed: authState.isLoading
                                        ? null
                                        : () => _handleQuickLogin(UserRole.manager),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          label: 'Resepsionis',
                                          variant: AppButtonVariant.outline,
                                          icon: Icons.badge_outlined,
                                          onPressed: authState.isLoading
                                              ? null
                                              : () => _handleQuickLogin(UserRole.receptionist),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: AppButton(
                                          label: 'Manajer Hotel',
                                          variant: AppButtonVariant.secondary,
                                          icon: Icons.admin_panel_settings_outlined,
                                          onPressed: authState.isLoading
                                              ? null
                                              : () => _handleQuickLogin(UserRole.manager),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: AppSpacing.xl),

                                // Footer note
                                Text(
                                  'Hotel Sinar Harapan — RedDoorz Partner\nSistem manajemen properti v1.0',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textDisabled,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left Panel (desktop only) ──────────────────────────────────────
class _LeftBrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy900,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo mark
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.orange600,
              borderRadius: AppRadius.roundedLg,
            ),
            child: const Center(
              child: Text(
                'SH',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Hotel Sinar\nHarapan',
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withAlpha(30),
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: const Color(0xFFDC2626).withAlpha(80)),
            ),
            child: const Text(
              'RedDoorz Partner',
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),

          const Spacer(),

          // Feature highlights
          ..._buildFeatureList(),

          const Spacer(),

          // Bottom tagline
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.navy700,
              borderRadius: AppRadius.roundedLg,
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frontdesk & Property Management System',
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OCR KTP · Reservasi Walk-in & RedDoorz · Check-in/out · Laporan Manajer',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.navy100.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      (Icons.grid_view_rounded, 'Manajemen kamar real-time'),
      (Icons.document_scanner_outlined, 'Scan KTP otomatis dengan OCR'),
      (Icons.receipt_long_outlined, 'Invoice & laporan terformat'),
      (Icons.chat_bubble_outline_rounded, 'Notifikasi WhatsApp otomatis'),
    ];

    return features.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navy700,
              borderRadius: AppRadius.roundedMd,
            ),
            child: Icon(f.$1, size: 18, color: AppColors.navy100),
          ),
          const SizedBox(width: 14),
          Text(
            f.$2,
            style: AppTypography.body.copyWith(
              color: AppColors.navy100.withAlpha(200),
            ),
          ),
        ],
      ),
    )).toList();
  }
}

// ── Mobile Logo ────────────────────────────────────────────────────
class _MobileLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.navy900,
            borderRadius: AppRadius.roundedLg,
          ),
          child: const Center(
            child: Text(
              'SH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
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
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'RedDoorz Partner · PMS',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
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
        color: AppColors.statusErrorBg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.statusOccupied.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.statusOccupied),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.statusOccupied,
                fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
