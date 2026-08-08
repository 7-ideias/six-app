import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Campo de texto para as telas de autenticação.
///
/// Fundo branco, borda #BCBCBC, raio 6px, altura 51px.
/// Rótulo opcional acima (12px Regular black).
/// Foco aplica borda brand (#0F2D3A).
class SixAuthInput extends StatelessWidget {
  const SixAuthInput({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final Color textColor = SixAuthTokens.textPrimary(context);
    final Color hintColor = SixAuthTokens.fieldHint(context);
    final Color labelColor = SixAuthTokens.fieldLabel(context);
    final Color fillColor = SixAuthTokens.fieldFill(context);
    final Color borderColor = SixAuthTokens.fieldBorder(context);
    final Color focusedBorderColor = SixAuthTokens.fieldBorderFocused(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: SixAuthTokens.fontSizeLabel,
              fontWeight: SixAuthTokens.fontWeightLabel,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: SixAuthTokens.heightInput,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            autofocus: autofocus,
            cursorColor: focusedBorderColor,
            style: TextStyle(
              fontSize: SixAuthTokens.fontSizeBody,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: SixAuthTokens.fontSizeBody,
              ),
              suffixIcon: suffix,
              suffixIconColor: SixAuthTokens.dividerText(context),
              filled: true,
              fillColor: fillColor,
              contentPadding: SixAuthTokens.paddingInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
