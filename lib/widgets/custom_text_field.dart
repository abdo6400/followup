import 'package:flutter/material.dart';


class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String?)? onSaved;
  final void Function(String?)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final bool autofocus;
  final bool expands;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final bool enableInteractiveSelection;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final bool? filled;
  final Color? fillColor;
  final String? errorText;
  final String? helperText;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final bool isDense;
  final double borderRadius;
  final double? height;
  final double? width;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSaved,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.autofocus = false,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.enableInteractiveSelection = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textAlignVertical,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.filled = true,
    this.fillColor = Colors.white,
    this.errorText,
    this.helperText,
    this.hintStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.isDense = false,
    this.borderRadius = 12.0,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: height,
      width: width,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        onSaved: onSaved,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: textInputAction,
        focusNode: focusNode,
        autofocus: autofocus,
        expands: expands,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        enableInteractiveSelection: enableInteractiveSelection,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textAlignVertical: textAlignVertical,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled ? theme.colorScheme.onSurface : theme.hintColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: prefixIcon,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          suffixText: suffixText,
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          border: border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
              ),
          enabledBorder: enabledBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
              ),
          focusedBorder: focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ),
              ),
          errorBorder: errorBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.0,
                ),
              ),
          focusedErrorBorder: focusedErrorBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2.0,
                ),
              ),
          filled: filled,
          fillColor: fillColor,
          errorText: errorText,
          helperText: helperText,
          hintStyle: hintStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
          labelStyle: labelStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
          errorStyle: errorStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
          helperStyle: helperStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
          isDense: isDense,
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
