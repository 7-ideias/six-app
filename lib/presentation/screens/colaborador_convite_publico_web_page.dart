import 'package:flutter/material.dart';

import '../../core/services/colaborador_convite_web_service.dart';
import '../../data/models/colaborador_convite_model.dart';

class ColaboradorConvitePublicoWebPage extends StatefulWidget {
  const ColaboradorConvitePublicoWebPage({
    super.key,
    required this.codigo,
    required this.initialUri,
  });

  final String codigo;
  final Uri initialUri;

  @override
  State<ColaboradorConvitePublicoWebPage> createState() => _ColaboradorConvitePublicoWebPageState();
}

class _ColaboradorConvitePublicoWebPageState extends State<ColaboradorConvitePublicoWebPage> {
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();
  final TextEditingController _emailController = TextEditingController();
  ColaboradorConvitePublicoResponse? _convite;
  bool _loading = true;
  bool _confirmando = false;
  bool _emailConfirmado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _validar();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final ColaboradorConvitePublicoResponse convite = await _service.validarConvitePublico(widget.codigo);
      if (!mounted) return;
      setState(() {
        _convite = convite;
        _loading = false;
        _emailConfirmado = convite.status.toUpperCase() == 'EMAIL_CONFIRMADO';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _mensagemAmigavel(error);
      });
    }
  }

  Future<void> _confirmarEmail() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _erro = 'Digite o e-mail que recebeu este convite.');
      return;
    }

    setState(() {
      _confirmando = true;
      _erro = null;
    });

    try {
      await _service.confirmarEmailConvite(widget.codigo, email);
      if (!mounted) return;
      setState(() {
        _confirmando = false;
        _emailConfirmado = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail confirmado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _confirmando = false;
        _erro = _mensagemAmigavel(error);
      });
    }
  }

  String _mensagemAmigavel(Object error) {
    final String message = error.toString().replaceAll('Exception: ', '');
    if (message.contains('CONVITE_EMAIL_DIVERGENTE')) {
      return 'O e-mail digitado não confere com o e-mail que recebeu este convite.';
    }
    if (message.contains('CONVITE_EXPIRADO')) {
      return 'Este convite expirou. Solicite um novo convite ao administrador.';
    }
    if (message.contains('CONVITE_JA_UTILIZADO')) {
      return 'Este convite já foi utilizado.';
    }
    return message;
  }

  void _irParaLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading ? _loadingCard(theme) : _content(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingCard(ThemeData theme) {
    return _shell(
      theme: theme,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3)),
          SizedBox(height: 18),
          Text('Validando convite de colaborador...'),
        ],
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final ColaboradorConvitePublicoResponse? convite = _convite;
    if (_erro != null && convite == null) {
      return _shell(
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.link_off_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 14),
            Text('Não foi possível carregar o convite', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_erro!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _validar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return _shell(
      theme: theme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.group_add_outlined, color: theme.colorScheme.primary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Convite de colaborador', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Confirme o e-mail que recebeu este link para continuar.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _info(theme, Icons.storefront_outlined, 'Comércio', convite?.nomeFantasia ?? '-'),
          _info(theme, Icons.verified_user_outlined, 'Status', _emailConfirmado ? 'E-mail confirmado' : convite?.status ?? '-'),
          _info(theme, Icons.schedule_outlined, 'Validade', _formatDate(convite?.expiraEm)),
          const SizedBox(height: 18),
          if (_emailConfirmado) _successState(theme) else _emailConfirmationForm(theme),
          if (_erro != null) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_erro!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emailConfirmationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirmarEmail(),
          decoration: InputDecoration(
            labelText: 'Digite o e-mail que recebeu o convite',
            hintText: 'exemplo@email.com',
            prefixIcon: const Icon(Icons.mail_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _confirmando ? null : _confirmarEmail,
          icon: _confirmando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
          label: Text(_confirmando ? 'Confirmando...' : 'Confirmar e-mail'),
        ),
      ],
    );
  }

  Widget _successState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.verified_outlined, color: Colors.green.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'E-mail confirmado',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'O convite foi confirmado para testes. A ativação completa do acesso com login e senha poderá ser finalizada em uma próxima etapa do fluxo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _irParaLogin,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Ir para o login'),
          ),
        ],
      ),
    );
  }

  Widget _shell({required ThemeData theme, required Widget child}) {
    return Container(
      key: ValueKey<Object?>(_loading ? 'loading' : _erro ?? _convite?.emailConvidado),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _info(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
