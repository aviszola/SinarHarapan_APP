import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

/// Widget yang dirender di dalam root OverlayEntry untuk animasi pintu membelah.
/// Menampilkan dua potongan snapshot LoginScreen yang diklip dan meluncur keluar:
/// - Kiri: panel navy (desktop: 5/11 lebar layar, mobile: 50% lebar layar)
/// - Kanan: panel putih/netral (sisanya)
class SplitDoorOverlayWidget extends StatefulWidget {
  final ui.Image image;
  final double splitWidth;
  final double totalWidth;
  final double totalHeight;
  final VoidCallback onComplete;
  final Duration duration;

  const SplitDoorOverlayWidget({
    super.key,
    required this.image,
    required this.splitWidth,
    required this.totalWidth,
    required this.totalHeight,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 950),
  });

  @override
  State<SplitDoorOverlayWidget> createState() => SplitDoorOverlayWidgetState();
}

class SplitDoorOverlayWidgetState extends State<SplitDoorOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;
  late final Animation<double> logoFadeAnimation;
  late final FocusScopeNode _focusScopeNode;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _focusScopeNode = FocusScopeNode();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Phase 1 (0.0 to 0.15): pintu tahan tertutup (142ms), badge SH tampil di tengah
    // Phase 2 (0.15 to 1.0): kedua pintu meluncur keluar (808ms) dengan Curves.easeInOutCubic
    animation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOutCubic),
    );

    // Badge memudar seiring terbukanya pintu
    logoFadeAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.15, 0.38, curve: Curves.easeOut),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    _focusScopeNode.dispose();
    widget.image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rightWidth = widget.totalWidth - widget.splitWidth;

    return AbsorbPointer(
      absorbing: true, // Menyerap seluruh pointer input selama animasi berlangsung
      child: FocusScope(
        node: _focusScopeNode, // Isolasi keyboard focus dari route di bawahnya
        child: ExcludeSemantics(
          excluding: true, // Isolasi pembaca layar
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final progress = animation.value;
              final logoProgress = logoFadeAnimation.value;

              final leftOffset = -progress * widget.splitWidth;
              final rightOffset = progress * rightWidth;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Potongan Panel Kiri (Snapshot LoginScreen diklip di batas splitWidth)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: widget.splitWidth,
                    height: widget.totalHeight,
                    child: Transform.translate(
                      offset: Offset(leftOffset, 0),
                      child: RepaintBoundary(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: widget.totalWidth,
                            maxWidth: widget.totalWidth,
                            minHeight: widget.totalHeight,
                            maxHeight: widget.totalHeight,
                            child: RawImage(
                              image: widget.image,
                              width: widget.totalWidth,
                              height: widget.totalHeight,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Potongan Panel Kanan (Snapshot LoginScreen diklip dari splitWidth hingga akhir)
                  Positioned(
                    left: widget.splitWidth,
                    top: 0,
                    width: rightWidth,
                    height: widget.totalHeight,
                    child: Transform.translate(
                      offset: Offset(rightOffset, 0),
                      child: RepaintBoundary(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: widget.totalWidth,
                            maxWidth: widget.totalWidth,
                            minHeight: widget.totalHeight,
                            maxHeight: widget.totalHeight,
                            child: Transform.translate(
                              offset: Offset(-widget.splitWidth, 0),
                              child: RawImage(
                                image: widget.image,
                                width: widget.totalWidth,
                                height: widget.totalHeight,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Monogram Badge "SH" di pertemuan tengah kedua panel
                  if (logoProgress < 1.0)
                    Positioned(
                      left: widget.splitWidth - 29,
                      top: (widget.totalHeight / 2) - 29,
                      width: 58,
                      height: 58,
                      child: Opacity(
                        opacity: (1.0 - logoProgress).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: (1.0 - 0.25 * logoProgress).clamp(0.0, 1.0),
                          child: RepaintBoundary(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.brandOrange,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.white.withAlpha(40),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandNavyDark.withAlpha(50),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'SH',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.navy900,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pengelola Root Overlay untuk transisi split-door login.
/// Tidak bergantung pada route lifecycle: overlay dipasang di root overlay sebelum route berpindah,
/// dan tetap utuh saat GoRouter mengganti rute di bawahnya.
class SplitDoorOverlay {
  static OverlayEntry? _currentEntry;

  /// Mengambil snapshot layar login dan memasang animasi split-door di root overlay.
  /// Setelah frame pertama terpasang dan tergambar, fungsi ini selesai sehingga
  /// auth state & router dapat berpindah ke dashboard tujuan di bawah overlay.
  static Future<void> run({
    required BuildContext context,
    required GlobalKey boundaryKey,
  }) async {
    // 1. Reduced motion: jika aktif, langsung lewati tanpa animasi
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return;
    }

    // 2. Ambil snapshot visual layar login
    final ui.Image snapshot;
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      snapshot = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      // Jika snapshot gagal (misal pada environment headless tanpa rasterizer), fallback aman
      return;
    }

    if (!context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final mediaQuery = MediaQuery.of(context);
    final totalWidth = mediaQuery.size.width;
    final totalHeight = mediaQuery.size.height;
    final splitWidth = totalWidth >= 900 ? totalWidth * (5 / 11) : totalWidth * 0.5;

    // Bersihkan entry sebelumnya jika ada untuk mencegah double-trigger
    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return SplitDoorOverlayWidget(
          image: snapshot,
          splitWidth: splitWidth,
          totalWidth: totalWidth,
          totalHeight: totalHeight,
          onComplete: () {
            try {
              entry.remove();
            } catch (_) {}
            if (_currentEntry == entry) {
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // 3. Pastikan frame pertama overlay selesai tergambar sebelum route berganti
    await WidgetsBinding.instance.endOfFrame;
  }
}

/// Signature Split-Door Transition for Sinar Harapan PMS (In-Tree Fallback / Test Component).
class SplitDoorTransition extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;
  final Duration duration;

  const SplitDoorTransition({
    super.key,
    required this.child,
    this.onComplete,
    this.duration = const Duration(milliseconds: 950),
  });

  @override
  State<SplitDoorTransition> createState() => _SplitDoorTransitionState();
}

class _SplitDoorTransitionState extends State<SplitDoorTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _doorAnimation;
  late final Animation<double> _logoAnimation;
  late final FocusScopeNode _focusScopeNode;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _focusScopeNode = FocusScopeNode();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _doorAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOutCubic),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.38, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_completed) {
        _completed = true;
        widget.onComplete?.call();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
        _completed = true;
        widget.onComplete?.call();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) == true && _completed) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final halfWidth = screenWidth / 2;

        return PopScope(
          canPop: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: widget.child,
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final doorProgress = _doorAnimation.value;
                  final logoProgress = _logoAnimation.value;

                  if (doorProgress >= 1.0) {
                    return const SizedBox.shrink();
                  }

                  final leftOffset = -doorProgress * halfWidth;
                  final rightOffset = doorProgress * halfWidth;

                  return FocusScope(
                    node: _focusScopeNode,
                    child: ExcludeSemantics(
                      excluding: true,
                      child: IgnorePointer(
                        ignoring: doorProgress >= 1.0,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: halfWidth,
                              child: Transform.translate(
                                offset: Offset(leftOffset, 0),
                                child: RepaintBoundary(
                                  child: Container(
                                    color: AppColors.brandNavyDark,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: 1,
                                        color: AppColors.white.withAlpha(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: halfWidth,
                              child: Transform.translate(
                                offset: Offset(rightOffset, 0),
                                child: RepaintBoundary(
                                  child: Container(
                                    color: AppColors.bg,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: 1,
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (logoProgress < 1.0)
                              Center(
                                child: Opacity(
                                  opacity: (1.0 - logoProgress).clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: (1.0 - 0.25 * logoProgress).clamp(0.0, 1.0),
                                    child: RepaintBoundary(
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: AppColors.brandOrange,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.white.withAlpha(40),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.brandNavyDark.withAlpha(50),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'SH',
                                            style: AppTextStyles.titleMedium.copyWith(
                                              color: AppColors.navy900,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 22,
                                              letterSpacing: -0.5,
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
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Rute Khusus PageRouteBuilder dengan opaque: false
class SplitDoorPageRoute<T> extends PageRouteBuilder<T> {
  final Widget destination;
  final VoidCallback? onComplete;

  SplitDoorPageRoute({
    required this.destination,
    this.onComplete,
    super.settings,
    Duration duration = const Duration(milliseconds: 650),
  }) : super(
          opaque: false,
          transitionDuration: duration,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) == true;
            return SplitDoorTransition(
              duration: disableAnim ? Duration.zero : duration,
              onComplete: onComplete,
              child: destination,
            );
          },
        );
}
