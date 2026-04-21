import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/exceptions/recuperacao_senha_exception.dart';
import '../../core/services/recuperacao_senha_service.dart';
import 'nova_senha_mobile.dart';

class VerificarCodigoRecuperacaoMobile extends StatefulWidget {
  final String email;

  const VerificarCodigoRecuperacaoMobile({
    super.key,
    required this.email,
  });

  @override
  State<VerificarCodigoRecuperacaoMobile> createState() =>
      _VerificarCodigoRecuperacaoMobileState();
}

class _VerificarCodigoRecuperacaoMobileState
    extends State<VerificarCodigoRecuperacaoMobile> {
  static const int _codeLength = 6;
  static const int _resendCooldownSeconds = 45;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _isValidating = false;
  bool _isResending = false;
  int _resendSecondsLeft = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendSecondsLeft <= 1) {
          _resendSecondsLeft = 0;
          t.cancel();
        } else {
          _resendSecondsLeft--;
        }
      });
    });
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      FocusScope.of(context).unfocus();
      setState(() {});
      if (digits.length >= _codeLength) _validar();
      return;
    }

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_currentCode.length == _codeLength) _validar();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _reenviarCodigo() async {
    if (_isResending || _resendSecondsLeft > 0) return;
    setState(() => _isResending = true);
    try {
      await _service.enviarCodigo(widget.email);
      if (!mounted) return;
      _showSnack('Novo código enviado para ${widget.email}');
      _startResendTimer();
    } on RecuperacaoSenhaException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível reenviar o código. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _validar() async {
    if (_isValidating) return;
    final code = _currentCode;
    if (code.length < _codeLength) {
      _showSnack('Digite os 6 dígitos do código');
      return;
    }

    setState(() => _isValidating = true);
    try {
      await _service.validarCodigo(email: widget.email, codigo: code);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NovaSenhaMobile(
            email: widget.email,
            codigo: code,
          ),
        ),
      );
    } on RecuperacaoSenhaException catch (e) {
      _showSnack(e.message);
      _clearCode();
    } catch (_) {
      _showSnack('Não foi possível validar o código. Tente novamente.');
      _clearCode();
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const fieldFill = Color(0xFFF1F3F2);
    const labelGrey = Color(0xFF8A8F8D);
    const textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: textDark, size: 20),
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
              const Text(
                'Verificar código',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: labelGrey,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Digite o código de 6 dígitos que\nenviamos para o e-mail ',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextSpan(
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ).style,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Campos de dígitos ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) {
                  return _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    fillColor: fieldFill,
                    activeBorder: primary,
                    onChanged: (v) => _onDigitChanged(i, v),
                    onKey: (event) => _onKey(i, event),
                  );
                }),
              ),
              const SizedBox(height: 22),

              // ── Reenviar código ───────────────────────────────────────
              Center(
                child: _resendSecondsLeft > 0
                    ? Text(
                        'Não recebeu? Reenviar em ${_resendSecondsLeft}s',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: labelGrey,
                        ),
                      )
                    : GestureDetector(
                        onTap: _isResending ? null : _reenviarCodigo,
                        behavior: HitTestBehavior.opaque,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: labelGrey,
                            ),
                            children: [
                              const TextSpan(text: 'Não recebeu? '),
                              TextSpan(
                                text: _isResending
                                    ? 'Enviando...'
                                    : 'Reenviar código',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),

              // ── Botão Verificar ───────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isValidating ? null : _validar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Verificar',
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

// ── Caixa individual de dígito OTP ─────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color fillColor;
  final Color activeBorder;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKey;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.fillColor,
    required this.activeBorder,
    required this.onChanged,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 58,
      child: Focus(
        onKeyEvent: (_, event) => onKey(event),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: fillColor,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: activeBorder, width: 1.4),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
