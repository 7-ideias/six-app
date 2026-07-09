import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/caixa_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../l10n/six_i18n.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';

class FormasRecebimentoConfiguracaoContent extends StatefulWidget {
  const FormasRecebimentoConfiguracaoContent({super.key});

  @override
  State<FormasRecebimentoConfiguracaoContent> createState() =>
      _FormasRecebimentoConfiguracaoContentState();
}

class _FormasRecebimentoConfiguracaoContentState
    extends State<FormasRecebimentoConfiguracaoContent> {
  late final CaixaService _caixaService;

  List<TiposRecebimento> _tipos = const <TiposRecebimento>[];
  bool _carregando = true;
  bool _restaurandoPadrao = false;
  String? _erro;
  String? _salvandoCodigo;

  List<TiposRecebimento> get _tiposOrdenados {
    final List<TiposRecebimento> ordenados = List<TiposRecebimento>.of(_tipos);
    ordenados.sort((TiposRecebimento a, TiposRecebimento b) {
      final int ordem = a.ordemExibicao.compareTo(b.ordemExibicao);
      if (ordem != 0) return ordem;
      return _numeroTipo(a.codigoTipo).compareTo(_numeroTipo(b.codigoTipo));
    });
    return ordenados;
  }

  @override
  void initState() {
    super.initState();
    _caixaService = CaixaService(apiClient: HttpCaixaApiClient());
    _carregarTipos();
  }

  Future<void> _carregarTipos({bool manterConteudoAtual = false}) async {
    setState(() {
      _carregando = true;
      if (!manterConteudoAtual) {
        _erro = null;
      }
    });

    try {
      final List<TiposRecebimento> tipos =
          await _caixaService.listarTiposRecebimentoConfiguraveis();
      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _carregando = false;
        _erro = null;
      });
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = _mensagemErro(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = context.t(
          'configuracoes.recebimento.errorLoad',
          fallback: 'Não foi possível carregar as formas de recebimento.',
        );
      });
    }
  }

  String _mensagemErro(int statusCode, {bool alteracao = false}) {
    switch (statusCode) {
      case 400:
        return context.t(
          'configuracoes.recebimento.errorBadRequest',
          fallback: 'Dados inválidos para esta operação.',
        );
      case 401:
        return context.t(
          'configuracoes.recebimento.errorUnauthorized',
          fallback: 'Sessão expirada. Faça login novamente.',
        );
      case 403:
        return context.t(
          'configuracoes.recebimento.errorForbidden',
          fallback:
              'Você não possui permissão para alterar configurações da empresa.',
        );
      case 404:
        return context.t(
          'configuracoes.recebimento.errorNotFound',
          fallback: 'Configuração de forma de recebimento não encontrada.',
        );
      default:
        return context.t(
          alteracao
              ? 'configuracoes.recebimento.errorSaveWithStatus'
              : 'configuracoes.recebimento.errorLoadWithStatus',
          fallback:
              alteracao
                  ? 'Erro ao salvar forma de recebimento (HTTP $statusCode).'
                  : 'Erro ao carregar formas de recebimento (HTTP $statusCode).',
        );
    }
  }

  Future<void> _editarTipo(TiposRecebimento tipo) async {
    final TiposRecebimento? atualizado = await showDialog<TiposRecebimento>(
      context: context,
      barrierDismissible: true,
      builder:
          (BuildContext dialogContext) =>
              _EscCloseScope(child: _TipoRecebimentoEditDialog(tipo: tipo)),
    );

    if (atualizado == null) return;

    setState(() => _salvandoCodigo = tipo.codigoTipo);
    try {
      await _caixaService.atualizarTipoRecebimentoConfiguravel(
        codigoTipo: tipo.codigoTipo,
        tipo: atualizado,
      );

      if (!mounted) return;
      await _carregarTipos(manterConteudoAtual: true);
      if (!mounted) return;

      _mostrarMensagem(
        context.t(
          'configuracoes.recebimento.saveSuccess',
          fallback: 'Forma de recebimento atualizada com sucesso.',
        ),
      );
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        _mensagemErro(error.statusCode, alteracao: true),
        erro: true,
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        context.t(
          'configuracoes.recebimento.errorSave',
          fallback: 'Não foi possível salvar a forma de recebimento.',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoCodigo = null);
      }
    }
  }

  Future<void> _restaurarPadrao() async {
    final bool confirmar =
        await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return _EscCloseScope(
              child: AlertDialog(
                icon: const Icon(Icons.restart_alt_rounded),
                title: Text(
                  context.t(
                    'configuracoes.recebimento.restoreConfirmTitle',
                    fallback: 'Restaurar padrão',
                  ),
                ),
                content: Text(
                  context.t(
                    'configuracoes.recebimento.restoreConfirmBody',
                    fallback:
                        'Esta ação restaura os 10 tipos de recebimento para a configuração padrão da empresa.',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      context.t('common.cancel', fallback: 'Cancelar'),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      context.t(
                        'configuracoes.recebimento.restoreAction',
                        fallback: 'Restaurar padrão',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    if (!confirmar) return;

    setState(() => _restaurandoPadrao = true);
    try {
      await _caixaService.restaurarTiposRecebimentoPadrao();
      if (!mounted) return;
      await _carregarTipos(manterConteudoAtual: true);
      if (!mounted) return;
      _mostrarMensagem(
        context.t(
          'configuracoes.recebimento.restoreSuccess',
          fallback:
              'Configuração padrão das formas de recebimento restaurada com sucesso.',
        ),
      );
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        _mensagemErro(error.statusCode, alteracao: true),
        erro: true,
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        context.t(
          'configuracoes.recebimento.restoreError',
          fallback: 'Não foi possível restaurar a configuração padrão.',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _restaurandoPadrao = false);
      }
    }
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<TiposRecebimento> tipos = _tiposOrdenados;
    final int ativos =
        tipos.where((TiposRecebimento item) => item.ativo).length;
    final int imediatos =
        tipos
            .where(
              (TiposRecebimento item) =>
                  item.naturezaRecebimento.trim().toUpperCase() == 'IMEDIATO',
            )
            .length;
    final int futuros =
        tipos
            .where(
              (TiposRecebimento item) =>
                  item.naturezaRecebimento.trim().toUpperCase() == 'FUTURO',
            )
            .length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          SixWebEntry(
            order: 0,
            child: _ResumoFormasRecebimentoCard(
              total: tipos.length,
              ativos: ativos,
              imediatos: imediatos,
              futuros: futuros,
            ),
          ),
          const SizedBox(height: 12),
          if (_carregando && _tipos.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_erro != null && _tipos.isNotEmpty) ...<Widget>[
            _InlineErrorCard(
              mensagem: _erro!,
              onRetry: _carregando ? null : _carregarTipos,
            ),
            const SizedBox(height: 10),
          ],
          Expanded(child: _buildBody(tipos)),
          const SizedBox(height: 12),
          _buildBottomBar(total: tipos.length, ativos: ativos),
        ],
      ),
    );
  }

  Widget _buildBody(List<TiposRecebimento> tipos) {
    if (_carregando && _tipos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SixBackendLoading(
            title: context.t(
              'configuracoes.recebimento.loadingTitle',
              fallback: 'Carregando formas de recebimento',
            ),
            subtitle: context.t(
              'configuracoes.recebimento.loadingSubtitle',
              fallback: 'Sincronizando as configurações da empresa no backend.',
            ),
            animation: SixBackendLoadingAnimation.skeletonPulse,
            leadingIcon: Icons.payments_rounded,
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(
            4,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
              child: const SixWebLoadingBlock(height: 132),
            ),
          ),
        ],
      );
    }

    if (_erro != null && _tipos.isEmpty) {
      return _ErrorStateCard(mensagem: _erro!, onRetry: _carregarTipos);
    }

    if (tipos.isEmpty) {
      return _EmptyStateCard(onReload: _carregarTipos);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tipos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final TiposRecebimento tipo = tipos[index];
        return SixWebEntry(
          order: index + 2,
          child: _TipoRecebimentoCard(
            tipo: tipo,
            salvando: _salvandoCodigo == tipo.codigoTipo,
            onEditar: () => _editarTipo(tipo),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({required int total, required int ativos}) {
    final ThemeData theme = Theme.of(context);
    final bool bloqueado = _restaurandoPadrao || _salvandoCodigo != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 820;
          final Widget info = Text(
            '${context.t('configuracoes.recebimento.countPrefix', fallback: 'Tipos carregados')}: $total • ${context.t('configuracoes.recebimento.activeCount', fallback: 'Ativos')}: $ativos',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          );

          final Widget actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed:
                    (_carregando || bloqueado) ? null : () => _carregarTipos(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.t(
                    'configuracoes.recebimento.refreshAction',
                    fallback: 'Atualizar',
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed:
                    (_carregando || bloqueado || _tipos.isEmpty)
                        ? null
                        : _restaurarPadrao,
                icon:
                    _restaurandoPadrao
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.restart_alt_rounded),
                label: Text(
                  context.t(
                    'configuracoes.recebimento.restoreAction',
                    fallback: 'Restaurar padrão',
                  ),
                ),
              ),
            ],
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[info, const SizedBox(height: 10), actions],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: info),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  int _numeroTipo(String codigoTipo) {
    final String normalized = codigoTipo.trim().toLowerCase();
    final RegExpMatch? match = RegExp(r'^tipo(\d+)$').firstMatch(normalized);
    if (match == null) return 999;
    return int.tryParse(match.group(1) ?? '') ?? 999;
  }
}

class _ResumoFormasRecebimentoCard extends StatelessWidget {
  const _ResumoFormasRecebimentoCard({
    required this.total,
    required this.ativos,
    required this.imediatos,
    required this.futuros,
  });

  final int total;
  final int ativos;
  final int imediatos;
  final int futuros;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 860;
          final List<_MiniMetric> metricas = <_MiniMetric>[
            _MiniMetric(
              icon: Icons.payments_rounded,
              label: context.t(
                'configuracoes.recebimento.metricsTotal',
                fallback: 'Tipos configurados',
              ),
              value: '$total',
            ),
            _MiniMetric(
              icon: Icons.verified_rounded,
              label: context.t(
                'configuracoes.recebimento.metricsActive',
                fallback: 'Ativos',
              ),
              value: '$ativos',
            ),
            _MiniMetric(
              icon: Icons.flash_on_rounded,
              label: context.t(
                'configuracoes.recebimento.metricsImmediate',
                fallback: 'Natureza imediata',
              ),
              value: '$imediatos',
            ),
            _MiniMetric(
              icon: Icons.schedule_rounded,
              label: context.t(
                'configuracoes.recebimento.metricsFuture',
                fallback: 'Natureza futura',
              ),
              value: '$futuros',
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.t(
                  'configuracoes.recebimento.contextTitle',
                  fallback: 'Formas de recebimento configuráveis',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t(
                  'configuracoes.recebimento.contextDescription',
                  fallback:
                      'Personalize como sua empresa recebe pagamentos. Os códigos internos são mantidos pelo sistema, mas o nome e o comportamento podem ser ajustados.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              if (compacto)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: metricas
                      .map(
                        (_MiniMetric item) =>
                            SizedBox(width: 190, child: _buildMetrica(item)),
                      )
                      .toList(growable: false),
                )
              else
                Row(
                  children: metricas
                      .map(
                        (_MiniMetric item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _buildMetrica(item),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetrica(_MiniMetric metrica) {
    return Builder(
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(metrica.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metrica.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                metrica.value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TipoRecebimentoCard extends StatefulWidget {
  const _TipoRecebimentoCard({
    required this.tipo,
    required this.onEditar,
    required this.salvando,
  });

  final TiposRecebimento tipo;
  final VoidCallback onEditar;
  final bool salvando;

  @override
  State<_TipoRecebimentoCard> createState() => _TipoRecebimentoCardState();
}

class _TipoRecebimentoCardState extends State<_TipoRecebimentoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color corDestaque =
        _parseHexColor(widget.tipo.corHex) ?? theme.colorScheme.primary;
    final bool naturezaFutura =
        widget.tipo.naturezaRecebimento.trim().toUpperCase() == 'FUTURO';
    final IconData icone = _resolverIcone(
      widget.tipo.icone,
      naturezaRecebimento: widget.tipo.naturezaRecebimento,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _hovered
                  ? theme.colorScheme.primary.withOpacity(0.02)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _hovered
                    ? theme.colorScheme.primary.withOpacity(0.28)
                    : theme.colorScheme.outlineVariant,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.shadowColor.withOpacity(_hovered ? 0.10 : 0.04),
              blurRadius: _hovered ? 16 : 10,
              offset: Offset(0, _hovered ? 8 : 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compacto = constraints.maxWidth < 940;

            final Widget conteudo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: corDestaque.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icone, color: corDestaque),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.tipo.descricaoExibicao.trim().isEmpty
                                ? context.t(
                                  'configuracoes.recebimento.unnamed',
                                  fallback: 'Sem nome definido',
                                )
                                : widget.tipo.descricaoExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _chip(
                                context: context,
                                icon: Icons.tag_rounded,
                                label: widget.tipo.codigoTipo,
                              ),
                              _chip(
                                context: context,
                                icon:
                                    naturezaFutura
                                        ? Icons.schedule_rounded
                                        : Icons.flash_on_rounded,
                                label: _naturezaLabel(
                                  context,
                                  widget.tipo.naturezaRecebimento,
                                ),
                              ),
                              _chip(
                                context: context,
                                icon:
                                    widget.tipo.ativo
                                        ? Icons.verified_rounded
                                        : Icons.pause_circle_outline_rounded,
                                label:
                                    widget.tipo.ativo
                                        ? context.t(
                                          'common.active',
                                          fallback: 'Ativo',
                                        )
                                        : context.t(
                                          'common.inactive',
                                          fallback: 'Inativo',
                                        ),
                                foreground:
                                    widget.tipo.ativo
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF991B1B),
                                background:
                                    widget.tipo.ativo
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!compacto) ...<Widget>[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: widget.salvando ? null : widget.onEditar,
                        icon:
                            widget.salvando
                                ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.edit_rounded),
                        label: Text(
                          context.t('common.edit', fallback: 'Editar'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _infoPill(
                      context,
                      title: context.t(
                        'configuracoes.recebimento.requiresClient',
                        fallback: 'Exige cliente',
                      ),
                      value:
                          widget.tipo.exigeCliente
                              ? context.t('common.yes', fallback: 'Sim')
                              : context.t('common.no', fallback: 'Não'),
                    ),
                    _infoPill(
                      context,
                      title: context.t(
                        'configuracoes.recebimento.installments',
                        fallback: 'Aceita parcelamento',
                      ),
                      value:
                          widget.tipo.aceitaParcelamento
                              ? context.t('common.yes', fallback: 'Sim')
                              : context.t('common.no', fallback: 'Não'),
                    ),
                    _infoPill(
                      context,
                      title: context.t(
                        'configuracoes.recebimento.displayOrder',
                        fallback: 'Ordem',
                      ),
                      value: '${widget.tipo.ordemExibicao}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _naturezaDescricao(context, widget.tipo.naturezaRecebimento),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (compacto) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: widget.salvando ? null : widget.onEditar,
                      icon:
                          widget.salvando
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.edit_rounded),
                      label: Text(context.t('common.edit', fallback: 'Editar')),
                    ),
                  ),
                ],
              ],
            );

            return conteudo;
          },
        ),
      ),
    );
  }

  Widget _chip({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? foreground,
    Color? background,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color fg = foreground ?? theme.colorScheme.onSurfaceVariant;
    final Color bg = background ?? theme.colorScheme.surfaceContainerHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$title: ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _naturezaLabel(BuildContext context, String natureza) {
    final String code = natureza.trim().toUpperCase();
    if (code == 'FUTURO') {
      return context.t(
        'configuracoes.recebimento.natureFuture',
        fallback: 'Futuro',
      );
    }
    return context.t(
      'configuracoes.recebimento.natureImmediate',
      fallback: 'Imediato',
    );
  }

  String _naturezaDescricao(BuildContext context, String natureza) {
    final String code = natureza.trim().toUpperCase();
    if (code == 'FUTURO') {
      return context.t(
        'configuracoes.recebimento.natureFutureDescription',
        fallback: 'Gera valor a receber para uma data futura.',
      );
    }
    return context.t(
      'configuracoes.recebimento.natureImmediateDescription',
      fallback: 'Entra no caixa no momento do recebimento.',
    );
  }
}

class _TipoRecebimentoEditDialog extends StatefulWidget {
  const _TipoRecebimentoEditDialog({required this.tipo});

  final TiposRecebimento tipo;

  @override
  State<_TipoRecebimentoEditDialog> createState() =>
      _TipoRecebimentoEditDialogState();
}

class _TipoRecebimentoEditDialogState
    extends State<_TipoRecebimentoEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _ordemController;
  late final TextEditingController _corController;
  late final TextEditingController _iconeController;
  late String _natureza;
  late bool _ativo;
  late bool _exigeCliente;
  late bool _aceitaParcelamento;

  static const List<String> _coresSugestao = <String>[
    '#16A34A',
    '#0EA5E9',
    '#F59E0B',
    '#8B5CF6',
    '#EF4444',
    '#64748B',
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.tipo.descricaoExibicao,
    );
    _ordemController = TextEditingController(
      text: widget.tipo.ordemExibicao.toString(),
    );
    _corController = TextEditingController(text: widget.tipo.corHex);
    _iconeController = TextEditingController(text: widget.tipo.icone);
    _natureza =
        widget.tipo.naturezaRecebimento.trim().toUpperCase() == 'FUTURO'
            ? 'FUTURO'
            : 'IMEDIATO';
    _ativo = widget.tipo.ativo;
    _exigeCliente = widget.tipo.exigeCliente;
    _aceitaParcelamento = widget.tipo.aceitaParcelamento;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ordemController.dispose();
    _corController.dispose();
    _iconeController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState?.validate() != true) return;

    final String corNormalizada = _normalizarHex(_corController.text);

    Navigator.of(context).pop(
      widget.tipo.copyWith(
        descricaoExibicao: _nomeController.text.trim(),
        naturezaRecebimento: _natureza,
        ativo: _ativo,
        exigeCliente: _exigeCliente,
        aceitaParcelamento: _aceitaParcelamento,
        ordemExibicao: int.tryParse(_ordemController.text.trim()) ?? 1,
        corHex: corNormalizada,
        icone: _iconeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
      title: Text(
        context.t(
          'configuracoes.recebimento.editDialogTitle',
          fallback: 'Editar forma de recebimento',
        ),
      ),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  initialValue: widget.tipo.codigoTipo,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'configuracoes.recebimento.technicalCode',
                      fallback: 'Código técnico',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'configuracoes.recebimento.displayName',
                      fallback: 'Nome de exibição',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.text_fields_rounded),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.t(
                        'configuracoes.recebimento.validationName',
                        fallback: 'Informe o nome de exibição.',
                      );
                    }
                    if (value.trim().length < 2) {
                      return context.t(
                        'configuracoes.recebimento.validationNameLength',
                        fallback: 'Use pelo menos 2 caracteres.',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _natureza,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'configuracoes.recebimento.nature',
                      fallback: 'Natureza',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.swap_horiz_rounded),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'IMEDIATO',
                      child: Text(
                        context.t(
                          'configuracoes.recebimento.natureImmediate',
                          fallback: 'Imediato',
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'FUTURO',
                      child: Text(
                        context.t(
                          'configuracoes.recebimento.natureFuture',
                          fallback: 'Futuro',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _natureza = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ordemController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: context.t(
                      'configuracoes.recebimento.displayOrder',
                      fallback: 'Ordem de exibição',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.reorder_rounded),
                  ),
                  validator: (String? value) {
                    final int? ordem = int.tryParse(value?.trim() ?? '');
                    if (ordem == null || ordem <= 0) {
                      return context.t(
                        'configuracoes.recebimento.validationOrder',
                        fallback:
                            'Informe uma ordem válida maior ou igual a 1.',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _corController,
                        decoration: InputDecoration(
                          labelText: context.t(
                            'configuracoes.recebimento.color',
                            fallback: 'Cor (opcional)',
                          ),
                          hintText: '#16A34A',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.palette_outlined),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _CorPreview(hex: _corController.text),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 42,
                            minHeight: 42,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (String? value) {
                          final String texto = value?.trim() ?? '';
                          if (texto.isEmpty) return null;
                          if (_parseHexColor(texto) == null) {
                            return context.t(
                              'configuracoes.recebimento.validationColor',
                              fallback: 'Use um HEX válido no formato #RRGGBB.',
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _coresSugestao
                      .map(
                        (String cor) => InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              _corController.text = cor;
                            });
                          },
                          child: _CorPreview(hex: cor, compact: false),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _iconeController,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'configuracoes.recebimento.icon',
                      fallback: 'Ícone (opcional)',
                    ),
                    hintText: 'payments_rounded',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: Icon(
                      _resolverIcone(
                        _iconeController.text,
                        naturezaRecebimento: _natureza,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _ToggleTile(
                  value: _ativo,
                  title: context.t('common.active', fallback: 'Ativo'),
                  subtitle: context.t(
                    'configuracoes.recebimento.activeDescription',
                    fallback:
                        'Controla se a forma pode ser utilizada nos fluxos.',
                  ),
                  onChanged: (bool value) => setState(() => _ativo = value),
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  value: _exigeCliente,
                  title: context.t(
                    'configuracoes.recebimento.requiresClient',
                    fallback: 'Exige cliente',
                  ),
                  subtitle: context.t(
                    'configuracoes.recebimento.requiresClientDescription',
                    fallback:
                        'Obrigatório quando esta forma depende de um cliente identificado.',
                  ),
                  onChanged:
                      (bool value) => setState(() => _exigeCliente = value),
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  value: _aceitaParcelamento,
                  title: context.t(
                    'configuracoes.recebimento.installments',
                    fallback: 'Aceita parcelamento',
                  ),
                  subtitle: context.t(
                    'configuracoes.recebimento.installmentsDescription',
                    fallback: 'Permite dividir o recebimento em parcelas.',
                  ),
                  onChanged:
                      (bool value) =>
                          setState(() => _aceitaParcelamento = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('common.cancel', fallback: 'Cancelar')),
        ),
        FilledButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.check_rounded),
          label: Text(context.t('common.save', fallback: 'Salvar')),
        ),
      ],
    );
  }

  String _normalizarHex(String input) {
    final String texto = input.trim();
    if (texto.isEmpty) return '';
    final String semHash = texto.startsWith('#') ? texto.substring(1) : texto;
    return '#${semHash.toUpperCase()}';
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.mensagem, required this.onRetry});

  final String mensagem;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry == null ? null : () => onRetry!.call(),
            child: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.mensagem, required this.onRetry});

  final String mensagem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t(
                'configuracoes.recebimento.errorStateTitle',
                fallback: 'Não foi possível carregar as configurações',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.t('common.tryAgain', fallback: 'Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onReload});

  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t(
              'configuracoes.recebimento.emptyTitle',
              fallback: 'Nenhuma forma de recebimento encontrada',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t(
              'configuracoes.recebimento.emptyDescription',
              fallback:
                  'Atualize a tela para sincronizar os tipos configurados da empresa.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t(
                'configuracoes.recebimento.refreshAction',
                fallback: 'Atualizar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CorPreview extends StatelessWidget {
  const _CorPreview({required this.hex, this.compact = true});

  final String hex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color cor = _parseHexColor(hex) ?? const Color(0xFFE2E8F0);
    return Container(
      width: compact ? 18 : 28,
      height: compact ? 18 : 28,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(compact ? 6 : 999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
    );
  }
}

class _MiniMetric {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class _EscCloseScope extends StatelessWidget {
  const _EscCloseScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _CloseDialogIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

Color? _parseHexColor(String? value) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final String normalized = text.startsWith('#') ? text.substring(1) : text;
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) {
    return null;
  }
  return Color(int.parse('FF$normalized', radix: 16));
}

IconData _resolverIcone(String value, {required String naturezaRecebimento}) {
  final String normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );

  const Map<String, IconData> icones = <String, IconData>{
    'payments': Icons.payments_rounded,
    'paymentsrounded': Icons.payments_rounded,
    'money': Icons.attach_money_rounded,
    'cash': Icons.money_rounded,
    'pix': Icons.qr_code_2_rounded,
    'creditcard': Icons.credit_card_rounded,
    'debitcard': Icons.credit_card_rounded,
    'boleto': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'invoice': Icons.receipt_long_rounded,
    'schedule': Icons.schedule_rounded,
    'future': Icons.schedule_rounded,
    'accountbalancewallet': Icons.account_balance_wallet_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  if (normalized.isNotEmpty && icones.containsKey(normalized)) {
    return icones[normalized]!;
  }

  final int? decimalCodePoint = int.tryParse(value.trim());
  if (decimalCodePoint != null) {
    return IconData(decimalCodePoint, fontFamily: 'MaterialIcons');
  }

  final String raw = value.trim().toLowerCase();
  if (raw.startsWith('0x')) {
    final int? hexCodePoint = int.tryParse(raw.substring(2), radix: 16);
    if (hexCodePoint != null) {
      return IconData(hexCodePoint, fontFamily: 'MaterialIcons');
    }
  }

  if (naturezaRecebimento.trim().toUpperCase() == 'FUTURO') {
    return Icons.schedule_rounded;
  }
  return Icons.payments_rounded;
}
