import 'package:appplanilha/design_system/tokens/auth_tokens.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: SixAuthTokens.fontSizeLabel,
              fontWeight: SixAuthTokens.fontWeightLabel,
              color: SixAuthTokens.colorFieldLabel,
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
            style: const TextStyle(
              fontSize: SixAuthTokens.fontSizeBody,
              color: SixAuthTokens.colorTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: SixAuthTokens.colorFieldHint,
                fontSize: SixAuthTokens.fontSizeBody,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: SixAuthTokens.colorFieldFill,
              contentPadding: SixAuthTokens.paddingInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: const BorderSide(
                  color: SixAuthTokens.colorFieldBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: const BorderSide(
                  color: SixAuthTokens.colorFieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SixAuthTokens.radiusInput),
                borderSide: const BorderSide(
                  color: SixAuthTokens.colorFieldBorderFocused,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
