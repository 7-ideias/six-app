import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Botão primário para as telas de autenticação.
///
/// Fundo #0F2D3A (brand), texto branco SemiBold 16px.
/// Raio 24px (pill), altura 51px.
class SixAuthPrimaryButton extends StatelessWidget {
  const SixAuthPrimaryButton({
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
    final Color backgroundColor = SixAuthTokens.buttonPrimaryBackground(
      context,
    );
    final Color foregroundColor = SixAuthTokens.buttonPrimaryForeground(
      context,
    );

    return SizedBox(
      height: SixAuthTokens.heightButtonPrimary,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SixAuthTokens.radiusButtonPrimary,
            ),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: foregroundColor,
                    strokeWidth: 2.4,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: SixAuthTokens.fontSizeButtonPrimary,
                    fontWeight: SixAuthTokens.fontWeightButtonPrimary,
                  ),
                ),
      ),
    );
  }
}
