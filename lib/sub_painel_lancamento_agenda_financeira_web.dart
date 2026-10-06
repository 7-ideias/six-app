import 'package:sixpos/presentation/components/web/conta_financeira_web_field.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_labels.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_web_fields.dart';
import 'package:sixpos/presentation/components/web/agenda_centro_custo_web_field.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class SubPainelLancamentoAgendaFinanceiraWeb extends StatelessWidget {
  const SubPainelLancamentoAgendaFinanceiraWeb({
    super.key,
    required this.body,
    required this.textoDaAppBar,
  });

  final Widget body;
  final String textoDaAppBar;

  void _fecharSubPainel(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = WebThemeTokens.applyTo(Theme.of(context));
    final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
    return Theme(
      data: theme,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape):
              () => _fecharSubPainel(context),
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: Semantics(
              namesRoute: true,
              label: textoDaAppBar,
              child: AnimatedContainer(
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                width: MediaQuery.of(context).size.width * 0.97,
                height: MediaQuery.of(context).size.height * 0.96,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: tokens.cardBorder),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Scaffold(
                  backgroundColor: tokens.workspaceBackground,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: false,
                    titleSpacing: 24,
                    title: Text(
                      textoDaAppBar,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    backgroundColor: tokens.surfaceMuted,
                    foregroundColor: tokens.primaryText,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: Border(bottom: BorderSide(color: tokens.cardBorder)),
                    actions: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _fecharSubPainel(context),
                        tooltip: context.t('common.close', fallback: 'Fechar'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showSubPainelLancamentoAgendaFinanceiraWeb(
  BuildContext context, {
  required String empresaSelecionada,
  required List<String> empresas,
  bool modoEdicao = false,
  Map<String, dynamic>? lancamentoInicial,
  AgendaFinanceiraLancamentoService? service,
}) {
  return showSixWebAnimatedDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.t(
      'agenda.launch.dialogBarrier',
      fallback:
          modoEdicao
              ? 'Editar lançamento financeiro'
              : 'Novo lançamento financeiro',
    ),
    overlayColor: const Color(0xC20B1324),
    overlayBlurSigma: 12,
    transitionDuration: const Duration(milliseconds: 320),
    padding: const EdgeInsets.all(12),
    builder: (BuildContext dialogContext) {
      return SubPainelLancamentoAgendaFinanceiraWeb(
        textoDaAppBar:
            modoEdicao
                ? context.t('agenda.form.edit')
                : context.t('agenda.form.create'),
        body: _LancamentoAgendaFinanceiraWebBody(
          service: service,
          empresaSelecionada: empresaSelecionada,
          empresas: empresas,
          modoEdicao: modoEdicao,
          lancamentoInicial: lancamentoInicial,
        ),
      );
    },
  );
}

class _LancamentoAgendaFinanceiraWebBody extends StatefulWidget {
  const _LancamentoAgendaFinanceiraWebBody({
    this.service,
    required this.empresaSelecionada,
    required this.empresas,
    required this.modoEdicao,
    this.lancamentoInicial,
  });

  final AgendaFinanceiraLancamentoService? service;
  final String empresaSelecionada;
  final List<String> empresas;
  final bool modoEdicao;
  final Map<String, dynamic>? lancamentoInicial;

  @override
  State<_LancamentoAgendaFinanceiraWebBody> createState() =>
      _LancamentoAgendaFinanceiraWebBodyState();
}

class _LancamentoAgendaFinanceiraWebBodyState
    extends State<_LancamentoAgendaFinanceiraWebBody> {
  final String _uuidCriacao = 'web-${DateTime.now().microsecondsSinceEpoch}';
  AgendaFinanceiraRecorrencia _recorrencia = AgendaFinanceiraRecorrencia();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AgendaFinanceiraLancamentoService _service =
      widget.service ?? AgendaFinanceiraLancamentoService();
  late final CaixaApiClient _caixaApiClient = HttpCaixaApiClient(
    espacoFinanceiro: () => _service.espacoFinanceiro,
  );

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _idContatoController = TextEditingController();
  String? _contaFinanceiraId;
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _valorConfirmadoController =
      TextEditingController(text: '0,00');
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _documentoFiscalController =
      TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();
  final TextEditingController _dataOperacaoController = TextEditingController();
  final TextEditingController _dataVencimentoController =
      TextEditingController();
  final TextEditingController _dataCompetenciaController =
      TextEditingController();

  final _dataPrevisaoController = TextEditingController();
  DateTime? _dataPrevisaoPagamento;
  DateTime? _dataCriacao;
  DateTime? _dataQuitacao;
  bool _registrarPagamento = false;
  DateTime _dataPagamentoRealizado = DateTime.now();
  final _dataPagamentoController = TextEditingController();
  bool _isLoading = false;
  bool _statusQuitada = false;
  bool _bloquearTipoStatusPorConfirmacao = false;
  String? _idLancamentoEdicao;
  String? _uuidOperacaoAppEdicao;
  String? _centroCustoId;

  String _tipoSelecionado = 'Pagar';
  String _statusSelecionado = 'Pendente';
  String _origemSelecionada = 'Despesa manual';
  String _empresaSelecionada = '';
  String _formaPagamentoSelecionada = 'Pix';

  DateTime _dataOperacao = DateTime.now();
  DateTime _dataVencimento = DateTime.now();
  DateTime _dataCompetencia = DateTime.now();

  static const List<String> _status = <String>['Previsto', 'Pendente'];
  static const List<String> _origens = <String>[
    'Venda',
    'Ordem de serviço',
    'Despesa manual',
    'Compra',
    'Parcela',
    'Movimentação de caixa',
  ];
  static const List<String> _formasPagamentoPadrao = <String>[
    'Pix',
    'Boleto',
    'Transferência',
    'Cartão de crédito',
    'Cartão de débito',
    'Débito automático',
    'Dinheiro',
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

  List<String> _formasPagamento = List<String>.from(_formasPagamentoPadrao);
  bool _carregandoTiposRecebimento = false;

  bool get _bloquearTipoStatus =>
      widget.modoEdicao && _bloquearTipoStatusPorConfirmacao;

  @override
  void initState() {
    super.initState();
    final List<String> empresas =
        widget.empresas.isEmpty ? <String>['Empresa'] : widget.empresas;
    _empresaSelecionada =
        empresas.contains(widget.empresaSelecionada)
            ? widget.empresaSelecionada
            : empresas.first;

    if (widget.modoEdicao && widget.lancamentoInicial != null) {
      _preencherCamposEdicao(widget.lancamentoInicial!);
    }

    _sincronizarTextosData();
    if (!widget.modoEdicao)
      _valorConfirmadoController.text = _formatarValorParaCampo(0);
    _valorController.addListener(_atualizarResumo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTiposRecebimentoAtivos();
    });
  }

  void _atualizarResumo() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _valorController.removeListener(_atualizarResumo);
    _dataPrevisaoController.dispose();
    _dataPagamentoController.dispose();
    _descricaoController.dispose();
    _contatoController.dispose();
    _idContatoController.dispose();
    _categoriaController.dispose();
    _valorController.dispose();
    _valorConfirmadoController.dispose();
    _responsavelController.dispose();
    _observacoesController.dispose();
    _referenciaController.dispose();
    _documentoFiscalController.dispose();
    _centroCustoController.dispose();
    _dataOperacaoController.dispose();
    _dataVencimentoController.dispose();
    _dataCompetenciaController.dispose();
    super.dispose();
  }

  void _preencherCamposEdicao(Map<String, dynamic> item) {
    _recorrencia = AgendaFinanceiraRecorrencia.fromJson(item);
    _idLancamentoEdicao = item['id']?.toString();
    _uuidOperacaoAppEdicao =
        item['uuidOperacaoApp']?.toString() ?? item['id']?.toString();

    final String tipoItem = item['tipo']?.toString().toLowerCase() ?? '';
    if (tipoItem == 'receber') {
      _tipoSelecionado = 'Receber';
    } else if (tipoItem == 'pagar') {
      _tipoSelecionado = 'Pagar';
    }

    final codigoStatus = LancamentoAgendaFinanceiraRequest.normalizarStatus(
      item['status']?.toString() ?? 'PENDENTE',
    );
    final String status = switch (codigoStatus) {
      'PREVISTO' => 'Previsto',
      'PENDENTE' => 'Pendente',
      'PAGO' => 'Pago',
      'RECEBIDO' => 'Recebido',
      'PARCIAL' => 'Parcial',
      'CANCELADO' => 'Cancelado',
      _ => item['status']?.toString() ?? '',
    };
    _statusSelecionado = status;

    final double valorConfirmado = _toDoubleDynamic(item['valorConfirmado']);
    final double valorRestante = _toDoubleDynamic(item['valorRestante']);
    final String statusNormalizado = _normalizarSemAcento(status).toUpperCase();
    _statusQuitada =
        statusNormalizado == 'PAGO' ||
        statusNormalizado == 'RECEBIDO' ||
        (valorConfirmado > 0 && valorRestante <= 0);
    if (valorConfirmado > 0 && _status.contains(_statusSelecionado)) {
      _statusSelecionado =
          valorRestante > 0
              ? 'Parcial'
              : (_tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago');
    }
    _bloquearTipoStatusPorConfirmacao =
        _statusQuitada || valorConfirmado > 0 || !_status.contains(status);

    final String origem = item['origem']?.toString() ?? '';
    if (_origens.contains(origem)) _origemSelecionada = origem;
    _alinharOrigemComTipo(_tipoSelecionado);

    final String formaPagamento = item['formaPagamento']?.toString() ?? '';
    if (formaPagamento.trim().isNotEmpty) {
      _formaPagamentoSelecionada = _formaPagamentoLabel(formaPagamento);
      if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
        _formasPagamento = <String>[
          _formaPagamentoSelecionada,
          ..._formasPagamento,
        ];
      }
    }

    final String empresa = item['empresa']?.toString() ?? '';
    if (widget.empresas.contains(empresa)) _empresaSelecionada = empresa;

    final dynamic valorOriginal =
        item['valorOriginal'] ??
        item['valorTotalOperacao'] ??
        item['valorTotal'] ??
        item['valor'];
    _descricaoController.text = item['descricao']?.toString() ?? '';
    _contatoController.text = item['contato']?.toString() ?? '';
    _idContatoController.text = item['idContato']?.toString() ?? '';
    _contaFinanceiraId = item['contaFinanceiraId']?.toString();
    _categoriaController.text = item['categoria']?.toString() ?? '';
    _valorController.text = _formatarValorParaCampo(valorOriginal);
    _valorConfirmadoController.text = _formatarValorParaCampo(valorConfirmado);
    _responsavelController.text = item['responsavel']?.toString() ?? '';
    _observacoesController.text = item['observacoes']?.toString() ?? '';
    _referenciaController.text = item['referenciaExterna']?.toString() ?? '';
    _documentoFiscalController.text = item['documentoFiscal']?.toString() ?? '';
    _centroCustoController.text = item['centroDeCusto']?.toString() ?? '';
    _centroCustoId = item['centroCustoId']?.toString();

    _dataCriacao = DateTime.tryParse(item['dataCriacao']?.toString() ?? '');
    _dataQuitacao = DateTime.tryParse(item['dataLiquidacao']?.toString() ?? '');
    _dataPrevisaoPagamento = DateTime.tryParse(
      item['dataPrevisaoPagamento']?.toString() ?? '',
    );
    _dataVencimento = _parseData(item['vencimento'], fallback: _dataVencimento);
    _dataOperacao = _parseData(item['dataOperacao'], fallback: _dataVencimento);
    _dataCompetencia = _parseData(
      item['dataCompetencia'],
      fallback: _dataVencimento,
    );
  }

  Future<void> _carregarTiposRecebimentoAtivos() async {
    setState(() => _carregandoTiposRecebimento = true);
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas = _montarFormasPagamentoAtivas(
        informacoes.tiposRecebimento,
      );
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamento = formas;
        if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
          _formaPagamentoSelecionada = _formasPagamento.first;
        }
      });
    } catch (_) {
      // Mantém os valores padrão para não impedir o lançamento caso o endpoint falhe.
    } finally {
      if (mounted) setState(() => _carregandoTiposRecebimento = false);
    }
  }

  List<String> _montarFormasPagamentoAtivas(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos =
        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(
          (TiposRecebimento a, TiposRecebimento b) =>
              a.ordemExibicao.compareTo(b.ordemExibicao),
        );

    final List<String> descricoes = <String>[];
    final Map<String, String> backendAtualizado = Map<String, String>.from(
      _backendPorDescricaoFormaPagamento,
    );

    for (final TiposRecebimento tipo in ativos) {
      final String backend =
          _backendFormaPagamentoPorCodigoTipo(tipo.codigoTipo) ??
          _backendFormaPagamentoPorDescricao(tipo.descricaoExibicao);
      final String descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : _formaPagamentoLabel(backend);

      if (descricao.trim().isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      backendAtualizado[descricao] = backend;
    }

    if (descricoes.isNotEmpty) {
      _backendPorDescricaoFormaPagamento
        ..clear()
        ..addAll(backendAtualizado);
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
      case 'tipo6':
        return 'TRANSFERENCIA';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      default:
        return null;
    }
  }

  String _backendFormaPagamentoPorDescricao(String descricao) {
    final String normalizado = _normalizarSemAcento(descricao).toUpperCase();
    if (normalizado.contains('PIX')) return 'PIX';
    if (normalizado.contains('BOLETO')) return 'BOLETO';
    if (normalizado.contains('CREDITO')) return 'CARTAO_CREDITO';
    if (normalizado.contains('DEBITO AUTOMATICO')) return 'DEBITO_AUTOMATICO';
    if (normalizado.contains('DEBITO')) return 'CARTAO_DEBITO';
    if (normalizado.contains('TRANSFER')) return 'TRANSFERENCIA';
    if (normalizado.contains('DINHEIRO')) return 'DINHEIRO';
    return normalizado.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  String _formaPagamentoLabel(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PIX':
        return 'Pix';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      case 'DINHEIRO':
        return 'Dinheiro';
      default:
        return value.trim().isEmpty ? 'Pix' : value;
    }
  }

  String _normalizarSemAcento(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _formatarValorParaCampo(dynamic valor) {
    final numero =
        valor is num ? valor : double.tryParse(valor?.toString() ?? '') ?? 0;
    return context.read<LocaleSettingsProvider>().formatDecimal(numero);
  }

  double _toDouble(String text) {
    final regional = context.read<LocaleSettingsProvider>();
    final limpo =
        regional
            .stripCurrencyMarkers(text)
            .replaceAll(regional.thousandSeparator, '')
            .replaceAll(regional.decimalSeparator, '.')
            .trim();
    final valor = double.tryParse(limpo);
    return valor != null && valor.isFinite ? valor : 0;
  }

  double _toDoubleDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _normalizarData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  DateTime _parseData(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return _normalizarData(value);
    final String texto = value.toString().trim();
    if (texto.isEmpty) return fallback;
    if (texto.contains('/')) {
      final List<String> partes = texto.split('/');
      if (partes.length == 3) {
        final int? dia = int.tryParse(partes[0]);
        final int? mes = int.tryParse(partes[1]);
        final int? ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) {
          return DateTime(ano, mes, dia);
        }
      }
    }
    final DateTime? data = DateTime.tryParse(texto);
    return data == null ? fallback : _normalizarData(data);
  }

  void _sincronizarTextosData() {
    _dataPagamentoController.text = _formatarDataBr(_dataPagamentoRealizado);
    _dataPrevisaoController.text =
        _dataPrevisaoPagamento == null
            ? ''
            : _formatarDataBr(_dataPrevisaoPagamento!);
    _dataOperacaoController.text = _formatarDataBr(_dataOperacao);
    _dataVencimentoController.text = _formatarDataBr(_dataVencimento);
    _dataCompetenciaController.text = _formatarDataBr(_dataCompetencia);
  }

  String _formatarDataBr(DateTime data) =>
      context.read<LocaleSettingsProvider>().formatDate(data);

  bool _origemSugerePagar(String origem) =>
      origem == 'Despesa manual' || origem == 'Compra';

  bool _origemSugereReceber(String origem) =>
      origem == 'Venda' || origem == 'Ordem de serviço';

  String _origemPadraoPorTipo(String tipo) =>
      tipo == 'Receber' ? 'Venda' : 'Despesa manual';

  void _alinharOrigemComTipo(String tipo) {
    if (tipo == 'Receber' && _origemSugerePagar(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    } else if (tipo == 'Pagar' && _origemSugereReceber(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    }
  }

  void _aplicarTipoSelecionado(String tipo) {
    if (_bloquearTipoStatus) return;
    _tipoSelecionado = tipo;
    _alinharOrigemComTipo(tipo);
    if (tipo == 'Receber' && _statusSelecionado == 'Pago') {
      _statusSelecionado = 'Recebido';
    } else if (tipo == 'Pagar' && _statusSelecionado == 'Recebido') {
      _statusSelecionado = 'Pago';
    }
  }

  String _statusPadraoPorTipo() {
    if (_statusQuitada) {
      return _tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago';
    }
    return _statusSelecionado;
  }

  String _tipoOperacaoParaBackend() => _tipoSelecionado.toUpperCase();

  String _origemParaBackend() {
    switch (_origemSelecionada) {
      case 'Venda':
        return 'VENDA';
      case 'Ordem de serviço':
        return 'ORDEM_SERVICO';
      case 'Despesa manual':
        return 'DESPESA_MANUAL';
      case 'Compra':
        return 'COMPRA';
      case 'Parcela':
        return 'PARCELA';
      case 'Movimentação de caixa':
        return 'MOVIMENTACAO_CAIXA';
      default:
        return _tipoSelecionado == 'Receber' ? 'VENDA' : 'DESPESA_MANUAL';
    }
  }

  String _formaPagamentoParaBackend() {
    return _backendPorDescricaoFormaPagamento[_formaPagamentoSelecionada] ??
        _backendFormaPagamentoPorDescricao(_formaPagamentoSelecionada);
  }

  LancamentoAgendaFinanceiraRequest _buildRequest() {
    final double valorTotal = _toDouble(_valorController.text);
    final String idLocal = _uuidOperacaoAppEdicao ?? _uuidCriacao;
    final String tipoOperacao = _tipoOperacaoParaBackend();
    final String origem = _origemParaBackend();
    final String formaPagamento = _formaPagamentoParaBackend();
    final String contatoIdDigitado = _idContatoController.text.trim();
    final String contatoNome = _contatoController.text.trim();
    final bool isReceber = _tipoSelecionado == 'Receber';

    final Map<String, dynamic> payload = <String, dynamic>{
      'agendaFinanceira': <String, dynamic>{
        'tipoFiltro': tipoOperacao,
        'statusFiltro': _statusPadraoPorTipo(),
        'origemFiltro': origem,
        'empresaFiltro': _empresaSelecionada,
        'formaPrevistaPagamento': formaPagamento,
        'atualizarPrevisaoPagamento': true,
        'dataPrevisaoPagamento':
            _dataPrevisaoPagamento?.toIso8601String().split('T').first,
      },
      'contato': <String, dynamic>{
        'id': contatoIdDigitado,
        'nome': contatoNome,
      },
    };

    return LancamentoAgendaFinanceiraRequest(
      uuidOperacaoApp: idLocal,
      descricao: _descricaoController.text.trim(),
      tipoOperacao: tipoOperacao,
      statusOperacao: _statusPadraoPorTipo(),
      dataOperacao: _dataOperacao,
      dataVencimento: _dataVencimento,
      dataCompetencia: _dataCompetencia,
      dataQuitacao: _statusQuitada ? _dataQuitacao : null,
      statusQuitada: _statusQuitada,
      operacaoFinalizadaProntaCaixa: _statusQuitada,
      clientePediuParaApagar: false,
      origem: origem,
      formaPagamento: formaPagamento,
      empresa: _empresaSelecionada,
      categoria: _categoriaController.text.trim(),
      contaFinanceiraId: _contaFinanceiraId,
      idColaborador: 'web-user',
      nomeColaborador: _responsavelController.text.trim(),
      idCliente:
          isReceber && contatoIdDigitado.isNotEmpty ? contatoIdDigitado : null,
      nomeCliente: isReceber && contatoNome.isNotEmpty ? contatoNome : null,
      idFornecedor:
          !isReceber && contatoIdDigitado.isNotEmpty ? contatoIdDigitado : null,
      nomeFornecedor: !isReceber && contatoNome.isNotEmpty ? contatoNome : null,
      referenciaExterna:
          _referenciaController.text.trim().isEmpty
              ? null
              : _referenciaController.text.trim(),
      documentoFiscal:
          _documentoFiscalController.text.trim().isEmpty
              ? null
              : _documentoFiscalController.text.trim(),
      centroDeCusto:
          _centroCustoController.text.trim().isEmpty
              ? null
              : _centroCustoController.text.trim(),
      centroCustoId: _centroCustoId,
      valorTotalProdutos: 0,
      valorTotalServicos: 0,
      valorTotalOperacao: valorTotal,
      observacoes:
          _observacoesController.text.trim().isEmpty
              ? null
              : _observacoesController.text.trim(),
      configuracaoRecorrencia: _recorrencia,
      payloadOriginalJson: payload,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_toDouble(_valorController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero.')),
      );
      return;
    }

    final erroRecorrencia = _recorrencia.validar(_dataVencimento);
    if (erroRecorrencia != null ||
        (_recorrencia.ativa &&
            !['Pendente', 'Previsto'].contains(_statusSelecionado))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recorrenciaLabel(context, erroRecorrencia ?? 'pendingError'),
          ),
        ),
      );
      return;
    }

    final LancamentoAgendaFinanceiraRequest request = _buildRequest();
    setState(() => _isLoading = true);
    late final String idGerado;

    try {
      final LancamentoAgendaFinanceiraResponse response =
          widget.modoEdicao
              ? await _service.editarLancamento(
                _idLancamentoEdicao ?? request.uuidOperacaoApp,
                request,
                escopo: _recorrencia.escopo,
              )
              : await _service.cadastrarLancamento(request);
      idGerado = response.id;
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recorrenciaLabel(
              context,
              error is AgendaFinanceiraLancamentoApiException
                  ? error.codigoRecorrencia ?? 'saveError'
                  : 'saveError',
            ),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (widget.modoEdicao
              ? 'Lançamento atualizado com sucesso.'
              : 'Lançamento salvo com sucesso.'),
        ),
      ),
    );
    Navigator.of(context).pop({
      ...request.toAgendaItem(idFallback: idGerado),
      'registrarPagamento': _registrarPagamento,
      'dataLiquidacaoSolicitada': _dataPagamentoRealizado.toIso8601String(),
    });
  }

  Future<void> _confirmarExcluirLancamento() async {
    final String? id = _idLancamentoEdicao;
    if (!widget.modoEdicao || id == null || id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lançamento ainda não possui identificador para exclusão.',
          ),
        ),
      );
      return;
    }

    final bool confirmado =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            final WebThemeTokens tokens = WebThemeTokens.of(dialogContext);
            return AlertDialog(
              backgroundColor: tokens.surfaceElevated,
              surfaceTintColor: Colors.transparent,
              title: const Text('Excluir lançamento?'),
              content: Text(
                '${recorrenciaLabel(context, 'deleteConfirm')}\n${recorrenciaLabel(context, _recorrencia.escopo)}',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Excluir/apagar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.danger,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onError,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmado) await _excluirLancamento(id);
  }

  Future<void> _excluirLancamento(String idLancamento) async {
    setState(() => _isLoading = true);
    try {
      final LancamentoAgendaFinanceiraResponse response = await _service
          .excluirLancamento(idLancamento, escopo: _recorrencia.escopo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento excluído definitivamente.')),
      );
      Navigator.of(context).pop(<String, dynamic>{
        'id': response.id.isEmpty ? idLancamento : response.id,
        'deleted': true,
        'status': response.status,
      });
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir lançamento: ${e.statusCode}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir o lançamento agora.'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hintText,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hintText,
      prefixIcon:
          icon == null
              ? null
              : Icon(icon, size: 18, color: tokens.secondaryText),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: tokens.inputBackground,
      labelStyle: TextStyle(color: tokens.secondaryText),
      hintStyle: TextStyle(color: tokens.mutedText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: tokens.secondaryText.withValues(alpha: 0.22),
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.disabledBackground),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    int maxLines = 1,
    bool enabled = true,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: _inputDecoration(label, hintText: hintText, icon: icon),
      validator:
          requiredField
              ? (String? value) =>
                  value == null || value.trim().isEmpty
                      ? context.t('agenda.form.required')
                      : null
              : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
    bool requiredField = false,
    bool enabled = true,
    bool clearable = false,
    DateTime? lastDate,
    IconData icon = Icons.event_outlined,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: _inputDecoration(
        label,
        icon: icon,
        suffixIcon:
            clearable && controller.text.isNotEmpty
                ? IconButton(
                  tooltip: context.t('agenda.form.clearForecast'),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed:
                      () => setState(() {
                        _dataPrevisaoPagamento = null;
                        _sincronizarTextosData();
                      }),
                )
                : const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      validator:
          requiredField
              ? (String? v) =>
                  v == null || v.trim().isEmpty
                      ? context.t('agenda.form.required')
                      : null
              : null,
      onTap:
          !enabled
              ? null
              : () async {
                final DateTime? selecionada = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2000),
                  lastDate: lastDate ?? DateTime(2100),
                );
                if (!mounted || selecionada == null) return;
                onChanged(_normalizarData(selecionada));
                _sincronizarTextosData();
                setState(() {});
              },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
    IconData icon = Icons.tune_rounded,
    Widget? trailing,
  }) {
    final List<String> safeItems = items.isEmpty ? <String>['Pix'] : items;
    final String safeValue =
        safeItems.contains(value) ? value : safeItems.first;
    return _SixWebSelectField(
      label: label,
      value: safeValue,
      items: safeItems,
      icon: icon,
      enabled: enabled,
      trailing: trailing,
      onChanged: onChanged,
    );
  }

  String _label(String key) => context.t('agenda.form.$key');

  String get _situacaoLabel => _label(switch (_statusSelecionado) {
    'Pendente' => 'open',
    'Previsto' => 'planned',
    'Parcial' => 'partial',
    'Pago' => 'paid',
    'Recebido' => 'received',
    'Cancelado' => 'cancelled',
    _ => 'open',
  });

  int get _diasAtraso {
    if (_statusQuitada || _statusSelecionado == 'Cancelado') return 0;
    final now = DateTime.now();
    final hoje = DateTime.utc(now.year, now.month, now.day);
    final vencimento = DateTime.utc(
      _dataVencimento.year,
      _dataVencimento.month,
      _dataVencimento.day,
    );
    return hoje.difference(vencimento).inDays.clamp(0, 100000);
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _label(title),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 20),
      ...children,
    ],
  );

  Widget _fields(List<Widget> fields, {int columns = 2}) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth < 560 ? 1 : columns;
      final width = (constraints.maxWidth - 16 * (count - 1)) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 20,
        children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ],
      );
    },
  );

  Widget _helper(String key) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      _label(key),
      style: TextStyle(
        fontSize: 12,
        color: WebThemeTokens.of(context).secondaryText,
      ),
    ),
  );

  Widget _notice(String text, {bool warning = false}) {
    final tokens = WebThemeTokens.of(context);
    final color = warning ? tokens.warning : tokens.secondaryText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.error_outline : Icons.info_outline,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _panel(Widget child) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.secondaryText.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }

  Widget _summary() {
    final regional = context.watch<LocaleSettingsProvider>();
    final tokens = WebThemeTokens.of(context);
    Widget row(String key, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _label(key),
              style: TextStyle(color: tokens.secondaryText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label('summary'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Text(
            _label(_tipoSelecionado == 'Receber' ? 'receivable' : 'payable'),
            style: TextStyle(color: tokens.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            regional.formatCurrency(_toDouble(_valorController.text)),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Divider(),
          row('situation', _situacaoLabel),
          row('due', regional.formatDate(_dataVencimento)),
          row(
            _tipoSelecionado == 'Receber' ? 'forecastReceive' : 'forecastPay',
            _dataPrevisaoPagamento == null
                ? _label('notSet')
                : regional.formatDate(_dataPrevisaoPagamento!),
          ),
          row(
            _tipoSelecionado == 'Receber' ? 'receivedValue' : 'paidValue',
            regional.formatCurrency(_toDouble(_valorConfirmadoController.text)),
          ),
          if (_diasAtraso > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _notice(
                _label(
                  _diasAtraso == 1 ? 'overdueOne' : 'overdue',
                ).replaceAll('{days}', '$_diasAtraso'),
                warning: true,
              ),
            ),
          const Divider(),
          row(
            'registered',
            _dataCriacao == null
                ? (widget.modoEdicao ? _label('notSet') : _label('onSave'))
                : regional.formatDate(_dataCriacao!),
          ),
          _helper('registeredHint'),
          const SizedBox(height: 20),
          _notice(_label('settlementHint')),
        ],
      ),
    );
  }

  Widget _formContent() {
    final tokens = WebThemeTokens.of(context);
    final receber = _tipoSelecionado == 'Receber';
    Widget separator() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Divider(height: 1),
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('main', [
            _fields([
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'Pagar', label: Text(_label('payable'))),
                  ButtonSegment(
                    value: 'Receber',
                    label: Text(_label('receivable')),
                  ),
                ],
                selected: {_tipoSelecionado},
                onSelectionChanged:
                    _bloquearTipoStatus
                        ? null
                        : (value) => setState(
                          () => _aplicarTipoSelecionado(value.first),
                        ),
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              _buildTextField(
                controller: _descricaoController,
                label: _label('description'),
                requiredField: true,
              ),
            ]),
            const SizedBox(height: 22),
            _fields([
              _buildTextField(
                controller: _valorController,
                label: _label('amount'),
                requiredField: true,
                enabled: !_bloquearTipoStatus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _statusSelecionado,
                isExpanded: true,
                decoration: _inputDecoration(_label('situation')),
                items: [
                  for (final status
                      in (_status.contains(_statusSelecionado)
                          ? _status
                          : [_statusSelecionado]))
                    DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'Pendente'
                            ? _label('open')
                            : status == 'Previsto'
                            ? _label('planned')
                            : _situacaoLabel,
                      ),
                    ),
                ],
                onChanged:
                    _bloquearTipoStatus
                        ? null
                        : (value) =>
                            setState(() => _statusSelecionado = value!),
              ),
              _buildDateField(
                label: _label('competence'),
                controller: _dataCompetenciaController,
                initialDate: _dataCompetencia,
                onChanged: (date) => _dataCompetencia = date,
              ),
            ], columns: 3),
            _helper('competenceHint'),
            if (_bloquearTipoStatus)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _notice(_label('locked')),
              ),
          ]),
          separator(),
          _section('dates', [
            _fields([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateField(
                    label: _label('due'),
                    controller: _dataVencimentoController,
                    initialDate: _dataVencimento,
                    requiredField: true,
                    onChanged: (date) => _dataVencimento = date,
                  ),
                  _helper('dueHint'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateField(
                    label: _label(receber ? 'forecastReceive' : 'forecastPay'),
                    controller: _dataPrevisaoController,
                    initialDate: _dataPrevisaoPagamento ?? DateTime.now(),
                    clearable: true,
                    onChanged: (date) => _dataPrevisaoPagamento = date,
                  ),
                  _helper(receber ? 'forecastReceiveHint' : 'forecastPayHint'),
                ],
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _notice(_label('forecastHint'), warning: _diasAtraso > 0),
            ),
            if (!_bloquearTipoStatus) ...[
              const SizedBox(height: 14),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _registrarPagamento,
                title: Text(
                  _label(receber ? 'alreadyReceived' : 'alreadyPaid'),
                ),
                subtitle: Text(
                  _label('settleAfterSave'),
                  style: TextStyle(fontSize: 12, color: tokens.secondaryText),
                ),
                onChanged:
                    (value) =>
                        setState(() => _registrarPagamento = value ?? false),
              ),
              if (_registrarPagamento) ...[
                const SizedBox(height: 16),
                _buildDateField(
                  label: _label('actualDate'),
                  controller: _dataPagamentoController,
                  initialDate: _dataPagamentoRealizado,
                  lastDate: DateTime.now(),
                  onChanged: (date) => _dataPagamentoRealizado = date,
                ),
              ],
            ],
          ]),
          separator(),
          _section('classification', [
            _fields([
              _buildTextField(
                controller: _contatoController,
                label: _label(receber ? 'customer' : 'supplier'),
              ),
              _buildTextField(
                controller: _categoriaController,
                label: _label('category'),
                requiredField: true,
              ),
              Text(context.t('space.' + _service.espacoFinanceiro)),
              ContaFinanceiraWebField(
                espaco: _service.espacoFinanceiro,
                value: _contaFinanceiraId,
                onChanged: (id) => setState(() => _contaFinanceiraId = id),
              ),
              TextButton.icon(
                onPressed: () async {
                  final nome = await selecionarContaWeb(
                    context,
                    _service.espacoFinanceiro,
                    grupo: 'CATEGORIAS',
                  );
                  if (nome != null && mounted)
                    setState(() => _categoriaController.text = nome);
                },
                icon: const Icon(Icons.category_outlined),
                label: Text(context.t('space.CATEGORIAS')),
              ),
              AgendaCentroCustoWebField(
                service: _service,
                initialId: _centroCustoId,
                initialName: _centroCustoController.text,
                enabled: !_isLoading,
                onChanged:
                    (centro) => setState(() {
                      _centroCustoId = centro?.id;
                      _centroCustoController.text = centro?.nome ?? '';
                    }),
              ),
              _buildDropdownField(
                label: _label('paymentMethod'),
                value: _formaPagamentoSelecionada,
                items: _formasPagamento,
                enabled: !_carregandoTiposRecebimento,
                onChanged:
                    (value) =>
                        setState(() => _formaPagamentoSelecionada = value!),
              ),
            ]),
          ]),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _responsavelController,
            label: _label('responsible'),
            requiredField: true,
          ),
          const SizedBox(height: 20),
          AgendaRecorrenciaWebFields(
            compact: true,
            config: _recorrencia,
            vencimento: _dataVencimento,
            enabled: !_isLoading,
            onChanged: () => setState(() {}),
          ),
          if (_recorrencia.ativa && _dataPrevisaoPagamento != null)
            _helper('forecastRecurrenceHint'),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              _label('additional'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            childrenPadding: const EdgeInsets.only(top: 12, bottom: 20),
            children: [
              _fields([
                _buildDropdownField(
                  label: _label('origin'),
                  value: _origemSelecionada,
                  items: _origens,
                  onChanged:
                      (value) => setState(() => _origemSelecionada = value!),
                ),
                if (_service.espacoFinanceiro == 'EMPRESA')
                  _buildDropdownField(
                    label: _label('company'),
                    value: _empresaSelecionada,
                    items:
                        widget.empresas.isEmpty ? ['Empresa'] : widget.empresas,
                    onChanged:
                        (value) => setState(() => _empresaSelecionada = value!),
                  ),
                _buildDateField(
                  label: _label('transactionDate'),
                  controller: _dataOperacaoController,
                  initialDate: _dataOperacao,
                  onChanged: (date) => _dataOperacao = date,
                ),

                _buildTextField(
                  controller: _documentoFiscalController,
                  label: _label('document'),
                ),
                _buildTextField(
                  controller: _referenciaController,
                  label: _label('reference'),
                ),
                _buildTextField(
                  controller: _idContatoController,
                  label: _label(receber ? 'customerId' : 'supplierId'),
                ),
              ]),
              _helper('transactionHint'),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _observacoesController,
            label: _label('notes'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar() {
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (widget.modoEdicao)
            TextButton.icon(
              onPressed: _isLoading ? null : _confirmarExcluirLancamento,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(_label('delete')),
              style: TextButton.styleFrom(foregroundColor: tokens.danger),
            ),
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(_label('cancel')),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _salvar,
            child: Text(
              _label(
                _isLoading
                    ? 'saving'
                    : _registrarPagamento
                    ? (_tipoSelecionado == 'Receber'
                        ? 'saveReceive'
                        : 'saveContinue')
                    : widget.modoEdicao
                    ? 'update'
                    : 'save',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label('subtitle'),
                      style: TextStyle(
                        color: WebThemeTokens.of(context).secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1050)
                          return Column(
                            children: [
                              _formContent(),
                              const SizedBox(height: 20),
                              _summary(),
                            ],
                          );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _formContent()),
                            const SizedBox(width: 20),
                            Expanded(flex: 3, child: _summary()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildActionsBar(),
        ],
      ),
    );
  }
}

class _SixWebSelectField extends StatefulWidget {
  const _SixWebSelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final Widget? trailing;

  @override
  State<_SixWebSelectField> createState() => _SixWebSelectFieldState();
}

class _SixWebSelectFieldState extends State<_SixWebSelectField> {
  bool _open = false;
  bool _hover = false;

  String get _safeValue {
    if (widget.items.contains(widget.value)) {
      return widget.value;
    }
    return widget.items.isEmpty ? '' : widget.items.first;
  }

  Future<void> _showMenu() async {
    if (!widget.enabled || widget.items.isEmpty) {
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
          widget.items
              .map(
                (String item) => PopupMenuItem<String>(
                  value: item,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: _SixWebSelectMenuItem(
                    label: _agendaOptionLabel(context, item),
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
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.enabled && (_open || _hover);
    final Color borderColor =
        active
            ? tokens.selectedBorder
            : tokens.secondaryText.withValues(alpha: 0.22);
    final Color backgroundColor =
        widget.enabled
            ? (active ? tokens.selectedBackground : tokens.inputBackground)
            : tokens.disabledBackground;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${widget.label}: $_safeValue',
      child: Tooltip(
        message: widget.enabled ? 'Selecionar ${widget.label}' : widget.label,
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          cursor:
              widget.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.enabled ? _showMenu : null,
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
                  borderRadius: BorderRadius.circular(10),
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
                      size: 20,
                      color:
                          widget.enabled
                              ? tokens.secondaryText
                              : tokens.disabledForeground,
                    ),
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
                            _agendaOptionLabel(context, _safeValue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  widget.enabled
                                      ? tokens.primaryText
                                      : tokens.disabledForeground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.trailing != null) ...<Widget>[
                      widget.trailing!,
                      const SizedBox(width: 8),
                    ],
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
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
  }
}

class _SixWebSelectMenuItem extends StatelessWidget {
  const _SixWebSelectMenuItem({required this.label, required this.selected});

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

String _agendaOptionLabel(BuildContext context, String value) {
  const keys = <String, String>{
    'Venda': 'sale',
    'Ordem de serviço': 'service',
    'Despesa manual': 'expense',
    'Compra': 'purchase',
    'Parcela': 'installment',
    'Movimentação de caixa': 'cashMovement',
    'Boleto': 'bankSlip',
    'Transferência': 'transfer',
    'Cartão de crédito': 'credit',
    'Cartão de débito': 'debit',
    'Débito automático': 'directDebit',
    'Dinheiro': 'cash',
  };
  final key = keys[value];
  return key == null ? value : context.t('agenda.form.option.$key');
}
