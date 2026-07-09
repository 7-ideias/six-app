import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

import '../../providers/locale_settings_provider.dart';

class AgendaFinanceiraWeb extends StatefulWidget {
  const AgendaFinanceiraWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AgendaFinanceiraWeb> createState() => _AgendaFinanceiraWebState();
}

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb> {
  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService = AgendaFinanceiraAcoesFinanceiras();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  static const List<String> _periodos = <String>['Hoje', 'Próximos 7 dias', 'Este mês', 'Próximo mês'];
  static const List<String> _tipos = <String>['Todos', 'Receber', 'Pagar'];
  static const List<String> _status = <String>['Todos', 'Previsto', 'Pendente', 'Vence hoje', 'Vencido', 'Pago', 'Recebido', 'Parcial', 'Cancelado'];
  static const List<String> _formasPagamentoPadrao = <String>['Todos', 'Pix', 'Boleto', 'Transferência', 'Cartão de crédito', 'Cartão de débito', 'Débito automático', 'Dinheiro'];

  final Map<String, String> _backendPorDescricaoFormaPagamento = <String, String>{
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

  final Map<String, String> _descricaoPorBackendFormaPagamento = <String, String>{
    'PIX': 'Pix',
    'BOLETO': 'Boleto',
    'TRANSFERENCIA': 'Transferência',
    'CARTAO_CREDITO': 'Cartão de crédito',
    'CARTAO_DEBITO': 'Cartão de débito',
    'DEBITO_AUTOMATICO': 'Débito automático',
    'DINHEIRO': 'Dinheiro',
  };

  List<String> _formasPagamento = List<String>.from(_formasPagamentoPadrao);
  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];
  Map<String, dynamic> _totaisConfirmados = <String, dynamic>{};

  int _abaSelecionada = 0;
  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  String _formaPagamentoSelecionada = 'Todos';
  bool _carregando = false;
  bool _executandoAcao = false;
  bool _overlayInicialAberto = false;
  DateTime? _ultimaConsultaEm;

  List<Map<String, dynamic>> get _itensAgenda => _gruposAgenda
      .expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>())
      .where(_passaFiltrosLocais)
      .toList();

  List<Map<String, dynamic>> get _itensConfirmadosFiltrados => _itensConfirmados.where(_passaFiltrosLocais).toList();

  double get _totalReceberPrevisto => _somar(_itensAgenda, 'receber', 'valorRestante');
  double get _totalPagarPrevisto => _somar(_itensAgenda, 'pagar', 'valorRestante');
  double get _totalRecebidoConfirmado => _toDouble(_totaisConfirmados['totalRecebidoConfirmado']);
  double get _totalPagoConfirmado => _toDouble(_totaisConfirmados['totalPagoConfirmado']);
  double get _saldoPrevisto => (_totalRecebidoConfirmado + _totalReceberPrevisto) - (_totalPagoConfirmado + _totalPagarPrevisto);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool abriuOverlay = await _abrirComoOverlayInicialSeNecessario();
      if (abriuOverlay || !mounted) return;
      await _carregarTiposPagamentoConfigurados();
      await _consultar();
    });
  }

  bool _estaDentroDeDialog() {
    return context.findAncestorWidgetOfExactType<Dialog>() != null;
  }

  Future<bool> _abrirComoOverlayInicialSeNecessario() async {
    if (!widget.embedded || widget.onBack == null || _overlayInicialAberto || _estaDentroDeDialog()) {
      return false;
    }
    _overlayInicialAberto = true;
    final NavigatorState rootNavigator = Navigator.of(context, rootNavigator: true);
    final BuildContext rootContext = rootNavigator.context;
    widget.onBack?.call();
    await Future<void>.delayed(Duration.zero);
    if (!rootContext.mounted) return true;
    await showDialog<void>(
      context: rootContext,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;
        return _EscOverlayScope(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
        _formasPagamento = <String>['Todos', ...formas];
        if (!_formasPagamento.contains(_formaPagamentoSelecionada)) _formaPagamentoSelecionada = 'Todos';
      });
    } catch (_) {}
  }

  List<String> _montarFormasPagamento(List<TiposRecebimento> tipos) {
    final descricoes = <String>[];
    final backendAtualizado = Map<String, String>.from(_backendPorDescricaoFormaPagamento);
    final descricaoAtualizada = Map<String, String>.from(_descricaoPorBackendFormaPagamento);
    final ativos = tipos.where((tipo) => tipo.ativo).toList()..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    for (final tipo in ativos) {
      final backend = _backendFormaPagamentoPorCodigoTipo(tipo.codigoTipo);
      if (backend == null) continue;
      final descricao = tipo.descricaoExibicao.trim().isNotEmpty ? tipo.descricaoExibicao.trim() : (_descricaoPorBackendFormaPagamento[backend] ?? '');
      if (descricao.isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      backendAtualizado[descricao] = backend;
      descricaoAtualizada[backend] = descricao;
    }
    if (descricoes.isNotEmpty) {
      _backendPorDescricaoFormaPagamento..clear()..addAll(backendAtualizado);
      _descricaoPorBackendFormaPagamento..clear()..addAll(descricaoAtualizada);
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
      default:
        return null;
    }
  }

  List<String> _tiposRecebimentoDisponiveis(Map<String, dynamic> item) {
    final valores = _formasPagamento.where((forma) => forma != 'Todos' && forma.trim().isNotEmpty).toSet().toList(growable: true);
    final formaAtual = item['formaPagamento']?.toString().trim() ?? '';
    if (formaAtual.isNotEmpty && !valores.contains(formaAtual)) {
      valores.insert(0, formaAtual);
    }
    if (valores.isEmpty) {
      valores.add('Pix');
    }
    return valores;
  }

  bool _passaFiltrosLocais(Map<String, dynamic> item) {
    final tipoOk = _tipoSelecionado == 'Todos' || (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') || (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
    final statusOk = _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;
    final formaOk = _formaPagamentoSelecionada == 'Todos' || item['formaPagamento'] == _formaPagamentoSelecionada;
    return tipoOk && statusOk && formaOk;
  }

  Future<void> _consultar({bool mostrarFeedback = false}) async {
    if (_carregando) return;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agenda atualizada: ${_itensAgenda.length} lançamento(s).')));
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao consultar agenda (${e.statusCode}).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível consultar a agenda financeira.')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  AgendaFinanceiraConsultaRequest _buildRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoRequest(),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: _tipoSelecionado == 'Todos' ? 'TODOS' : _tipoSelecionado.toUpperCase(),
        status: _statusFiltro(),
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: _formasPagamentoFiltro(),
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada: _abaSelecionada == 0 ? 'AGENDA' : (_abaSelecionada == 1 ? 'CALENDARIO' : (_abaSelecionada == 2 ? 'FLUXO_PREVISTO' : 'VALORES_CONFIRMADOS')),
    );
  }

  AgendaFinanceiraPeriodoRequest _periodoRequest() {
    final hoje = DateTime.now();
    final base = DateTime(hoje.year, hoje.month, hoje.day);
    switch (_periodoSelecionado) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoRequest(modo: 'HOJE', dataInicio: base, dataFim: base);
      case 'Este mês':
        return AgendaFinanceiraPeriodoRequest(modo: 'ESTE_MES', dataInicio: DateTime(base.year, base.month, 1), dataFim: DateTime(base.year, base.month + 1, 0));
      case 'Próximo mês':
        return AgendaFinanceiraPeriodoRequest(modo: 'PROXIMO_MES', dataInicio: DateTime(base.year, base.month + 1, 1), dataFim: DateTime(base.year, base.month + 2, 0));
      default:
        return AgendaFinanceiraPeriodoRequest(modo: 'PROXIMOS_7_DIAS', dataInicio: base, dataFim: base.add(const Duration(days: 7)));
    }
  }

  List<String> _statusFiltro() {
    switch (_statusSelecionado) {
      case 'Previsto': return <String>['PREVISTO'];
      case 'Pendente': return <String>['PENDENTE'];
      case 'Vence hoje': return <String>['VENCE_HOJE'];
      case 'Vencido': return <String>['VENCIDO'];
      case 'Pago': return <String>['PAGO'];
      case 'Recebido': return <String>['RECEBIDO'];
      case 'Parcial': return <String>['PARCIAL'];
      case 'Cancelado': return <String>['CANCELADO'];
      default: return <String>[];
    }
  }

  List<String> _formasPagamentoFiltro() => _formaPagamentoSelecionada == 'Todos' ? <String>[] : <String>[_formaPagamentoBackend(_formaPagamentoSelecionada)];

  void _aplicarAgenda(Map<String, dynamic> payload) {
    final gruposRaw = payload['gruposAgenda'];
    final grupos = <Map<String, dynamic>>[];
    if (gruposRaw is List) {
      for (final grupo in gruposRaw.whereType<Map<String, dynamic>>()) {
        final itensRaw = grupo['itens'];
        grupos.add(<String, dynamic>{
          'grupo': grupo['titulo']?.toString() ?? 'Lançamentos',
          'descricao': grupo['descricao']?.toString() ?? '',
          'itens': itensRaw is List ? itensRaw.whereType<Map<String, dynamic>>().map(_mapearItemAgenda).toList() : <Map<String, dynamic>>[],
        });
      }
    }
    _gruposAgenda..clear()..addAll(grupos);
  }

  void _aplicarConfirmados(Map<String, dynamic> payload) {
    final totais = payload['totais'];
    final itens = payload['itens'];
    _totaisConfirmados = totais is Map<String, dynamic> ? Map<String, dynamic>.from(totais) : <String, dynamic>{};
    _itensConfirmados..clear()..addAll(itens is List ? itens.whereType<Map<String, dynamic>>().map(_mapearItemConfirmado).toList() : <Map<String, dynamic>>[]);
  }

  Map<String, dynamic> _mapearItemAgenda(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    final valorOriginal = _toDouble(item['valorOriginal'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final valorRestante = _toDouble(item['valorRestante'] ?? (valorOriginal - valorConfirmado));
    final acoesRaw = item['acoesDisponiveis'];
    final acoes = acoesRaw is List ? acoesRaw.map((acao) => _acaoLabel(acao?.toString())).where((acao) => acao.isNotEmpty).toSet().toList() : <String>[];
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
      'formaPagamento': _formaPagamentoLabel(item['formaPagamento']?.toString()),
      'empresa': _empresaNome(item['empresa']),
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'acoes': acoes,
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr((item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'formaPagamento': _formaPagamentoLabel(item['formaPagamento']?.toString()),
      'empresa': _empresaNome(item['empresa']),
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
    };
  }

  List<Map<String, dynamic>> _mapearLiquidacoes(dynamic raw) => raw is List ? raw.whereType<Map<String, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[];

  void _sincronizarValoresConfirmadosNosLancamentos() {
    final confirmadosPorId = <String, Map<String, dynamic>>{for (final item in _itensConfirmados) item['id'].toString(): item};
    for (final grupo in _gruposAgenda) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      for (final item in itens) {
        final confirmado = confirmadosPorId[item['id']?.toString()];
        if (confirmado == null) continue;
        item['valorConfirmado'] = confirmado['valorConfirmado'];
        item['valorRestante'] = confirmado['valorRestante'];
        item['valor'] = confirmado['valorRestante'];
        item['liquidacoes'] = confirmado['liquidacoes'] ?? <Map<String, dynamic>>[];
        if (_toDouble(confirmado['valorConfirmado']) > 0 && _toDouble(confirmado['valorRestante']) > 0) item['status'] = 'Parcial';
      }
    }
  }

  Future<void> _executarAcao(String acao, Map<String, dynamic> item) async {
    final comando = acao.trim().toLowerCase();
    if (comando == 'detalhes' || comando == 'detalhar') { await _mostrarDetalhesLancamento(item); return; }
    if (comando == 'editar') { await _editarLancamento(item); return; }
    if (comando == 'registrar parcial') { await _registrarParcial(item); return; }
    if (comando == 'liquidar' || comando == 'receber' || comando == 'pagar') { await _confirmarTotal(item, 'Liquidar'); return; }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ação "$acao" ainda não implementada.')));
  }

  Future<void> _mostrarDetalhesLancamento(Map<String, dynamic> item) async {
    if (_executandoAcao) return;
    final id = item['id']?.toString() ?? '';
    Map<String, dynamic> detalhe = <String, dynamic>{};
    bool fallback = false;
    setState(() => _executandoAcao = true);
    try {
      if (id.trim().isNotEmpty) detalhe = await _service.buscarDetalheLancamento(id);
      if (detalhe.isEmpty) fallback = true;
    } catch (_) { fallback = true; }
    finally { if (mounted) setState(() => _executandoAcao = false); }
    if (!mounted) return;
    final alterado = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _LancamentoDetalhesDialog(
        item: item,
        detalhe: detalhe,
        fallback: fallback,
        formatarMoeda: _formatarMoeda,
        formatarData: _formatarDataFlexivel,
        formaPagamentoLabel: _formaPagamentoLabel,
        onExcluirLancamento: () => _confirmarExcluirLancamentoDetalhe(item),
        onExcluirLiquidacao: (liquidacao) => _confirmarExcluirLiquidacaoDetalhe(item, liquidacao),
      ),
    );
    if (alterado == true && mounted) await _consultar(mostrarFeedback: true);
  }

  Future<bool> _confirmarExcluirLancamentoDetalhe(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.trim().isEmpty) return false;
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Esta ação vai apagar definitivamente todo o lançamento financeiro e suas confirmações/parciais. Essa operação não pode ser desfeita.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Excluir lançamento'),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError),
          ),
        ],
      ),
    );
    if (confirmado != true) return false;
    try {
      setState(() => _executandoAcao = true);
      await _service.excluirLancamento(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento excluído com sucesso.')));
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao excluir lançamento (${e.statusCode}).')));
      return false;
    } finally { if (mounted) setState(() => _executandoAcao = false); }
  }

  Future<bool> _confirmarExcluirLiquidacaoDetalhe(Map<String, dynamic> item, Map<String, dynamic> liquidacao) async {
    final idLancamento = item['id']?.toString() ?? '';
    final idLiquidacao = liquidacao['id']?.toString() ?? '';
    if (idLancamento.trim().isEmpty || idLiquidacao.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível identificar a parcial para exclusão.')));
      return false;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir parcial?'),
        content: const Text('Esta ação vai remover apenas esta confirmação/parcial e recalcular o valor em aberto do lançamento.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Excluir parcial'),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError),
          ),
        ],
      ),
    );
    if (confirmado != true) return false;
    try {
      setState(() => _executandoAcao = true);
      await _acoesService.excluirLiquidacao(idLancamento: idLancamento, idLiquidacao: idLiquidacao);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcial excluída com sucesso.')));
      return true;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao excluir parcial (${e.statusCode}).')));
      return false;
    } finally { if (mounted) setState(() => _executandoAcao = false); }
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) async {
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();
    final formasDisponiveis = _tiposRecebimentoDisponiveis(item);
    final formaAtual = item['formaPagamento']?.toString().trim() ?? '';
    String formaSelecionada = formasDisponiveis.contains(formaAtual) ? formaAtual : formasDisponiveis.first;
    String? erroValor;
    final resultado = await showDialog<_ParcialLancamentoResultado>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Registrar parcial'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            Text('Valor em aberto: ${_formatarMoeda(_toDouble(item['valorRestante'] ?? item['valor']))}'),
            const SizedBox(height: 12),
            TextField(controller: valorController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Valor parcial', errorText: erroValor)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: formaSelecionada,
              decoration: const InputDecoration(labelText: 'Tipo de recebimento'),
              items: formasDisponiveis.map((forma) => DropdownMenuItem<String>(value: forma, child: Text(forma))).toList(),
              onChanged: (value) { if (value == null || value.trim().isEmpty) return; setDialogState(() => formaSelecionada = value); },
            ),
            const SizedBox(height: 12),
            TextField(controller: observacaoController, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Observação')),
          ]),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final digitado = _toDouble(valorController.text);
            final aberto = _toDouble(item['valorRestante'] ?? item['valor']);
            if (digitado <= 0) { setDialogState(() => erroValor = 'Informe um valor maior que zero.'); return; }
            if (digitado >= aberto) { setDialogState(() => erroValor = 'Informe um valor menor que o aberto.'); return; }
            Navigator.of(dialogContext).pop(_ParcialLancamentoResultado(valor: digitado, formaPagamento: formaSelecionada));
          }, child: const Text('Salvar')),
        ],
      )),
    );
    final observacao = observacaoController.text.trim();
    valorController.dispose();
    observacaoController.dispose();
    if (resultado == null) return;
    await _executarComLoading(() async {
      await _acoesService.executarAbatimento(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraParcialRequest(
          tipoLiquidacao: 'PARCIAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: resultado.valor,
          formaPagamentoRealizada: _formaPagamentoBackend(resultado.formaPagamento),
          observacoes: observacao.isEmpty ? 'Lançamento parcial registrado pela agenda financeira.' : observacao,
        ),
      );
      await _consultar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcial registrada com sucesso.')));
    });
  }

  Future<void> _confirmarTotal(Map<String, dynamic> item, String label) async {
    final valor = _toDouble(item['valorRestante'] ?? item['valor']);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liquidar lançamento'),
        content: Text('Confirmar liquidação de ${_formatarMoeda(valor)}?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(label)),
        ],
      ),
    );
    if (confirmado != true) return;
    await _executarComLoading(() async {
      await _acoesService.executarTotal(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: _formaPagamentoBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: 'Liquidação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
        ),
      );
      await _consultar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento liquidado com sucesso.')));
    });
  }

  Future<void> _executarComLoading(Future<void> Function() action) async {
    if (_executandoAcao) return;
    setState(() => _executandoAcao = true);
    try { await action(); }
    on AgendaFinanceiraLancamentoApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha na ação (${e.statusCode}).'))); }
    finally { if (mounted) setState(() => _executandoAcao = false); }
  }

  Future<void> _novoLancamento() async {
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(context, empresaSelecionada: 'Empresa', empresas: const <String>['Empresa']);
    if (!mounted || item == null) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    final empresaAtual = _empresaNome(item['empresa']).trim();
    final empresas = <String>[empresaAtual.isEmpty ? 'Empresa' : empresaAtual];
    final atualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(context, empresaSelecionada: empresas.first, empresas: empresas, modoEdicao: true, lancamentoInicial: item);
    if (!mounted || atualizado == null) return;
    await _consultar(mostrarFeedback: true);
  }

  void _fechar() {
    final onBack = widget.onBack;
    if (onBack != null) { onBack(); return; }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded && widget.onBack != null && !_estaDentroDeDialog()) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{const SingleActivator(LogicalKeyboardKey.escape): _fechar},
      child: Focus(
        autofocus: true,
        child: Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _consultar(mostrarFeedback: true),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _buildHeader(theme),
                  const SizedBox(height: 14),
                  _buildFiltros(theme),
                  if (_carregando || _executandoAcao) ...const <Widget>[SizedBox(height: 10), LinearProgressIndicator(minHeight: 3)],
                  const SizedBox(height: 14),
                  _buildResumo(theme),
                  const SizedBox(height: 18),
                  _buildAbas(theme),
                  const SizedBox(height: 16),
                  _buildConteudoAba(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Agenda financeira', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          Text(_ultimaConsultaEm == null ? 'Filtre os lançamentos e acompanhe seus detalhes.' : 'Atualizado às ${_ultimaConsultaEm!.hour.toString().padLeft(2, '0')}:${_ultimaConsultaEm!.minute.toString().padLeft(2, '0')}'),
        ])),
        OutlinedButton.icon(onPressed: _carregando ? null : () => _consultar(mostrarFeedback: true), icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
        const SizedBox(width: 10),
        FilledButton.icon(onPressed: _novoLancamento, icon: const Icon(Icons.add_rounded), label: const Text('Novo lançamento')),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: _fechar,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Fechar',
        ),
      ]),
    ),
  );

  Widget _buildFiltros(ThemeData theme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
        _drop('Período', _periodoSelecionado, _periodos, (v) => setState(() => _periodoSelecionado = v!)),
        _drop('Tipo', _tipoSelecionado, _tipos, (v) => setState(() => _tipoSelecionado = v!)),
        _drop('Status', _statusSelecionado, _status, (v) => setState(() => _statusSelecionado = v!)),
        _drop('Tipo de pagamento', _formaPagamentoSelecionada, _formasPagamento, (v) => setState(() => _formaPagamentoSelecionada = v!)),
        FilledButton.icon(
          onPressed: _carregando ? null : () => _consultar(mostrarFeedback: true),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar'),
        ),
      ]),
    ),
  );

  Widget _drop(String label, String value, List<String> values, ValueChanged<String?> onChanged) {
    final safeValue = values.contains(value) ? value : values.first;
    return SizedBox(
      width: label == 'Tipo de pagamento' ? 260 : 190,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        items: values.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) {
    final cards = <Map<String, dynamic>>[
      <String, dynamic>{'titulo': 'A receber previsto', 'valor': _totalReceberPrevisto, 'icone': Icons.south_west_rounded},
      <String, dynamic>{'titulo': 'A pagar previsto', 'valor': _totalPagarPrevisto, 'icone': Icons.north_east_rounded},
      <String, dynamic>{'titulo': 'Recebido confirmado', 'valor': _totalRecebidoConfirmado, 'icone': Icons.verified_rounded},
      <String, dynamic>{'titulo': 'Saldo previsto', 'valor': _saldoPrevisto, 'icone': Icons.account_balance_wallet_outlined},
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 1000 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
      return Wrap(spacing: 12, runSpacing: 12, children: cards.map((card) => SizedBox(width: width, child: _resumoCard(theme, card))).toList());
    });
  }

  Widget _resumoCard(ThemeData theme, Map<String, dynamic> card) {
    final valor = _toDouble(card['valor']);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Icon(card['icone'] as IconData, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(card['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_formatarMoeda(valor), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildAbas(ThemeData theme) => SegmentedButton<int>(
    selected: <int>{_abaSelecionada},
    onSelectionChanged: (value) => setState(() => _abaSelecionada = value.first),
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
    if (itens.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum lançamento encontrado.')));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: itens.map((item) => _cardLancamento(theme, item)).toList());
  }

  Widget _cardLancamento(ThemeData theme, Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    final acoes = List<String>.from((item['acoes'] as List?)?.map((e) => e.toString()) ?? const <String>[]);
    if (!acoes.contains('Detalhes')) acoes.add('Detalhes');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _executandoAcao ? null : () => _mostrarDetalhesLancamento(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
              Chip(label: Text(tipoEntrada ? 'Receber' : 'Pagar')),
              Chip(label: Text(item['status']?.toString() ?? '-')),
              Chip(label: Text(item['formaPagamento']?.toString() ?? '-')),
              if (_toDouble(item['valorConfirmado']) > 0) Chip(label: Text('Confirmado: ${_formatarMoeda(_toDouble(item['valorConfirmado']))}')),
              if (_toDouble(item['valorRestante']) > 0) Chip(label: Text('Aberto: ${_formatarMoeda(_toDouble(item['valorRestante']))}')),
            ]),
            const SizedBox(height: 8),
            Text(item['descricao']?.toString() ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${item['contato']} • Vence em ${item['vencimento']}'),
            const SizedBox(height: 8),
            Text('Original: ${_formatarMoeda(_toDouble(item['valorOriginal']))}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
              OutlinedButton.icon(onPressed: _executandoAcao ? null : () => _editarLancamento(item), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')),
              ...acoes.take(4).map((acao) => OutlinedButton(onPressed: _executandoAcao ? null : () => _executarAcao(acao, item), child: Text(acao))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildValoresConfirmados(ThemeData theme) {
    final itens = _itensConfirmadosFiltrados;
    if (itens.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum valor confirmado no período.')));
    return Column(children: itens.map((item) => Card(child: ListTile(
      onTap: () => _mostrarDetalhesLancamento(item),
      leading: Icon(item['tipo'] == 'receber' ? Icons.south_west_rounded : Icons.north_east_rounded),
      title: Text(item['descricao']?.toString() ?? ''),
      subtitle: Text('${item['contato']} • ${item['data']} • ${item['formaPagamento']} • Restante: ${_formatarMoeda(_toDouble(item['valorRestante']))}'),
      trailing: Text(_formatarMoeda(_toDouble(item['valorConfirmado'])), style: const TextStyle(fontWeight: FontWeight.w900)),
    ))).toList());
  }

  Widget _buildCalendario(ThemeData theme) {
    final itens = List<Map<String, dynamic>>.from(_itensAgenda)..sort((a, b) => (a['vencimento']?.toString() ?? '').compareTo(b['vencimento']?.toString() ?? ''));
    if (itens.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum lançamento encontrado no calendário.')));
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const <DataColumn>[
      DataColumn(label: Text('Data')), DataColumn(label: Text('Tipo')), DataColumn(label: Text('Tipo de pagamento')), DataColumn(label: Text('Descrição')), DataColumn(label: Text('Valor'), numeric: true), DataColumn(label: Text('Ações')),
    ], rows: itens.map((item) => DataRow(cells: <DataCell>[
      DataCell(Text(item['vencimento']?.toString() ?? '-')), DataCell(Text(item['tipo'] == 'receber' ? 'Receber' : 'Pagar')), DataCell(Text(item['formaPagamento']?.toString() ?? '-')), DataCell(SizedBox(width: 340, child: Text(item['descricao']?.toString() ?? '-', overflow: TextOverflow.ellipsis))), DataCell(Text(_formatarMoeda(_toDouble(item['valorRestante'] ?? item['valor'])))), DataCell(TextButton(onPressed: () => _mostrarDetalhesLancamento(item), child: const Text('Detalhes'))),
    ])).toList())));
  }

  Widget _buildFluxo(ThemeData theme) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
    Text('Fluxo previsto', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    Text('Entradas em aberto: ${_formatarMoeda(_totalReceberPrevisto)}'),
    Text('Saídas em aberto: ${_formatarMoeda(_totalPagarPrevisto)}'),
    const SizedBox(height: 8),
    Text('Saldo previsto: ${_formatarMoeda(_saldoPrevisto)}', style: const TextStyle(fontWeight: FontWeight.w900)),
  ])));

  double _somar(List<Map<String, dynamic>> itens, String tipo, String campo) => itens.where((item) => item['tipo'] == tipo && item['status']?.toString() != 'Cancelado').fold<double>(0, (soma, item) => soma + _toDouble(item[campo] ?? item['valor']));

  String _acaoLabel(String? acao) {
    switch ((acao ?? '').toUpperCase()) {
      case 'EDITAR': case 'ALTERAR': return 'Editar';
      case 'REGISTRAR_RECEBIMENTO': case 'RECEBER': case 'REGISTRAR_PAGAMENTO': case 'PAGAR': return 'Liquidar';
      case 'REGISTRAR_PARCIAL': return 'Registrar parcial';
      case 'DETALHAR': case 'DETALHES': return 'Detalhes';
      default: return '';
    }
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PAGO': return 'Pago';
      case 'RECEBIDO': return 'Recebido';
      case 'PARCIAL': return 'Parcial';
      case 'CANCELADO': return 'Cancelado';
      case 'VENCIDO': return 'Vencido';
      case 'VENCE_HOJE': return 'Vence hoje';
      case 'PREVISTO': return 'Previsto';
      default: return 'Pendente';
    }
  }

  String _formaPagamentoLabel(String? formaPagamento) {
    final backend = (formaPagamento ?? '').toUpperCase();
    final configurada = _descricaoPorBackendFormaPagamento[backend];
    if (configurada != null && configurada.trim().isNotEmpty) return configurada;
    return _descricaoPorBackendFormaPagamento[backend] ?? (formaPagamento?.toString().trim().isNotEmpty == true ? formaPagamento! : 'Pix');
  }

  String _formaPagamentoBackend(String label) => _backendPorDescricaoFormaPagamento[label] ?? _backendPorDescricaoFormaPagamento[_formaPagamentoLabel(label)] ?? label.toUpperCase().replaceAll(' ', '_');
  String _empresaNome(dynamic empresa) => empresa is Map<String, dynamic> ? empresa['nome']?.toString() ?? '' : empresa?.toString() ?? '';

  String _formatarDataIsoParaBr(String? dataIso) {
    if (dataIso == null || dataIso.trim().isEmpty) return '-';
    try { final data = DateTime.parse(dataIso); return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}'; }
    catch (_) { return dataIso; }
  }

  String _formatarDataFlexivel(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final text = value.toString();
    if (text.contains('/')) return text;
    return _formatarDataIsoParaBr(text);
  }

  String _formatarDataHora(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final texto = value.trim();
      final normalizado = texto.contains(',') && texto.contains('.') ? texto.replaceAll('.', '').replaceAll(',', '.') : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  String _formatarMoeda(double valor) => context.read<LocaleSettingsProvider>().formatCurrency(valor);
}

class _ParcialLancamentoResultado {
  const _ParcialLancamentoResultado({required this.valor, required this.formaPagamento});
  final double valor;
  final String formaPagamento;
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
      shortcuts: const <ShortcutActivator, Intent>{SingleActivator(LogicalKeyboardKey.escape): _EscOverlayIntent()},
      child: Actions(
        actions: <Type, Action<Intent>>{
          _EscOverlayIntent: CallbackAction<_EscOverlayIntent>(onInvoke: (_) { Navigator.of(context).maybePop(); return null; }),
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
  final Future<bool> Function(Map<String, dynamic> liquidacao) onExcluirLiquidacao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contato = _mapa(detalhe['contato']);
    final origem = _mapa(detalhe['origem']);
    final categoria = _mapa(detalhe['categoria']);
    final empresa = _mapa(detalhe['empresa']);
    final responsavel = _mapa(detalhe['responsavel']);
    final historico = _listaMapas(detalhe['historico']);
    final liquidacoes = _liquidacoes();
    final comprovantes = _listaStrings(detalhe['comprovantes']);
    final acoes = _listaStrings(detalhe['acoesDisponiveis']);
    final valorOriginal = _numero(detalhe['valorOriginal'], item['valorOriginal'] ?? item['valor']);
    final valorPago = _numero(detalhe['valorPagoRecebido'], item['valorConfirmado']);
    final valorAberto = _numero(detalhe['valorAberto'], item['valorRestante']);
    final descricao = _texto(detalhe['descricao'], item['descricao']);
    final stamp = _stampData(_texto(detalhe['status'], item['status']), valorAberto);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
        child: Column(children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Row(children: <Widget>[
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                const Text('Detalhes do lançamento', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(descricao, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ])),
              TextButton.icon(
                onPressed: () async { final excluido = await onExcluirLancamento(); if (excluido && context.mounted) Navigator.of(context).pop(true); },
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir lançamento'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded, color: Colors.white), tooltip: 'Fechar'),
            ]),
          ),
          Expanded(child: Stack(children: <Widget>[
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  if (fallback) _avisoFallback(theme),
                  Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                    _chip(theme, _texto(detalhe['tipo'], item['tipo'] == 'pagar' ? 'Pagar' : 'Receber')),
                    _chip(theme, _texto(detalhe['status'], item['status'])),
                    _chip(theme, formaPagamentoLabel(_texto(detalhe['formaPagamento'], item['formaPagamento']))),
                    _chip(theme, 'ID: ${_texto(detalhe['idLancamento'], item['id'])}'),
                  ]),
                  const SizedBox(height: 18),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth >= 760 ? (constraints.maxWidth - 24) / 3 : double.infinity;
                    return Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
                      SizedBox(width: width, child: _valorCard(theme, 'Valor original', formatarMoeda(valorOriginal), Icons.receipt_long_outlined)),
                      SizedBox(width: width, child: _valorCard(theme, 'Confirmado', formatarMoeda(valorPago), Icons.verified_outlined)),
                      SizedBox(width: width, child: _valorCard(theme, 'Em aberto', formatarMoeda(valorAberto), Icons.account_balance_wallet_outlined)),
                    ]);
                  }),
                  const SizedBox(height: 18),
                  _section(theme, 'Datas', Icons.calendar_month_outlined, <Widget>[
                    _info('Competência', formatarData(detalhe['dataCompetencia'])),
                    _info('Vencimento', formatarData(_valor(detalhe['dataVencimento'], item['vencimento']))),
                    _info('Liquidação', formatarData(detalhe['dataLiquidacao'])),
                  ]),
                  _section(theme, 'Classificação', Icons.filter_alt_outlined, <Widget>[
                    _info('Empresa', _texto(empresa['nome'], item['empresa'])),
                    _info('Categoria', _texto(categoria['nome'], categoria['descricao'], item['categoria'])),
                    _info('Origem', _texto(origem['codigoExibicao'], origem['tipo'], item['origem'])),
                    _info('Referência', _texto(origem['id'])),
                  ]),
                  _section(theme, 'Contato e responsabilidade', Icons.people_alt_outlined, <Widget>[
                    _info('Contato', _texto(contato['nome'], item['contato'])),
                    _info('Tipo', _texto(contato['tipo'])),
                    _info('Documento', _texto(contato['documento'])),
                    _info('Telefone', _texto(contato['telefone'])),
                    _info('E-mail', _texto(contato['email'])),
                    _info('Responsável', _texto(responsavel['nome'], item['responsavel'])),
                  ]),
                  _section(theme, 'Observações', Icons.notes_outlined, <Widget>[SizedBox(width: double.infinity, child: SelectableText(_texto(detalhe['observacoes'], item['observacoes'], 'Sem observações.')))]),
                  if (liquidacoes.isNotEmpty) _section(theme, 'Confirmações e liquidações', Icons.payments_outlined, liquidacoes.map((l) => _liquidacaoTile(context, theme, l)).toList()),
                  if (historico.isNotEmpty) _section(theme, 'Histórico', Icons.history_outlined, historico.map((h) => _info(formatarData(h['dataHora']), _texto(h['descricao']))).toList()),
                  if (comprovantes.isNotEmpty) _section(theme, 'Comprovantes', Icons.attach_file_outlined, comprovantes.map((c) => _info('Arquivo', c)).toList()),
                  if (acoes.isNotEmpty) _section(theme, 'Ações disponíveis', Icons.touch_app_outlined, <Widget>[Wrap(spacing: 8, runSpacing: 8, children: acoes.map((a) => Chip(label: Text(a))).toList())]),
                ]),
              ),
            ),
            if (stamp != null)
              Positioned(top: 18, right: 28, child: _statusStamp(stamp)),
          ])),
        ]),
      ),
    );
  }

  _DetalheStatusStampData? _stampData(String status, double valorAberto) {
    final normalized = status.trim().toUpperCase().replaceAll(' ', '_');
    if (normalized == 'PAGO' || normalized == 'RECEBIDO' || valorAberto <= 0 && (normalized == 'FINALIZADA' || normalized == 'FINALIZADO')) return const _DetalheStatusStampData('PAGO', Color(0xFF16A34A));
    if (normalized == 'PARCIAL') return const _DetalheStatusStampData('PARCIAL', Color(0xFFF59E0B));
    if (normalized == 'CANCELADO' || normalized == 'CANCELADA') return const _DetalheStatusStampData('CANCELADO', Color(0xFFDC2626));
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
            color: stamp.color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: stamp.color, width: 3),
            boxShadow: <BoxShadow>[BoxShadow(color: stamp.color.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Text(stamp.label, style: TextStyle(color: stamp.color, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 2.6)),
        ),
      ),
    ),
  );

  Widget _avisoFallback(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer.withOpacity(0.60), borderRadius: BorderRadius.circular(18)),
    child: const Text('Não foi possível carregar o detalhe completo do backend. Exibindo os dados disponíveis na agenda filtrada.', style: TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _chip(ThemeData theme, String label) => Chip(label: Text(label), backgroundColor: theme.colorScheme.primary.withOpacity(0.08));

  Widget _valorCard(ThemeData theme, String titulo, String valor, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outline.withOpacity(0.10))),
    child: Row(children: <Widget>[Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(valor, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]))]),
  );

  Widget _section(ThemeData theme, String title, IconData icon, List<Widget> children) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Row(children: <Widget>[Icon(icon, color: theme.colorScheme.primary, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]), const SizedBox(height: 14), Wrap(spacing: 12, runSpacing: 12, children: children)]),
  );

  Widget _info(String label, String value) => SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), SelectableText(value.trim().isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w800))]));

  Widget _liquidacaoTile(BuildContext context, ThemeData theme, Map<String, dynamic> liquidacao) {
    final idLiquidacao = liquidacao['id']?.toString() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Wrap(spacing: 18, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
          _info('Tipo', _texto(liquidacao['tipoLiquidacao'], liquidacao['tipo'])),
          _info('Data', formatarData(liquidacao['dataLiquidacao'])),
          _info('Valor', formatarMoeda(_numero(liquidacao['valorLiquidado'], null))),
          _info('Restante antes', formatarMoeda(_numero(liquidacao['valorRestanteAntes'], null))),
          _info('Restante depois', formatarMoeda(_numero(liquidacao['valorRestanteDepois'], null))),
          _info('Tipo de pagamento', formaPagamentoLabel(liquidacao['formaPagamentoRealizada']?.toString())),
          if (idLiquidacao.isNotEmpty)
            TextButton.icon(
              onPressed: () async { final excluiu = await onExcluirLiquidacao(liquidacao); if (excluiu && context.mounted) Navigator.of(context).pop(true); },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir parcial'),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            ),
        ]),
        if (_texto(liquidacao['observacoes']).trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          SelectableText('Observação: ${_texto(liquidacao['observacoes'])}'),
        ],
      ]),
    );
  }

  List<Map<String, dynamic>> _liquidacoes() {
    final detalheLiquidacoes = _listaMapas(detalhe['liquidacoes']);
    if (detalheLiquidacoes.isNotEmpty) return detalheLiquidacoes;
    return _listaMapas(item['liquidacoes']);
  }

  List<Map<String, dynamic>> _listaMapas(dynamic raw) => raw is List ? raw.whereType<Map<String, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[];
  List<String> _listaStrings(dynamic raw) => raw is List ? raw.map((item) => item?.toString() ?? '').where((item) => item.trim().isNotEmpty).toList() : <String>[];
  Map<String, dynamic> _mapa(dynamic raw) => raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  dynamic _valor(dynamic primary, dynamic fallback) => primary == null || primary.toString().trim().isEmpty ? fallback : primary;
  String _texto(dynamic primary, [dynamic secondary, dynamic third]) { for (final value in <dynamic>[primary, secondary, third]) { if (value == null) continue; final text = value.toString().trim(); if (text.isNotEmpty) return text; } return '-'; }
  double _numero(dynamic primary, dynamic fallback) { final value = _valor(primary, fallback); if (value is num) return value.toDouble(); if (value is String) { final normalizado = value.contains(',') && value.contains('.') ? value.replaceAll('.', '').replaceAll(',', '.') : value.replaceAll(',', '.'); return double.tryParse(normalizado) ?? 0; } return 0; }
}

class _DetalheStatusStampData {
  const _DetalheStatusStampData(this.label, this.color);
  final String label;
  final Color color;
}
