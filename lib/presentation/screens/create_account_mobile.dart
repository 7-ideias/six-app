import 'package:flutter/material.dart';
import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';

import '../../core/services/nova_empresa_service.dart';
import 'conta_criada_mobile.dart';

class CreateAccountMobile extends StatefulWidget {
  const CreateAccountMobile({super.key});

  @override
  State<CreateAccountMobile> createState() => _CreateAccountMobileState();
}

class _CreateAccountMobileState extends State<CreateAccountMobile> {
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final NovaEmpresaService _novaEmpresaService = NovaEmpresaService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _passwordMismatchError;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      _showSnack('Aceite os Termos e Condições para continuar');
      return;
    }

    final login = _loginCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (login.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Preencha todos os campos');
      return;
    }

    if (password.length < 8) {
      _showSnack('A senha precisa ter ao menos 8 caracteres');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _passwordMismatchError = 'As senhas não coincidem.');
      _showSnack('As senhas informadas não são iguais. Verifique e tente novamente.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _novaEmpresaService.criarNovaEmpresa(login: login, senha: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ContaCriadaMobile()),
        (route) => false,
      );
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: SixAuthTokens.colorShellBackground,
      appBar: AppBar(
        backgroundColor: SixAuthTokens.colorShellBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: SixAuthTokens.colorTextPrimary,
            size: 20,
          ),
          onPressed: _goToLogin,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const SixAuthTitle(
              title: 'Criar conta',
              subtitle: 'Informe um login e uma senha para começar',
            ),
            const SizedBox(height: 28),
            SixAuthInput(
              label: 'Login',
              hint: 'Seu login de acesso',
              controller: _loginCtrl,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 14),
            SixAuthInput(
              label: 'Senha',
              hint: 'Mínimo 8 caracteres',
              controller: _passwordCtrl,
              obscure: _obscurePassword,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SixAuthTokens.colorDividerText,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SixAuthInput(
              label: 'Confirme a senha',
              hint: 'Repita sua senha',
              controller: _confirmPasswordCtrl,
              obscure: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SixAuthTokens.colorDividerText,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            if (_passwordMismatchError != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _passwordMismatchError!,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            InkWell(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _agreeTerms,
                        onChanged: (v) => setState(
                          () => _agreeTerms = v ?? false,
                        ),
                        activeColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Concordo com os Termos e Condições',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: SixAuthTokens.colorTextPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SixAuthPrimaryButton(
              label: 'Cadastrar',
              onPressed: _signUp,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _goToLogin,
                child: Text(
                  'Já tem uma conta? Entrar',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
