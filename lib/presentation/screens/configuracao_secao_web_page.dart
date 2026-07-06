import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import 'empresa_configuracao_screen.dart';
import 'regionalizacao_configuracao_content.dart';
import 'regras_operacionais_configuracao_content.dart';

class ConfiguracaoSecaoWebPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  const ConfiguracaoSecaoWebPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
  });

  @override
  State<ConfiguracaoSecaoWebPage> createState() =>
      _ConfiguracaoSecaoWebPageState();
}

class _ConfiguracaoSecaoWebPageState extends State<ConfiguracaoSecaoWebPage> {
  bool _regionalizacaoComAlteracaoPendente = false;

  bool get _ehConfiguracaoEmpresa => widget.title == 'Empresa';
  bool get _ehRegionalizacao => widget.title == 'Regionalização';
  bool get _ehRegrasOperacionais => widget.title == 'Regras operacionais';

  Future<void> _handleBack() async {
    if (_ehRegionalizacao && _regionalizacaoComAlteracaoPendente) {
      final bool sairSemSalvar = await _confirmarSaidaSemSalvar();
      if (!sairSemSalvar) return;
    }

    widget.onBack?.call();
  }

  Future<bool> _confirmarSaidaSemSalvar() async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sair sem salvar?')),
            ],
          ),
          content: Text(
            'Existem alterações de regionalização que ainda não foram salvas. Se você sair agora, essas alterações não serão aplicadas.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Continuar editando'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair sem salvar'),
            ),
          ],
        );
      },
    );

    return confirmado ?? false;
  }

  void _atualizarRegionalizacaoPendente(bool pendente) {
    if (_regionalizacaoComAlteracaoPendente == pendente || !mounted) return;
    setState(() => _regionalizacaoComAlteracaoPendente = pendente);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _SairConfiguracaoSecaoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SairConfiguracaoSecaoIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              _handleBack();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: theme.colorScheme.surface,
            child: Column(
              children: <Widget>[
                _buildHeader(context),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 860;
          final Widget titleBlock = Row(
            children: <Widget>[
              _headerIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget closeButton = Align(
            alignment: compact ? Alignment.centerRight : Alignment.center,
            child: IconButton.filledTonal(
              onPressed: _handleBack,
              tooltip: context.t('common.close', fallback: 'Fechar'),
              icon: const Icon(Icons.close_rounded),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: 14),
                closeButton,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              closeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _headerIcon(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(widget.icon, color: theme.colorScheme.primary, size: 28),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_ehConfiguracaoEmpresa) {
      return _buildEmpresaContent(context);
    }

    if (_ehRegionalizacao) {
      return _buildRegionalizacaoContent(context);
    }

    if (_ehRegrasOperacionais) {
      return const RegrasOperacionaisConfiguracaoContent();
    }

    return _buildBlankContent(context);
  }

  Widget _buildEmpresaContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(22),
            child: EmpresaConfiguracaoForm(embedded: true),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionalizacaoContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _RegionalizacaoConfirmacaoScope(
        onDirtyChanged: _atualizarRegionalizacaoPendente,
        child: const RegionalizacaoConfiguracaoContent(embedded: true),
      ),
    );
  }

  Widget _buildBlankContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RegionalizacaoConfirmacaoScope extends StatefulWidget {
  const _RegionalizacaoConfirmacaoScope({
    required this.child,
    required this.onDirtyChanged,
  });

  final Widget child;
  final ValueChanged<bool> onDirtyChanged;

  @override
  State<_RegionalizacaoConfirmacaoScope> createState() =>
      _RegionalizacaoConfirmacaoScopeState();
}

class _RegionalizacaoConfirmacaoScopeState
    extends State<_RegionalizacaoConfirmacaoScope> {
  bool _mostrarAvisoDeConfirmacao = false;
  bool _salvandoAnteriormente = false;

  void _registrarPossivelAlteracao() {
    if (_mostrarAvisoDeConfirmacao || !mounted) return;
    setState(() => _mostrarAvisoDeConfirmacao = true);
    widget.onDirtyChanged(true);
  }

  void _marcarComoConfirmado() {
    if (!_mostrarAvisoDeConfirmacao || !mounted) return;
    setState(() => _mostrarAvisoDeConfirmacao = false);
    widget.onDirtyChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final bool salvando = context.select<LocaleSettingsProvider, bool>(
      (LocaleSettingsProvider provider) => provider.regionalizacaoSaving,
    );

    if (_salvandoAnteriormente && !salvando) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _marcarComoConfirmado());
    }
    _salvandoAnteriormente = salvando;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) => _registrarPossivelAlteracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _mostrarAvisoDeConfirmacao
                ? const _RegionalizacaoConfirmacaoBanner()
                : const SizedBox.shrink(),
          ),
          if (_mostrarAvisoDeConfirmacao) const SizedBox(height: 12),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _RegionalizacaoConfirmacaoBanner extends StatelessWidget {
  const _RegionalizacaoConfirmacaoBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warningColor = Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Alteração pendente de confirmação',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Após alterar qualquer configuração de regionalização, clique em Salvar alterações. Se você sair, fechar ou recarregar antes de salvar, a alteração não será aplicada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade900,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SairConfiguracaoSecaoIntent extends Intent {
  const _SairConfiguracaoSecaoIntent();
}
