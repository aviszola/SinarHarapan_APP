import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_icons.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/split_door_transition.dart';

/// Screen Login Hotel Sinar Harapan — Frontdesk PMS
/// Diimplementasikan sesuai desain resmi Framer (Desktop, Tablet, Mobile)
/// dengan mempertahankan animasi tirai split-door pada keberhasilan autentikasi.
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


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final Widget scaffold = isDesktop
        ? Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppColors.white,
            body: Row(
              children: [
                // Panel Kiri: Identitas Hotel Sinar Harapan (Navy Blue, Framer Layout)
                const Expanded(
                  flex: 5,
                  child: _LeftBrandPanel(),
                ),

                // Panel Kanan: Form Login Bersih (White Panel, Framer Layout)
                Expanded(
                  flex: 6,
                  child: Container(
                    height: double.infinity,
                    color: AppColors.white,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildLoginForm(context, authState, isDesktop: true),
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
            backgroundColor: AppColors.white,
            body: Column(
              children: [
                // Header Ringkas Brand Hotel (Mobile)
                _buildMobileBrandHeader(context),

                // Form Login Mobile
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildLoginForm(context, authState, isDesktop: false),
                      ),
                    ),
                  ),
                ),
              ],
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

  /// Header Brand Ringkas untuk Tampilan Mobile (< 900px)
  Widget _buildMobileBrandHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.brandNavyDark,
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.brandOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hotel Sinar Harapan',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Form Login Utama (Digunakan di Desktop & Mobile sesuai acuan Framer)
  Widget _buildLoginForm(BuildContext context, AuthState authState, {required bool isDesktop}) {
    final isBusy = authState.isLoading || _isTransitioning;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Judul Form
          Text(
            'Masuk ke Sistem',
            style: isDesktop
                ? AppTextStyles.titleLarge.copyWith(
                    color: AppColors.brandNavyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: -0.4,
                  )
                : AppTextStyles.titleMedium.copyWith(
                    color: AppColors.brandNavyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
          ),
          const SizedBox(height: 8),

          // Subjudul
          Text(
            'Masuk menggunakan akun staf hotel Anda.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: isDesktop ? 14 : 13.5,
            ),
          ),
          const SizedBox(height: 28),

          // Banner Error Autentikasi Inline
          if (authState.errorMessage != null) ...[
            _ErrorBanner(message: authState.errorMessage!),
            const SizedBox(height: 20),
          ],

          // Input Nama Pengguna
          AppTextField(
            label: 'Nama Pengguna',
            hint: 'Masukkan nama pengguna',
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            autofocus: isDesktop,
            semanticIdentifier: 'login_username_input',
            borderRadius: BorderRadius.circular(8),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Nama pengguna wajib diisi'
                : null,
          ),
          const SizedBox(height: 20),

          // Input Kata Sandi
          AppTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan kata sandi',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            isPassword: true,
            semanticIdentifier: 'login_password_input',
            borderRadius: BorderRadius.circular(8),
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 24),

          // Tombol Utama Masuk ke Sistem (Oranye Brand, Kontras 5.65:1 WCAG AA)
          AppButton(
            label: 'Masuk ke Sistem',
            semanticIdentifier: 'login_submit_button',
            variant: AppButtonVariant.primary,
            height: 50,
            borderRadius: BorderRadius.circular(8),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            isLoading: isBusy,
            onPressed: isBusy ? null : _handleLogin,
          ),
          const SizedBox(height: 16),

          // Bantuan Kata Sandi
          Center(
            child: Text(
              'Lupa kata sandi? Hubungi Manajer Hotel.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Catatan Akses Staf
          Center(
            child: Text(
              'Gunakan akun Anda sendiri. Jaga kerahasiaan akses hotel.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),


        ],
      ),
    );
  }
}

// ── Left Brand Panel (Desktop & Tablet >= 900px) ─────────────────────
class _LeftBrandPanel extends StatelessWidget {
  const _LeftBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandNavyDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Akses Bar Oranye + Judul Hotel
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Hotel Sinar Harapan',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Pesan Hero Utama (Sesuai Framer Screenshot)
                      Text(
                        'Sistem operasional\nfrontdesk dan\nmanajemen hotel.',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi Pendukung
                      Text(
                        'Ruang kerja staf untuk pelayanan yang tertata, dari kedatangan hingga kepulangan tamu.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFB0C0DA),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Garis Pembatas Halus & Info Restrained Bawah
                      Divider(
                        color: AppColors.white.withAlpha(30),
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Khusus staf Hotel Sinar Harapan',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF8CA0C0),
                          fontSize: 13,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Inline Error Banner ──────────────────────────────────────────────
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

