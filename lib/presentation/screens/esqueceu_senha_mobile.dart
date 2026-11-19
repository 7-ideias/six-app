import '../../l10n/password_recovery_texts.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';

import '../../core/exceptions/recuperacao_senha_exception.dart';
import '../../core/services/recuperacao_senha_service.dart';
import 'verificar_codigo_recuperacao_mobile.dart';

class EsqueceuSenhaMobile extends StatefulWidget {
  const EsqueceuSenhaMobile({super.key}) : emailDaConta = null;

  const EsqueceuSenhaMobile.alterarSenha({
    super.key,
    required String this.emailDaConta,
  });

  final String? emailDaConta;

  @override
  State<EsqueceuSenhaMobile> createState() => _EsqueceuSenhaMobileState();
}

class _EsqueceuSenhaMobileState extends State<EsqueceuSenhaMobile> {
  final TextEditingController _emailCtrl = TextEditingController();
  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enviarCodigo() async {
    if (_isLoading) return;
    final email = (widget.emailDaConta ?? _emailCtrl.text).trim();
    if (email.isEmpty) {
      _showSnack('Informe seu e-mail');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.enviarCodigo(
        email,
        contaAutenticada: widget.emailDaConta != null,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => VerificarCodigoRecuperacaoMobile(
                email: email,
                contaAutenticada: widget.emailDaConta != null,
              ),
        ),
      );
    } on RecuperacaoSenhaException catch (e) {
      if (mounted) _showSnack(passwordRecoveryError(context, e));
    } catch (_) {
      if (mounted) _showSnack(passwordRecoveryText(context, 'unavailable'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = SixAuthTokens.shellBackground(context);
    final Color primary = SixAuthTokens.interactiveColor(context);
    final Color foreground = SixAuthTokens.onInteractiveColor(context);
    final Color fieldFill = SixAuthTokens.fieldFill(context);
    final Color fieldBorder = SixAuthTokens.fieldBorder(context);
    final Color labelGrey = SixAuthTokens.textMuted(context);
    final Color textColor = SixAuthTokens.textPrimary(context);
    final bool useAdaptiveBorder = SixAuthTokens.usesMobileAdaptiveColors(
      context,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.emailDaConta == null
                    ? 'Esqueceu a senha?'
                    : passwordRecoveryText(context, 'change'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.emailDaConta == null
                    ? 'Informe seu e-mail para\nrecuperar sua senha'
                    : passwordRecoveryText(context, 'sendToAccount'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: labelGrey, height: 1.45),
              ),
              const SizedBox(height: 32),

              // ── Campo E-mail ──────────────────────────────────────────
              if (widget.emailDaConta case final email?)
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _enviarCodigo(),
                  cursorColor: primary,
                  style: TextStyle(fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    hintStyle: TextStyle(color: labelGrey, fontSize: 15),
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          useAdaptiveBorder
                              ? BorderSide(color: fieldBorder)
                              : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          useAdaptiveBorder
                              ? BorderSide(color: fieldBorder)
                              : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primary.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // ── Botão Enviar Código ────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: foreground,
                    disabledBackgroundColor: primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: foreground,
                              strokeWidth: 2.4,
                            ),
                          )
                          : Text(
                            passwordRecoveryText(context, 'sendCode'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
