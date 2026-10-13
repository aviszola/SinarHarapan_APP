import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../theme/app_icons.dart';

/// Consistent text input field matching design.md §6.4.
/// Height: 48px, border 1px → 2px navy on focus, no glow/shadow.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final EdgeInsets? scrollPadding;
  final bool isPassword;
  final bool isAutoFilled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final String? semanticIdentifier;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.scrollPadding,
    this.isPassword = false,
    this.isAutoFilled = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints,
    this.contentPadding,
    this.borderRadius,
    this.semanticIdentifier,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  bool _focused = false;
  bool _capsLockOn = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
    _effectiveFocusNode.addListener(_handleFocusChange);
    if (widget.isPassword) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      _checkCapsLock();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    _checkCapsLock();
    return false;
  }

  void _checkCapsLock() {
    if (widget.isPassword) {
      try {
        final isCaps = HardwareKeyboard.instance.lockModesEnabled
            .contains(KeyboardLockMode.capsLock);
        if (mounted && isCaps != _capsLockOn) {
          setState(() => _capsLockOn = isCaps);
        }
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      // Smooth auto-scroll context into visible area when virtual keyboard opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _effectiveFocusNode.hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.28,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    if (mounted) {
      setState(() => _focused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    if (widget.isPassword) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _focused ? AppColors.navy700 : AppColors.textPrimary,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (widget.isAutoFilled) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navy100,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'Diisi otomatis',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.navy700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Semantics(
          identifier: widget.semanticIdentifier,
          label: widget.label,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
          focusNode: _effectiveFocusNode,
          scrollPadding: widget.scrollPadding ??
              const EdgeInsets.only(
                bottom: 120,
                top: 24,
                left: 16,
                right: 16,
              ),
          scrollPhysics: const ClampingScrollPhysics(),
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          style: AppTypography.body.copyWith(
            color: widget.readOnly ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            contentPadding: widget.contentPadding,
            filled: true,
            fillColor: widget.readOnly ? AppColors.bg : AppColors.surface,
            border: widget.borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: widget.borderRadius!,
                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                  )
                : null,
            enabledBorder: widget.borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: widget.borderRadius!,
                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                  )
                : null,
            focusedBorder: widget.borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: widget.borderRadius!,
                    borderSide: const BorderSide(color: AppColors.brandNavy, width: 1.5),
                  )
                : null,
            errorBorder: widget.borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: widget.borderRadius!,
                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                  )
                : null,
            focusedErrorBorder: widget.borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: widget.borderRadius!,
                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                  )
                : null,
            prefixIcon: widget.prefixIcon != null
                ? AppIcon(
                    widget.prefixIcon!,
                    size: AppIconSize.medium,
                    color: _focused ? AppColors.navy700 : AppColors.textSecondary,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? Semantics(
                    button: true,
                    label: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                    child: IconButton(
                      icon: AppIcon(
                        _obscure ? AppIcons.eye : AppIcons.eyeOff,
                        size: AppIconSize.medium,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  )
                : widget.suffix,
          ),
        ),
      ),

        if (widget.isPassword && _capsLockOn && _focused) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.keyboard_capslock_rounded,
                size: 14,
                color: AppColors.statusDirty,
              ),
              const SizedBox(width: 4),
              Text(
                'Caps Lock aktif',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.statusDirtyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
