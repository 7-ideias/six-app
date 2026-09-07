import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';

Future<String?> showGoogleAccountLinkMobileSheet(
  BuildContext context, {
  required bool creatingAccount,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _GoogleAccountLinkSheet(creatingAccount: creatingAccount);
    },
  );
}

class _GoogleAccountLinkSheet extends StatefulWidget {
  const _GoogleAccountLinkSheet({required this.creatingAccount});

  final bool creatingAccount;

  @override
  State<_GoogleAccountLinkSheet> createState() =>
      _GoogleAccountLinkSheetState();
}

class _GoogleAccountLinkSheetState extends State<_GoogleAccountLinkSheet> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final String password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _error = context.t(
          'auth.googleLink.passwordRequired',
          fallback: 'Informe sua senha atual para continuar.',
        );
      });
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 8, 22, 22 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t(
              'auth.googleLink.title',
              fallback: 'Vincular Conta Google',
            ),
            style: TextStyle(
              color: colors.titleText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              widget.creatingAccount
                  ? 'auth.googleLink.createDescription'
                  : 'auth.googleLink.loginDescription',
              fallback: widget.creatingAccount
                  ? 'Este e-mail já possui um acesso SixoApp. Informe a senha atual apenas para vincular o Google; sua nova empresa continuará separada.'
                  : 'Este e-mail já possui um acesso SixoApp. Informe a senha atual uma única vez para vincular o Google. A senha não será alterada.',
            ),
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SixoAppAuthField(
            controller: _passwordController,
            label: context.t('auth.password', fallback: 'Senha atual'),
            hint: context.t(
              'auth.googleLink.passwordHint',
              fallback: 'Digite sua senha atual',
            ),
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colors.mutedText,
                size: 20,
              ),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SixoAppAuthPrimaryButton(
            label: context.t(
              widget.creatingAccount
                  ? 'auth.googleLink.createAction'
                  : 'auth.googleLink.loginAction',
              fallback: widget.creatingAccount
                  ? 'Vincular e criar minha empresa'
                  : 'Vincular e entrar',
            ),
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: SixMobilePalette.brandBlue,
            ),
            child: Text(
              context.t('common.cancel', fallback: 'Cancelar'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
