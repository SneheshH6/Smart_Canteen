import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ButtonVariant { primary, accent, outline, ghost }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  const AppButton.accent({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
    this.padding,
    this.backgroundColor,
    this.textColor,
  }) : variant = ButtonVariant.accent;

  const AppButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
    this.padding,
    this.backgroundColor,
    this.textColor,
  }) : variant = ButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 44,
    this.borderRadius = 12,
    this.padding,
    this.backgroundColor,
    this.textColor,
  }) : variant = ButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      if (onPressed == null) return AppColors.border;
      switch (variant) {
        case ButtonVariant.primary:
          return AppColors.primary;
        case ButtonVariant.accent:
          return AppColors.accent;
        case ButtonVariant.outline:
        case ButtonVariant.ghost:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (textColor != null) return textColor!;
      if (onPressed == null) return AppColors.textMuted;
      switch (variant) {
        case ButtonVariant.primary:
        case ButtonVariant.accent:
          return Colors.white;
        case ButtonVariant.outline:
          return AppColors.primary;
        case ButtonVariant.ghost:
          return AppColors.textSecondary;
      }
    }

    Border? getBorder() {
      if (variant == ButtonVariant.outline) {
        return Border.all(
          color: onPressed == null ? AppColors.border : AppColors.primary,
          width: 1.5,
        );
      }
      return null;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: getBorder(),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: getTextColor()),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: getTextColor(),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
