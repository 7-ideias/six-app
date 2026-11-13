import 'package:sixpos/presentation/components/web/agenda_filtros_avancados_web.dart';
import 'package:sixpos/presentation/screens/gastos_categorias_web.dart';
import 'package:sixpos/presentation/screens/faturas_cartao_web.dart';
import 'package:sixpos/presentation/components/web/financeiro_configuracao_web_dialog.dart';
import 'package:sixpos/presentation/components/web/agenda_resumo_periodo_web.dart';
import 'package:sixpos/presentation/components/agenda_financeira_status_labels.dart';
import 'package:sixpos/data/models/agenda_financeira_baixa_model.dart';
import 'package:sixpos/core/services/agenda_venda_comprovante_service.dart';
import 'package:sixpos/presentation/components/agenda_itens_venda_resumo.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/models/competencia_financeira.dart';
import 'package:sixpos/presentation/components/web/agenda_financeira_lancamento_card_web.dart';
import 'package:sixpos/core/utils/agenda_financeira_ordenacao_calendario.dart';
import '../../core/utils/agenda_forma_pagamento_exibicao.dart';
import '../components/web/payment_name_editor_web.dart';
import '../../domain/services/caixa/caixa_service.dart';

import 'package:sixpos/data/models/agenda_imposto_renda.dart';
import 'package:sixpos/presentation/components/web/agenda_imposto_renda_web_fields.dart';

import 'recebiveis_vendas_web.dart';
import 'configuracoes_espaco_web.dart';

import 'package:sixpos/presentation/components/web/six_web_recebimento_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_financial_launch_delete_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_labels.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_confirmacao.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/six_web_action_styles.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/models/web_header_assets_model.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

import '../../providers/locale_settings_provider.dart';
import '../components/web/six_managed_web_hero.dart';
import '../components/web/six_web_operational_texts.dart';
import '../layouts/six_web_page_shell.dart';
import '../theme/web_theme_tokens.dart';

class AgendaFinanceiraWeb extends StatefulWidget {
  const AgendaFinanceiraWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AgendaFinanceiraWeb> createState() => _AgendaFinanceiraWebState();
}

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb> {
  List<TiposRecebimento> _tiposPagamentoEditaveis = [];
  bool _podeEditarTiposPagamento = false;
  bool _editandoTipoPagamento = false;

  Future<String?> _editarNomeTipoPagamento(String nome) async {
    if (!_podeEditarTiposPagamento ||
        _editandoTipoPagamento ||
        _service.espacoFinanceiro != 'EMPRESA') {
      return null;
    }
    final candidatos = _tiposPagamentoEditaveis.where(
      (t) => t.descricaoExibicao.trim() == nome,
    );
    if (candidatos.length != 1) return null;
    final tipo = candidatos.single;
    _editandoTipoPagamento = true;
    try {
      final TiposRecebimento? salvo = await showDialog<TiposRecebimento>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentNameEditorWeb(
          tipo: tipo,
          service: CaixaService(apiClient: _caixaApiClient),
        ),
      );
      if (!mounted || salvo == null) return null;
      setState(() {
        _tiposPagamentoEditaveis = [
          for (final item in _tiposPagamentoEditaveis)
            if (item.codigoTipo == salvo.codigoTipo) salvo else item,
        ];
        final selecionados = _formasPagamentoSelecionadas
            .map((label) => _codigoTipoPorDescricaoFormaPagamento[label])
            .whereType<String>()
            .toSet();
        final formas = _montarFormasPagamento(_tiposPagamentoEditaveis);
        _tiposRecebimentoFiltro = ['Todos', ...formas];
        _formasPagamentoSelecionadas
          ..clear()
          ..addAll(
            formas.where(
              (label) => selecionados.contains(
                _codigoTipoPorDescricaoFormaPagamento[label],
              ),
            ),
          );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('paymentSettings.saved'))),
      );
      return salvo.descricaoExibicao;
    } finally {
      _editandoTipoPagamento = false;
    }
  }

  bool _trocandoEspaco = false;
  Future<void> _trocarEspaco(String espaco) async {
    if (_trocandoEspaco ||
        _carregando ||
        _executandoAcao ||
        _service.espacoFinanceiro == espaco) {
      return;
    }
    setState(() {
      _trocandoEspaco = true;
      _gruposAgenda.clear();
      _itensConfirmados.clear();
      _centrosCustoSelecionados.clear();
      _formasPagamentoSelecionadas.clear();
      _service.espacoFinanceiro = espaco;
      _acoesService.espacoFinanceiro = espaco;
      _centrosCusto = [];
    });
    _salvarPreferenciasAgendaFinanceira();
    await _carregarTiposPagamentoConfigurados();
    await _carregarCentrosCusto();
    if (mounted) await _consultar(mostrarFeedback: true);
    if (mounted) setState(() => _trocandoEspaco = false);
  }

  Future<void> _configurarEspaco() async {
    await showFinanceiroConfiguracaoWebDialog<void>(
      context: context,
      title: context.t('space.settings'),
      child: ConfiguracoesEspacoWeb(espaco: _service.espacoFinanceiro),
    );
    if (mounted) await _carregarCentrosCusto();
  }

  bool _somenteImpostoRenda = false;

  bool get _filtrosOcupados =>
      _trocandoEspaco || _carregando || _executandoAcao;

  Widget _seletorEspaco() {
    final tokens = WebThemeTokens.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          context.t('agenda.web.space'),
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: tokens.secondaryText,
            selectedForegroundColor: tokens.primaryText,
            selectedBackgroundColor: tokens.selectedBackground,
            side: BorderSide(color: tokens.cardBorder),
          ),
          segments: [
            for (final tipo in ['EMPRESA', 'PESSOAL'])
              ButtonSegment(value: tipo, label: Text(context.t('space.$tipo'))),
          ],
          selected: {_service.espacoFinanceiro},
          onSelectionChanged:
              _filtrosOcupados ? null : (value) => _trocarEspaco(value.first),
        ),
        TextButton.icon(
          onPressed: _filtrosOcupados ? null : _configurarEspaco,
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: Text(context.t('agenda.web.manageSpace')),
        ),
      ],
    );
  }

  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService =
      AgendaFinanceiraAcoesFinanceiras();
  late final CaixaApiClient _caixaApiClient = HttpCaixaApiClient(
    espacoFinanceiro: () => _service.espacoFinanceiro,
  );
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  static const String _periodoIntervaloPersonalizado =
      'Intervalo personalizado';
  static const List<String> _periodos = <String>[
    'Hoje',
    'Próximos 7 dias',
    'Este mês',
    'Próximo mês',
    _periodoIntervaloPersonalizado,
  ];
  static const List<String> _tipos = <String>['Todos', 'Receber', 'Pagar'];
  static const List<String> _status = <String>[
    'Todos',
    'Previsto',
    'Pendente',
    'Vence hoje',
    'Vencido',
    'Pago',
    'Recebido',
    'Parcial',
    'Cancelado',
  ];

  final Map<String, String> _backendPorDescricaoFormaPagamento =
      <String, String>{
        'Pix': 'PIX',
        'Boleto': 'BOLETO',
        'Transferência': 'TRANSFERENCIA',
        'Cartão de crédito': 'CARTAO_CREDITO',
        'Cartão Crédito': 'CARTAO_CREDITO',
        'Cartão de débito': 'CARTAO_DEBITO',
        'Cartão Débito': 'CARTAO_DEBITO',
        'Débito automático': 'DEBITO_AUTOMATICO',
        'Dinheiro': 'DINHEIRO',
      };

  final Map<String, String> _descricaoPorBackendFormaPagamento =
      <String, String>{
        'PIX': 'Pix',
        'BOLETO': 'Boleto',
        'TRANSFERENCIA': 'Transferência',
        'CARTAO_CREDITO': 'Cartão de crédito',
        'CARTAO_DEBITO': 'Cartão de débito',
        'DEBITO_AUTOMATICO': 'Débito automático',
        'DINHEIRO': 'Dinheiro',
      };

  final Map<String, String> _codigoTipoPorDescricaoFormaPagamento =
      <String, String>{
        'Dinheiro': 'tipo1',
        'Pix': 'tipo2',
        'Cartão de crédito': 'tipo3',
        'Cartão de débito': 'tipo4',
        'Boleto': 'tipo5',
        'Fiado': 'tipo6',
        'Débito automático': 'tipo7',
        'Transferência': 'tipo8',
        'Vale': 'tipo9',
        'Outros': 'tipo10',
      };

  List<String> _tiposRecebimentoFiltro = <String>['Todos'];
  List<CentroCustoModel> _centrosCusto = <CentroCustoModel>[];
  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];

  int _abaSelecionada = 0;
  bool _calendarioDataDecrescente = true;
  String _periodoSelecionado = 'Próximos 7 dias';
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  final Set<String> _formasPagamentoSelecionadas = <String>{};
  final Set<String> _centrosCustoSelecionados = <String>{};
  bool _carregando = false;
  bool _executandoAcao = false;
  bool _mostrarCancelados = false;
  bool _overlayInicialAberto = false;
  bool _usuarioAlterouFiltros = false;
  PreferenciasIndividuaisDoUsuarioModel? _preferenciasAgendaRestauradas;
  Future<void> _salvamentoPreferencias = Future<void>.value();
  DateTime? _ultimaConsultaEm;

  List<Map<String, dynamic>> get _itensAgenda => _gruposAgenda
      .expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>(),)
      .where(_passaFiltrosLocais)
      .toList();

  List<Map<String, dynamic>> get _itensConfirmadosFiltrados =>
      _itensConfirmados.where(_passaFiltrosLocais).toList();

  double get _totalReceberPrevisto =>
      _somar(_itensAgenda, 'receber', 'valorRestante');
  double get _totalPagarPrevisto =>
      _somar(_itensAgenda, 'pagar', 'valorRestante');
  double get _totalRecebidoConfirmado =>
      _somar(_itensConfirmadosFiltrados, 'receber', 'valorConfirmado');
  double get _totalPagoConfirmado =>
      _somar(_itensConfirmadosFiltrados, 'pagar', 'valorConfirmado');
  double get _saldoARealizar => _totalReceberPrevisto - _totalPagarPrevisto;
  double get _saldoPrevisto =>
      (_totalRecebidoConfirmado + _totalReceberPrevisto) -
      (_totalPagoConfirmado + _totalPagarPrevisto);
  double get _saldoConfirmado =>
      _totalRecebidoConfirmado - _totalPagoConfirmado;

  @override
  void initState() {
    super.initState();
    final hoje = _hojeNormalizado();
    _dataInicioPersonalizada = DateTime(hoje.year, hoje.month, 1);
    _dataFimPersonalizada = hoje;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool abriuOverlay = await _abrirComoOverlayInicialSeNecessario();
      if (abriuOverlay || !mounted) return;
      await _restaurarPreferenciasAgendaFinanceira();
      await _restaurarPreferenciasAgendaFinanceiraBackend();
      if (!mounted) return;
      await _carregarTiposPagamentoConfigurados();
      await _carregarCentrosCusto();
      final preferencias = _preferenciasAgendaRestauradas;
      if (!mounted) return;
      if (preferencias != null && !_usuarioAlterouFiltros) {
        _aplicarPreferenciasAgendaFinanceira(preferencias);
      }
      await _consultar();
    });
  }

  Future<void> _restaurarPreferenciasAgendaFinanceira() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
      return;
    }
    _aplicarPreferenciasAgendaFinanceira(preferencias);
  }

  Future<void> _restaurarPreferenciasAgendaFinanceiraBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
        return;
      }
      _aplicarPreferenciasAgendaFinanceira(preferencias);
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar preferencias da agenda financeira: $error\n$stackTrace',
      );
    }
  }

  void _aplicarPreferenciasAgendaFinanceira(
    PreferenciasIndividuaisDoUsuarioModel preferencias,
  ) {
    _preferenciasAgendaRestauradas = preferencias;
    final AgendaFinanceiraFiltrosPreferencia filtros =
        preferencias.agendaFinanceiraFiltrosWeb;
    final String periodo = _periodoLabelPreferencia(filtros.periodo);
    final String tipo = _tipoLabelPreferencia(filtros.tipo);
    final String status = _statusLabelPreferencia(filtros.status);
    final Set<String> formasPagamento = filtros.tiposDePagamento
        .map(_formaPagamentoLabelPorCodigoPreferencia)
        .whereType<String>()
        .where(_tiposRecebimentoFiltro.contains)
        .toSet();

    setState(() {
      _service.espacoFinanceiro = filtros.espacoFinanceiro;
      _acoesService.espacoFinanceiro = filtros.espacoFinanceiro;
      _somenteImpostoRenda = filtros.somenteImpostoRenda;
      _mostrarCancelados = filtros.mostrarCancelados;
      _abaSelecionada = AgendaFinanceiraFiltrosPreferencia.visoes.indexOf(
        filtros.visaoSelecionada,
      );
      _calendarioDataDecrescente = filtros.calendarioDataDecrescente;
      _centrosCustoSelecionados
        ..clear()
        ..addAll(
          _centrosCusto
              .where(
                (centro) =>
                    centro.ativo && filtros.centrosCustoIds.contains(centro.id),
              )
              .map((centro) => centro.nome),
        );
      if (_periodos.contains(periodo)) {
        _periodoSelecionado = periodo;
      }
      if (_tipos.contains(tipo)) {
        _tipoSelecionado = tipo;
      }
      if (_status.contains(status)) {
        _statusSelecionado = status;
      }
      if (filtros.dataInicio != null) {
        _dataInicioPersonalizada = _normalizarData(filtros.dataInicio!);
      }
      if (filtros.dataFim != null) {
        _dataFimPersonalizada = _normalizarData(filtros.dataFim!);
      }
      _formasPagamentoSelecionadas
        ..clear()
        ..addAll(formasPagamento);
      if (_usaPeriodoPersonalizado) {
        _ajustarPeriodoPersonalizadoSeguro();
      }
    });
  }

  bool _estaDentroDeDialog() {
    return context.findAncestorWidgetOfExactType<Dialog>() != null;
  }

  Future<bool> _abrirComoOverlayInicialSeNecessario() async {
    if (!widget.embedded ||
        widget.onBack == null ||
        _overlayInicialAberto ||
        _estaDentroDeDialog()) {
      return false;
    }
    _overlayInicialAberto = true;
    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    final BuildContext rootContext = rootNavigator.context;
    widget.onBack?.call();
    await Future<void>.delayed(Duration.zero);
    if (!rootContext.mounted) return true;
    final WebThemeTokens pageTokens = WebThemeTokens.of(rootContext);
    await showDialog<void>(
      context: rootContext,
      barrierColor: pageTokens.workspaceBackground.withValues(alpha: 0.72),
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;
        final WebThemeTokens tokens = WebThemeTokens.of(dialogContext);
        return _EscOverlayScope(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: tokens.surfaceElevated,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              width: size.width * 0.94,
              height: size.height * 0.90,
              child: AgendaFinanceiraWeb(
                embedded: true,
                onBack: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        );
      },
    );
    return true;
  }

  Future<void> _carregarTiposPagamentoConfigurados() async {
    final espaco = _service.espacoFinanceiro;
    _podeEditarTiposPagamento = false;
    try {
      final informacoes = await _caixaApiClient.getInformacoesBasicasDoCaixa();
      if (!mounted || espaco != _service.espacoFinanceiro) return;
      final formas = _montarFormasPagamento(informacoes.tiposRecebimento);
      setState(() {
        _tiposPagamentoEditaveis = informacoes.tiposRecebimento;
        _podeEditarTiposPagamento =
            espaco == 'EMPRESA' && informacoes.podeEditarTiposRecebimento;
        _tiposRecebimentoFiltro = <String>['Todos', ...formas];
        _formasPagamentoSelecionadas.removeWhere(
          (forma) => !_tiposRecebimentoFiltro.contains(forma),
        );
      });
    } catch (_) {}
  }

  Future<void> _carregarCentrosCusto() async {
    try {
      final centros = await _service.listarCentrosCusto();
      if (!mounted) return;
      setState(() => _centrosCusto = centros);
    } catch (_) {
      // Mantém a agenda disponível mesmo sem o catálogo.
    }
  }

  List<String> _montarFormasPagamento(List<TiposRecebimento> tipos) {
    final descricoes = <String>[];
    final backendAtualizado = Map<String, String>.from(
      _backendPorDescricaoFormaPagamento,
    );
    final descricaoAtualizada = Map<String, String>.from(
      _descricaoPorBackendFormaPagamento,
    );
    final codigoAtualizado = Map<String, String>.from(
      _codigoTipoPorDescricaoFormaPagamento,
    );
    final ativos = tipos.where((tipo) => tipo.ativo).toList()
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    for (final tipo in ativos) {
      final codigoTipo = tipo.codigoTipo.trim().toLowerCase();
      final backend = _backendFormaPagamentoPorCodigoTipo(codigoTipo);
      final descricao = tipo.descricaoExibicao.trim().isNotEmpty
          ? tipo.descricaoExibicao.trim()
          : (_descricaoPorBackendFormaPagamento[backend] ?? codigoTipo);
      if (descricao.isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      codigoAtualizado[descricao] = codigoTipo;
      descricaoAtualizada[codigoTipo] = descricao;
      if (backend != null) {
        backendAtualizado[descricao] = backend;
        descricaoAtualizada[backend] = descricao;
      }
    }
    if (descricoes.isNotEmpty) {
      _backendPorDescricaoFormaPagamento
        ..clear()
        ..addAll(backendAtualizado);
      _descricaoPorBackendFormaPagamento
        ..clear()
        ..addAll(descricaoAtualizada);
      _codigoTipoPorDescricaoFormaPagamento
        ..clear()
        ..addAll(codigoAtualizado);
    }
    return descricoes;
  }

  String? _backendFormaPagamentoPorCodigoTipo(String codigoTipo) {
    switch (codigoTipo.trim().toLowerCase()) {
      case 'tipo1':
        return 'DINHEIRO';
      case 'tipo2':
        return 'PIX';
      case 'tipo3':
        return 'CARTAO_CREDITO';
      case 'tipo4':
        return 'CARTAO_DEBITO';
      case 'tipo5':
        return 'BOLETO';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      case 'tipo8':
        return 'TRANSFERENCIA';
      default:
        return null;
    }
  }

  bool _passaFiltrosLocais(Map<String, dynamic> item) {
    final tipoOk =
        _tipoSelecionado == 'Todos' ||
        (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
        (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
    final statusOk =
        _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;
    final formaOk =
        _formasPagamentoSelecionadas.isEmpty ||
        _codigosTipoRecebimentoFiltro().contains(
          item['codigoTipoRecebimento']?.toString().trim().toLowerCase(),
        );
    final centroOk =
        _centrosCustoSelecionados.isEmpty ||
        _centrosCustoSelecionados.contains(item['centroDeCusto']?.toString());
    final cancelado = const {
      'cancelado',
      'cancelada',
    }.contains(item['status']?.toString().toLowerCase());
    final visibilidadeOk =
        _mostrarCancelados || _statusSelecionado == 'Cancelado' || !cancelado;
    return tipoOk && statusOk && formaOk && centroOk && visibilidadeOk;
  }

  Future<void> _consultar({bool mostrarFeedback = false}) async {
    if (_carregando) return;
    final erroPeriodo = _validarPeriodoSelecionado();
    if (erroPeriodo != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(erroPeriodo)));
      return;
    }
    setState(() => _carregando = true);
    try {
      final request = _buildRequest();
      final resultado = await _service.consultarAgendaEmParalelo(request);
      if (!mounted) return;
      _aplicarAgenda(resultado.agenda);
      _aplicarConfirmados(resultado.valoresConfirmados);
      _sincronizarValoresConfirmadosNosLancamentos();
      _ultimaConsultaEm = DateTime.now().toUtc();
      if (!resultado.valoresConfirmadosDisponiveis) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Agenda atualizada, mas os valores confirmados não puderam ser carregados.',
            ),
          ),
        );
      } else if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Agenda atualizada: ${_itensAgenda.length} lançamento(s).',
            ),
          ),
        );
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao consultar agenda (${e.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível consultar a agenda financeira.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  AgendaFinanceiraConsultaRequest _buildRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoRequest(),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: _tipoSelecionado == 'Todos'
            ? 'TODOS'
            : _tipoSelecionado.toUpperCase(),
        status: _statusFiltro(),
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: const <String>[],
        codigosTipoRecebimento: _codigosTipoRecebimentoFiltro(),
        centrosCusto: _centrosCustoSelecionados.toList(growable: false),
        clienteFornecedor: null,
        somenteCriticos: false,
        somenteImpostoRenda: _somenteImpostoRenda,
      ),
      visaoSelecionada: _abaSelecionada == 0
          ? 'AGENDA'
          : (_abaSelecionada == 1
                ? 'CALENDARIO'
                : (_abaSelecionada == 2
                      ? 'FLUXO_PREVISTO'
                      : 'VALORES_CONFIRMADOS')),
    );
  }

  AgendaFinanceiraPeriodoRequest _periodoRequest() {
    final base = _hojeNormalizado();
    switch (_periodoSelecionado) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'HOJE',
          dataInicio: base,
          dataFim: base,
        );
      case 'Este mês':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'ESTE_MES',
          dataInicio: DateTime(base.year, base.month, 1),
          dataFim: DateTime(base.year, base.month + 1, 0),
        );
      case 'Próximo mês':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PROXIMO_MES',
          dataInicio: DateTime(base.year, base.month + 1, 1),
          dataFim: DateTime(base.year, base.month + 2, 0),
        );
      case _periodoIntervaloPersonalizado:
        final inicio = _inicioPeriodoPersonalizado();
        final fim = _fimPeriodoPersonalizado();
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PERSONALIZADO',
          dataInicio: inicio,
          dataFim: fim,
        );
      default:
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PROXIMOS_7_DIAS',
          dataInicio: base,
          dataFim: base.add(const Duration(days: 7)),
        );
    }
  }

  DateTime _hojeNormalizado() {
    final hoje = context.read<LocaleSettingsProvider>().calendarNow;
    return DateTime(hoje.year, hoje.month, hoje.day);
  }

  DateTime _normalizarData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  bool get _usaPeriodoPersonalizado =>
      _periodoSelecionado == _periodoIntervaloPersonalizado;

  DateTime _limiteFimPeriodoPersonalizado(DateTime inicio) {
    final inicioNormalizado = _normalizarData(inicio);
    final limite = DateTime(
      inicioNormalizado.year + 1,
      inicioNormalizado.month,
      inicioNormalizado.day,
    );
    if (limite.month != inicioNormalizado.month) {
      return DateTime(
        inicioNormalizado.year + 1,
        inicioNormalizado.month + 1,
        0,
      );
    }
    return limite;
  }

  DateTime _inicioPeriodoPersonalizado() =>
      _normalizarData(_dataInicioPersonalizada);

  DateTime _fimPeriodoPersonalizado() => _normalizarData(_dataFimPersonalizada);

  String? _validarPeriodoSelecionado() {
    if (!_usaPeriodoPersonalizado) return null;
    final inicio = _inicioPeriodoPersonalizado();
    final fim = _fimPeriodoPersonalizado();
    if (fim.isBefore(inicio)) {
      return 'A data final não pode ser anterior à data inicial.';
    }
    if (fim.isAfter(_limiteFimPeriodoPersonalizado(inicio))) {
      return 'O intervalo personalizado deve ter no máximo 1 ano.';
    }
    return null;
  }

  void _selecionarPeriodo(String? periodo) {
    if (_filtrosOcupados) return;
    if (periodo == null) return;
    setState(() {
      _periodoSelecionado = periodo;
      if (_usaPeriodoPersonalizado) {
        _ajustarPeriodoPersonalizadoSeguro();
      }
    });
    _salvarPreferenciasAgendaFinanceira();
    unawaited(_consultar());
  }

  void _selecionarTipo(String? tipo) {
    if (_filtrosOcupados) return;
    if (tipo == null || !_tipos.contains(tipo)) {
      return;
    }
    setState(() => _tipoSelecionado = tipo);
    _salvarPreferenciasAgendaFinanceira();
    unawaited(_consultar());
  }

  void _selecionarStatus(String? status) {
    if (_filtrosOcupados) return;
    if (status == null || !_status.contains(status)) {
      return;
    }
    setState(() => _statusSelecionado = status);
    _salvarPreferenciasAgendaFinanceira();
    unawaited(_consultar());
  }

  void _salvarPreferenciasAgendaFinanceira() {
    _usuarioAlterouFiltros = true;
    final AgendaFinanceiraFiltrosPreferencia filtros =
        AgendaFinanceiraFiltrosPreferencia(
          espacoFinanceiro: _service.espacoFinanceiro,
          somenteImpostoRenda: _somenteImpostoRenda,
          mostrarCancelados: _mostrarCancelados,
          visaoSelecionada:
              AgendaFinanceiraFiltrosPreferencia.visoes[_abaSelecionada],
          calendarioDataDecrescente: _calendarioDataDecrescente,
          centrosCustoIds: _centrosCusto
              .where(
                (centro) =>
                    centro.ativo &&
                    _centrosCustoSelecionados.contains(centro.nome),
              )
              .map((centro) => centro.id)
              .toList(),
          periodo: AgendaFinanceiraPeriodoWebPreferenciaApi.fromCodigo(
            _periodoCodigoPreferencia(_periodoSelecionado),
            AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
          ),
          dataInicio: _usaPeriodoPersonalizado
              ? _inicioPeriodoPersonalizado()
              : null,
          dataFim: _usaPeriodoPersonalizado ? _fimPeriodoPersonalizado() : null,
          tipo: AgendaFinanceiraTipoWebPreferenciaApi.fromCodigo(
            _tipoCodigoPreferencia(_tipoSelecionado),
            AgendaFinanceiraTipoWebPreferencia.todos,
          ),
          status: AgendaFinanceiraStatusWebPreferenciaApi.fromCodigo(
            _statusCodigoPreferencia(_statusSelecionado),
            AgendaFinanceiraStatusWebPreferencia.todos,
          ),
          tiposDePagamento: _codigosTipoPagamentoPreferencia(
            _formasPagamentoSelecionadas,
          ),
        );
    // Serializa alterações rápidas para a última seleção prevalecer no backend.
    _salvamentoPreferencias = _salvamentoPreferencias
        .then(
          (_) => _usuarioService.atualizarPreferenciasIndividuais(
            agendaFinanceiraFiltrosWeb: filtros.toJson(),
            agendaFinanceiraPeriodoWeb: filtros.periodo.codigo,
            agendaFinanceiraTipoWeb: filtros.tipo.codigo,
            agendaFinanceiraStatusWeb: filtros.status.codigo,
            agendaFinanceiraTipoDePagamentoWeb: filtros.tiposDePagamento,
          ),
        )
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Erro ao salvar preferencias da agenda financeira: $error\n$stackTrace',
          );
        });
    unawaited(_salvamentoPreferencias);
  }

  String _periodoCodigoPreferencia(String periodo) {
    switch (periodo) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoWebPreferencia.hoje.codigo;
      case 'Este mês':
        return AgendaFinanceiraPeriodoWebPreferencia.esteMes.codigo;
      case 'Próximo mês':
        return AgendaFinanceiraPeriodoWebPreferencia.proximoMes.codigo;
      case _periodoIntervaloPersonalizado:
        return AgendaFinanceiraPeriodoWebPreferencia.personalizado.codigo;
      default:
        return AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias.codigo;
    }
  }

  String _periodoLabelPreferencia(
    AgendaFinanceiraPeriodoWebPreferencia periodo,
  ) {
    switch (periodo) {
      case AgendaFinanceiraPeriodoWebPreferencia.hoje:
        return 'Hoje';
      case AgendaFinanceiraPeriodoWebPreferencia.esteMes:
        return 'Este mês';
      case AgendaFinanceiraPeriodoWebPreferencia.proximoMes:
        return 'Próximo mês';
      case AgendaFinanceiraPeriodoWebPreferencia.personalizado:
        return _periodoIntervaloPersonalizado;
      case AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias:
        return 'Próximos 7 dias';
    }
  }

  String _tipoCodigoPreferencia(String tipo) {
    switch (tipo) {
      case 'Receber':
        return AgendaFinanceiraTipoWebPreferencia.receber.codigo;
      case 'Pagar':
        return AgendaFinanceiraTipoWebPreferencia.pagar.codigo;
      default:
        return AgendaFinanceiraTipoWebPreferencia.todos.codigo;
    }
  }

  String _tipoLabelPreferencia(AgendaFinanceiraTipoWebPreferencia tipo) {
    switch (tipo) {
      case AgendaFinanceiraTipoWebPreferencia.receber:
        return 'Receber';
      case AgendaFinanceiraTipoWebPreferencia.pagar:
        return 'Pagar';
      case AgendaFinanceiraTipoWebPreferencia.todos:
        return 'Todos';
    }
  }

  String _statusCodigoPreferencia(String status) {
    switch (status) {
      case 'Previsto':
        return AgendaFinanceiraStatusWebPreferencia.previsto.codigo;
      case 'Pendente':
        return AgendaFinanceiraStatusWebPreferencia.pendente.codigo;
      case 'Vence hoje':
        return AgendaFinanceiraStatusWebPreferencia.venceHoje.codigo;
      case 'Vencido':
        return AgendaFinanceiraStatusWebPreferencia.vencido.codigo;
      case 'Pago':
        return AgendaFinanceiraStatusWebPreferencia.pago.codigo;
      case 'Recebido':
        return AgendaFinanceiraStatusWebPreferencia.recebido.codigo;
      case 'Parcial':
        return AgendaFinanceiraStatusWebPreferencia.parcial.codigo;
      case 'Cancelado':
        return AgendaFinanceiraStatusWebPreferencia.cancelado.codigo;
      default:
        return AgendaFinanceiraStatusWebPreferencia.todos.codigo;
    }
  }

  String _statusLabelPreferencia(AgendaFinanceiraStatusWebPreferencia status) {
    switch (status) {
      case AgendaFinanceiraStatusWebPreferencia.previsto:
        return 'Previsto';
      case AgendaFinanceiraStatusWebPreferencia.pendente:
        return 'Pendente';
      case AgendaFinanceiraStatusWebPreferencia.venceHoje:
        return 'Vence hoje';
      case AgendaFinanceiraStatusWebPreferencia.vencido:
        return 'Vencido';
      case AgendaFinanceiraStatusWebPreferencia.pago:
        return 'Pago';
      case AgendaFinanceiraStatusWebPreferencia.recebido:
        return 'Recebido';
      case AgendaFinanceiraStatusWebPreferencia.parcial:
        return 'Parcial';
      case AgendaFinanceiraStatusWebPreferencia.cancelado:
        return 'Cancelado';
      case AgendaFinanceiraStatusWebPreferencia.todos:
        return 'Todos';
    }
  }

  List<String> _codigosTipoPagamentoPreferencia(Set<String> formasPagamento) {
    return formasPagamento
        .map(_codigoTipoFormaPagamentoSelecionada)
        .whereType<String>()
        .where((codigo) => codigo.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _formaPagamentoLabelPorCodigoPreferencia(String codigo) {
    final String codigoNormalizado = codigo.trim().toLowerCase();
    if (codigoNormalizado.isEmpty) {
      return null;
    }
    return _descricaoPorBackendFormaPagamento[codigoNormalizado] ??
        _descricaoPorBackendFormaPagamento[codigo.trim().toUpperCase()];
  }

  void _ajustarPeriodoPersonalizadoSeguro() {
    _dataInicioPersonalizada = _normalizarData(_dataInicioPersonalizada);
    _dataFimPersonalizada = _normalizarData(_dataFimPersonalizada);
    if (_dataFimPersonalizada.isBefore(_dataInicioPersonalizada)) {
      _dataFimPersonalizada = _dataInicioPersonalizada;
    }
    final limite = _limiteFimPeriodoPersonalizado(_dataInicioPersonalizada);
    if (_dataFimPersonalizada.isAfter(limite)) {
      _dataFimPersonalizada = limite;
    }
  }

  Future<void> _selecionarDataInicioPersonalizada() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataInicioPersonalizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada == null || !mounted) return;
    setState(() {
      _dataInicioPersonalizada = _normalizarData(selecionada);
      _ajustarPeriodoPersonalizadoSeguro();
    });
    _salvarPreferenciasAgendaFinanceira();
    await _consultar();
  }

  Future<void> _selecionarDataFimPersonalizada() async {
    final inicio = _normalizarData(_dataInicioPersonalizada);
    final limite = _limiteFimPeriodoPersonalizado(inicio);
    final fimAtual = _normalizarData(_dataFimPersonalizada);
    final initialDate =
        fimAtual.isBefore(inicio)
            ? inicio
            : (fimAtual.isAfter(limite) ? limite : fimAtual);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: inicio,
      lastDate: limite,
    );
    if (selecionada == null || !mounted) return;
    setState(() {
      _dataFimPersonalizada = _normalizarData(selecionada);
      _ajustarPeriodoPersonalizadoSeguro();
    });
    _salvarPreferenciasAgendaFinanceira();
    await _consultar();
  }

  List<String> _statusFiltro() {
    switch (_statusSelecionado) {
      case 'Previsto':
        return <String>['PREVISTO'];
      case 'Pendente':
        return <String>['PENDENTE'];
      case 'Vence hoje':
        return <String>['VENCE_HOJE'];
      case 'Vencido':
        return <String>['VENCIDO'];
      case 'Pago':
        return <String>['PAGO'];
      case 'Recebido':
        return <String>['RECEBIDO'];
      case 'Parcial':
        return <String>['PARCIAL'];
      case 'Cancelado':
        return <String>['CANCELADO'];
      default:
        return <String>[];
    }
  }

  List<String> _codigosTipoRecebimentoFiltro() {
    if (_formasPagamentoSelecionadas.isEmpty) return <String>[];
    return _formasPagamentoSelecionadas
        .map((forma) => _codigoTipoPorDescricaoFormaPagamento[forma])
        .whereType<String>()
        .where((codigo) => codigo.trim().isNotEmpty)
        .toList();
  }

  void _aplicarAgenda(Map<String, dynamic> payload) {
    final gruposRaw = payload['gruposAgenda'];
    final grupos = <Map<String, dynamic>>[];
    if (gruposRaw is List) {
      for (final grupo in gruposRaw.whereType<Map<String, dynamic>>()) {
        final itensRaw = grupo['itens'];
        grupos.add(<String, dynamic>{
          'grupo': grupo['titulo']?.toString() ?? 'Lançamentos',
          'descricao': grupo['descricao']?.toString() ?? '',
          'itens': itensRaw is List
              ? itensRaw
                    .whereType<Map<String, dynamic>>()
                    .map(_mapearItemAgenda)
                    .toList()
              : <Map<String, dynamic>>[],
        });
      }
    }
    _gruposAgenda
      ..clear()
      ..addAll(grupos);
  }

  void _aplicarConfirmados(Map<String, dynamic> payload) {
    final itens = payload['itens'];
    _itensConfirmados
      ..clear()
      ..addAll(
        itens is List
            ? itens
                  .whereType<Map<String, dynamic>>()
                  .map(_mapearItemConfirmado)
                  .toList()
            : <Map<String, dynamic>>[],
      );
  }

  Map<String, dynamic> _mapearItemAgenda(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR'
        ? 'pagar'
        : 'receber';
    final valorOriginal = _toDouble(item['valorOriginal'] ?? item['valor']);
    final quitado = const [
      'PAGO',
      'RECEBIDO',
    ].contains(item['status']?.toString().toUpperCase());
    final valorConfirmado = _toDouble(
      item['valorConfirmado'] ?? (quitado ? valorOriginal : 0),
    );
    final valorRestante = _toDouble(
      item['valorRestante'] ?? (valorOriginal - valorConfirmado),
    );
    final acoesRaw = item['acoesDisponiveis'];
    final acoes = acoesRaw is List
        ? acoesRaw
              .map((acao) => _acaoLabel(acao?.toString()))
              .where((acao) => acao.isNotEmpty)
              .toSet()
              .toList()
        : <String>[];
    if (!acoes.contains('Detalhes')) acoes.add('Detalhes');
    if (item['serieRecorrenciaId'] != null &&
        ![
          'PAGO',
          'RECEBIDO',
          'CANCELADO',
          'PARCIAL',
        ].contains(item['status']?.toString().toUpperCase())) {
      acoes.add('Cancelar');
    }
    return <String, dynamic>{
      ...item,
      'id': item['idLancamento']?.toString() ?? '',
      'contaFinanceiraId': item['contaFinanceiraId']?.toString(),
      'codigoOperacao': item['codigoOperacao']?.toString(),
      'tipo': tipo,
      'descricao': item['faturaCartaoId'] != null ? '${context.t('invoices.invoice')} ${item['descricao'] ?? ''}' : item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': valorOriginal,
      'valorConfirmado': valorConfirmado,
      'valorRestante': valorRestante,
      'valor': item['valorEvento'] ?? (valorRestante > 0 ? valorRestante : valorOriginal),
      'dataAgendaFormatada': _formatarDataIsoParaBr((item['dataAgenda'] ?? item['dataVencimento'])?.toString()),
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'origem': item['origem']?.toString() ?? '',
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': agendaFormaPagamentoExibicao(item),
      'empresa': _empresaNome(item['empresa']),
      'categoria': item['categoria']?.toString() ?? '',
      'centroCustoId': item['centroCustoId']?.toString(),
      'centroDeCusto': item['centroDeCusto']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'acoes': acoes,
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR'
        ? 'pagar'
        : 'receber';
    return <String, dynamic>{
      ...item,
      'acoes': <String>{
        'Detalhes',
        ...((item['acoesDisponiveis'] as List?) ?? [])
            .map((a) => _acaoLabel(a?.toString()))
            .where((a) => a.isNotEmpty),
      }.toList(),
      'id': item['idLancamento']?.toString() ?? '',
      'contaFinanceiraId': item['contaFinanceiraId']?.toString(),
      'tipo': tipo,
      'descricao': item['faturaCartaoId'] != null ? '${context.t('invoices.invoice')} ${item['descricao'] ?? ''}' : item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr(
        (item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString(),
      ),
      'dataAgendaFormatada': _formatarDataIsoParaBr((item['dataAgenda'] ?? item['dataVencimento'])?.toString()),
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': agendaFormaPagamentoExibicao(item),
      'empresa': _empresaNome(item['empresa']),
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  List<Map<String, dynamic>> _mapearLiquidacoes(dynamic raw) => raw is List
      ? raw
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  void _sincronizarValoresConfirmadosNosLancamentos() {
    final confirmadosPorId = <String, Map<String, dynamic>>{
      for (final item in _itensConfirmados) item['id'].toString(): item,
    };
    for (final grupo in _gruposAgenda) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      for (final item in itens) {
        // Event values already represent only this date, never the whole operation.
        if (item['tipoEvento'] != null) continue;
        final confirmado = confirmadosPorId[item['id']?.toString()];
        if (confirmado == null) continue;
        if (confirmado['valorOriginal'] != null) {
          item['valorOriginal'] = confirmado['valorOriginal'];
        }
        item['valorConfirmado'] = confirmado['valorConfirmado'];
        item['valorRestante'] = confirmado['valorRestante'];
        item['valor'] = _toDouble(confirmado['valorRestante']) > 0
            ? confirmado['valorRestante']
            : item['valorOriginal'];
        item['liquidacoes'] =
            confirmado['liquidacoes'] ?? <Map<String, dynamic>>[];
        if (_toDouble(confirmado['valorConfirmado']) > 0 &&
            _toDouble(confirmado['valorRestante']) > 0) {
          item['status'] = 'Parcial';
        }
      }
    }
  }

  Future<bool> _cancelarRecorrencia(Map<String, dynamic> item) async {
    if (_executandoAcao || item['serieRecorrenciaId'] == null) return false;
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return false;
    final config = AgendaFinanceiraRecorrencia.fromJson(item);
    final confirmacao = await confirmarImpactoRecorrencia(
      context,
      mobile: false,
      recorrencia: config,
      descricao: item['descricao']?.toString() ?? 'Lançamento recorrente',
      valorFormatado: _formatarMoeda(
        _toDouble(item['valorOriginal'] ?? item['valor']),
      ),
      vencimentoFormatado: item['vencimento']?.toString() ?? '',
      cancelar: true,
      permitirTrocarEscopo: true,
    );
    if (confirmacao == null || !mounted) return false;
    setState(() => _executandoAcao = true);
    try {
      await _service.cancelarRecorrencia(
        id,
        escopo: confirmacao.escopo,
        motivo: confirmacao.motivo,
      );
      if (!mounted) return false;
      await _consultar(mostrarFeedback: true);
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recorrenciaLabel(context, e.codigoRecorrencia ?? 'saveError'),
            ),
          ),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível cancelar a ocorrência.'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _mostrarDetalhesLancamento(Map<String, dynamic> item) async {
    if (_executandoAcao) return;
    final id = item['id']?.toString() ?? '';
    Map<String, dynamic> detalhe = <String, dynamic>{};
    bool fallback = false;
    setState(() => _executandoAcao = true);
    try {
      if (id.trim().isNotEmpty) {
        detalhe = await _service.buscarDetalheLancamento(id);
      }
      if (detalhe.isEmpty) fallback = true;
    } catch (_) {
      fallback = true;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
    if (!mounted) return;
    final faturaId=detalhe['faturaCartaoId']?.toString()??item['faturaCartaoId']?.toString();
    if(faturaId!=null&&faturaId.isNotEmpty){await _abrirCartoes(faturaId:faturaId);return;}
    bool editar = false;
    final alterado = await showSixWebAnimatedDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.t(
        'agenda.launchDetails.dialogBarrier',
        fallback: 'Detalhes do lançamento financeiro',
      ),
      overlayColor: const Color(0xC20B1324),
      overlayBlurSigma: 12,
      transitionDuration: const Duration(milliseconds: 320),
      builder: (dialogContext) => _LancamentoDetalhesDialog(
        item: item,
        detalhe: detalhe,
        fallback: fallback,
        formatarMoeda: _formatarMoeda,
        formatarData: _formatarDataFlexivel,
        onEditarLancamento: () {
          editar = true;
          Navigator.of(dialogContext).pop(false);
        },
        onBaixarComprovante: (formato) => _baixarComprovanteVenda(
          detalhe['idOperacaoComprovante']?.toString() ?? '',
          formato,
        ),
        onExcluirLancamento: () => _confirmarExcluirLancamentoDetalhe(item),
        onExcluirLiquidacao: (liquidacao) =>
            _confirmarExcluirLiquidacaoDetalhe(item, liquidacao),
      ),
    );
    if (editar && mounted) {
      await _editarLancamento(item);
    } else if (alterado == true && mounted) {
      await _consultar(mostrarFeedback: true);
    }
  }

  Future<void> _baixarComprovanteVenda(
    String idOperacao,
    FormatoImpressaoOperacao formato,
  ) async {
    try {
      final comprovantes = AgendaVendaComprovanteService();
      final pdf = await comprovantes.gerar(idOperacao, formato: formato);
      if (!mounted) return;
      final iniciou = comprovantes.baixarWeb(pdf);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            iniciou
                ? 'Comprovante PDF pronto para download.'
                : 'O navegador não iniciou o download. Verifique suas permissões.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível gerar o comprovante. Tente novamente.',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmarExcluirLancamentoDetalhe(
    Map<String, dynamic> item,
  ) async {
    if (_executandoAcao) return false;
    if (item['serieRecorrenciaId'] != null) {
      return _cancelarRecorrencia(item);
    }
    final id = item['id']?.toString() ?? '';
    if (id.trim().isEmpty) return false;

    final descricao = item['descricao']?.toString().trim();
    final valor = _toDouble(
      item['valorOriginal'] ?? item['valorTotalOperacao'] ?? item['valor'],
    );
    final status = item['status']?.toString().trim();

    final confirmado = await showSixWebFinancialLaunchDeleteDialog(
      context: context,
      description: descricao?.isNotEmpty == true
          ? descricao!
          : context.t(
              'agenda.launchDelete.unnamedLaunch',
              fallback: 'Lançamento sem descrição',
            ),
      amountLabel: _formatarMoeda(valor),
      statusLabel: status?.isNotEmpty == true
          ? status!
          : context.t('common.notInformed', fallback: 'Não informada'),
      onConfirm: () async {
        setState(() => _executandoAcao = true);
        try {
          await _service.excluirLancamento(id);
        } finally {
          if (mounted) setState(() => _executandoAcao = false);
        }
      },
      errorMessageBuilder: (Object error) {
        if (error is AgendaFinanceiraLancamentoApiException) {
          return context.t(
            'agenda.launchDelete.apiError',
            fallback: 'Falha ao excluir lançamento.',
          );
        }
        return context.t(
          'agenda.launchDelete.error',
          fallback:
              'Não foi possível excluir o lançamento agora. Tente novamente em instantes.',
        );
      },
    );
    if (confirmado != true) return false;
    return true;
  }

  Future<bool> _confirmarExcluirLiquidacaoDetalhe(
    Map<String, dynamic> item,
    Map<String, dynamic> liquidacao,
  ) async {
    final idLancamento = item['id']?.toString() ?? '';
    final idLiquidacao = liquidacao['id']?.toString() ?? '';
    if (idLancamento.trim().isEmpty || idLiquidacao.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar a parcial para exclusão.',
          ),
        ),
      );
      return false;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      barrierColor: WebThemeTokens.of(
        context,
      ).workspaceBackground.withValues(alpha: 0.72),
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('agenda.adjustments.reverse')),
        content: Text(
          liquidacao['grupoLiquidacaoId'] != null
              ? context.t('agenda.adjustments.reverseGroup')
              : 'Esta ação vai remover apenas esta confirmação/parcial e recalcular o valor em aberto do lançamento.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(context.t('agenda.adjustments.reverse')),
            style: SixWebActionStyles.danger(dialogContext),
          ),
        ],
      ),
    );
    if (confirmado != true) return false;
    try {
      setState(() => _executandoAcao = true);
      await _acoesService.excluirLiquidacao(
        idLancamento: idLancamento,
        idLiquidacao: idLiquidacao,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('agenda.adjustments.reversedSuccess')),
          ),
        );
      }
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 409
                  ? context.t('agenda.adjustments.reverseLaterFirst')
                  : 'Falha ao estornar baixa (${e.statusCode}).',
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) =>
      _liquidarComFormas(item, parcialInicial: true);

  Future<void> _confirmarTotal(Map<String, dynamic> item, String label) =>
      _liquidarComFormas(item, parcialInicial: false);

  Future<void> _liquidarComFormas(
    Map<String, dynamic> item, {
    required bool parcialInicial,
  }) async {
    if (_executandoAcao) return;
    final bool pagamento = item['tipo']?.toString().toLowerCase() == 'pagar';
    final destinosFinanceiros =
        !pagamento &&
        _service.espacoFinanceiro == 'EMPRESA' &&
        item['origem']?.toString().toUpperCase() == 'VENDA';
    AgendaBaixaDados? dadosBaixa;
    String? contaInicial = item['contaFinanceiraId']?.toString();
    setState(() => _executandoAcao = true);
    try {
      final detalhe = await _service.buscarDetalheLancamento(
        item['id'].toString(),
      );
      if (detalhe.isEmpty) throw const FormatException('Detalhe vazio');
      dadosBaixa = AgendaBaixaDados.fromDetalhe(detalhe, item);
      contaInicial = dadosBaixa.contaPrevistaId;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t('space.retry'))));
      }
      return;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
    if (!mounted) return;
    final resultado = await SixWebRecebimentoDialog.show(
      context,
      destinosFinanceiros: destinosFinanceiros,
      permitirAjustes: true,
      exigirConta: true,
      espacoFinanceiro: _service.espacoFinanceiro,
      contaFinanceiraInicial: contaInicial,
      titulo: context.t(
        pagamento
            ? 'agenda.settlement.payTitle'
            : 'agenda.settlement.receiveTitle',
      ),
      descricao: item['descricao']?.toString() ?? '',
      contato: item['contato']?.toString(),
      valorAberto: dadosBaixa.valorAberto,
      pagamento: pagamento,
      tipoInicial: parcialInicial
          ? SixWebRecebimentoTipo.parcial
          : SixWebRecebimentoTipo.total,
      codigoTipoInicial: item['codigoTipoRecebimento']?.toString(),
      caixaApiClient: _caixaApiClient,
      dadosBaixa: dadosBaixa,
      agendaService: _service,
      onConfirm: (resultado) async {
        final dataLiquidacao = resultado.dataLiquidacao ??
            context.read<LocaleSettingsProvider>().calendarNow;
        final contaFinanceiraId =
            resultado.recebimentos.first.contaFinanceiraId;
        final String? idSessaoCaixa = _service.espacoFinanceiro == 'PESSOAL'
            ? null
            : await _buscarIdSessaoCaixaAberta();
        if (resultado.total) {
          await _acoesService.executarTotal(
            idLancamento: item['id'].toString(),
            request: AgendaFinanceiraLiquidacaoRequest(
              contaFinanceiraId: contaFinanceiraId,
              tipoLiquidacao: 'TOTAL',
              dataLiquidacao: dataLiquidacao,
              classificacao: resultado.classificacao,
              valorLiquidado: resultado.valor,
              desconto: resultado.desconto,
              acrescimo: resultado.acrescimo,
              formaPagamentoRealizada: resultado.codigoTipoRecebimento,
              recebimentos: resultado.recebimentos,
              observacoes: resultado.observacao,
              referenciaExterna: item['id']?.toString(),
              idSessaoCaixa: idSessaoCaixa,
            ),
          );
        } else {
          await _acoesService.executarAbatimento(
            idLancamento: item['id'].toString(),
            request: AgendaFinanceiraParcialRequest(
              contaFinanceiraId: contaFinanceiraId,
              tipoLiquidacao: 'PARCIAL',
              dataLiquidacao: dataLiquidacao,
              classificacao: resultado.classificacao,
              valorLiquidado: resultado.valor,
              desconto: resultado.desconto,
              acrescimo: resultado.acrescimo,
              formaPagamentoRealizada: resultado.codigoTipoRecebimento,
              recebimentos: resultado.recebimentos,
              observacoes: resultado.observacao,
              idSessaoCaixa: idSessaoCaixa,
            ),
          );
        }
      },
    );
    if (resultado == null || !mounted) return;
    await _consultar();
  }

  Future<String?> _buscarIdSessaoCaixaAberta() async {
    final CaixaSessao? sessao = await _caixaApiClient.getSessaoAtual();
    final String? idSessaoCaixa = sessao?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  String? _codigoTipoFormaPagamentoSelecionada(String formaSelecionada) {
    final codigo = _codigoTipoPorDescricaoFormaPagamento[formaSelecionada]
        ?.trim();
    if (codigo == null || codigo.isEmpty) {
      return null;
    }
    return codigo;
  }

  Future<void> _abrirCartoes({String? faturaId}) async {
    await abrirFaturasCartaoWeb(context,espaco:_service.espacoFinanceiro,faturaId:faturaId,);
    if(mounted) await _consultar(mostrarFeedback:true);
  }

  Future<void> _novoLancamento() async {
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      service: _service,
      empresaSelecionada: 'Empresa',
      empresas: const <String>['Empresa'],
    );
    if (!mounted || item == null) {
      return;
    }
    final espaco = item['espacoFinanceiro']?.toString();
    if (espaco != null && espaco != _service.espacoFinanceiro) {
      await _trocarEspaco(espaco);
      if (!mounted) return;
    }
    if (item['registrarPagamento'] == true) {
      await _confirmarTotal(item, 'Liquidar');
    }
    if (!mounted) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    if (_executandoAcao) return;
    setState(() => _executandoAcao = true);
    try {
      final detalhe = await _service.buscarDetalheLancamento(
        item['id'].toString(),
      );
      if (detalhe.isEmpty) throw const FormatException('Detalhe vazio');
      if (!mounted) return;
      final dadosEdicao = detalhe['dadosEdicao'];
      if (dadosEdicao is Map && dadosEdicao['podeEditar'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('agenda.edit.AGF_EDICAO_INDISPONIVEL')),
          ),
        );
        return;
      }
      item = AgendaFinanceiraLancamentoDetalhe.fromJson(
        detalhe,
      ).paraEdicao(item);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(recorrenciaLabel(context, 'saveError'))),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }

    if (!mounted) return;
    final empresaAtual = _empresaNome(item['empresa']).trim();
    final empresas = <String>[empresaAtual.isEmpty ? 'Empresa' : empresaAtual];
    final atualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      service: _service,
      empresaSelecionada: empresas.first,
      empresas: empresas,
      modoEdicao: true,
      lancamentoInicial: item,
    );
    if (!mounted || atualizado == null) {
      return;
    }
    if (atualizado['registrarPagamento'] == true) {
      await _confirmarTotal(atualizado, 'Liquidar');
    }
    if (!mounted) return;
    await _consultar(mostrarFeedback: true);
  }

  void _fechar() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.of(context).maybePop();
  }

  ThemeData _agendaWebTheme(ThemeData baseTheme) {
    final ThemeData webTheme = WebThemeTokens.applyTo(baseTheme);
    final WebThemeTokens tokens = WebThemeTokens.resolve(webTheme);
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: tokens.cardBorder),
    );

    return webTheme.copyWith(
      scaffoldBackgroundColor: tokens.workspaceBackground,
      textTheme: webTheme.textTheme.apply(
        bodyColor: tokens.primaryText,
        displayColor: tokens.primaryText,
      ),
      cardTheme: webTheme.cardTheme.copyWith(
        margin: EdgeInsets.zero,
        color: tokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      inputDecorationTheme: webTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: tokens.inputBackground,
        hintStyle: TextStyle(color: tokens.mutedText),
        labelStyle: TextStyle(color: tokens.secondaryText),
        helperStyle: TextStyle(color: tokens.mutedText),
        errorStyle: TextStyle(
          color: tokens.danger,
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.disabledBackground),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.danger, width: 1.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: SixWebActionStyles.secondary(context),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: SixWebActionStyles.primary(context),
      ),
      textButtonTheme: TextButtonThemeData(
        style: SixWebActionStyles.text(context),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.selectedBackground;
            }
            return tokens.cardBackground;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.primaryText;
            }
            return tokens.secondaryText;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: tokens.selectedBorder, width: 1.1);
            }
            return BorderSide(color: tokens.cardBorder);
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      chipTheme: webTheme.chipTheme.copyWith(
        backgroundColor: tokens.surfaceMuted,
        selectedColor: tokens.selectedBackground,
        secondarySelectedColor: tokens.selectedBackground,
        disabledColor: tokens.disabledBackground,
        labelStyle: TextStyle(
          color: tokens.secondaryText,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: tokens.cardBorder),
      ),
      dataTableTheme: webTheme.dataTableTheme.copyWith(
        headingRowColor: WidgetStatePropertyAll<Color>(tokens.surfaceMuted),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.hovered)
              ? tokens.hoverBackground
              : tokens.cardBackground,
        ),
        headingTextStyle: TextStyle(
          color: tokens.secondaryText,
          fontWeight: FontWeight.w900,
        ),
        dataTextStyle: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w600,
        ),
        dividerThickness: 1,
      ),
      dialogTheme: webTheme.dialogTheme.copyWith(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: webTheme.popupMenuTheme.copyWith(
        color: tokens.menuBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool podeFecharTela = widget.onBack != null || !widget.embedded;
    if (widget.embedded && widget.onBack != null && !_estaDentroDeDialog()) {
      return const SizedBox.shrink();
    }
    final ThemeData agendaTheme = _agendaWebTheme(Theme.of(context));
    final WebThemeTokens tokens = WebThemeTokens.resolve(agendaTheme);

    return Theme(
      data: agendaTheme,
      child: Builder(
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          final Widget content = Focus(
            autofocus: podeFecharTela,
            child: SixWebPageShell(
              child: RefreshIndicator(
                onRefresh: () => _consultar(mostrarFeedback: true),
                child: ListView(
                  padding: SixWebPageShell.scrollPadding,
                  children: <Widget>[
                    _buildHeader(
                      context,
                      theme,
                      showCloseButton: podeFecharTela,
                    ),
                    SixWebPageShell.sectionGap,
                    _buildFiltros(theme),
                    if (_trocandoEspaco ||
                        _carregando ||
                        _executandoAcao) ...const <Widget>[
                      SizedBox(height: 10),
                      LinearProgressIndicator(minHeight: 3),
                    ],
                    SixWebPageShell.sectionGap,
                    _buildResumo(theme),
                    SixWebPageShell.sectionGap,
                    _buildAbas(theme),
                    SixWebPageShell.sectionGap,
                    _buildConteudoAba(theme),
                  ],
                ),
              ),
            ),
          );

          return Material(
            color: tokens.workspaceBackground,
            child: SafeArea(
              child: podeFecharTela
                  ? CallbackShortcuts(
                      bindings: <ShortcutActivator, VoidCallback>{
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _fechar,
                      },
                      child: content,
                    )
                  : content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme, {
    required bool showCloseButton,
  }) {
    final tokens = WebThemeTokens.of(context);
    final atalhos = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          style: _secondaryCtaStyle(theme),
          onPressed:
              _filtrosOcupados
                  ? null
                  : () async {
                    final periodo = _periodoRequest();
                    await abrirGastosCategoriasWeb(
                      context,
                      espaco: _service.espacoFinanceiro,
                      inicio: periodo.dataInicio,
                      fim: periodo.dataFim,
                    );
                    if (mounted) await _consultar();
                  },
          icon: const Icon(Icons.donut_small_outlined, size: 18),
          label: Text(context.t('gastos.title')),
        ),
        OutlinedButton.icon(
          style: _secondaryCtaStyle(theme),
          onPressed: _filtrosOcupados ? null : _abrirCartoes,
          icon: const Icon(Icons.credit_card_outlined, size: 18),
          label: Text(context.t('invoices.title')),
        ),
        if (_service.espacoFinanceiro == 'EMPRESA')
          TextButton.icon(
            onPressed:
                _filtrosOcupados
                    ? null
                    : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RecebiveisVendasWeb(),
                      ),
                    ),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(context.t('machine.receivables')),
          ),
      ],
    );
    final atualizacao = Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_ultimaConsultaEm != null)
          Text(
            SixWebOperationalTexts.updatedAt(
              context,
              context.watch<LocaleSettingsProvider>().formatTime(
                _ultimaConsultaEm!,
              ),
            ),
            style: TextStyle(color: tokens.secondaryText, fontSize: 12),
          ),
        TextButton.icon(
          onPressed:
              _filtrosOcupados ? null : () => _consultar(mostrarFeedback: true),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.t('common.refresh')),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SixManagedWebHero(
          page: WebHeaderAssetPage.agendaFinanceira,
          compactLayout: true,
          title: SixWebOperationalTexts.title(
            context,
            WebHeaderAssetPage.agendaFinanceira,
          ),
          subtitle: context.t('agenda.web.subtitle'),
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                style: _primaryCtaStyle(theme),
                onPressed: _filtrosOcupados ? null : _novoLancamento,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  SixWebOperationalTexts.action(context, 'agenda.newEntry'),
                ),
              ),
              if (showCloseButton)
                IconButton(
                  onPressed: _fechar,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: context.t('common.close'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1150) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [atalhos, const SizedBox(height: 8), atualizacao],
              );
            }
            return Row(
              children: [
                Expanded(child: atalhos),
                const SizedBox(width: 16),
                atualizacao,
              ],
            );
          },
        ),
      ],
    );
  }

  int get _quantidadeFiltrosAvancados =>
      (_formasPagamentoSelecionadas.isEmpty ? 0 : 1) +
      (_centrosCustoSelecionados.isEmpty ? 0 : 1) +
      (_somenteImpostoRenda ? 1 : 0) +
      (_mostrarCancelados ? 1 : 0);

  Future<void> _abrirFiltrosAvancados() async {
    if (_filtrosOcupados) return;
    final resultado = await showAgendaFiltrosAvancadosWeb(
      context: context,
      initial: AgendaFiltrosAvancados(
        pagamentos: _formasPagamentoSelecionadas,
        centros: _centrosCustoSelecionados,
        somenteImpostoRenda: _somenteImpostoRenda,
        mostrarCancelados: _mostrarCancelados,
      ),
      pagamentos:
          _tiposRecebimentoFiltro.where((value) => value != 'Todos').toList(),
      centros: _centrosCusto.map((centro) => centro.nome).toList(),
      espaco: context.t('space.${_service.espacoFinanceiro}'),
      statusCancelado: _statusSelecionado == 'Cancelado',
      onEditarPagamento:
          _podeEditarTiposPagamento ? _editarNomeTipoPagamento : null,
    );
    if (!mounted || resultado == null) return;
    setState(() {
      _formasPagamentoSelecionadas
        ..clear()
        ..addAll(resultado.pagamentos);
      _centrosCustoSelecionados
        ..clear()
        ..addAll(resultado.centros);
      _somenteImpostoRenda = resultado.somenteImpostoRenda;
      _mostrarCancelados = resultado.mostrarCancelados;
    });
    _salvarPreferenciasAgendaFinanceira();
    await _consultar();
  }

  Widget _chipFiltro(String label, VoidCallback remover) => InputChip(
    label: Text(label, overflow: TextOverflow.ellipsis),
    tooltip: label,
    deleteButtonTooltipMessage: context.t('agenda.web.removeFilter'),
    onDeleted:
        _filtrosOcupados
            ? null
            : () {
              setState(remover);
              _salvarPreferenciasAgendaFinanceira();
              unawaited(_consultar());
            },
    visualDensity: VisualDensity.compact,
  );

  String _rotuloFiltro(String value) {
    final periodoIndex = _periodos.indexOf(value);
    if (periodoIndex >= 0) {
      return context.t('agenda.mobile.period.$periodoIndex');
    }
    return switch (value) {
      'Todos' => context.t('common.all'),
      'Receber' => context.t('agenda.periodSummary.receivable'),
      'Pagar' => context.t('agenda.periodSummary.payable'),
      'Vence hoje' => context.t('agenda.web.dueToday'),
      'Vencido' => context.t('agenda.web.overdue'),
      _ => AgendaFinanceiraStatusLabels.rotulo(context, value),
    };
  }

  Widget _buildFiltros(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    final chips = <Widget>[
      if (_somenteImpostoRenda)
        _chipFiltro(context.t('ir.filter'), () => _somenteImpostoRenda = false),
      if (_mostrarCancelados)
        _chipFiltro(
          context.t('agenda.list.showCanceled'),
          () => _mostrarCancelados = false,
        ),
      for (final forma in _formasPagamentoSelecionadas)
        _chipFiltro(
          '${context.t('agenda.web.paymentType')}: $forma',
          () => _formasPagamentoSelecionadas.remove(forma),
        ),
      for (final centro in _centrosCustoSelecionados)
        _chipFiltro(
          '${context.t('agenda.web.costCenter')}: $centro',
          () => _centrosCustoSelecionados.remove(centro),
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _seletorEspaco(),
            Divider(height: 28, color: tokens.divider),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final columns =
                    constraints.maxWidth / scale >= 1000
                        ? 4
                        : constraints.maxWidth / scale >= 600
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _drop(
                      context.t('agenda.mobile.period'),
                      _periodoSelecionado,
                      _periodos,
                      _selecionarPeriodo,
                      Icons.calendar_today_outlined,
                      width,
                    ),
                    _drop(
                      context.t('agenda.journey.type'),
                      _tipoSelecionado,
                      _tipos,
                      _selecionarTipo,
                      Icons.swap_vert_rounded,
                      width,
                    ),
                    _drop(
                      context.t('agenda.web.status'),
                      _statusSelecionado,
                      _status,
                      _selecionarStatus,
                      Icons.flag_outlined,
                      width,
                    ),
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        key: const ValueKey('agenda-more-filters'),
                        style: _secondaryCtaStyle(theme).copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(0, 56),
                          ),
                        ),
                        onPressed:
                            _filtrosOcupados ? null : _abrirFiltrosAvancados,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(
                          '${context.t('agenda.web.moreFilters')}${_quantidadeFiltrosAvancados == 0 ? '' : ' · $_quantidadeFiltrosAvancados'}',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_usaPeriodoPersonalizado) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _dateFilterField(
                    context.t('agenda.web.startDate'),
                    _dataInicioPersonalizada,
                    _selecionarDataInicioPersonalizada,
                  ),
                  _dateFilterField(
                    context.t('agenda.web.endDate'),
                    _dataFimPersonalizada,
                    _selecionarDataFimPersonalizada,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              [
                context.t('space.${_service.espacoFinanceiro}'),
                _rotuloFiltro(_periodoSelecionado),
                if (_tipoSelecionado != 'Todos')
                  _rotuloFiltro(_tipoSelecionado),
                if (_statusSelecionado != 'Todos')
                  _rotuloFiltro(_statusSelecionado),
              ].join(' · '),
              style: TextStyle(color: tokens.secondaryText, fontSize: 12),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: chips),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateFilterField(String label, DateTime value, VoidCallback onTap) =>
      _AgendaFilterTrigger(
        width: 200,
        label: label,
        value: _formatarDataCurta(value),
        icon: Icons.event_outlined,
        onTap: _filtrosOcupados ? null : onTap,
      );

  Widget _drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
    IconData icon,
    double width,
  ) => _AgendaFilterDropdown(
    label: label,
    value: values.contains(value) ? value : values.first,
    values: values,
    labelFor: _rotuloFiltro,
    icon: icon,
    width: width,
    onChanged: _filtrosOcupados ? null : onChanged,
  );

  Future<void> _mostrarComposicaoConfirmada(String tipo) async {
    final itens = _itensConfirmadosFiltrados.where((i) => i['tipo'] == tipo).toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t(tipo == 'receber'
          ? 'agenda.mobile.summary.received' : 'agenda.mobile.summary.paid',),),
        content: SizedBox(
          width: 760,
          height: MediaQuery.sizeOf(dialogContext).height * .65,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.t('agenda.summary.actualDates')),
            const SizedBox(height: 12),
            Text(_formatarMoeda(tipo == 'receber' ? _totalRecebidoConfirmado : _totalPagoConfirmado,),
              style: Theme.of(dialogContext).textTheme.headlineSmall,),
            const SizedBox(height: 12),
            Expanded(child: itens.isEmpty
              ? Center(child: Text(context.t('agenda.summary.noEntries'),),)
              : ListView(children: itens.map((item) =>
                  _cardLancamento(Theme.of(dialogContext), item, exibirValorConfirmado: true,),).toList(),),),
          ],),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.t('common.close')),),],
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) => AgendaResumoPeriodoWeb(
    receberAberto: _totalReceberPrevisto,
    pagarAberto: _totalPagarPrevisto,
    saldoARealizar: _saldoARealizar,
    recebido: _totalRecebidoConfirmado,
    pago: _totalPagoConfirmado,
    realizado: _saldoConfirmado,
    projetado: _saldoPrevisto,
    formatarMoeda: _formatarMoeda,
    onRecebido: () => _mostrarComposicaoConfirmada('receber'),
    onPago: () => _mostrarComposicaoConfirmada('pagar'),
  );

  ButtonStyle _secondaryCtaStyle(ThemeData theme) =>
      SixWebActionStyles.secondary(context);

  ButtonStyle _primaryCtaStyle(ThemeData theme) =>
      SixWebActionStyles.primary(context);

  Widget _buildAbas(ThemeData theme) => DefaultTabController(
    key: ValueKey('agenda-tabs-$_abaSelecionada'),
    length: 4,
    initialIndex: _abaSelecionada,
    child: TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: WebThemeTokens.of(context).primaryText,
      unselectedLabelColor: WebThemeTokens.of(context).secondaryText,
      indicatorColor: WebThemeTokens.of(context).info,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: WebThemeTokens.of(context).divider,
      onTap: (value) {
        setState(() => _abaSelecionada = value);
        _salvarPreferenciasAgendaFinanceira();
      },
      tabs: [
        for (final key in ['agenda', 'calendar', 'forecast', 'confirmed'])
          Tab(text: context.t('agenda.web.tab.$key')),
      ],
    ),
  );

  Widget _buildConteudoAba(ThemeData theme) {
    if (_abaSelecionada == 3) return _buildValoresConfirmados(theme);
    if (_abaSelecionada == 1) return _buildCalendario(theme);
    if (_abaSelecionada == 2) return _buildFluxo(theme);
    return _buildAgenda(theme);
  }

  Widget _buildAgenda(ThemeData theme) {
    final itens = _itensAgenda;
    if (itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum lançamento encontrado.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: itens.map((item) => _cardLancamento(theme, item)).toList(),
    );
  }

  Widget _cardLancamento(
    ThemeData theme,
    Map<String, dynamic> item, {
    bool exibirValorConfirmado = false,
  }) {
    return AgendaFinanceiraLancamentoCardWeb(
      item: item,
      exibirValorConfirmado: exibirValorConfirmado,
      formatarMoeda: _formatarMoeda,
      bloqueado: _executandoAcao,
      onDetalhes: () => _mostrarDetalhesLancamento(item),
      onEditar: () => _editarLancamento(item),
      onLiquidar: () => _confirmarTotal(item, 'Liquidar'),
      onRegistrarParcial: () => _registrarParcial(item),
      onCancelar: () => _cancelarRecorrencia(item),
      onExcluir: item['faturaCartaoId'] != null ? null : () async {
        if (_executandoAcao) return;
        final excluido = await _confirmarExcluirLancamentoDetalhe(item);
        if (excluido && mounted) {
          await _consultar(mostrarFeedback: true);
        }
      },
      onComprovante: () => _baixarComprovanteDaLista(item),
    );
  }

  Future<void> _baixarComprovanteDaLista(Map<String, dynamic> item) async {
    if (_executandoAcao) return;
    final id = item['id']?.toString().trim() ?? '';
    if (id.isEmpty) return;
    setState(() => _executandoAcao = true);
    try {
      final detalhe = await _service.buscarDetalheLancamento(id);
      if (!mounted) return;
      if (detalhe['comprovanteVendaDisponivel'] != true ||
          (detalhe['idOperacaoComprovante']?.toString().trim() ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprovante indisponível para esta venda.'),
          ),
        );
        return;
      }
      await _baixarComprovanteVenda(
        detalhe['idOperacaoComprovante'].toString(),
        FormatoImpressaoOperacao.a4,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível consultar o comprovante da venda.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Widget _buildValoresConfirmados(ThemeData theme) {
    final itens = _itensConfirmadosFiltrados;
    if (itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum valor confirmado no período.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: itens
          .map(
            (item) => _cardLancamento(theme, item, exibirValorConfirmado: true),
          )
          .toList(),
    );
  }

  Widget _buildCalendario(ThemeData theme) {
    final itens = AgendaFinanceiraOrdenacaoCalendario.ordenarPorVencimento(
      _itensAgenda,
      decrescente: _calendarioDataDecrescente,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Lançamentos: ${itens.length}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Tooltip(
                message: 'Alternar ordenação por data de vencimento',
                child: TextButton.icon(
                  key: const Key('agenda-calendario-ordenar-data'),
                  onPressed: () {
                    setState(
                      () => _calendarioDataDecrescente =
                          !_calendarioDataDecrescente,
                    );
                    _salvarPreferenciasAgendaFinanceira();
                  },
                  icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _calendarioDataDecrescente
                            ? 'Data: mais recentes'
                            : 'Data: mais antigas',
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _calendarioDataDecrescente
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (itens.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhum lançamento encontrado no calendário.'),
            ),
          )
        else
          ...itens.map((item) => _cardLancamento(theme, item)),
      ],
    );
  }

  Widget _buildFluxo(ThemeData theme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Fluxo previsto',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text('Entradas em aberto: ${_formatarMoeda(_totalReceberPrevisto)}'),
          Text('Saídas em aberto: ${_formatarMoeda(_totalPagarPrevisto)}'),
          const SizedBox(height: 8),
          Text(
            '${context.t('agenda.mobile.summary.forecastBalance')}: ${_formatarMoeda(_saldoPrevisto)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );

  double _somar(List<Map<String, dynamic>> itens, String tipo, String campo) =>
      itens
          .where(
            (item) =>
                item['tipo'] == tipo &&
                item['status']?.toString() != 'Cancelado',
          )
          .fold<double>(
            0,
            (soma, item) => soma + _toDouble(item[campo] ?? item['valor']),
          );

  String _acaoLabel(String? acao) {
    switch ((acao ?? '').toUpperCase()) {
      case 'EDITAR':
      case 'ALTERAR':
        return 'Editar';
      case 'REGISTRAR_RECEBIMENTO':
      case 'RECEBER':
      case 'REGISTRAR_PAGAMENTO':
      case 'PAGAR':
        return 'Liquidar';
      case 'REGISTRAR_PARCIAL':
        return 'Registrar parcial';
      case 'DETALHAR':
      case 'DETALHES':
        return 'Detalhes';
      default:
        return '';
    }
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PAGO':
        return 'Pago';
      case 'RECEBIDO':
        return 'Recebido';
      case 'PARCIAL':
        return 'Parcial';
      case 'CANCELADO':
        return 'Cancelado';
      case 'VENCIDO':
        return 'Vencido';
      case 'VENCE_HOJE':
        return 'Vence hoje';
      case 'PREVISTO':
        return 'Previsto';
      default:
        return 'Pendente';
    }
  }

  String? _codigoTipoPorBackendFormaPagamento(String backend) {
    switch (backend.trim().toUpperCase()) {
      case 'DINHEIRO':
        return 'tipo1';
      case 'PIX':
        return 'tipo2';
      case 'CARTAO_CREDITO':
        return 'tipo3';
      case 'CARTAO_DEBITO':
        return 'tipo4';
      case 'BOLETO':
        return 'tipo5';
      case 'DEBITO_AUTOMATICO':
        return 'tipo7';
      case 'TRANSFERENCIA':
        return 'tipo8';
      default:
        return null;
    }
  }

  String? _codigoTipoRecebimentoItem(Map<String, dynamic> item) {
    final codigo = item['codigoTipoRecebimento']
        ?.toString()
        .trim()
        .toLowerCase();
    if (codigo != null && RegExp(r'^tipo(10|[1-9])$').hasMatch(codigo)) {
      return codigo;
    }
    return _codigoTipoPorBackendFormaPagamento(
      item['formaPagamento']?.toString() ?? '',
    );
  }

  String _empresaNome(dynamic empresa) => empresa is Map<String, dynamic>
      ? empresa['nome']?.toString() ?? ''
      : empresa?.toString() ?? '';

  String _formatarDataIsoParaBr(String? dataIso) {
    if (dataIso == null || dataIso.trim().isEmpty) return '-';
    try {
      final data = DateTime.parse(dataIso);
      return _formatarDataCurta(data);
    } catch (_) {
      return dataIso;
    }
  }

  String _formatarDataCurta(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _formatarDataFlexivel(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final text = value.toString();
    if (text.contains('/')) return text;
    return _formatarDataIsoParaBr(text);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final texto = value.trim();
      final normalizado = texto.contains(',') && texto.contains('.')
          ? texto.replaceAll('.', '').replaceAll(',', '.')
          : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  String _formatarMoeda(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);
}

class _AgendaFilterDropdown extends StatefulWidget {
  const _AgendaFilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.icon,
    required this.onChanged,
    this.width,
  });

  final String label;
  final String value;
  final List<String> values;
  final IconData icon;
  final ValueChanged<String?>? onChanged;
  final String Function(String) labelFor;
  final double? width;

  @override
  State<_AgendaFilterDropdown> createState() => _AgendaFilterDropdownState();
}

class _AgendaFilterDropdownState extends State<_AgendaFilterDropdown> {
  bool _open = false;

  String get _safeValue {
    if (widget.values.contains(widget.value)) {
      return widget.value;
    }
    return widget.values.isEmpty ? '' : widget.values.first;
  }

  Future<void> _showOptions() async {
    if (widget.values.isEmpty || widget.onChanged == null) {
      return;
    }
    setState(() => _open = true);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String safeValue = _safeValue;

    final String? selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          position.dx,
          position.dy + box.size.height + 8,
          box.size.width,
          box.size.height,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 12,
      color: tokens.menuBackground,
      constraints: BoxConstraints.tightFor(width: box.size.width),
      items:
          widget.values
              .map(
                (item) => PopupMenuItem<String>(
                  value: item,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: _AgendaFilterMenuItem(
                    label: widget.labelFor(item),
                    selected: item == safeValue,
                  ),
                ),
              )
              .toList(),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AgendaFilterTrigger(
      label: widget.label,
      value: widget.labelFor(_safeValue),
      icon: widget.icon,
      width: widget.width,
      open: _open,
      onTap: widget.onChanged == null ? null : _showOptions,
    );
  }
}

class _AgendaFilterTrigger extends StatefulWidget {
  const _AgendaFilterTrigger({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.width,
    this.open = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final double? width;
  final bool open;

  @override
  State<_AgendaFilterTrigger> createState() => _AgendaFilterTriggerState();
}

class _AgendaFilterTriggerState extends State<_AgendaFilterTrigger> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool enabled = widget.onTap != null;
    final bool active = enabled && (widget.open || _hover);
    final Color borderColor =
        active ? tokens.selectedBorder : tokens.cardBorder;
    final Color backgroundColor =
        active ? tokens.selectedBackground : tokens.inputBackground;
    final Widget content = Semantics(
      button: true,
      enabled: enabled,
      label: '${widget.label}: ${widget.value}',
      child: Tooltip(
        message: '${widget.label}: ${widget.value}',
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? widget.onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow:
                      active
                          ? <BoxShadow>[
                            BoxShadow(
                              color: tokens.info.withValues(alpha: 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: widget.open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                            active
                                ? Theme.of(context).colorScheme.primary
                                : tokens.mutedText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.width == null) return content;
    return SizedBox(width: widget.width, child: content);
  }
}

class _AgendaFilterMenuItem extends StatelessWidget {
  const _AgendaFilterMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected ? Icons.check_circle_rounded : Icons.arrow_right_rounded,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : tokens.mutedText,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscOverlayIntent extends Intent {
  const _EscOverlayIntent();
}

class _EscOverlayScope extends StatelessWidget {
  const _EscOverlayScope({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _EscOverlayIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _EscOverlayIntent: CallbackAction<_EscOverlayIntent>(
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

class _LancamentoDetalhesDialog extends StatelessWidget {
  const _LancamentoDetalhesDialog({
    required this.item,
    required this.detalhe,
    required this.fallback,
    required this.formatarMoeda,
    required this.formatarData,
    required this.onExcluirLancamento,
    required this.onExcluirLiquidacao,
    required this.onBaixarComprovante,
    required this.onEditarLancamento,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> detalhe;
  final bool fallback;
  final String Function(double) formatarMoeda;
  final String Function(dynamic) formatarData;
  final Future<bool> Function() onExcluirLancamento;
  final VoidCallback onEditarLancamento;
  final Future<void> Function(FormatoImpressaoOperacao) onBaixarComprovante;
  final Future<bool> Function(Map<String, dynamic> liquidacao)
  onExcluirLiquidacao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final contato = _mapa(detalhe['contato']);
    final origem = _mapa(detalhe['origem']);
    final categoria = _mapa(detalhe['categoria']);
    final empresa = _mapa(detalhe['empresa']);
    final responsavel = _mapa(detalhe['responsavel']);
    final historico = _listaMapas(detalhe['historico']);
    final liquidacoes = _liquidacoes();
    final estornadas = _listaMapas(detalhe['liquidacoesEstornadas']);
    final comprovantes = _listaStrings(detalhe['comprovantes']);
    final String codigoOperacao = _texto(
      detalhe['codigoOperacao'],
      item['codigoOperacao']
    ).trim();
    final acoes = _listaStrings(detalhe['acoesDisponiveis']);
    final valorOriginal = _numero(
      detalhe['valorOriginal'],
      item['valorOriginal'] ?? item['valor'],
    );
    final valorPago = _numero(
      detalhe['valorPagoRecebido'],
      item['valorConfirmado'],
    );
    final valorAberto = _numero(detalhe['valorAberto'], item['valorRestante']);
    final descricao = _texto(detalhe['descricao'], item['descricao']);
    final stamp = _stampData(
      context,
      tokens,
      _texto(detalhe['status'], item['status']),
      _texto(detalhe['tipo'], item['tipo']),
      valorAberto,
    );
    return Semantics(
      namesRoute: true,
      label: context.t(
        'agenda.launchDetails.dialogBarrier',
        fallback: 'Detalhes do lançamento financeiro',
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  border: Border(bottom: BorderSide(color: tokens.cardBorder)),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Detalhes do lançamento',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            descricao,
                            style: TextStyle(
                              color: tokens.primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (detalhe['comprovanteVendaDisponivel'] == true)
                      PopupMenuButton<FormatoImpressaoOperacao>(
                        tooltip: context.t('agenda.saleItems.downloadPdf'),
                        icon: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: tokens.info,
                        ),
                        onSelected: onBaixarComprovante,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: FormatoImpressaoOperacao.a4,
                            child: Text(context.t('agenda.saleItems.pdfA4'),),
                          ),
                          PopupMenuItem(
                            value: FormatoImpressaoOperacao.cupomTermico,
                            child: Text(context.t('agenda.saleItems.pdfCupom'),),
                          ),
                        ],
                      ),
                    if (!fallback && acoes.contains('EDITAR'))
                      IconButton(
                        key: const ValueKey('agenda-detail-edit'),
                        tooltip: context.t('agenda.edit.action'),
                        onPressed: onEditarLancamento,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (![
                      'Cancelado',
                      'Pago',
                      'Recebido',
                      'Parcial',
                    ].contains(item['status']?.toString()))
                      TextButton.icon(
                        onPressed: () async {
                          final excluido = await onExcluirLancamento();
                          if (excluido && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        icon: Icon(
                          item['serieRecorrenciaId'] != null
                              ? Icons.event_busy_outlined
                              : Icons.delete_forever_outlined,
                        ),
                        label: Text(
                          item['serieRecorrenciaId'] != null
                              ? 'Cancelar ocorrência'
                              : 'Excluir lançamento',
                        ),
                        style: SixWebActionStyles.dangerText(context),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close_rounded, color: tokens.mutedText),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (fallback) _avisoFallback(theme),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _chip(
                                  theme,
                                  _texto(
                                    detalhe['tipo'],
                                    item['tipo'] == 'pagar'
                                        ? 'Pagar'
                                        : 'Receber',
                                  ),
                                ),
                                _chip(
                                  theme,
                                  _texto(detalhe['status'], item['status']),
                                ),
                                _chip(
                                  theme,
                                  agendaFormaPagamentoExibicao(
                                    detalhe,
                                    fallback: item,
                                  ),
                                ),
                                _chip(
                                  theme,
                                  codigoOperacao.isNotEmpty
                                      ? 'Operação: $codigoOperacao'
                                      : 'Operação sem código',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth >= 760
                                    ? (constraints.maxWidth - 24) / 3
                                    : double.infinity;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: <Widget>[
                                    SizedBox(
                                      width: width,
                                      child: _valorCard(
                                        theme,
                                        'Valor original',
                                        formatarMoeda(valorOriginal),
                                        Icons.receipt_long_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _valorCard(
                                        theme,
                                        'Confirmado',
                                        formatarMoeda(valorPago),
                                        Icons.verified_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _valorCard(
                                        theme,
                                        'Em aberto',
                                        formatarMoeda(valorAberto),
                                        Icons.account_balance_wallet_outlined,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            if (_numero(detalhe['descontoTotal'], null) > 0 ||
                                _numero(detalhe['acrescimoTotal'], null) > 0)
                              _section(
                                theme,
                                context.t('agenda.adjustments.title'),
                                Icons.tune,
                                [
                                  _info(
                                    context.t('agenda.adjustments.discount'),
                                    formatarMoeda(
                                      _numero(detalhe['descontoTotal'], null),
                                    ),
                                  ),
                                  _info(
                                    context.t('agenda.adjustments.surcharge'),
                                    formatarMoeda(
                                      _numero(detalhe['acrescimoTotal'], null),
                                    ),
                                  ),
                                ],
                              ),
                            if (AgendaItensVendaResumo.ehVenda(detalhe))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: AgendaItensVendaResumo(
                                  itens: AgendaItensVendaResumo.lerItens(
                                    detalhe,
                                  ),
                                  formatarMoeda: formatarMoeda,
                                  mostrarVazio: true,
                                ),
                              ),
                            _section(
                              theme,
                              'Datas',
                              Icons.calendar_month_outlined,
                              <Widget>[
                                _info(
                                  'Competência',
                                  CompetenciaFinanceira.formatarValor(
                                    detalhe['dataCompetencia'],
                                  ),
                                ),
                                _info(
                                  'Vencimento',
                                  formatarData(
                                    _valor(
                                      detalhe['dataVencimento'],
                                      item['vencimento'],
                                    ),
                                  ),
                                ),
                                _info(
                                  'Liquidação',
                                  formatarData(detalhe['dataLiquidacao']),
                                ),
                              ],
                            ),
                            _section(
                              theme,
                              'Classificação',
                              Icons.filter_alt_outlined,
                              <Widget>[
                                _info(
                                  'Empresa',
                                  _texto(empresa['nome'], item['empresa']),
                                ),
                                _info(
                                  'Categoria',
                                  _texto(
                                    categoria['nome'],
                                    categoria['descricao'],
                                    item['categoria'],
                                  ),
                                ),
                                if (_texto(
                                  detalhe['centroDeCusto'],
                                  item['centroDeCusto'],
                                ).trim().isNotEmpty)
                                  _info(
                                    'Centro de custos',
                                    _texto(
                                      detalhe['centroDeCusto'],
                                      item['centroDeCusto'],
                                    ),
                                  ),
                                _info(
                                  'Origem',
                                  _texto(
                                    origem['codigoExibicao'],
                                    origem['tipo'],
                                    item['origem'],
                                  ),
                                ),
                              ],
                            ),
                            _section(
                              theme,
                              'Contato e responsabilidade',
                              Icons.people_alt_outlined,
                              <Widget>[
                                _info(
                                  'Contato',
                                  _texto(contato['nome'], item['contato']),
                                ),
                                _info('Tipo', _texto(contato['tipo'])),
                                _info(
                                  'Documento',
                                  _texto(contato['documento']),
                                ),
                                _info('Telefone', _texto(contato['telefone'])),
                                _info('E-mail', _texto(contato['email'])),
                                _info(
                                  'Responsável',
                                  _texto(
                                    responsavel['nome'],
                                    item['responsavel'],
                                  ),
                                ),
                              ],
                            ),
                            _section(
                              theme,
                              'Observações',
                              Icons.notes_outlined,
                              <Widget>[
                                SizedBox(
                                  width: double.infinity,
                                  child: SelectableText(
                                    _texto(
                                      detalhe['observacoes'],
                                      item['observacoes'],
                                      'Sem observações.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (liquidacoes.isNotEmpty)
                              _section(
                                theme,
                                'Confirmações e liquidações',
                                Icons.payments_outlined,
                                liquidacoes
                                    .map(
                                      (l) => _liquidacaoTile(context, theme, l),
                                    )
                                    .toList(),
                              ),
                            if (estornadas.isNotEmpty)
                              _section(
                                theme,
                                context.t('agenda.adjustments.reversed'),
                                Icons.undo,
                                estornadas
                                    .map(
                                      (r) => _liquidacaoTile(context, theme, r),
                                    )
                                    .toList(),
                              ),
                            if (historico.isNotEmpty)
                              _section(
                                theme,
                                'Histórico',
                                Icons.history_outlined,
                                historico
                                    .map(
                                      (h) => _info(
                                        formatarData(h['dataHora']),
                                        _texto(h['descricao']),
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (AgendaImpostoRenda.fromJson(detalhe).marcado ||
                                AgendaImpostoRenda.fromJson(
                                  detalhe,
                                ).comprovantes.isNotEmpty)
                              AgendaImpostoRendaWebFields(
                                draft: AgendaImpostoRenda.fromJson(detalhe),
                                enabled: false,
                                onChanged: () {},
                              ),
                            if (comprovantes.isNotEmpty)
                              _section(
                                theme,
                                'Comprovantes',
                                Icons.attach_file_outlined,
                                comprovantes
                                    .map((c) => _info('Arquivo', c))
                                    .toList(),
                              ),
                            if (acoes.isNotEmpty)
                              _section(
                                theme,
                                'Ações disponíveis',
                                Icons.touch_app_outlined,
                                <Widget>[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: acoes
                                        .map(
                                          (a) => Chip(
                                            label: Text(
                                              a == 'EDITAR'
                                                  ? context.t(
                                                      'agenda.edit.action',
                                                    )
                                                  : a,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (stamp != null)
                      Positioned(
                        top: 18,
                        right: 28,
                        child: _statusStamp(stamp),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DetalheStatusStampData? _stampData(
    BuildContext context,
    WebThemeTokens tokens,
    String status,
    String tipo,
    double valorAberto,
  ) {
    final normalized = status.trim().toUpperCase().replaceAll(' ', '_');
    if (normalized == 'PAGO' ||
        normalized == 'RECEBIDO' ||
        valorAberto <= 0 &&
            (normalized == 'FINALIZADA' || normalized == 'FINALIZADO')) {
      return _DetalheStatusStampData(
        AgendaFinanceiraStatusLabels.rotuloQuitacao(
          context,
          tipo: tipo,
          status: status,
        ).toUpperCase(),
        tokens.success,
      );
    }
    if (normalized == 'PARCIAL') {
      return _DetalheStatusStampData('PARCIAL', tokens.warning);
    }
    if (normalized == 'CANCELADO' || normalized == 'CANCELADA') {
      return _DetalheStatusStampData('CANCELADO', tokens.statusNeutral);
    }
    return null;
  }

  Widget _statusStamp(_DetalheStatusStampData stamp) => IgnorePointer(
    child: Transform.rotate(
      angle: -0.12,
      child: Opacity(
        opacity: 0.94,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: stamp.color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: stamp.color, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: stamp.color.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            stamp.label,
            style: TextStyle(
              color: stamp.color,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _avisoFallback(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: WebThemeTokens.resolve(theme).surfaceMuted,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: WebThemeTokens.resolve(theme).cardBorder),
    ),
    child: const Text(
      'Não foi possível carregar o detalhe completo do backend. Exibindo os dados disponíveis na agenda filtrada.',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  Widget _chip(ThemeData theme, String label) => Chip(
    label: Text(label),
    backgroundColor: WebThemeTokens.resolve(theme).selectedBackground,
    side: BorderSide(color: WebThemeTokens.resolve(theme).selectedBorder),
  );

  Widget _valorCard(
    ThemeData theme,
    String titulo,
    String valor,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WebThemeTokens.resolve(theme).surfaceMuted,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: WebThemeTokens.resolve(theme).cardBorder),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: WebThemeTokens.resolve(theme).info),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: WebThemeTokens.resolve(theme).cardBackground,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: WebThemeTokens.resolve(theme).cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: WebThemeTokens.resolve(theme).info, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: children),
      ],
    ),
  );

  Widget _info(String label, String value) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value.trim().isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _liquidacaoTile(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> liquidacao,
  ) {
    final idLiquidacao = liquidacao['id']?.toString() ?? '';
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _info(
                'Tipo',
                _texto(liquidacao['tipoLiquidacao'], liquidacao['tipo']),
              ),
              _info('Data', formatarData(liquidacao['dataLiquidacao'])),
              if (_numero(liquidacao['desconto'], null) > 0)
                _info(
                  context.t('agenda.adjustments.discount'),
                  formatarMoeda(_numero(liquidacao['desconto'], null)),
                ),
              if (_numero(liquidacao['acrescimo'], null) > 0)
                _info(
                  context.t('agenda.adjustments.surcharge'),
                  formatarMoeda(_numero(liquidacao['acrescimo'], null)),
                ),
              _info(
                'Valor',
                formatarMoeda(_numero(liquidacao['valorLiquidado'], null)),
              ),
              _info(
                'Restante antes',
                formatarMoeda(_numero(liquidacao['valorRestanteAntes'], null)),
              ),
              _info(
                'Restante depois',
                formatarMoeda(_numero(liquidacao['valorRestanteDepois'], null)),
              ),
              _info(
                context.t(
                  _texto(detalhe['tipo'], item['tipo']).trim().toUpperCase() ==
                          'RECEBER'
                      ? 'recebimento.tipoRecebimento'
                      : 'agenda.settlement.methodType',
                ),
                agendaFormaPagamentoExibicao(liquidacao),
              ),
              if ((liquidacao['contaFinanceiraNome']?.toString() ?? '')
                  .isNotEmpty)
                _info(
                  context.t('space.actualAccount'),
                  liquidacao['contaFinanceiraNome'].toString(),
                ),
              if (idLiquidacao.isNotEmpty &&
                  !liquidacao.containsKey('estornadoPor'))
                TextButton.icon(
                  onPressed: () async {
                    final excluiu = await onExcluirLiquidacao(liquidacao);
                    if (excluiu && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(context.t('agenda.adjustments.reverse')),
                  style: SixWebActionStyles.dangerText(context),
                ),
            ],
          ),
          if (_texto(liquidacao['observacoes']).trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            SelectableText('Observação: ${_texto(liquidacao['observacoes'])}'),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _liquidacoes() {
    final detalheLiquidacoes = _listaMapas(detalhe['liquidacoes']);
    if (detalheLiquidacoes.isNotEmpty) return detalheLiquidacoes;
    return _listaMapas(item['liquidacoes']);
  }

  List<Map<String, dynamic>> _listaMapas(dynamic raw) => raw is List
      ? raw
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
  List<String> _listaStrings(dynamic raw) => raw is List
      ? raw
            .map((item) => item?.toString() ?? '')
            .where((item) => item.trim().isNotEmpty)
            .toList()
      : <String>[];
  Map<String, dynamic> _mapa(dynamic raw) =>
      raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  dynamic _valor(dynamic primary, dynamic fallback) =>
      primary == null || primary.toString().trim().isEmpty ? fallback : primary;
  String _texto(dynamic primary, [dynamic secondary, dynamic third]) {
    for (final value in <dynamic>[primary, secondary, third]) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '-';
  }

  double _numero(dynamic primary, dynamic fallback) {
    final value = _valor(primary, fallback);
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalizado = value.contains(',') && value.contains('.')
          ? value.replaceAll('.', '').replaceAll(',', '.')
          : value.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }
}

class _DetalheStatusStampData {
  const _DetalheStatusStampData(this.label, this.color);
  final String label;
  final Color color;
}
