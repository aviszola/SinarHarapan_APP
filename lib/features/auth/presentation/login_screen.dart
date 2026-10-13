import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_icons.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import '../domain/user_model.dart';
import 'auth_controller.dart';
import 'widgets/split_door_transition.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _repaintBoundaryKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isTransitioning = false;

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
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isTransitioning) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTransitioning = true);

    _usernameFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authStateProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
            beforeStateChange: (user) async {
              if (mounted) {
                await SplitDoorOverlay.run(
                  context: context,
                  boundaryKey: _repaintBoundaryKey,
                );
              }
            },
          );
    } finally {
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  void _handleQuickLogin(UserRole role) async {
    if (_isTransitioning) return;
    // Audit keamanan release: gate fungsi pemanggil secara ketat
    if (kReleaseMode) return;
    assert(!kReleaseMode, 'Quick login tidak diizinkan di mode rilis');

    setState(() => _isTransitioning = true);

    _usernameFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authStateProvider.notifier).quickLogin(
            role,
            beforeStateChange: (user) async {
              if (mounted) {
                await SplitDoorOverlay.run(
                  context: context,
                  boundaryKey: _repaintBoundaryKey,
                );
              }
            },
          );
    } finally {
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final Widget scaffold = isDesktop
        ? Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppColors.bg,
            body: Row(
              children: [
                // Panel Kiri: Identitas Hotel & Informasi Operasional Frontdesk
                const Expanded(
                  flex: 5,
                  child: _LeftBrandPanel(),
                ),

                // Panel Kanan: Kartu Form Login Staf
                Expanded(
                  flex: 6,
                  child: Container(
                    height: double.infinity,
                    color: AppColors.bg,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDesktopCard(context, authState),
                              const SizedBox(height: 20),
                              Text(
                                'Hotel Sinar Harapan · Frontdesk PMS v1.0',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textDisabled,
                                  fontSize: 12,
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
              ],
            ),
          )
        : Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppColors.bg,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnifiedMobileCard(context, authState),
                        const SizedBox(height: 16),
                        Text(
                          'Hotel Sinar Harapan · Frontdesk PMS v1.0',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: PopScope(
        canPop: !_isTransitioning,
        child: IgnorePointer(
          ignoring: _isTransitioning,
          child: scaffold,
        ),
      ),
    );
  }

  /// Kartu Login Desktop (lebar >= 900px)
  Widget _buildDesktopCard(BuildContext context, AuthState authState) {
    final isBusy = authState.isLoading || _isTransitioning;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Form: Identitas SH Mini + Status Terminal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'SH',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavyTint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.brandNavyBorder, width: 1),
                  ),
                  child: Text(
                    'FRONTDESK PMS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Masuk ke Sistem',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.brandNavyDark,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Masukkan akun staf untuk membuka sistem PMS.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Inline Error Banner
            if (authState.errorMessage != null) ...[
              _ErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: 20),
            ],

            // Input Nama Pengguna (tanpa ikon prefix dekoratif)
            AppTextField(
              label: 'Nama Pengguna',
              hint: 'Contoh: nama_pengguna',
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              autofocus: true,
              semanticIdentifier: 'login_username_input',
              borderRadius: BorderRadius.circular(10),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama pengguna wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),

            // Input Kata Sandi
            AppTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi staf',
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              isPassword: true,
              semanticIdentifier: 'login_password_input',
              borderRadius: BorderRadius.circular(10),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 24),

            // Tombol Utama Masuk (Tinggi >= 52px, radius 10px, teks navy900 kontras 5.65:1 pada oranye)
            AppButton(
              label: 'Masuk ke Sistem',
              semanticIdentifier: 'login_submit_button',
              variant: AppButtonVariant.primary,
              icon: AppIcons.login,
              height: 52,
              borderRadius: BorderRadius.circular(10),
              fontSize: 15.5,
              isLoading: isBusy,
              onPressed: isBusy ? null : _handleLogin,
            ),
            const SizedBox(height: 12),

            // Teks Bantuan Staf
            Center(
              child: Text(
                'Lupa kata sandi? Hubungi Manajer Hotel.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            // Mode Pengembangan (Hanya aktif jika BUKAN Release Mode)
            if (!kReleaseMode) ...[
              const SizedBox(height: 24),
              const _DividerLabel(label: 'Mode Pengembangan'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: AppButton(
                          label: 'Resepsionis',
                          variant: AppButtonVariant.outline,
                          icon: Icons.person_outline,
                          height: 38,
                          borderRadius: BorderRadius.circular(8),
                          fontSize: 12.5,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: isBusy
                              ? null
                              : () => _handleQuickLogin(UserRole.receptionist),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: AppButton(
                          label: 'Manajer Hotel',
                          variant: AppButtonVariant.outline,
                          icon: Icons.admin_panel_settings_outlined,
                          height: 38,
                          borderRadius: BorderRadius.circular(8),
                          fontSize: 12.5,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: isBusy
                              ? null
                              : () => _handleQuickLogin(UserRole.manager),
                        ),
                      ),
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

  /// Kartu Terpadu Mobile (< 900px): Menyatu tanpa kesan dua kotak terpisah
  Widget _buildUnifiedMobileCard(BuildContext context, AuthState authState) {
    final isBusy = authState.isLoading || _isTransitioning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Brand Terintegrasi di Atas Kartu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.brandNavyDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'SH',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Frontdesk PMS v1.0',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandNavyTint.withAlpha(200),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form Body
          Padding(
            padding: const EdgeInsets.all(24),
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
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan akun staf untuk membuka sistem PMS.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Inline Error Banner
                  if (authState.errorMessage != null) ...[
                    _ErrorBanner(message: authState.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Input Nama Pengguna
                  AppTextField(
                    label: 'Nama Pengguna',
                    hint: 'Contoh: nama_pengguna',
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    semanticIdentifier: 'login_username_input',
                    borderRadius: BorderRadius.circular(10),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama pengguna wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Input Kata Sandi
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi staf',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    isPassword: true,
                    semanticIdentifier: 'login_password_input',
                    borderRadius: BorderRadius.circular(10),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Utama Masuk
                  AppButton(
                    label: 'Masuk ke Sistem',
                    semanticIdentifier: 'login_submit_button',
                    variant: AppButtonVariant.primary,
                    icon: AppIcons.login,
                    height: 52,
                    borderRadius: BorderRadius.circular(10),
                    fontSize: 15.5,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : _handleLogin,
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Lupa kata sandi? Hubungi Manajer Hotel.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Mode Pengembangan (Hanya jika BUKAN Release Mode)
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 24),
                    const _DividerLabel(label: 'Mode Pengembangan'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Center(
                              child: AppButton(
                                label: 'Resepsionis',
                                variant: AppButtonVariant.outline,
                                icon: Icons.person_outline,
                                height: 38,
                                borderRadius: BorderRadius.circular(8),
                                fontSize: 12,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: isBusy
                                    ? null
                                    : () => _handleQuickLogin(UserRole.receptionist),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Center(
                              child: AppButton(
                                label: 'Manajer Hotel',
                                variant: AppButtonVariant.outline,
                                icon: Icons.admin_panel_settings_outlined,
                                height: 38,
                                borderRadius: BorderRadius.circular(8),
                                fontSize: 12,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: isBusy
                                    ? null
                                    : () => _handleQuickLogin(UserRole.manager),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left Brand Panel (Desktop) ───────────────────────────────────────
class _LeftBrandPanel extends StatefulWidget {
  const _LeftBrandPanel();

  @override
  State<_LeftBrandPanel> createState() => _LeftBrandPanelState();
}

class _LeftBrandPanelState extends State<_LeftBrandPanel> {
  late DateTime _now;
  Timer? _timer;

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final dayName = _days[dt.weekday - 1];
    final monthName = _months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandNavyDark,
      child: Stack(
        children: [
          // Watermark SH Monogram Besar (~8% opasitas, tampak halus & jelas di layar nyata)
          Positioned(
            right: -24,
            bottom: 40,
            child: IgnorePointer(
              child: Text(
                'SH',
                style: TextStyle(
                  fontSize: 240,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white.withAlpha(20),
                  letterSpacing: -12,
                  height: 1,
                ),
              ),
            ),
          ),

          // Konten Operasional Panel Kiri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Blok Brand Atas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brandOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'SH',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.navy900,
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
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Frontdesk & Property Management System',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandNavyTint.withAlpha(210),
                      ),
                    ),
                  ],
                ),

                // Blok Operasional Riil Tengah (Waktu & Tanggal Live Sistem)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withAlpha(22),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.brandOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'WAKTU OPERASIONAL SISTEM',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brandNavyTint.withAlpha(200),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _formatTime(_now),
                        style: AppTextStyles.numberHero.copyWith(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_now),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.brandNavyTint.withAlpha(220),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: AppColors.white.withAlpha(20),
                        height: 1,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 15,
                            color: AppColors.brandNavyTint,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Operasional Resepsionis & Manajemen',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandNavyTint.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Blok Info Properti & Versi Bawah (Nyata, tanpa mock/hardcode status koneksi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.white.withAlpha(22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hotel_outlined,
                        size: 16,
                        color: AppColors.brandOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hotel Sinar Harapan',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Frontdesk PMS v1.0',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandNavyTint.withAlpha(190),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(90), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon.small(
              AppIcons.error,
              color: AppColors.errorText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.errorText,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.3,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bug_report_outlined,
                size: 13,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
