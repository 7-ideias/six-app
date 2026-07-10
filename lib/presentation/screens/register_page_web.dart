import 'package:flutter/material.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';

import '../../core/services/nova_empresa_service.dart';
import '../components/web_auth_shell.dart';
import '../components/web_root/web_i18n_gate.dart';
import 'conta_criada_web.dart';

class RegisterPageWeb extends StatefulWidget {
  const RegisterPageWeb({super.key});

  @override
  State<RegisterPageWeb> createState() => _RegisterPageWebState();
}

class _RegisterPageWebState extends State<RegisterPageWeb> {
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final NovaEmpresaService _novaEmpresaService = NovaEmpresaService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _passwordMismatchError;

  late WebRootL10n _l10n;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_validatePasswordsMatch);
    _confirmPasswordCtrl.addListener(_validatePasswordsMatch);
  }

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

  void _validatePasswordsMatch() {
    if (_confirmPasswordCtrl.text.isEmpty) {
      if (_passwordMismatchError != null) {
        setState(() => _passwordMismatchError = null);
      }
      return;
    }

    final equal = _passwordCtrl.text == _confirmPasswordCtrl.text;
    final next = equal ? null : _l10n.authPasswordMismatch;
    if (next != _passwordMismatchError) {
      setState(() => _passwordMismatchError = next);
    }
  }

  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      _showSnack(_l10n.authErrAcceptTerms);
      return;
    }

    final login = _loginCtrl.text.trim();
    final senha = _passwordCtrl.text;
    final confirmSenha = _confirmPasswordCtrl.text;

    if (login.isEmpty || senha.isEmpty || confirmSenha.isEmpty) {
      _showSnack(_l10n.authErrFillAllFields);
      return;
    }

    if (senha.length < 8) {
      _showSnack(_l10n.authErrPasswordTooShort);
      return;
    }

    if (senha != confirmSenha) {
      setState(() => _passwordMismatchError = _l10n.authPasswordMismatch);
      _showSnack(_l10n.authErrPasswordsNotEqual);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _novaEmpresaService.criarNovaEmpresa(login: login, senha: senha);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ContaCriadaWeb()),
        (route) => false,
      );
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebI18nGate(
      builder: (context) {
        _l10n = WebRootL10n.of(context);
        final primary = Theme.of(context).colorScheme.primary;

        return WebAuthShell(
          showBack: true,
          onBack: _goToLogin,
          child: WebAuthStaggeredItems(
            children: [
              WebAuthTitle(
                title: _l10n.authRegisterTitle,
                subtitle: _l10n.authRegisterSubtitle,
              ),
              const SizedBox(height: 28),
              WebAuthTextField(
                controller: _loginCtrl,
                hint: 'Informe seu login de acesso',
                label: 'Login',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              WebAuthTextField(
                controller: _passwordCtrl,
                hint: _l10n.authPasswordMinHint,
                label: _l10n.authPasswordLabel,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: WebAuthShell.labelGrey(),
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              WebAuthTextField(
                controller: _confirmPasswordCtrl,
                hint: _l10n.authConfirmPasswordHint,
                label: _l10n.authConfirmPasswordLabel,
                obscure: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signUp(),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: WebAuthShell.labelGrey(),
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              if (_passwordMismatchError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    _passwordMismatchError!,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 12,
                    ),
                  ),
                ),
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              color: WebAuthShell.textDark(),
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: _l10n.authAgreeWith),
                              TextSpan(
                                text: _l10n.authTermsAndConditions,
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              WebAuthPrimaryButton(
                label: _l10n.authCreateAccountButton,
                onPressed: _signUp,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _goToLogin,
                  behavior: HitTestBehavior.opaque,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: WebAuthShell.labelGrey(),
                      ),
                      children: [
                        TextSpan(text: _l10n.authAlreadyHaveAccount),
                        TextSpan(
                          text: _l10n.authSignInLink,
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
            ],
          ),
        );
      },
    );
  }
}
