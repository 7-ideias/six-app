import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

import '../../providers/locale_settings_provider.dart';
import '../theme/web_theme_tokens.dart';

class AgendaFinanceiraWeb extends StatefulWidget {
  const AgendaFinanceiraWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AgendaFinanceiraWeb> createState() => _AgendaFinanceiraWebState();
}

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb> {
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService =
      AgendaFinanceiraAcoesFinanceiras();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();
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
  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];

  int _abaSelecionada = 0;
  String _periodoSelecionado = 'Próximos 7 dias';
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  final Set<String> _formasPagamentoSelecionadas = <String>{};
  bool _carregando = false;
  bool _executandoAcao = false;
  bool _overlayInicialAberto = false;
  bool _usuarioAlterouFiltros = false;
  DateTime? _ultimaConsultaEm;

  List<Map<String, dynamic>> get _itensAgenda =>
      _gruposAgenda
          .expand(
            (grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>(),
          )
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
      await _carregarTiposPagamentoConfigurados();
      await _restaurarPreferenciasAgendaFinanceira();
      await _restaurarPreferenciasAgendaFinanceiraBackend();
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
    final AgendaFinanceiraFiltrosPreferencia filtros =
        preferencias.agendaFinanceiraFiltrosWeb;
    final String periodo = _periodoLabelPreferencia(filtros.periodo);
    final String tipo = _tipoLabelPreferencia(filtros.tipo);
    final String status = _statusLabelPreferencia(filtros.status);
    final Set<String> formasPagamento =
        filtros.tiposDePagamento
            .map(_formaPagamentoLabelPorCodigoPreferencia)
            .whereType<String>()
            .where(_tiposRecebimentoFiltro.contains)
            .toSet();

    setState(() {
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
    try {
      final informacoes = await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final formas = _montarFormasPagamento(informacoes.tiposRecebimento);
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _tiposRecebimentoFiltro = <String>['Todos', ...formas];
        _formasPagamentoSelecionadas.removeWhere(
          (forma) => !_tiposRecebimentoFiltro.contains(forma),
        );
      });
    } catch (_) {}
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
    final ativos =
        tipos.where((tipo) => tipo.ativo).toList()
          ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    for (final tipo in ativos) {
      final codigoTipo = tipo.codigoTipo.trim().toLowerCase();
      final backend = _backendFormaPagamentoPorCodigoTipo(codigoTipo);
      final descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
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
    return tipoOk && statusOk && formaOk;
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
      final agenda = await _service.consultarLancamentos(request);
      final confirmados = await _service.consultarValoresConfirmados(request);
      if (!mounted) return;
      _aplicarAgenda(agenda);
      _aplicarConfirmados(confirmados);
      _sincronizarValoresConfirmadosNosLancamentos();
      _ultimaConsultaEm = DateTime.now();
      if (mostrarFeedback) {
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
        tipo:
            _tipoSelecionado == 'Todos'
                ? 'TODOS'
                : _tipoSelecionado.toUpperCase(),
        status: _statusFiltro(),
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: const <String>[],
        codigosTipoRecebimento: _codigosTipoRecebimentoFiltro(),
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada:
          _abaSelecionada == 0
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
    final hoje = DateTime.now();
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
    if (periodo == null) return;
    setState(() {
      _periodoSelecionado = periodo;
      if (_usaPeriodoPersonalizado) {
        _ajustarPeriodoPersonalizadoSeguro();
      }
    });
    _salvarPreferenciasAgendaFinanceira();
  }

  void _selecionarTipo(String? tipo) {
    if (tipo == null || !_tipos.contains(tipo)) {
      return;
    }
    setState(() => _tipoSelecionado = tipo);
    _salvarPreferenciasAgendaFinanceira();
  }

  void _selecionarStatus(String? status) {
    if (status == null || !_status.contains(status)) {
      return;
    }
    setState(() => _statusSelecionado = status);
    _salvarPreferenciasAgendaFinanceira();
  }

  void _selecionarTiposPagamento(Set<String> resultado) {
    final Set<String> valoresValidos =
        resultado
            .where((forma) => _tiposRecebimentoFiltro.contains(forma))
            .toSet();
    setState(() {
      _formasPagamentoSelecionadas
        ..clear()
        ..addAll(valoresValidos);
    });
    _salvarPreferenciasAgendaFinanceira();
  }

  void _salvarPreferenciasAgendaFinanceira() {
    _usuarioAlterouFiltros = true;
    final AgendaFinanceiraFiltrosPreferencia filtros =
        AgendaFinanceiraFiltrosPreferencia(
          periodo: AgendaFinanceiraPeriodoWebPreferenciaApi.fromCodigo(
            _periodoCodigoPreferencia(_periodoSelecionado),
            AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
          ),
          dataInicio:
              _usaPeriodoPersonalizado ? _inicioPeriodoPersonalizado() : null,
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
    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            agendaFinanceiraFiltrosWeb: filtros.toJson(),
            agendaFinanceiraPeriodoWeb: filtros.periodo.codigo,
            agendaFinanceiraTipoWeb: filtros.tipo.codigo,
            agendaFinanceiraStatusWeb: filtros.status.codigo,
            agendaFinanceiraTipoDePagamentoWeb: filtros.tiposDePagamento,
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar preferencias da agenda financeira: $error\n$stackTrace',
            );
          }),
    );
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
          'itens':
              itensRaw is List
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
    final tipo =
        item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    final valorOriginal = _toDouble(item['valorOriginal'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final valorRestante = _toDouble(
      item['valorRestante'] ?? (valorOriginal - valorConfirmado),
    );
    final acoesRaw = item['acoesDisponiveis'];
    final acoes =
        acoesRaw is List
            ? acoesRaw
                .map((acao) => _acaoLabel(acao?.toString()))
                .where((acao) => acao.isNotEmpty)
                .toSet()
                .toList()
            : <String>[];
    if (!acoes.contains('Detalhes')) acoes.add('Detalhes');
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': valorOriginal,
      'valorConfirmado': valorConfirmado,
      'valorRestante': valorRestante,
      'valor': valorRestante > 0 ? valorRestante : valorOriginal,
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'origem': item['origem']?.toString() ?? '',
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': _formaPagamentoLabel(
        _codigoTipoRecebimentoItem(item) ?? item['formaPagamento']?.toString(),
      ),
      'empresa': _empresaNome(item['empresa']),
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'acoes': acoes,
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo =
        item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr(
        (item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString(),
      ),
      'status': _statusLabel(item['status']?.toString()),
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': _formaPagamentoLabel(
        _codigoTipoRecebimentoItem(item) ?? item['formaPagamento']?.toString(),
      ),
      'empresa': _empresaNome(item['empresa']),
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  List<Map<String, dynamic>> _mapearLiquidacoes(dynamic raw) =>
      raw is List
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
        final confirmado = confirmadosPorId[item['id']?.toString()];
        if (confirmado == null) continue;
        item['valorConfirmado'] = confirmado['valorConfirmado'];
        item['valorRestante'] = confirmado['valorRestante'];
        item['valor'] = confirmado['valorRestante'];
        item['liquidacoes'] =
            confirmado['liquidacoes'] ?? <Map<String, dynamic>>[];
        if (_toDouble(confirmado['valorConfirmado']) > 0 &&
            _toDouble(confirmado['valorRestante']) > 0) {
          item['status'] = 'Parcial';
        }
      }
    }
  }

  Future<void> _executarAcao(String acao, Map<String, dynamic> item) async {
    final comando = acao.trim().toLowerCase();
    if (comando == 'detalhes' || comando == 'detalhar') {
      await _mostrarDetalhesLancamento(item);
      return;
    }
    if (comando == 'editar') {
      await _editarLancamento(item);
      return;
    }
    if (comando == 'registrar parcial') {
      await _registrarParcial(item);
      return;
    }
    if (comando == 'liquidar' || comando == 'receber' || comando == 'pagar') {
      await _confirmarTotal(item, 'Liquidar');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ação "$acao" ainda não implementada.')),
    );
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
    final pageTokens = WebThemeTokens.of(context);
    final alterado = await showDialog<bool>(
      context: context,
      barrierColor: pageTokens.workspaceBackground.withValues(alpha: 0.72),
      barrierDismissible: true,
      builder:
          (dialogContext) => _LancamentoDetalhesDialog(
            item: item,
            detalhe: detalhe,
            fallback: fallback,
            formatarMoeda: _formatarMoeda,
            formatarData: _formatarDataFlexivel,
            formaPagamentoLabel: _formaPagamentoLabel,
            onExcluirLancamento: () => _confirmarExcluirLancamentoDetalhe(item),
            onExcluirLiquidacao:
                (liquidacao) =>
                    _confirmarExcluirLiquidacaoDetalhe(item, liquidacao),
          ),
    );
    if (alterado == true && mounted) await _consultar(mostrarFeedback: true);
  }

  Future<bool> _confirmarExcluirLancamentoDetalhe(
    Map<String, dynamic> item,
  ) async {
    final id = item['id']?.toString() ?? '';
    if (id.trim().isEmpty) return false;
    final confirmado = await showDialog<bool>(
      context: context,
      barrierColor: WebThemeTokens.of(
        context,
      ).workspaceBackground.withValues(alpha: 0.72),
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Excluir lançamento?'),
            content: const Text(
              'Esta ação vai apagar definitivamente todo o lançamento financeiro e suas confirmações/parciais. Essa operação não pode ser desfeita.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir lançamento'),
                style: FilledButton.styleFrom(
                  backgroundColor: WebThemeTokens.of(dialogContext).danger,
                  foregroundColor: WebThemeTokens.of(dialogContext).onDanger,
                ),
              ),
            ],
          ),
    );
    if (confirmado != true) return false;
    try {
      setState(() => _executandoAcao = true);
      await _service.excluirLancamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento excluído com sucesso.')),
        );
      }
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao excluir lançamento (${e.statusCode}).'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
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
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Excluir parcial?'),
            content: const Text(
              'Esta ação vai remover apenas esta confirmação/parcial e recalcular o valor em aberto do lançamento.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir parcial'),
                style: FilledButton.styleFrom(
                  backgroundColor: WebThemeTokens.of(dialogContext).danger,
                  foregroundColor: WebThemeTokens.of(dialogContext).onDanger,
                ),
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
          const SnackBar(content: Text('Parcial excluída com sucesso.')),
        );
      }
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao excluir parcial (${e.statusCode}).'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) async {
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();
    final formasDisponiveis =
        await _carregarFormasPagamentoDisponiveisParaLiquidacao();
    if (!mounted) {
      valorController.dispose();
      observacaoController.dispose();
      return;
    }
    if (formasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carregue os tipos de recebimento antes de registrar parcial.',
          ),
        ),
      );
      valorController.dispose();
      observacaoController.dispose();
      return;
    }
    String formaSelecionada = _formaPagamentoInicialLiquidacao(
      item,
      formasDisponiveis,
    );
    String? erroValor;
    final resultado = await showDialog<_ParcialLancamentoResultado>(
      context: context,
      barrierColor: WebThemeTokens.of(
        context,
      ).workspaceBackground.withValues(alpha: 0.72),
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text('Registrar parcial'),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Valor em aberto: ${_formatarMoeda(_toDouble(item['valorRestante'] ?? item['valor']))}',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Valor parcial',
                            errorText: erroValor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AgendaFilterDropdown(
                          label: 'Tipo de recebimento',
                          value: formaSelecionada,
                          values: formasDisponiveis,
                          icon: Icons.payments_outlined,
                          onChanged: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return;
                            }
                            setDialogState(() => formaSelecionada = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: observacaoController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observação',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final digitado = _toDouble(valorController.text);
                        final aberto = _toDouble(
                          item['valorRestante'] ?? item['valor'],
                        );
                        if (digitado <= 0) {
                          setDialogState(
                            () =>
                                erroValor = 'Informe um valor maior que zero.',
                          );
                          return;
                        }
                        if (digitado >= aberto) {
                          setDialogState(
                            () =>
                                erroValor =
                                    'Informe um valor menor que o aberto.',
                          );
                          return;
                        }
                        final codigoTipo = _codigoTipoFormaPagamentoSelecionada(
                          formaSelecionada,
                        );
                        if (codigoTipo == null) {
                          setDialogState(
                            () =>
                                erroValor = 'Selecione um tipo de recebimento.',
                          );
                          return;
                        }
                        Navigator.of(dialogContext).pop(
                          _ParcialLancamentoResultado(
                            valor: digitado,
                            codigoTipoRecebimento: codigoTipo,
                          ),
                        );
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );
    final observacao = observacaoController.text.trim();
    valorController.dispose();
    observacaoController.dispose();
    if (resultado == null) {
      return;
    }
    await _executarComLoading(() async {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      await _acoesService.executarAbatimento(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraParcialRequest(
          tipoLiquidacao: 'PARCIAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: resultado.valor,
          formaPagamentoRealizada: resultado.codigoTipoRecebimento,
          observacoes:
              observacao.isEmpty
                  ? 'Lançamento parcial registrado pela agenda financeira.'
                  : observacao,
          idSessaoCaixa: idSessaoCaixa,
        ),
      );
      await _consultar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcial registrada com sucesso.')),
        );
      }
    });
  }

  Future<void> _confirmarTotal(Map<String, dynamic> item, String label) async {
    final valor = _toDouble(item['valorRestante'] ?? item['valor']);
    final formasDisponiveis =
        await _carregarFormasPagamentoDisponiveisParaLiquidacao();
    if (!mounted) {
      return;
    }
    if (formasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carregue os tipos de recebimento antes de liquidar o lançamento.',
          ),
        ),
      );
      return;
    }

    String formaSelecionada = _formaPagamentoInicialLiquidacao(
      item,
      formasDisponiveis,
    );
    String? erroForma;
    final codigoTipoRecebimento = await showDialog<String>(
      context: context,
      barrierColor: WebThemeTokens.of(
        context,
      ).workspaceBackground.withValues(alpha: 0.72),
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text('Liquidar lançamento'),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Confirmar liquidação de ${_formatarMoeda(valor)}?',
                        ),
                        const SizedBox(height: 14),
                        _AgendaFilterDropdown(
                          label: 'Tipo de recebimento',
                          value: formaSelecionada,
                          values: formasDisponiveis,
                          icon: Icons.payments_outlined,
                          onChanged: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return;
                            }
                            setDialogState(() {
                              formaSelecionada = value;
                              erroForma = null;
                            });
                          },
                        ),
                        if (erroForma != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            erroForma!,
                            style: TextStyle(
                              color: WebThemeTokens.of(dialogContext).danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final codigoTipo = _codigoTipoFormaPagamentoSelecionada(
                          formaSelecionada,
                        );
                        if (codigoTipo == null) {
                          setDialogState(
                            () =>
                                erroForma = 'Selecione um tipo de recebimento.',
                          );
                          return;
                        }
                        Navigator.pop(dialogContext, codigoTipo);
                      },
                      child: Text(label),
                    ),
                  ],
                ),
          ),
    );
    if (codigoTipoRecebimento == null) {
      return;
    }
    await _executarComLoading(() async {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      await _acoesService.executarTotal(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: codigoTipoRecebimento,
          observacoes: 'Liquidação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
          idSessaoCaixa: idSessaoCaixa,
        ),
      );
      await _consultar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento liquidado com sucesso.')),
        );
      }
    });
  }

  Future<String?> _buscarIdSessaoCaixaAberta() async {
    final CaixaSessao? sessao = await _caixaApiClient.getSessaoAtual();
    final String? idSessaoCaixa = sessao?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  List<String> _formasPagamentoDisponiveisParaLiquidacao() {
    return _tiposRecebimentoFiltro
        .where((forma) => forma != 'Todos' && forma.trim().isNotEmpty)
        .toList();
  }

  Future<List<String>>
  _carregarFormasPagamentoDisponiveisParaLiquidacao() async {
    final formasAtuais = _formasPagamentoDisponiveisParaLiquidacao();
    if (formasAtuais.isNotEmpty) {
      return formasAtuais;
    }
    await _carregarTiposPagamentoConfigurados();
    return _formasPagamentoDisponiveisParaLiquidacao();
  }

  String _formaPagamentoInicialLiquidacao(
    Map<String, dynamic> item,
    List<String> formasDisponiveis,
  ) {
    if (formasDisponiveis.isEmpty) {
      return '';
    }
    final formaAtual = item['formaPagamento']?.toString().trim() ?? '';
    if (formasDisponiveis.contains(formaAtual)) {
      return formaAtual;
    }
    final codigoAtual =
        item['codigoTipoRecebimento']?.toString().trim().toLowerCase() ?? '';
    return formasDisponiveis.firstWhere(
      (forma) => _codigoTipoPorDescricaoFormaPagamento[forma] == codigoAtual,
      orElse: () => formasDisponiveis.first,
    );
  }

  String? _codigoTipoFormaPagamentoSelecionada(String formaSelecionada) {
    final codigo =
        _codigoTipoPorDescricaoFormaPagamento[formaSelecionada]?.trim();
    if (codigo == null || codigo.isEmpty) {
      return null;
    }
    return codigo;
  }

  Future<void> _executarComLoading(Future<void> Function() action) async {
    if (_executandoAcao) {
      return;
    }
    setState(() => _executandoAcao = true);
    try {
      await action();
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha na ação (${e.statusCode}).')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _executandoAcao = false);
      }
    }
  }

  Future<void> _novoLancamento() async {
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: 'Empresa',
      empresas: const <String>['Empresa'],
    );
    if (!mounted || item == null) {
      return;
    }
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    final empresaAtual = _empresaNome(item['empresa']).trim();
    final empresas = <String>[empresaAtual.isEmpty ? 'Empresa' : empresaAtual];
    final atualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: empresas.first,
      empresas: empresas,
      modoEdicao: true,
      lancamentoInicial: item,
    );
    if (!mounted || atualizado == null) {
      return;
    }
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
        style: OutlinedButton.styleFrom(
          backgroundColor: tokens.surfaceMuted,
          foregroundColor: tokens.info,
          disabledBackgroundColor: tokens.disabledBackground,
          disabledForegroundColor: tokens.disabledForeground,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: tokens.info.withValues(alpha: 0.24),
            width: 1.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.info,
          foregroundColor: tokens.onInfo,
          disabledBackgroundColor: tokens.disabledBackground,
          disabledForegroundColor: tokens.disabledForeground,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.secondaryText,
          disabledForegroundColor: tokens.disabledForeground,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
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
          (Set<WidgetState> states) =>
              states.contains(WidgetState.hovered)
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
            child: RefreshIndicator(
              onRefresh: () => _consultar(mostrarFeedback: true),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _buildHeader(theme, showCloseButton: podeFecharTela),
                  const SizedBox(height: 14),
                  _buildFiltros(theme),
                  if (_carregando || _executandoAcao) ...const <Widget>[
                    SizedBox(height: 10),
                    LinearProgressIndicator(minHeight: 3),
                  ],
                  const SizedBox(height: 14),
                  _buildResumo(theme),
                  const SizedBox(height: 18),
                  _buildAbas(theme),
                  const SizedBox(height: 16),
                  _buildConteudoAba(theme),
                ],
              ),
            ),
          );

          return Material(
            color: tokens.workspaceBackground,
            child: SafeArea(
              child:
                  podeFecharTela
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

  Widget _buildHeader(ThemeData theme, {required bool showCloseButton}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          Builder(
            builder: (BuildContext context) {
              final tokens = WebThemeTokens.of(context);
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tokens.selectedBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: tokens.info,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Agenda financeira',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _ultimaConsultaEm == null
                      ? 'Filtre os lançamentos e acompanhe seus detalhes.'
                      : 'Atualizado às ${_ultimaConsultaEm!.hour.toString().padLeft(2, '0')}:${_ultimaConsultaEm!.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: _secondaryCtaStyle(theme),
            onPressed:
                _carregando ? null : () => _consultar(mostrarFeedback: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Atualizar'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            style: _primaryCtaStyle(theme),
            onPressed: _novoLancamento,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo lançamento'),
          ),
          if (showCloseButton) ...<Widget>[
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _fechar,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Fechar',
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildFiltros(ThemeData theme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _drop('Período', _periodoSelecionado, _periodos, _selecionarPeriodo),
          if (_usaPeriodoPersonalizado) ...<Widget>[
            _dateFilterField(
              'Início',
              _dataInicioPersonalizada,
              _selecionarDataInicioPersonalizada,
            ),
            _dateFilterField(
              'Fim',
              _dataFimPersonalizada,
              _selecionarDataFimPersonalizada,
            ),
          ],
          _drop('Tipo', _tipoSelecionado, _tipos, _selecionarTipo),
          _drop('Status', _statusSelecionado, _status, _selecionarStatus),
          _multiSelectTipoPagamento(theme),
          FilledButton.icon(
            style: _primaryCtaStyle(theme),
            onPressed:
                _carregando ? null : () => _consultar(mostrarFeedback: true),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Buscar'),
          ),
        ],
      ),
    ),
  );

  Widget _dateFilterField(String label, DateTime value, VoidCallback onTap) {
    return _AgendaFilterTrigger(
      width: 170,
      label: label,
      value: _formatarDataCurta(value),
      icon: Icons.event_outlined,
      onTap: onTap,
    );
  }

  Widget _multiSelectTipoPagamento(ThemeData theme) {
    return _AgendaMultiSelectDropdown(
      width: 260,
      label: 'Tipo de pagamento',
      value: _formasPagamentoFiltroLabel(),
      values:
          _tiposRecebimentoFiltro.where((forma) => forma != 'Todos').toList(),
      selectedValues: _formasPagamentoSelecionadas,
      icon: Icons.payments_outlined,
      onChanged: _selecionarTiposPagamento,
    );
  }

  String _formasPagamentoFiltroLabel() {
    if (_formasPagamentoSelecionadas.isEmpty) {
      return 'Todos';
    }
    if (_formasPagamentoSelecionadas.length == 1) {
      return _formasPagamentoSelecionadas.first;
    }
    return '${_formasPagamentoSelecionadas.length} tipos selecionados';
  }

  Widget _drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue = values.contains(value) ? value : values.first;
    return _AgendaFilterDropdown(
      label: label,
      value: safeValue,
      values: values,
      icon: _iconeFiltro(label),
      width: _larguraFiltro(label),
      onChanged: onChanged,
    );
  }

  double _larguraFiltro(String label) {
    if (label == 'Tipo de pagamento') return 260;
    if (label == 'Período') return 230;
    return 190;
  }

  IconData _iconeFiltro(String label) {
    switch (label) {
      case 'Período':
        return Icons.calendar_today_outlined;
      case 'Tipo':
        return Icons.swap_vert_rounded;
      case 'Status':
        return Icons.flag_outlined;
      default:
        return Icons.tune_rounded;
    }
  }

  Widget _buildResumo(ThemeData theme) {
    final cards = <Map<String, dynamic>>[
      <String, dynamic>{
        'titulo': 'A receber aberto',
        'valor': _totalReceberPrevisto,
        'icone': Icons.south_west_rounded,
      },
      <String, dynamic>{
        'titulo': 'A pagar aberto',
        'valor': _totalPagarPrevisto,
        'icone': Icons.north_east_rounded,
      },
      <String, dynamic>{
        'titulo': 'Saldo previsto',
        'valor': _saldoPrevisto,
        'icone': Icons.query_stats_rounded,
      },
      <String, dynamic>{
        'titulo': 'Recebido confirmado',
        'valor': _totalRecebidoConfirmado,
        'icone': Icons.verified_rounded,
      },
      <String, dynamic>{
        'titulo': 'Pago confirmado',
        'valor': _totalPagoConfirmado,
        'icone': Icons.task_alt_rounded,
      },
      <String, dynamic>{
        'titulo': 'Saldo confirmado',
        'valor': _saldoConfirmado,
        'icone': Icons.account_balance_wallet_outlined,
      },
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth >= 1500
                ? (constraints.maxWidth - 60) / 6
                : constraints.maxWidth >= 1000
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              cards
                  .map(
                    (card) =>
                        SizedBox(width: width, child: _resumoCard(theme, card)),
                  )
                  .toList(),
        );
      },
    );
  }

  ButtonStyle _secondaryCtaStyle(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: tokens.info,
      backgroundColor: Color.alphaBlend(
        tokens.info.withValues(alpha: 0.06),
        tokens.cardBackground,
      ),
      side: BorderSide(color: tokens.selectedBorder.withValues(alpha: 0.78)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  ButtonStyle _primaryCtaStyle(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    final Color primary = theme.colorScheme.primary;
    return FilledButton.styleFrom(
      foregroundColor: theme.colorScheme.onPrimary,
      backgroundColor: Color.alphaBlend(
        primary.withValues(alpha: 0.92),
        tokens.surfaceElevated,
      ),
      disabledBackgroundColor: tokens.disabledBackground,
      disabledForegroundColor: tokens.disabledForeground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Color _agendaTipoAccent(String? tipo) {
    final tokens = WebThemeTokens.of(context);
    return tipo == 'pagar'
        ? tokens.financialNegative
        : tokens.financialPositive;
  }

  Color _agendaStatusAccent(String? status) {
    final tokens = WebThemeTokens.of(context);
    switch ((status ?? '').trim().toUpperCase()) {
      case 'VENCIDO':
        return tokens.danger;
      case 'VENCE HOJE':
      case 'VENCE_HOJE':
      case 'PARCIAL':
        return tokens.warning;
      case 'PAGO':
      case 'RECEBIDO':
      case 'QUITADO':
        return tokens.success;
      case 'CANCELADO':
      case 'CANCELADA':
        return tokens.statusNeutral;
      case 'PREVISTO':
        return tokens.info;
      case 'PENDENTE':
      case 'ABERTO':
      default:
        return tokens.statusNeutral;
    }
  }

  Widget _agendaPill(String label, Color accent, {IconData? icon}) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.10),
          tokens.cardBackground,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoCard(ThemeData theme, Map<String, dynamic> card) {
    final tokens = WebThemeTokens.of(context);
    final valor = _toDouble(card['valor']);
    final titulo = card['titulo'] as String;
    final Color accent =
        titulo.contains('receber') || titulo.contains('Recebido')
            ? tokens.financialPositive
            : titulo.contains('pagar') || titulo.contains('Pago')
            ? tokens.financialNegative
            : tokens.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  accent.withValues(alpha: 0.10),
                  tokens.cardBackground,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(card['icone'] as IconData, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarMoeda(valor),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbas(ThemeData theme) => SegmentedButton<int>(
    selected: <int>{_abaSelecionada},
    onSelectionChanged:
        (value) => setState(() => _abaSelecionada = value.first),
    segments: const <ButtonSegment<int>>[
      ButtonSegment<int>(value: 0, label: Text('Agenda')),
      ButtonSegment<int>(value: 1, label: Text('Calendário')),
      ButtonSegment<int>(value: 2, label: Text('Fluxo previsto')),
      ButtonSegment<int>(value: 3, label: Text('Valores confirmados')),
    ],
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

  Widget _cardLancamento(ThemeData theme, Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    final tokens = WebThemeTokens.of(context);
    final Color tipoAccent = _agendaTipoAccent(item['tipo']?.toString());
    final Color statusAccent = _agendaStatusAccent(item['status']?.toString());
    final acoes = List<String>.from(
      (item['acoes'] as List?)?.map((e) => e.toString()) ?? const <String>[],
    );
    if (!acoes.contains('Detalhes')) acoes.add('Detalhes');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _executandoAcao ? null : () => _mostrarDetalhesLancamento(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _agendaPill(
                    tipoEntrada ? 'Receber' : 'Pagar',
                    tipoAccent,
                    icon:
                        tipoEntrada
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                  ),
                  _agendaPill(
                    item['status']?.toString() ?? '-',
                    statusAccent,
                    icon: Icons.flag_outlined,
                  ),
                  _agendaPill(
                    item['formaPagamento']?.toString() ?? '-',
                    tokens.info,
                    icon: Icons.payments_outlined,
                  ),
                  if (_toDouble(item['valorConfirmado']) > 0)
                    _agendaPill(
                      'Confirmado: ${_formatarMoeda(_toDouble(item['valorConfirmado']))}',
                      tokens.success,
                      icon: Icons.verified_outlined,
                    ),
                  if (_toDouble(item['valorRestante']) > 0)
                    _agendaPill(
                      'Aberto: ${_formatarMoeda(_toDouble(item['valorRestante']))}',
                      statusAccent,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['descricao']?.toString() ?? '',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item['contato']} • Vence em ${item['vencimento']}',
                style: TextStyle(color: tokens.secondaryText),
              ),
              const SizedBox(height: 8),
              Text(
                'Original: ${_formatarMoeda(_toDouble(item['valorOriginal']))}',
                style: TextStyle(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed:
                        _executandoAcao ? null : () => _editarLancamento(item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  ...acoes
                      .take(4)
                      .map(
                        (acao) => OutlinedButton(
                          onPressed:
                              _executandoAcao
                                  ? null
                                  : () => _executarAcao(acao, item),
                          child: Text(acao),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      children:
          itens.map((item) {
            final tokens = WebThemeTokens.of(context);
            final accent = _agendaTipoAccent(item['tipo']?.toString());
            return Card(
              child: ListTile(
                onTap: () => _mostrarDetalhesLancamento(item),
                leading: Icon(
                  item['tipo'] == 'receber'
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: accent,
                ),
                title: Text(
                  item['descricao']?.toString() ?? '',
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${item['contato']} • ${item['data']} • ${item['formaPagamento']} • Restante: ${_formatarMoeda(_toDouble(item['valorRestante']))}',
                  style: TextStyle(color: tokens.secondaryText),
                ),
                trailing: Text(
                  _formatarMoeda(_toDouble(item['valorConfirmado'])),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCalendario(ThemeData theme) {
    final itens = List<Map<String, dynamic>>.from(_itensAgenda)..sort(
      (a, b) => (a['vencimento']?.toString() ?? '').compareTo(
        b['vencimento']?.toString() ?? '',
      ),
    );
    if (itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum lançamento encontrado no calendário.'),
        ),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Tipo de pagamento')),
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Valor'), numeric: true),
            DataColumn(label: Text('Ações')),
          ],
          rows:
              itens
                  .map(
                    (item) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(item['vencimento']?.toString() ?? '-')),
                        DataCell(
                          Text(item['tipo'] == 'receber' ? 'Receber' : 'Pagar'),
                        ),
                        DataCell(
                          Text(item['formaPagamento']?.toString() ?? '-'),
                        ),
                        DataCell(
                          SizedBox(
                            width: 340,
                            child: Text(
                              item['descricao']?.toString() ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatarMoeda(
                              _toDouble(item['valorRestante'] ?? item['valor']),
                            ),
                          ),
                        ),
                        DataCell(
                          TextButton(
                            onPressed: () => _mostrarDetalhesLancamento(item),
                            child: const Text('Detalhes'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
        ),
      ),
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
            'Saldo previsto: ${_formatarMoeda(_saldoPrevisto)}',
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

  String _formaPagamentoLabel(String? formaPagamento) {
    final backend = (formaPagamento ?? '').toUpperCase();
    final codigoConfigurado = _codigoTipoPorBackendFormaPagamento(backend);
    if (codigoConfigurado != null) {
      final descricaoConfigurada =
          _descricaoPorBackendFormaPagamento[codigoConfigurado];
      if (descricaoConfigurada != null &&
          descricaoConfigurada.trim().isNotEmpty) {
        return descricaoConfigurada;
      }
    }
    final configurada = _descricaoPorBackendFormaPagamento[backend];
    if (configurada != null && configurada.trim().isNotEmpty) {
      return configurada;
    }
    return _descricaoPorBackendFormaPagamento[backend] ??
        (formaPagamento?.toString().trim().isNotEmpty == true
            ? formaPagamento!
            : 'Pix');
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
    final codigo =
        item['codigoTipoRecebimento']?.toString().trim().toLowerCase();
    if (codigo != null && RegExp(r'^tipo(10|[1-9])$').hasMatch(codigo)) {
      return codigo;
    }
    return _codigoTipoPorBackendFormaPagamento(
      item['formaPagamento']?.toString() ?? '',
    );
  }

  String _empresaNome(dynamic empresa) =>
      empresa is Map<String, dynamic>
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
      final normalizado =
          texto.contains(',') && texto.contains('.')
              ? texto.replaceAll('.', '').replaceAll(',', '.')
              : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  String _formatarMoeda(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);
}

class _ParcialLancamentoResultado {
  const _ParcialLancamentoResultado({
    required this.valor,
    required this.codigoTipoRecebimento,
  });
  final double valor;
  final String codigoTipoRecebimento;
}

class _AgendaFilterDropdown extends StatefulWidget {
  const _AgendaFilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.icon,
    required this.onChanged,
    this.width,
  });

  final String label;
  final String value;
  final List<String> values;
  final IconData icon;
  final ValueChanged<String?> onChanged;
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
    if (widget.values.isEmpty) {
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
                    label: item,
                    selected: item == safeValue,
                  ),
                ),
              )
              .toList(),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AgendaFilterTrigger(
      label: widget.label,
      value: _safeValue,
      icon: widget.icon,
      width: widget.width,
      open: _open,
      onTap: _showOptions,
    );
  }
}

class _AgendaMultiSelectDropdown extends StatefulWidget {
  const _AgendaMultiSelectDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.selectedValues,
    required this.icon,
    required this.onChanged,
    this.width,
  });

  final String label;
  final String value;
  final List<String> values;
  final Set<String> selectedValues;
  final IconData icon;
  final ValueChanged<Set<String>> onChanged;
  final double? width;

  @override
  State<_AgendaMultiSelectDropdown> createState() =>
      _AgendaMultiSelectDropdownState();
}

class _AgendaMultiSelectDropdownState
    extends State<_AgendaMultiSelectDropdown> {
  bool _open = false;

  Future<void> _showOptions() async {
    setState(() => _open = true);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    final Set<String>? selected = await showMenu<Set<String>>(
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
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width < 320 ? 320 : box.size.width,
      ),
      items: <PopupMenuEntry<Set<String>>>[
        _AgendaMultiSelectMenuEntry(
          label: widget.label,
          values: widget.values,
          selectedValues: widget.selectedValues,
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AgendaFilterTrigger(
      label: widget.label,
      value: widget.value,
      icon: widget.icon,
      width: widget.width,
      open: _open,
      onTap: _showOptions,
    );
  }
}

class _AgendaMultiSelectMenuEntry extends PopupMenuEntry<Set<String>> {
  const _AgendaMultiSelectMenuEntry({
    required this.label,
    required this.values,
    required this.selectedValues,
  });

  final String label;
  final List<String> values;
  final Set<String> selectedValues;

  @override
  double get height {
    final int itemCount = values.length + 1;
    final double computed = 112 + (itemCount * 46);
    if (computed < 214) {
      return 214;
    }
    if (computed > 420) {
      return 420;
    }
    return computed;
  }

  @override
  bool represents(Set<String>? value) => false;

  @override
  State<_AgendaMultiSelectMenuEntry> createState() =>
      _AgendaMultiSelectMenuEntryState();
}

class _AgendaMultiSelectMenuEntryState
    extends State<_AgendaMultiSelectMenuEntry> {
  late final Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.selectedValues);
  }

  void _toggle(String value) {
    setState(() {
      if (_selection.contains(value)) {
        _selection.remove(value);
      } else {
        _selection.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.payments_outlined, color: tokens.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _selection.isEmpty ? 'Todos' : '${_selection.length}',
                  style: TextStyle(
                    color: tokens.info,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _AgendaMultiSelectMenuTile(
                      label: 'Todos',
                      selected: _selection.isEmpty,
                      onTap: () => setState(_selection.clear),
                    ),
                    const SizedBox(height: 4),
                    ...widget.values.map(
                      (value) => _AgendaMultiSelectMenuTile(
                        label: value,
                        selected: _selection.contains(value),
                        onTap: () => _toggle(value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: const Text('Limpar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(Set<String>.from(_selection)),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaMultiSelectMenuTile extends StatelessWidget {
  const _AgendaMultiSelectMenuTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? tokens.selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? tokens.info : tokens.mutedText,
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
          ),
        ),
      ),
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
        message: 'Selecionar ${widget.label}',
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? widget.onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 58,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
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
                    Icon(widget.icon, size: 18, color: tokens.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
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
                        color: active ? tokens.info : tokens.mutedText,
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
            color: selected ? tokens.info : tokens.mutedText,
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
    required this.formaPagamentoLabel,
    required this.onExcluirLancamento,
    required this.onExcluirLiquidacao,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> detalhe;
  final bool fallback;
  final String Function(double) formatarMoeda;
  final String Function(dynamic) formatarData;
  final String Function(String?) formaPagamentoLabel;
  final Future<bool> Function() onExcluirLancamento;
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
    final comprovantes = _listaStrings(detalhe['comprovantes']);
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
      tokens,
      _texto(detalhe['status'], item['status']),
      valorAberto,
    );
    return Dialog(
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
                  TextButton.icon(
                    onPressed: () async {
                      final excluido = await onExcluirLancamento();
                      if (excluido && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Excluir lançamento'),
                    style: TextButton.styleFrom(foregroundColor: tokens.danger),
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
                                  item['tipo'] == 'pagar' ? 'Pagar' : 'Receber',
                                ),
                              ),
                              _chip(
                                theme,
                                _texto(detalhe['status'], item['status']),
                              ),
                              _chip(
                                theme,
                                formaPagamentoLabel(
                                  _texto(
                                    detalhe['formaPagamento'],
                                    item['formaPagamento'],
                                  ),
                                ),
                              ),
                              _chip(
                                theme,
                                'ID: ${_texto(detalhe['idLancamento'], item['id'])}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width =
                                  constraints.maxWidth >= 760
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
                          _section(
                            theme,
                            'Datas',
                            Icons.calendar_month_outlined,
                            <Widget>[
                              _info(
                                'Competência',
                                formatarData(detalhe['dataCompetencia']),
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
                              _info(
                                'Origem',
                                _texto(
                                  origem['codigoExibicao'],
                                  origem['tipo'],
                                  item['origem'],
                                ),
                              ),
                              _info('Referência', _texto(origem['id'])),
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
                              _info('Documento', _texto(contato['documento'])),
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
                                  children:
                                      acoes
                                          .map((a) => Chip(label: Text(a)))
                                          .toList(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (stamp != null)
                    Positioned(top: 18, right: 28, child: _statusStamp(stamp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DetalheStatusStampData? _stampData(
    WebThemeTokens tokens,
    String status,
    double valorAberto,
  ) {
    final normalized = status.trim().toUpperCase().replaceAll(' ', '_');
    if (normalized == 'PAGO' ||
        normalized == 'RECEBIDO' ||
        valorAberto <= 0 &&
            (normalized == 'FINALIZADA' || normalized == 'FINALIZADO')) {
      return _DetalheStatusStampData('PAGO', tokens.success);
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
                'Tipo de pagamento',
                formaPagamentoLabel(
                  liquidacao['formaPagamentoRealizada']?.toString(),
                ),
              ),
              if (idLiquidacao.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final excluiu = await onExcluirLiquidacao(liquidacao);
                    if (excluiu && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir parcial'),
                  style: TextButton.styleFrom(foregroundColor: tokens.danger),
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

  List<Map<String, dynamic>> _listaMapas(dynamic raw) =>
      raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
  List<String> _listaStrings(dynamic raw) =>
      raw is List
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
      final normalizado =
          value.contains(',') && value.contains('.')
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
