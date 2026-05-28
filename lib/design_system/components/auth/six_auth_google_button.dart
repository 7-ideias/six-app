import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Botão "Continuar com Google" para as telas de autenticação.
///
/// Fundo branco, borda #BCBCBC, raio 6px, altura 50px.
class SixAuthGoogleButton extends StatelessWidget {
  const SixAuthGoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SixAuthTokens.heightButtonGoogle,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: SixAuthTokens.colorButtonGoogleBg,
          foregroundColor: SixAuthTokens.colorTextPrimary,
          elevation: 0,
          side: const BorderSide(
            color: SixAuthTokens.colorButtonGoogleBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SixAuthTokens.radiusButtonGoogle,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: SixAuthTokens.colorTextPrimary,
                  strokeWidth: 2.0,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleGlyph(),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: SixAuthTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                      color: SixAuthTokens.colorTextPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
