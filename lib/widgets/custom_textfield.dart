

import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final IconData? prefixIcon; // If you want to pass IconData only
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? labelColor;
  final Color? iconColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final int? maxLines;
  final String? hintText;
  final bool enabled;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final double? width;

  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.labelColor,
    this.iconColor,
    this.borderRadius = 12,
    this.contentPadding,
    this.maxLines = 1,
    this.hintText,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.width,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final double fieldWidth =
        widget.width ?? (MediaQuery.of(context).size.width < 600 ? 300 : 400);

    return Center(
      child: SizedBox(
        width: fieldWidth,
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.backgroundColor ?? Colors.grey.shade50,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? (widget.focusedBorderColor ??
                                const Color(0xFF00ACC1))
                          : (widget.iconColor ?? Colors.grey.shade600),
                      size: 20,
                    ),
              suffixIcon: widget.suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.grey.shade300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: widget.focusedBorderColor ?? const Color(0xFF00ACC1),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}