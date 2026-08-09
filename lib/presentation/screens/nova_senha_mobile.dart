import 'package:flutter/material.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';

import '../../core/exceptions/recuperacao_senha_exception.dart';
import '../../core/services/recuperacao_senha_service.dart';
import 'login_mobile.dart';

class NovaSenhaMobile extends StatefulWidget {
  final String email;
  final String codigo;

  const NovaSenhaMobile({super.key, required this.email, required this.codigo});

  @override
  State<NovaSenhaMobile> createState() => _NovaSenhaMobileState();
}

class _NovaSenhaMobileState extends State<NovaSenhaMobile> {
  final TextEditingController _senhaCtrl = TextEditingController();
  final TextEditingController _confirmarCtrl = TextEditingController();
  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _redefinir() async {
    final senha = _senhaCtrl.text.trim();
    final confirmar = _confirmarCtrl.text.trim();

    if (senha.isEmpty || confirmar.isEmpty) {
      _showSnack('Preencha todos os campos');
      return;
    }

    if (senha != confirmar) {
      _showSnack('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.redefinirSenha(
        email: widget.email,
        codigo: widget.codigo,
        novaSenha: senha,
      );
      if (!mounted) return;
      _showSnack('Senha redefinida com sucesso!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPageMobile()),
        (route) => false,
      );
    } on RecuperacaoSenhaException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível redefinir a senha. Tente novamente.');
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
                'Nova senha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Defina sua nova senha para\nacessar sua conta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: labelGrey, height: 1.45),
              ),
              const SizedBox(height: 32),

              // ── Nova senha ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Nova senha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              TextField(
                controller: _senhaCtrl,
                obscureText: _obscureSenha,
                textInputAction: TextInputAction.next,
                cursorColor: primary,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Digite sua nova senha',
                  hintStyle: TextStyle(color: labelGrey, fontSize: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: labelGrey,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(() => _obscureSenha = !_obscureSenha),
                  ),
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
              const SizedBox(height: 14),

              // ── Confirmar senha ───────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Confirmar senha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              TextField(
                controller: _confirmarCtrl,
                obscureText: _obscureConfirmar,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _redefinir(),
                cursorColor: primary,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Confirme sua nova senha',
                  hintStyle: TextStyle(color: labelGrey, fontSize: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmar
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: labelGrey,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureConfirmar = !_obscureConfirmar,
                        ),
                  ),
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

              // ── Botão Redefinir ────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _redefinir,
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
                          : const Text(
                            'Redefinir senha',
                            style: TextStyle(
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
