import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

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
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  bool _focused = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
    _effectiveFocusNode.addListener(_handleFocusChange);
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
            if (widget.isAutoFilled) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navy100,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_fix_high_rounded,
                        size: 11, color: AppColors.navy700),
                    const SizedBox(width: 3),
                    Text(
                      'Diisi otomatis',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.navy700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        TextFormField(
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
            filled: true,
            fillColor: widget.readOnly ? AppColors.bg : AppColors.surface,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _focused ? AppColors.navy700 : AppColors.textSecondary,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
