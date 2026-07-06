import 'package:flutter/material.dart';

import '../../l10n/six_i18n.dart';
import 'empresa_configuracao_screen.dart';
import 'regionalizacao_configuracao_content.dart';
import 'regras_operacionais_configuracao_content.dart';

class ConfiguracaoSecaoWebPage extends StatelessWidget {
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

  bool get _ehConfiguracaoEmpresa => title == 'Empresa';
  bool get _ehRegionalizacao => title == 'Regionalização';
  bool get _ehRegrasOperacionais => title == 'Regras operacionais';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: <Widget>[
          _buildHeader(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
              onPressed: onBack,
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
      child: Icon(icon, color: theme.colorScheme.primary, size: 28),
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
    return const Padding(
      padding: EdgeInsets.all(24),
      child: _RegionalizacaoConfirmacaoScope(
        child: RegionalizacaoConfiguracaoContent(embedded: true),
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
  const _RegionalizacaoConfirmacaoScope({required this.child});

  final Widget child;

  @override
  State<_RegionalizacaoConfirmacaoScope> createState() =>
      _RegionalizacaoConfirmacaoScopeState();
}

class _RegionalizacaoConfirmacaoScopeState
    extends State<_RegionalizacaoConfirmacaoScope> {
  bool _mostrarAvisoDeConfirmacao = false;

  void _registrarPossivelAlteracao() {
    if (_mostrarAvisoDeConfirmacao || !mounted) return;
    setState(() => _mostrarAvisoDeConfirmacao = true);
  }

  @override
  Widget build(BuildContext context) {
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
