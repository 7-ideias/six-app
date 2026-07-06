import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
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
  ColaboradorConvitePublicoResponse? _convite;
  bool _loading = true;
  bool _aceitando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _validar();
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
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _aceitar() async {
    setState(() {
      _aceitando = true;
      _erro = null;
    });

    try {
      await _service.aceitarConvite(widget.codigo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite aceito com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/app', (Route<dynamic> route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aceitando = false;
        _erro = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _login() async {
    await AuthService().logout();
    if (!mounted) return;
    final String redirect = Uri.encodeComponent(widget.initialUri.toString());
    Navigator.of(context).pushNamed('/login?redirect=$redirect');
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
                  color: theme.colorScheme.primary.withOpacity(0.10),
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
                    Text('Você recebeu um convite para acessar um comércio no Six.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _info(theme, Icons.storefront_outlined, 'Comércio', convite?.nomeFantasia ?? '-'),
          _info(theme, Icons.mail_outline, 'E-mail convidado', convite?.emailConvidado ?? '-'),
          _info(theme, Icons.verified_user_outlined, 'Status', convite?.status ?? '-'),
          _info(theme, Icons.schedule_outlined, 'Validade', _formatDate(convite?.expiraEm)),
          if (_erro != null) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_erro!),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _aceitando ? null : _aceitar,
                icon: _aceitando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_aceitando ? 'Aceitando...' : 'Aceitar convite'),
              ),
              OutlinedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Entrar com outro e-mail'),
              ),
            ],
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
            color: Colors.black.withOpacity(0.06),
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
          color: theme.colorScheme.primary.withOpacity(0.045),
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
