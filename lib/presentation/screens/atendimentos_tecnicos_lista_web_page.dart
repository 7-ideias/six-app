import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:signature/signature.dart';

import '../../core/config/app_config.dart';
import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/operational_procedure_flow_models.dart';
import '../../data/models/operational_procedure_models.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_status_signature_policy.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/web/six_web_atendimento_details_dialog.dart';
import '../components/web/six_web_atendimento_date_filter_dialog.dart';
import '../components/web/six_web_recebimento_dialog.dart';
import '../coordinators/operational_procedure_flow_coordinator.dart';
import '../theme/web_theme_tokens.dart';
import 'atendimento_tecnico_editar_dialog.dart';
import 'atendimentos_tecnicos_web_page.dart';

class AtendimentosTecnicosListaWebPage extends StatefulWidget {
  const AtendimentosTecnicosListaWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.procedureCoordinator,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final OperationalProcedureFlowCoordinator? procedureCoordinator;

  @override
  State<AtendimentosTecnicosListaWebPage> createState() =>
      _AtendimentosTecnicosListaWebPageState();
}

class _AtendimentosTecnicosListaWebPageState
    extends State<AtendimentosTecnicosListaWebPage> {
  static const String _semTecnicoKey = '__sem_tecnico__';

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final TextEditingController _buscaController = TextEditingController();
  late final OperationalProcedureFlowCoordinator _procedureCoordinator;

  late Future<_ListaAtendimentosState> _future;
  Timer? _salvarBuscaDebounce;
  bool _alterandoStatus = false;
  bool _gerandoLink = false;
  bool _gerandoLinkStatus = false;
  bool _abrindoNovoAtendimento = false;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  Set<String> _tecnicoFiltroKeys = <String>{};
  Set<String> _statusFiltroKeys = <String>{};
  AtendimentosCriadosStatusPagamentoFiltro _statusPagamentoFiltro =
      AtendimentosCriadosStatusPagamentoFiltro.todos;

  @override
  void initState() {
    super.initState();
    _procedureCoordinator =
        widget.procedureCoordinator ?? OperationalProcedureFlowCoordinator();
    _future = _carregar();
    _buscaController.addListener(_onBuscaChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restaurarPreferenciasAtendimentosCriados();
      await _restaurarPreferenciasAtendimentosCriadosBackend();
    });
  }

  @override
  void dispose() {
    _salvarBuscaDebounce?.cancel();
    _buscaController.removeListener(_onBuscaChanged);
    _buscaController.dispose();
    super.dispose();
  }

  Future<_ListaAtendimentosState> _carregar() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _service.buscarDominiosBase(),
      _service.listar(),
      _colaboradorApiClient.listarTecnicosAssistenciaTecnica(),
    ]);
    return _ListaAtendimentosState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
      tecnicos: results[2] as List<ColaboradorUsuarioResumo>,
    );
  }

  Future<void> _restaurarPreferenciasAtendimentosCriados() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
      return;
    }
    _aplicarPreferenciasAtendimentosCriados(
      preferencias.atendimentosCriadosFiltrosWeb,
    );
  }

  Future<void> _restaurarPreferenciasAtendimentosCriadosBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
        return;
      }
      _aplicarPreferenciasAtendimentosCriados(
        preferencias.atendimentosCriadosFiltrosWeb,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar preferencias dos atendimentos criados: '
        '$error\n$stackTrace',
      );
    }
  }

  void _aplicarPreferenciasAtendimentosCriados(
    AtendimentosCriadosFiltrosWebPreferencia filtros,
  ) {
    _aplicandoPreferencias = true;
    if (_buscaController.text != filtros.busca) {
      _buscaController.text = filtros.busca;
    }
    setState(() {
      _dataInicioFiltro = filtros.dataInicio;
      _dataFimFiltro = filtros.dataFim;
      _tecnicoFiltroKeys = filtros.tecnicoKeysSelecionadas.toSet();
      _statusFiltroKeys = filtros.statusKeysSelecionadas.toSet();
      _statusPagamentoFiltro = filtros.statusPagamento;
    });
    _aplicandoPreferencias = false;
  }

  void _agendarSalvarPreferenciasAtendimentosCriados() {
    _salvarBuscaDebounce?.cancel();
    _salvarBuscaDebounce = Timer(
      const Duration(milliseconds: 450),
      _salvarPreferenciasAtendimentosCriados,
    );
  }

  void _salvarPreferenciasAtendimentosCriados() {
    _salvarBuscaDebounce?.cancel();
    final filtros = AtendimentosCriadosFiltrosWebPreferencia(
      busca: _buscaController.text,
      dataInicio: _dataInicioFiltro,
      dataFim: _dataFimFiltro,
      tecnicoKeys: _sortedFiltroKeys(_tecnicoFiltroKeys),
      statusKeys: _sortedFiltroKeys(_statusFiltroKeys),
      statusPagamento: _statusPagamentoFiltro,
    );

    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            atendimentosCriadosFiltrosWeb: filtros.toJson(),
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar preferencias dos atendimentos criados: '
              '$error\n$stackTrace',
            );
          }),
    );
  }

  List<String> _sortedFiltroKeys(Set<String> keys) {
    final List<String> values = keys
      .map((String key) => key.trim())
      .where((String key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false)..sort();
    return values;
  }

  void _onBuscaChanged() {
    if (mounted) setState(() {});
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _agendarSalvarPreferenciasAtendimentosCriados();
    }
  }

  bool get _possuiFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _dataInicioFiltro != null ||
      _dataFimFiltro != null ||
      _tecnicoFiltroKeys.isNotEmpty ||
      _statusFiltroKeys.isNotEmpty ||
      _statusPagamentoFiltro != AtendimentosCriadosStatusPagamentoFiltro.todos;

  void _limparFiltros() {
    _aplicandoPreferencias = true;
    if (_buscaController.text.isNotEmpty) {
      _buscaController.clear();
    }
    setState(() {
      _dataInicioFiltro = null;
      _dataFimFiltro = null;
      _tecnicoFiltroKeys = <String>{};
      _statusFiltroKeys = <String>{};
      _statusPagamentoFiltro = AtendimentosCriadosStatusPagamentoFiltro.todos;
    });
    _aplicandoPreferencias = false;
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriados();
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  void _fechar() {
    final VoidCallback? onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _novoAtendimento() async {
    if (_abrindoNovoAtendimento) return;
    setState(() => _abrindoNovoAtendimento = true);

    try {
      final ProcedureFlowResult procedureResult = await _procedureCoordinator
          .execute(
            context: context,
            operationPoint: ProcedureOperationPoint.technicalServiceStartBefore,
          );
      if (!mounted || !procedureResult.shouldContinue) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          final Size size = MediaQuery.of(dialogContext).size;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              width: size.width * 0.96,
              height: size.height * 0.92,
              child: AtendimentosTecnicosWebPage(
                embedded: true,
                onBack: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          );
        },
      );

      if (mounted) {
        _recarregar();
      }
    } finally {
      if (mounted) {
        setState(() => _abrindoNovoAtendimento = false);
      }
    }
  }

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> itens,
    List<DominioOpcaoModel> statusOptions,
  ) {
    final termo = _buscaController.text.trim().toLowerCase();
    final inicio =
        _dataInicioFiltro == null ? null : _inicioDoDia(_dataInicioFiltro!);
    final fim = _dataFimFiltro == null ? null : _fimDoDia(_dataFimFiltro!);
    final Set<String> tecnicoKeys = Set<String>.from(_tecnicoFiltroKeys);
    final Set<String> statusKeys = Set<String>.from(_statusFiltroKeys);
    final statusPagamento = _statusPagamentoFiltro;

    return itens
        .where((atendimento) {
          final dataReferencia = _dataReferenciaFiltro(atendimento);
          if (inicio != null) {
            if (dataReferencia == null || dataReferencia.isBefore(inicio)) {
              return false;
            }
          }
          if (fim != null) {
            if (dataReferencia == null || dataReferencia.isAfter(fim)) {
              return false;
            }
          }
          if (tecnicoKeys.isNotEmpty &&
              !tecnicoKeys.contains(_tecnicoKeyAtendimento(atendimento))) {
            return false;
          }
          if (statusKeys.isNotEmpty &&
              !statusKeys.contains(_statusFiltroKeyAtendimento(atendimento))) {
            return false;
          }
          if (!_atendimentoPassaStatusPagamento(atendimento, statusPagamento)) {
            return false;
          }

          if (termo.isEmpty) return true;

          final equipamento = atendimento.equipamento;
          final texto =
              <String>[
                atendimento.numero,
                atendimento.nomeClienteSnapshot ?? '',
                atendimento.nomeTecnicoResponsavelSnapshot ?? '',
                atendimento.statusCodigo,
                atendimento.statusNomePtBr ?? '',
                atendimento.assinaturaAprovada
                    ? 'assinado assinatura aprovado'
                    : '',
                atendimento.requerNovaAssinatura
                    ? 'nova assinatura pendente assinatura'
                    : '',
                atendimento.operacaoLiquidada
                    ? 'liquidada pago recebido'
                    : 'nao liquidada não liquidada aberto pendente',
                atendimento.statusLiquidacaoCodigo,
                'versao ${atendimento.versaoOrcamento}',
                equipamento?.tipo ?? '',
                equipamento?.marca ?? '',
                equipamento?.modelo ?? '',
                equipamento?.imei ?? '',
                atendimento.defeitoRelatado ?? '',
                atendimento.diagnosticoTecnico ?? '',
                _formatarDataCurta(atendimento.dataEntregaPrevista),
              ].join(' ').toLowerCase();
          return texto.contains(termo);
        })
        .toList(growable: false);
  }

  bool _atendimentoPassaStatusPagamento(
    AtendimentoTecnicoModel atendimento,
    AtendimentosCriadosStatusPagamentoFiltro filtro,
  ) {
    switch (filtro) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return true;
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return _pagamentoEmAberto(atendimento);
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return _pagamentoLiquidado(atendimento);
    }
  }

  bool _pagamentoEmAberto(AtendimentoTecnicoModel atendimento) {
    return !atendimento.operacaoLiquidada && atendimento.valorEmAberto > 0;
  }

  bool _pagamentoLiquidado(AtendimentoTecnicoModel atendimento) {
    return atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0;
  }

  DateTime _inicioDoDia(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _fimDoDia(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  bool _entregaAtrasada(AtendimentoTecnicoModel atendimento) {
    final DateTime? entrega = atendimento.dataEntregaPrevista;
    if (entrega == null ||
        atendimento.operacaoLiquidada ||
        _atendimentoFinalizadoOperacionalmente(atendimento)) {
      return false;
    }
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime dataEntrega = _inicioDoDia(entrega);
    return dataEntrega.isBefore(hoje);
  }

  bool _atendimentoFinalizadoOperacionalmente(
    AtendimentoTecnicoModel atendimento,
  ) {
    final String statusCodigo = atendimento.statusCodigo.trim().toUpperCase();
    if (<String>{
      'DELIVERED',
      'ENTREGUE',
      'CANCELED',
      'CANCELADO',
      'CANCELADA',
      'NO_REPAIR',
      'SEM_REPARO',
      'FINALIZED',
      'FINALIZADO',
      'CONCLUIDO',
      'CONCLUÍDO',
    }.contains(statusCodigo)) {
      return true;
    }

    final String statusTexto =
        <String>[
          atendimento.statusNomePtBr ?? '',
          atendimento.statusNomeEnUs ?? '',
          atendimento.statusNomeEsEs ?? '',
        ].join(' ').toUpperCase();
    return statusTexto.contains('ENTREG') ||
        statusTexto.contains('DELIVER') ||
        statusTexto.contains('CANCEL') ||
        statusTexto.contains('SEM REPARO') ||
        statusTexto.contains('NO REPAIR') ||
        statusTexto.contains('FINALIZ') ||
        statusTexto.contains('CONCLU');
  }

  bool _clienteNaoAssinouAtendimentoAberto(
    AtendimentoTecnicoModel atendimento,
  ) {
    if (_atendimentoFinalizadoOperacionalmente(atendimento)) {
      return false;
    }
    return !atendimento.assinaturaAprovada;
  }

  DateTime? _dataReferenciaFiltro(AtendimentoTecnicoModel atendimento) {
    return atendimento.dataEntregaPrevista ??
        atendimento.dataAtualizacao ??
        atendimento.dataUltimaAlteracaoOrcamento ??
        atendimento.dataVencimentoEm ??
        atendimento.validadeOrcamentoEm;
  }

  String _tecnicoKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    final id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final nome = atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (nome.isNotEmpty) return nome.toLowerCase();
    return _semTecnicoKey;
  }

  String _tecnicoLabelAtendimento(AtendimentoTecnicoModel atendimento) {
    final nome = atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    return nome.isEmpty
        ? context.t(
          'atendimentoTecnico.filters.technician.none',
          fallback: 'Sem técnico responsável',
        )
        : nome;
  }

  String _statusFiltroKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    if (atendimento.statusId > 0) return 'id:${atendimento.statusId}';
    final String codigo = atendimento.statusCodigo.trim().toUpperCase();
    if (codigo.isNotEmpty) return 'codigo:$codigo';
    return '__sem_status__';
  }

  List<_TecnicoFiltroOption> _tecnicoOptions(
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicos,
  ) {
    final Map<String, _TecnicoFiltroOption> mapa =
        <String, _TecnicoFiltroOption>{};
    for (final ColaboradorUsuarioResumo tecnico in tecnicos) {
      if (!tecnico.ehTecnicoAssistenciaTecnica) continue;
      final String id =
          tecnico.idUnicoPessoal.trim().isNotEmpty
              ? tecnico.idUnicoPessoal.trim()
              : tecnico.email.trim();
      final String nome =
          tecnico.nomeDeGuerra.trim().isNotEmpty
              ? tecnico.nomeDeGuerra.trim()
              : tecnico.nome.trim().isNotEmpty
              ? tecnico.nome.trim()
              : tecnico.email.trim();
      final String key = id.isNotEmpty ? id : nome.toLowerCase();
      if (key.isEmpty || nome.isEmpty) continue;
      mapa[key] = _TecnicoFiltroOption(key: key, label: nome);
    }
    if (atendimentos.any(
      (AtendimentoTecnicoModel atendimento) =>
          _tecnicoKeyAtendimento(atendimento) == _semTecnicoKey,
    )) {
      mapa[_semTecnicoKey] = _TecnicoFiltroOption(
        key: _semTecnicoKey,
        label: context.t(
          'atendimentoTecnico.filters.technician.none',
          fallback: 'Sem técnico responsável',
        ),
      );
    }
    final options = mapa.values.toList(growable: false)..sort((a, b) {
      if (a.key == _semTecnicoKey) return 1;
      if (b.key == _semTecnicoKey) return -1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return options;
  }

  String _tecnicoFiltroLabel(List<_TecnicoFiltroOption> options) {
    final Set<String> keys = _tecnicoFiltroKeys;
    if (keys.isEmpty) {
      return context.t(
        'atendimentoTecnico.filters.technician.all',
        fallback: 'Todos os técnicos',
      );
    }
    if (keys.length == 1) {
      final String key = keys.first;
      for (final option in options) {
        if (option.key == key) return option.label;
      }
      return context.t(
        'atendimentoTecnico.filters.technician.selectedFallback',
        fallback: 'Técnico selecionado',
      );
    }
    return context
        .t(
          'atendimentoTecnico.filters.multiSelected',
          fallback: '{count} selecionados',
        )
        .replaceAll('{count}', keys.length.toString());
  }

  List<_StatusFiltroOption> _statusFiltroOptions(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusOptions,
  ) {
    final Map<String, _StatusFiltroOption> options =
        <String, _StatusFiltroOption>{};
    for (final atendimento in atendimentos) {
      final key = _statusFiltroKeyAtendimento(atendimento);
      final label = _statusLabel(atendimento, statusOptions);
      final current = options[key];
      options[key] = _StatusFiltroOption(
        key: key,
        label: current?.label ?? label,
        count: (current?.count ?? 0) + 1,
      );
    }
    final sortedOptions = options.values.toList(growable: false)..sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) return countCompare;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return sortedOptions;
  }

  String _statusFiltroDisplayLabel(List<_StatusFiltroOption> options) {
    final Set<String> selected = _statusFiltroKeys;
    if (selected.isEmpty) {
      return context.t(
        'atendimentoTecnico.filters.status.all',
        fallback: 'Todos os status',
      );
    }
    if (selected.length == 1) {
      final String key = selected.first;
      for (final option in options) {
        if (option.key == key) return option.label;
      }
      return context.t(
        'atendimentoTecnico.filters.status.selectedFallback',
        fallback: 'Status selecionado',
      );
    }
    return context
        .t(
          'atendimentoTecnico.filters.multiSelected',
          fallback: '{count} selecionados',
        )
        .replaceAll('{count}', selected.length.toString());
  }

  String _statusPagamentoFiltroLabel(
    AtendimentosCriadosStatusPagamentoFiltro value,
  ) {
    switch (value) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return context.t(
          'atendimentoTecnico.filters.paymentStatus.all',
          fallback: 'Todos os pagamentos',
        );
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return context.t(
          'atendimentoTecnico.filters.paymentStatus.open',
          fallback: 'Em aberto',
        );
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return context.t(
          'atendimentoTecnico.filters.paymentStatus.paid',
          fallback: 'Liquidado',
        );
    }
  }

  List<_TecnicoFiltroOption> _statusPagamentoFiltroOptions() {
    return <_TecnicoFiltroOption>[
      _TecnicoFiltroOption(
        key: AtendimentosCriadosStatusPagamentoFiltro.emAberto.codigo,
        label: _statusPagamentoFiltroLabel(
          AtendimentosCriadosStatusPagamentoFiltro.emAberto,
        ),
      ),
      _TecnicoFiltroOption(
        key: AtendimentosCriadosStatusPagamentoFiltro.liquidado.codigo,
        label: _statusPagamentoFiltroLabel(
          AtendimentosCriadosStatusPagamentoFiltro.liquidado,
        ),
      ),
    ];
  }

  String _periodoFiltroLabel() {
    final inicio = _dataInicioFiltro;
    final fim = _dataFimFiltro;
    if (inicio == null && fim == null) {
      return context.t(
        'atendimentoTecnico.web.dateFilterDialog.allDates',
        fallback: 'Todas as datas',
      );
    }
    if (inicio != null && fim != null) {
      return context
          .t(
            'atendimentoTecnico.web.dateFilterDialog.dateRange',
            fallback: '{start} até {end}',
          )
          .replaceAll('{start}', _formatarDataCurta(inicio))
          .replaceAll('{end}', _formatarDataCurta(fim));
    }
    if (inicio != null) {
      return context
          .t(
            'atendimentoTecnico.web.dateFilterDialog.dateFrom',
            fallback: 'A partir de {date}',
          )
          .replaceAll('{date}', _formatarDataCurta(inicio));
    }
    return context
        .t(
          'atendimentoTecnico.web.dateFilterDialog.dateUntil',
          fallback: 'Até {date}',
        )
        .replaceAll('{date}', _formatarDataCurta(fim!));
  }

  DominioOpcaoModel? _statusAtual(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId) return opcao;
    }
    return status.isEmpty ? null : status.first;
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final nomeBackend = _localizedLabel(
      pt: atendimento.statusNomePtBr,
      en: atendimento.statusNomeEnUs,
      es: atendimento.statusNomeEsEs,
      fallback: '',
    );
    if (nomeBackend != '-') return nomeBackend;
    return _statusLabelPorCodigo(atendimento.statusCodigo, status);
  }

  String _statusLabelPorCodigo(String? codigo, List<DominioOpcaoModel> status) {
    final normalizado = codigo?.trim().toUpperCase() ?? '';
    if (normalizado.isEmpty) return 'Sem status anterior';
    for (final opcao in status) {
      if (opcao.codigo.trim().toUpperCase() == normalizado) {
        return _statusOptionLabel(opcao);
      }
    }
    return normalizado;
  }

  String _statusOptionLabel(DominioOpcaoModel status) {
    return _localizedLabel(
      pt: status.nomePadraoPtBr,
      en: status.nomePadraoEnUs,
      es: status.nomePadraoEsEs,
      fallback: status.codigo,
    );
  }

  String _localizedLabel({
    required String? pt,
    required String? en,
    required String? es,
    required String fallback,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final selected = switch (languageCode) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
    final label = selected?.trim() ?? '';
    if (label.isNotEmpty) return label;
    final fallbackTrimmed = fallback.trim();
    return fallbackTrimmed.isEmpty ? '-' : fallbackTrimmed;
  }

  DominioOpcaoModel? _statusEtapaAtual(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final codigoAtual = atendimento.statusCodigo.trim().toUpperCase();
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId ||
          opcao.codigo.trim().toUpperCase() == codigoAtual) {
        return opcao;
      }
    }
    if (_statusAtendimentoEntregue(atendimento)) {
      for (final opcao in status) {
        if (_statusEntregue(opcao)) return opcao;
      }
    }
    return null;
  }

  List<DominioOpcaoModel> _statusFlowSteps(List<DominioOpcaoModel> status) {
    final steps = status.toList(growable: false)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    final visible = steps
        .where((step) => !_statusOcultoNaBarraDeProgresso(step))
        .toList(growable: false);
    if (visible.isEmpty) return const <DominioOpcaoModel>[];
    final int entregueIndex = visible.indexWhere(_statusEntregue);
    if (entregueIndex < 0) return visible;
    return visible.take(entregueIndex + 1).toList(growable: false);
  }

  double _statusProgressValue(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final steps = _statusFlowSteps(status);
    if (steps.isEmpty) return 0;
    final current = _statusEtapaAtual(atendimento, steps);
    if (current == null) return 0;
    final currentIndex = steps.indexWhere((step) => step.id == current.id);
    if (currentIndex < 0) return 0;
    return ((currentIndex + 1) / steps.length).clamp(0, 1).toDouble();
  }

  Color _statusProgressColor(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final current = _statusEtapaAtual(atendimento, _statusFlowSteps(status));
    final Color configuredColor = _colorFromHex(current?.cor, tokens.info);
    return _statusAccentForSurface(theme, configuredColor, tokens);
  }

  Color _statusAccentForSurface(
    ThemeData theme,
    Color color,
    WebThemeTokens tokens,
  ) {
    if (theme.colorScheme.brightness != Brightness.dark) {
      return color;
    }

    if (_contrastRatio(color, tokens.cardBackground) >= 3.0) {
      return color;
    }

    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(hsl.lightness < 0.60 ? 0.68 : hsl.lightness)
        .withSaturation(hsl.saturation < 0.38 ? 0.48 : hsl.saturation)
        .toColor();
  }

  double _contrastRatio(Color foreground, Color background) {
    final double foregroundLuminance = foreground.computeLuminance();
    final double backgroundLuminance = background.computeLuminance();
    final double lighter =
        foregroundLuminance > backgroundLuminance
            ? foregroundLuminance
            : backgroundLuminance;
    final double darker =
        foregroundLuminance > backgroundLuminance
            ? backgroundLuminance
            : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  bool _statusAtendimentoEntregue(AtendimentoTecnicoModel atendimento) {
    return _statusTextoEntregue(atendimento.statusCodigo) ||
        _statusTextoEntregue(atendimento.statusNomePtBr ?? '') ||
        _statusTextoEntregue(atendimento.statusNomeEnUs ?? '') ||
        _statusTextoEntregue(atendimento.statusNomeEsEs ?? '');
  }

  bool _statusEntregue(DominioOpcaoModel status) {
    return _statusTextoEntregue(status.codigo) ||
        _statusTextoEntregue(status.i18nKey) ||
        _statusTextoEntregue(status.nomePadraoPtBr) ||
        _statusTextoEntregue(status.nomePadraoEnUs) ||
        _statusTextoEntregue(status.nomePadraoEsEs);
  }

  bool _statusOcultoNaBarraDeProgresso(DominioOpcaoModel status) {
    return _statusTextoCanceladoOuSemReparo(status.codigo) ||
        _statusTextoCanceladoOuSemReparo(status.i18nKey) ||
        _statusTextoCanceladoOuSemReparo(status.nomePadraoPtBr) ||
        _statusTextoCanceladoOuSemReparo(status.nomePadraoEnUs) ||
        _statusTextoCanceladoOuSemReparo(status.nomePadraoEsEs);
  }

  bool _statusTextoEntregue(String value) {
    final normalized = _normalizarTextoStatus(value);
    return normalized == 'ENTREGUE' ||
        normalized == 'DELIVERED' ||
        normalized == 'ENTREGADO' ||
        normalized.startsWith('ENTREGUE ') ||
        normalized.startsWith('ENTREGUE(') ||
        normalized.startsWith('DELIVERED ') ||
        normalized.startsWith('DELIVERED(') ||
        normalized.startsWith('ENTREGADO ') ||
        normalized.startsWith('ENTREGADO(');
  }

  bool _statusTextoCanceladoOuSemReparo(String value) {
    final normalized = _normalizarTextoStatus(value);
    return normalized == 'CANCELED' ||
        normalized == 'CANCELLED' ||
        normalized == 'CANCELADO' ||
        normalized == 'CANCELADA' ||
        normalized == 'SEM REPARO' ||
        normalized == 'NO REPAIR' ||
        normalized.startsWith('CANCEL') ||
        normalized.startsWith('SEM REPARO ') ||
        normalized.startsWith('SEM REPARO(') ||
        normalized.startsWith('NO REPAIR ') ||
        normalized.startsWith('NO REPAIR(');
  }

  String _normalizarTextoStatus(String value) {
    return value.trim().toUpperCase().replaceAll('_', ' ').replaceAll('-', ' ');
  }

  Color _colorFromHex(String? value, Color fallback) {
    final hex = (value ?? '').replaceAll('#', '').trim();
    if (hex.length != 6 && hex.length != 8) return fallback;
    try {
      final normalized = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _formatarMoeda(double value) =>
      context.read<LocaleSettingsProvider>().formatCurrency(value);

  String _formatarInteiro(double value) {
    final inteiro = value.round();
    final negativo = inteiro < 0;
    final digits = inteiro.abs().toString();
    final separadorMilhar =
        context.read<LocaleSettingsProvider>().thousandSeparator;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      if (index > 0 && remaining % 3 == 0) {
        buffer.write(separadorMilhar);
      }
      buffer.write(digits[index]);
    }
    return '${negativo ? '-' : ''}$buffer';
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final locale = context.read<LocaleSettingsProvider>();
    return '${locale.formatDate(value)} ${locale.formatTime(value)}';
  }

  String _formatarDataCurta(DateTime? value) {
    if (value == null) return '-';
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String? _textoOuNulo(String? value) {
    final String texto = value?.trim() ?? '';
    return texto.isEmpty ? null : texto;
  }

  String _assinaturaResumo(AtendimentoTecnicoModel atendimento) {
    final nome = atendimento.assinaturaNomeAssinante?.trim() ?? '';
    final data = _formatarData(atendimento.assinaturaDataHora);
    if (nome.isEmpty && data == '-') return 'Assinado';
    if (nome.isEmpty) return 'Assinado em $data';
    if (data == '-') return 'Assinado por $nome';
    return 'Assinado por $nome em $data';
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final equipamento = atendimento.equipamento;
    final partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((parte) => parte.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? atendimento.numero : partes.join(' ');
  }

  String _clienteLabelAtendimento(AtendimentoTecnicoModel atendimento) {
    final String cliente = atendimento.nomeClienteSnapshot?.trim() ?? '';
    return cliente.isEmpty ? 'Cliente não informado' : cliente;
  }

  String? _codigoTipoRecebimentoInicial(AtendimentoTecnicoModel atendimento) {
    if (atendimento.recebimentos.isEmpty) return null;
    final String codigo =
        atendimento.recebimentos.last.codigoFormaRecebimento.trim();
    return codigo.isEmpty ? null : codigo;
  }

  String _observacaoRecebimentoPadrao(SixWebRecebimentoResultado resultado) {
    return resultado.total
        ? 'Recebimento total realizado no atendimento técnico web.'
        : 'Recebimento parcial realizado no atendimento técnico web.';
  }

  int _totalEmAberto(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos.where(_pagamentoEmAberto).length;

  int _totalAssinados(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos
          .where((atendimento) => atendimento.assinaturaAprovada)
          .length;

  double _valorAberto(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos
          .where(_pagamentoEmAberto)
          .fold<double>(
            0,
            (total, atendimento) => total + atendimento.valorEmAberto,
          );

  Future<void> _abrirEditarAtendimento(
    AtendimentoTecnicoModel atendimento,
  ) async {
    final bool alterou = await showAtendimentoTecnicoEditarDialog(
      context: context,
      atendimento: atendimento,
    );
    if (alterou && mounted) {
      _recarregar();
      _mostrarMensagem(
        'Atendimento atualizado. O histórico de auditoria foi registrado e uma nova assinatura pode ser solicitada.',
      );
    }
  }

  Future<void> _abrirRecebimento(AtendimentoTecnicoModel atendimento) async {
    if (atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0) {
      _mostrarMensagem('Este atendimento já está liquidado.');
      return;
    }
    final SixWebRecebimentoResultado? resultado =
        await SixWebRecebimentoDialog.show(
          context,
          titulo: 'Receber atendimento técnico',
          descricao: _equipamentoTitulo(atendimento),
          contato: _clienteLabelAtendimento(atendimento),
          valorAberto: atendimento.valorEmAberto,
          codigoTipoInicial: _codigoTipoRecebimentoInicial(atendimento),
          permitirParcial: true,
          observacaoInicial:
              'Recebimento realizado no atendimento técnico web.',
        );

    if (resultado == null || !mounted) return;
    try {
      await _service.receber(
        id: atendimento.id,
        input: AtendimentoTecnicoRecebimentoInput(
          codigoFormaRecebimento: resultado.codigoTipoRecebimento,
          nomeFormaRecebimento: resultado.descricaoTipoRecebimento,
          valor: resultado.valor,
          recebimentos: resultado.recebimentos,
          observacao:
              resultado.observacao ?? _observacaoRecebimentoPadrao(resultado),
        ),
      );
      if (!mounted) return;
      _recarregar();
      _mostrarMensagem(
        resultado.total
            ? 'Atendimento recebido com sucesso.'
            : 'Parcial recebida com sucesso.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível lançar o recebimento: $error');
    }
  }

  Future<void> _gerarLinkAssinatura(AtendimentoTecnicoModel atendimento) async {
    if (_gerandoLink) return;
    setState(() => _gerandoLink = true);
    try {
      final link = await _gerarLinkAssinaturaAtendimento(atendimento);
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Link de assinatura'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Link copiado para a área de transferência.'),
                    const SizedBox(height: 12),
                    SelectableText(link),
                    const SizedBox(height: 12),
                    Text(
                      atendimento.requerNovaAssinatura
                          ? 'Este atendimento foi alterado depois da última assinatura. Envie este novo link para o cliente assinar a versão atual.'
                          : 'Envie este link ao cliente por WhatsApp ou e-mail para aprovação e assinatura do serviço.',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível gerar o link: $error');
    } finally {
      if (mounted) setState(() => _gerandoLink = false);
    }
  }

  Future<String> _gerarLinkAssinaturaAtendimento(
    AtendimentoTecnicoModel atendimento,
  ) async {
    final String publicUrlMissingMessage = context.t(
      'atendimentoTecnico.signatureGate.publicUrlMissing',
      fallback: 'URL pública do aplicativo não configurada.',
    );
    final String linkMissingMessage = context.t(
      'atendimentoTecnico.signatureGate.linkMissing',
      fallback: 'Link de assinatura não retornado pelo backend.',
    );
    final String origin = AppConfig.publicFrontendOrigin.trim();
    if (origin.isEmpty) {
      throw Exception(publicUrlMissingMessage);
    }
    final response = await _service.gerarLinkAssinatura(
      id: atendimento.id,
      baseUrl: '$origin/atendimento/assinatura',
    );
    final link = response['link']?.toString().trim() ?? '';
    if (link.isEmpty) {
      throw Exception(linkMissingMessage);
    }
    return link;
  }

  Future<bool> _abrirAssinaturaNoDispositivo(
    AtendimentoTecnicoModel atendimento,
    DominioOpcaoModel status,
    String? observacaoStatus,
  ) async {
    if (_alterandoStatus) return false;
    final _AssinaturaDispositivoWebResult? result =
        await showDialog<_AssinaturaDispositivoWebResult>(
          context: context,
          barrierDismissible: !_alterandoStatus,
          builder:
              (_) => _AssinaturaDispositivoWebDialog(
                atendimento: atendimento,
                statusLabel: _statusOptionLabel(status),
              ),
        );
    if (result == null || !mounted) return false;
    setState(() => _alterandoStatus = true);
    try {
      await _service.assinarNoDispositivo(
        id: atendimento.id,
        status: status,
        observacaoStatus: observacaoStatus,
        nomeAssinante: result.nomeAssinante,
        documentoAssinante: _textoOuNulo(result.documentoAssinante),
        assinaturaDataUrl: result.assinaturaDataUrl,
        observacaoAssinatura: _textoOuNulo(result.observacao),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      _mostrarMensagem(
        '${context.t('atendimentoTecnico.signatureGate.deviceSignatureError', fallback: 'Não foi possível registrar a assinatura')}: $error',
      );
      return false;
    } finally {
      if (mounted) setState(() => _alterandoStatus = false);
    }
  }

  Future<void> _gerarLinkStatusPublico(
    AtendimentoTecnicoModel atendimento,
  ) async {
    if (_gerandoLinkStatus) return;
    setState(() => _gerandoLinkStatus = true);
    try {
      final baseUrl = '${Uri.base.origin}/atendimento/status';
      final response = await _service.gerarLinkStatusPublico(
        id: atendimento.id,
        baseUrl: baseUrl,
      );
      if (!mounted) return;
      final link = response.link.trim();
      if (link.isEmpty) {
        throw Exception(
          context.t(
            'atendimentoTecnico.publicStatus.linkMissing',
            fallback: 'Link não retornado pelo backend.',
          ),
        );
      }
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      final String textoCompartilhamento = _mensagemCompartilhamentoStatus(
        atendimento,
        link,
      );
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text(
                context.t(
                  'atendimentoTecnico.publicStatus.linkTitle',
                  fallback: 'Link público de status',
                ),
              ),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        'atendimentoTecnico.publicStatus.linkCopied',
                        fallback: 'Link copiado para a área de transferência.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(link),
                    const SizedBox(height: 12),
                    Text(
                      context.t(
                        'atendimentoTecnico.publicStatus.linkHelp',
                        fallback:
                            'Envie este link ao cliente para acompanhar o status atual do serviço.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.t('common.close', fallback: 'Fechar')),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!mounted) return;
                    _mostrarMensagem(
                      context.t(
                        'atendimentoTecnico.publicStatus.linkCopiedShort',
                        fallback: 'Link de status copiado.',
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(context.t('common.copy', fallback: 'Copiar')),
                ),
                FilledButton.icon(
                  onPressed:
                      () => _compartilharStatusPublico(
                        textoCompartilhamento,
                        link,
                      ),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(
                    context.t('common.share', fallback: 'Compartilhar'),
                  ),
                ),
              ],
            ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        '${context.t('atendimentoTecnico.publicStatus.linkError', fallback: 'Não foi possível gerar o link de status')}: $error',
      );
    } finally {
      if (mounted) setState(() => _gerandoLinkStatus = false);
    }
  }

  String _mensagemCompartilhamentoStatus(
    AtendimentoTecnicoModel atendimento,
    String link,
  ) {
    final chamada = context.t(
      'atendimentoTecnico.publicStatus.shareMessage',
      fallback: 'Acompanhe o status do seu serviço pelo link abaixo:',
    );
    return <String>[
      chamada,
      '${atendimento.numero} - ${_equipamentoTitulo(atendimento)}',
      link,
    ].join('\n\n');
  }

  Future<void> _compartilharStatusPublico(String mensagem, String link) async {
    try {
      await sharing.Share.share(
        mensagem,
        subject: context.t(
          'atendimentoTecnico.publicStatus.shareSubject',
          fallback: 'Status do serviço',
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      _mostrarMensagem(
        context.t(
          'atendimentoTecnico.publicStatus.shareFallback',
          fallback:
              'Não foi possível abrir o compartilhamento. O link foi copiado.',
        ),
      );
    }
  }

  Future<void> _abrirAlterarStatusDialog(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) async {
    if (status.isEmpty || _alterandoStatus) return;
    final alterou = await showDialog<bool>(
      context: context,
      barrierDismissible: !_alterandoStatus,
      builder: (dialogContext) {
        return _AlterarStatusAtendimentoWebDialog(
          atendimento: atendimento,
          status: status,
          statusAtual: _statusAtual(atendimento, status),
          statusAtualLabel: _statusLabel(atendimento, status),
          onSalvar: (DominioOpcaoModel novoStatus, String? observacao) async {
            bool bypassAssinatura = false;
            if (AtendimentoStatusSignaturePolicy.atendimentoPrecisaAssinaturaPara(
              atendimento: atendimento,
              status: novoStatus,
            )) {
              final _StatusSignatureGateAction? action =
                  await _abrirAssinaturaStatusDialog(atendimento, novoStatus);
              if (action == null || !mounted) return false;
              switch (action) {
                case _StatusSignatureGateAction.enviarLink:
                  await _gerarLinkAssinatura(atendimento);
                  return false;
                case _StatusSignatureGateAction.assinarNesteDispositivo:
                  return _abrirAssinaturaNoDispositivo(
                    atendimento,
                    novoStatus,
                    observacao,
                  );
                case _StatusSignatureGateAction.avancarSemAssinatura:
                  bypassAssinatura = true;
              }
            }
            setState(() => _alterandoStatus = true);
            try {
              await _service.alterarStatus(
                id: atendimento.id,
                status: novoStatus,
                observacao: observacao,
                bypassAssinatura: bypassAssinatura,
              );
              return true;
            } finally {
              if (mounted) {
                setState(() => _alterandoStatus = false);
              }
            }
          },
        );
      },
    );

    if (alterou == true && mounted) {
      _recarregar();
      _mostrarMensagem('Status atualizado no histórico.');
    }
  }

  Future<_StatusSignatureGateAction?> _abrirAssinaturaStatusDialog(
    AtendimentoTecnicoModel atendimento,
    DominioOpcaoModel status,
  ) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final String statusLabel = _statusOptionLabel(status);
    return showDialog<_StatusSignatureGateAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.draw_rounded, color: tokens.warning),
          title: Text(
            context.t(
              'atendimentoTecnico.signatureGate.title',
              fallback: 'Assinatura necessária',
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context
                      .t(
                        'atendimentoTecnico.signatureGate.message',
                        fallback:
                            'Para avançar para {status}, envie o link de assinatura ao cliente, assine neste dispositivo ou registre o bypass.',
                      )
                      .replaceAll('{status}', statusLabel),
                ),
                const SizedBox(height: 12),
                Text(
                  '${atendimento.numero} • ${_clienteLabelAtendimento(atendimento)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_StatusSignatureGateAction.avancarSemAssinatura),
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text(
                context.t(
                  'atendimentoTecnico.signatureGate.bypass',
                  fallback: 'Avançar sem assinatura',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_StatusSignatureGateAction.assinarNesteDispositivo),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(
                context.t(
                  'atendimentoTecnico.signatureGate.signHere',
                  fallback: 'Assinar neste dispositivo',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_StatusSignatureGateAction.enviarLink),
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(
                context.t(
                  'atendimentoTecnico.signatureGate.sendLink',
                  fallback: 'Enviar link ao cliente',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final content = FutureBuilder<_ListaAtendimentosState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }
        final state = snapshot.data!;
        final statusOptions = state.dominios.statusAtendimentoTecnico;
        final atendimentos = _filtrar(state.atendimentos, statusOptions);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final horizontalPadding = isCompact ? 16.0 : 28.0;
            return AnimatedContainer(
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              color: tokens.workspaceBackground,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      theme,
                      total: state.atendimentos.length,
                      filtrados: atendimentos.length,
                      isCompact: isCompact,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      10,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: <Widget>[
                          _buildResumo(theme, atendimentos, isCompact),
                          const SizedBox(height: 12),
                          _buildBusca(
                            theme,
                            isCompact,
                            state.atendimentos,
                            state.tecnicos,
                            statusOptions,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (atendimentos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          16,
                        ),
                        child: _EmptyState(onRetry: _recarregar),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final atendimento = atendimentos[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == atendimentos.length - 1 ? 0 : 10,
                            ),
                            child: _buildAtendimentoCard(
                              theme,
                              atendimento,
                              statusOptions,
                              isCompact,
                            ),
                          );
                        }, childCount: atendimentos.length),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    final bool podeFecharTela = widget.onBack != null || !widget.embedded;
    final Widget focusedContent = Focus(
      autofocus: podeFecharTela,
      child: content,
    );
    final Widget escAwareContent = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _fechar,
      },
      child: focusedContent,
    );

    if (widget.embedded) {
      return podeFecharTela ? escAwareContent : focusedContent;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos criados'),
        leading:
            widget.onBack == null
                ? null
                : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
      ),
      body: escAwareContent,
    );
  }

  Widget _buildLoading() {
    return _AtendimentosTecnicosWebSkeleton(
      showCloseButton: widget.onBack != null,
      semanticsLabel: context.t(
        'atendimentoTecnico.web.loading',
        fallback: 'Carregando atendimentos técnicos',
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme, {
    required int total,
    required int filtrados,
    required bool isCompact,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tokens.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.fact_check_outlined, color: tokens.info, size: 27),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Atendimentos criados',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Consulte, receba, edite, audite e gere assinatura.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _headerButton(theme, Icons.refresh_rounded, 'Atualizar', _recarregar),
        FilledButton.icon(
          onPressed: _abrindoNovoAtendimento ? null : _novoAtendimento,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Novo atendimento'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        _metricBadge(theme, '$total total', Icons.assignment_outlined),
        _metricBadge(theme, '$filtrados visíveis', Icons.filter_alt_outlined),
        if (widget.onBack != null) _closeButton(context),
      ],
    );

    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  theme.colorScheme.brightness == Brightness.dark ? 0.14 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child:
          isCompact
              ? Column(
                children: <Widget>[
                  titleBlock,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
    );
  }

  Widget _buildResumo(
    ThemeData theme,
    List<AtendimentoTecnicoModel> atendimentos,
    bool isCompact,
  ) {
    final total = atendimentos.length;
    final emAberto = _totalEmAberto(atendimentos);
    final assinados = _totalAssinados(atendimentos);
    final valorAberto = _valorAberto(atendimentos);
    final bool possuiFiltrosAtivos = _possuiFiltrosAtivos;
    final String resumoFiltradoHelper = context.t(
      'atendimentoTecnico.lista.summary.filteredScope',
      fallback: 'No filtro ativo',
    );
    final String saldoFiltradoHelper = context.t(
      'atendimentoTecnico.lista.summary.filteredOpenBalance',
      fallback: 'Saldo no filtro',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            isCompact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 36) / 4).clamp(
                  190.0,
                  constraints.maxWidth,
                );
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Atendimentos',
              value: total.toDouble(),
              formatter: _formatarInteiro,
              helper:
                  possuiFiltrosAtivos ? resumoFiltradoHelper : 'Total criado',
              icon: Icons.assignment_turned_in_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Em aberto',
              value: emAberto.toDouble(),
              formatter: _formatarInteiro,
              helper:
                  possuiFiltrosAtivos
                      ? resumoFiltradoHelper
                      : 'Aguardam recebimento',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Assinados',
              value: assinados.toDouble(),
              formatter: _formatarInteiro,
              helper:
                  possuiFiltrosAtivos
                      ? resumoFiltradoHelper
                      : 'Com aceite do cliente',
              icon: Icons.verified_rounded,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Valor aberto',
              value: valorAberto,
              formatter: _formatarMoeda,
              helper:
                  possuiFiltrosAtivos ? saldoFiltradoHelper : 'Saldo pendente',
              icon: Icons.payments_outlined,
              highlight: true,
              highlightColor: WebThemeTokens.of(context).financialNegative,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required double value,
    required String Function(double value) formatter,
    required String helper,
    required IconData icon,
    bool highlight = false,
    Color? highlightColor,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color destaque = highlightColor ?? tokens.info;
    final bool dark = theme.colorScheme.brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlight
                    ? destaque.withValues(alpha: dark ? 0.45 : 0.34)
                    : tokens.cardBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.12 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    highlight
                        ? destaque.withValues(alpha: dark ? 0.14 : 0.10)
                        : tokens.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: highlight ? destaque : tokens.info,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'summary-$label-${value.toStringAsFixed(4)}',
                    ),
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 720),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      return Text(
                        formatter(animatedValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlight ? destaque : tokens.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusca(
    ThemeData theme,
    bool isCompact,
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicos,
    List<DominioOpcaoModel> statusOptions,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final tecnicoOptions = _tecnicoOptions(atendimentos, tecnicos);
    final statusFiltroOptions = _statusFiltroOptions(
      atendimentos,
      statusOptions,
    );
    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double searchWidth =
              isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth * 0.42).clamp(320.0, 620.0);
          final filtroData = _filterTrigger(
            theme,
            width: isCompact ? constraints.maxWidth : 220,
            label: context.t(
              'atendimentoTecnico.web.dateFilterDialog.filterLabel',
              fallback: 'Data',
            ),
            value: _periodoFiltroLabel(),
            icon: Icons.event_outlined,
            onTap: _abrirFiltroDataWeb,
          );
          final filtroTecnico = _tecnicoFilterMenu(
            width: isCompact ? constraints.maxWidth : 250,
            options: tecnicoOptions,
          );
          final filtroStatus = _statusFilterMenu(
            width: isCompact ? constraints.maxWidth : 250,
            options: statusFiltroOptions,
            total: atendimentos.length,
          );
          final filtroStatusPagamento = _statusPagamentoFilterMenu(
            width: isCompact ? constraints.maxWidth : 230,
          );
          final limparFiltros =
              _possuiFiltrosAtivos
                  ? OutlinedButton.icon(
                    onPressed: _limparFiltros,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Limpar filtros'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                  : null;
          final auditoria = _metricBadge(
            theme,
            'Auditoria ativa',
            Icons.manage_history_rounded,
          );
          final searchField = SizedBox(
            width: searchWidth,
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText:
                    'Buscar por cliente, técnico, status, equipamento ou número...',
                prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
                suffixIcon:
                    _buscaController.text.trim().isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _buscaController.clear(),
                        ),
                filled: true,
                fillColor: tokens.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: tokens.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: tokens.selectedBorder,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          );

          final bool useWrappedFilters =
              isCompact ||
              constraints.maxWidth < (_possuiFiltrosAtivos ? 1710 : 1550);

          if (useWrappedFilters) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                searchField,
                filtroData,
                filtroTecnico,
                filtroStatus,
                filtroStatusPagamento,
                if (limparFiltros != null) limparFiltros,
                if (!isCompact) auditoria,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: searchField),
              const SizedBox(width: 12),
              filtroData,
              const SizedBox(width: 12),
              filtroTecnico,
              const SizedBox(width: 12),
              filtroStatus,
              const SizedBox(width: 12),
              filtroStatusPagamento,
              const SizedBox(width: 12),
              if (limparFiltros != null) ...<Widget>[
                limparFiltros,
                const SizedBox(width: 12),
              ],
              auditoria,
            ],
          );
        },
      ),
    );
  }

  Future<void> _abrirFiltroDataWeb() async {
    final result = await showSixWebAtendimentoDateFilterDialog(
      context: context,
      dataInicio: _dataInicioFiltro,
      dataFim: _dataFimFiltro,
      formatarData: _formatarDataCurta,
      dateFormatPattern: context.read<LocaleSettingsProvider>().dateFormat,
    );
    if (result == null || !mounted) return;
    setState(() {
      _dataInicioFiltro = result.dataInicio;
      _dataFimFiltro = result.dataFim;
    });
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriados();
  }

  Widget _filterTrigger(
    ThemeData theme, {
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: _filterDisplay(theme, label: label, value: value, icon: icon),
        ),
      ),
    );
  }

  Widget _filterDisplay(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: tokens.info, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: tokens.secondaryText),
        ],
      ),
    );
  }

  Widget _tecnicoFilterMenu({
    required double width,
    required List<_TecnicoFiltroOption> options,
  }) {
    return _FiltroMultiSelectDropdown(
      width: width,
      label: context.t(
        'atendimentoTecnico.filters.technician.label',
        fallback: 'Técnico responsável',
      ),
      displayValue: _tecnicoFiltroLabel(options),
      tooltip: context.t(
        'atendimentoTecnico.filters.technician.tooltip',
        fallback: 'Filtrar por técnico responsável',
      ),
      icon: Icons.engineering_outlined,
      selectedKeys: _tecnicoFiltroKeys,
      allLabel: context.t(
        'atendimentoTecnico.filters.technician.all',
        fallback: 'Todos os técnicos',
      ),
      itemIcon: Icons.engineering_outlined,
      options: options
          .map(
            (option) =>
                _FiltroMultiSelectOption(key: option.key, label: option.label),
          )
          .toList(growable: false),
      onChanged: (value) {
        setState(() {
          _tecnicoFiltroKeys = Set<String>.from(value);
        });
        _usuarioAlterouFiltros = true;
        _salvarPreferenciasAtendimentosCriados();
      },
    );
  }

  Widget _statusFilterMenu({
    required double width,
    required List<_StatusFiltroOption> options,
    required int total,
  }) {
    return _FiltroMultiSelectDropdown(
      width: width,
      label: context.t('atendimentoTecnico.status', fallback: 'Status'),
      displayValue: _statusFiltroDisplayLabel(options),
      tooltip: context.t(
        'atendimentoTecnico.filters.status.tooltip',
        fallback: 'Filtrar por status',
      ),
      icon: Icons.flag_outlined,
      selectedKeys: _statusFiltroKeys,
      allLabel: context
          .t(
            'atendimentoTecnico.filters.status.allWithCount',
            fallback: 'Todos os status ({count})',
          )
          .replaceAll('{count}', total.toString()),
      itemIcon: Icons.flag_outlined,
      options: options
          .map(
            (option) => _FiltroMultiSelectOption(
              key: option.key,
              label: option.label,
              count: option.count,
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        setState(() {
          _statusFiltroKeys = Set<String>.from(value);
        });
        _usuarioAlterouFiltros = true;
        _salvarPreferenciasAtendimentosCriados();
      },
    );
  }

  Widget _statusPagamentoFilterMenu({required double width}) {
    final String todosKey =
        AtendimentosCriadosStatusPagamentoFiltro.todos.codigo;
    return _TecnicoFiltroDropdown(
      width: width,
      label: context.t(
        'atendimentoTecnico.filters.paymentStatus.label',
        fallback: 'Status pagamento',
      ),
      displayValue: _statusPagamentoFiltroLabel(_statusPagamentoFiltro),
      tooltip: context.t(
        'atendimentoTecnico.filters.paymentStatus.tooltip',
        fallback: 'Filtrar por status do pagamento',
      ),
      icon: Icons.account_balance_wallet_outlined,
      selectedKey:
          _statusPagamentoFiltro ==
                  AtendimentosCriadosStatusPagamentoFiltro.todos
              ? null
              : _statusPagamentoFiltro.codigo,
      todosKey: todosKey,
      todosLabel: _statusPagamentoFiltroLabel(
        AtendimentosCriadosStatusPagamentoFiltro.todos,
      ),
      todosIcon: Icons.receipt_long_outlined,
      itemIcon: Icons.account_balance_wallet_outlined,
      options: _statusPagamentoFiltroOptions(),
      onChanged: (value) {
        setState(() {
          _statusPagamentoFiltro =
              AtendimentosCriadosStatusPagamentoFiltroApi.fromCodigo(
                value,
                AtendimentosCriadosStatusPagamentoFiltro.todos,
              );
        });
        _usuarioAlterouFiltros = true;
        _salvarPreferenciasAtendimentosCriados();
      },
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
    bool isCompact,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  theme.colorScheme.brightness == Brightness.dark
                      ? 0.12
                      : 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: _buildAtendimentoResumo(theme, atendimento, status, isCompact),
      ),
    );
  }

  Widget _buildAtendimentoResumo(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
    bool isCompact,
  ) {
    final Color statusColor = _statusProgressColor(theme, atendimento, status);
    final Widget identity = _buildAtendimentoIdentity(
      theme,
      atendimento,
      statusColor: statusColor,
    );
    final Widget metrics = _buildResumoRapidoAtendimento(
      theme,
      atendimento,
      status,
      statusColor: statusColor,
    );
    final Widget primaryActions = _buildAcoesPrincipaisAtendimento(
      theme,
      atendimento,
      isCompact: isCompact,
    );
    final Widget detailsControl = _detailsControl(
      onPressed: () => _abrirDetalhesAtendimento(atendimento, status),
    );
    final Widget tapTarget = _summaryTapTarget(
      onTap: () => _abrirDetalhesAtendimento(atendimento, status),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      detailsControl,
                    ],
                  ),
                  const SizedBox(height: 12),
                  metrics,
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: identity),
                  const SizedBox(width: 14),
                  Expanded(flex: 7, child: metrics),
                ],
              ),
    );

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  tapTarget,
                  const SizedBox(height: 12),
                  primaryActions,
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: tapTarget),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: primaryActions,
                  ),
                  const SizedBox(width: 8),
                  detailsControl,
                ],
              ),
    );
  }

  Widget _summaryTapTarget({
    required VoidCallback onTap,
    required Widget child,
  }) {
    final String label = context.t(
      'atendimentoTecnico.lista.openDetails',
      fallback: 'Ver detalhes',
    );
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: AnimatedContainer(
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              padding: const EdgeInsets.all(8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAtendimentoIdentity(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento, {
    required Color statusColor,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String cliente = _clienteLabelAtendimento(atendimento);
    final String tecnico = _tecnicoLabelAtendimento(atendimento);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            _equipamentoIcon(atendimento),
            color: statusColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _equipamentoTitulo(atendimento),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _summaryMetaPill(
                    theme,
                    atendimento.numero,
                    Icons.confirmation_number_outlined,
                    maxWidth: 150,
                  ),
                  _summaryMetaPill(
                    theme,
                    cliente,
                    Icons.person_outline_rounded,
                  ),
                  _summaryMetaPill(theme, tecnico, Icons.engineering_outlined),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoRapidoAtendimento(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status, {
    required Color statusColor,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool stackPills = maxWidth < 420;
        final double pillMaxWidth =
            stackPills ? maxWidth : (maxWidth * 0.34).clamp(150.0, 220.0);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _summaryMetricPill(
              theme,
              maxWidth: pillMaxWidth,
              label: context.t(
                'atendimentoTecnico.lista.summary.status',
                fallback: 'Status',
              ),
              value: _statusLabel(atendimento, status),
              icon: Icons.flag_outlined,
              emphasisColor: statusColor,
            ),
            _summaryMetricPill(
              theme,
              maxWidth: pillMaxWidth,
              label: context.t(
                'atendimentoTecnico.lista.summary.total',
                fallback: 'Total',
              ),
              value: _formatarMoeda(atendimento.valorTotalAtendimento),
              icon: Icons.payments_outlined,
            ),
            _summaryMetricPill(
              theme,
              maxWidth: pillMaxWidth,
              label: context.t(
                'atendimentoTecnico.lista.summary.openAmount',
                fallback: 'Aberto',
              ),
              value: _formatarMoeda(atendimento.valorEmAberto),
              icon: Icons.account_balance_wallet_outlined,
              emphasisColor:
                  atendimento.valorEmAberto > 0
                      ? tokens.financialNegative
                      : null,
            ),
            _summaryMetricPill(
              theme,
              maxWidth: pillMaxWidth,
              label: context.t(
                'atendimentoTecnico.lista.summary.delivery',
                fallback: 'Entrega',
              ),
              value: _formatarDataCurta(atendimento.dataEntregaPrevista),
              icon: Icons.assignment_turned_in_outlined,
              emphasisColor:
                  _entregaAtrasada(atendimento) ? tokens.danger : null,
            ),
            _summaryMetricPill(
              theme,
              maxWidth: pillMaxWidth,
              label: context.t(
                'atendimentoTecnico.lista.summary.validity',
                fallback: 'Validade',
              ),
              value: _formatarDataCurta(atendimento.validadeOrcamentoEm),
              icon: Icons.event_available_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryMetricPill(
    ThemeData theme, {
    required double maxWidth,
    required String label,
    required String value,
    required IconData icon,
    Color? emphasisColor,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = emphasisColor ?? tokens.secondaryText;
    final Color valueColor = emphasisColor ?? tokens.primaryText;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.10),
            tokens.cardBackground,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '$label: ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetaPill(
    ThemeData theme,
    String label,
    IconData icon, {
    double maxWidth = 260,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: tokens.secondaryText),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoesPrincipaisAtendimento(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento, {
    required bool isCompact,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      children: <Widget>[
        _actionButton(
          theme,
          label: 'Receber',
          icon: Icons.payments_outlined,
          onPressed:
              atendimento.operacaoLiquidada
                  ? null
                  : () => _abrirRecebimento(atendimento),
          filled: true,
        ),
        _actionButton(
          theme,
          label: 'Editar',
          icon: Icons.edit_note_rounded,
          onPressed: () => _abrirEditarAtendimento(atendimento),
        ),
      ],
    );
  }

  Widget _detailsControl({required VoidCallback onPressed}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String tooltip = context.t(
      'atendimentoTecnico.lista.openDetails',
      fallback: 'Ver detalhes',
    );
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: tokens.surfaceMuted,
          foregroundColor: tokens.info,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.visibility_outlined),
      ),
    );
  }

  Future<void> _abrirDetalhesAtendimento(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final ThemeData theme = Theme.of(context);
    final Color statusColor = _statusProgressColor(theme, atendimento, status);
    final String cliente = _clienteLabelAtendimento(atendimento);
    final String tecnico = _tecnicoLabelAtendimento(atendimento);

    return showSixWebAtendimentoDetailsDialog(
      context: context,
      equipmentTitle: _equipamentoTitulo(atendimento),
      attendanceNumber: atendimento.numero,
      customerLabel: cliente,
      technicianLabel: tecnico,
      accentColor: statusColor,
      accentIcon: _equipamentoIcon(atendimento),
      summaryMetrics: _buildAtendimentoMetricCards(
        atendimento,
        status,
        statusColor: statusColor,
      ),
      statusChips: _buildAtendimentoStatusChips(theme, atendimento, status),
      actionContent: _buildDetalhesDialogActions(theme, atendimento, status),
      progressContent: _statusProgressBar(theme, atendimento, status),
      detailsContent: _buildDetalhesInlineAtendimento(
        theme,
        atendimento,
        status,
      ),
    );
  }

  Widget _buildDetalhesDialogActions(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildAcoesPrimariasDetalhesAtendimento(
              theme,
              atendimento,
              isCompact: compact,
            ),
            const SizedBox(height: 10),
            _buildAcoesSecundariasDetalhesAtendimento(
              theme,
              atendimento,
              status,
              isCompact: compact,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAcoesPrimariasDetalhesAtendimento(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento, {
    required bool isCompact,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      children: <Widget>[
        _actionButton(
          theme,
          label: 'Receber',
          icon: Icons.payments_outlined,
          onPressed:
              atendimento.operacaoLiquidada
                  ? null
                  : () async {
                    Navigator.of(context).maybePop();
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    await _abrirRecebimento(atendimento);
                  },
          filled: true,
        ),
        _actionButton(
          theme,
          label: 'Editar',
          icon: Icons.edit_note_rounded,
          onPressed: () async {
            Navigator.of(context).maybePop();
            await Future<void>.delayed(Duration.zero);
            if (!mounted) return;
            await _abrirEditarAtendimento(atendimento);
          },
        ),
      ],
    );
  }

  List<SixWebAtendimentoDetailsMetric> _buildAtendimentoMetricCards(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status, {
    required Color statusColor,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return <SixWebAtendimentoDetailsMetric>[
      SixWebAtendimentoDetailsMetric(
        label: context.t(
          'atendimentoTecnico.lista.summary.status',
          fallback: 'Status',
        ),
        value: _statusLabel(atendimento, status),
        icon: Icons.flag_outlined,
        emphasisColor: statusColor,
      ),
      SixWebAtendimentoDetailsMetric(
        label: context.t(
          'atendimentoTecnico.lista.summary.total',
          fallback: 'Total',
        ),
        value: _formatarMoeda(atendimento.valorTotalAtendimento),
        icon: Icons.payments_outlined,
      ),
      SixWebAtendimentoDetailsMetric(
        label: context.t(
          'atendimentoTecnico.lista.summary.openAmount',
          fallback: 'Aberto',
        ),
        value: _formatarMoeda(atendimento.valorEmAberto),
        icon: Icons.account_balance_wallet_outlined,
        emphasisColor:
            atendimento.valorEmAberto > 0 ? tokens.financialNegative : null,
      ),
      SixWebAtendimentoDetailsMetric(
        label: context.t(
          'atendimentoTecnico.lista.summary.delivery',
          fallback: 'Entrega',
        ),
        value: _formatarDataCurta(atendimento.dataEntregaPrevista),
        icon: Icons.assignment_turned_in_outlined,
        emphasisColor: _entregaAtrasada(atendimento) ? tokens.danger : null,
      ),
      SixWebAtendimentoDetailsMetric(
        label: context.t(
          'atendimentoTecnico.lista.summary.validity',
          fallback: 'Validade',
        ),
        value: _formatarDataCurta(atendimento.validadeOrcamentoEm),
        icon: Icons.event_available_outlined,
      ),
    ];
  }

  List<Widget> _buildAtendimentoStatusChips(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final bool pagamentoAberto = _pagamentoEmAberto(atendimento);
    final bool entregaAtrasada = _entregaAtrasada(atendimento);
    final bool clienteNaoAssinou = _clienteNaoAssinouAtendimentoAberto(
      atendimento,
    );
    return <Widget>[
      pagamentoAberto ? _naoLiquidadaChip(theme) : _liquidadaChip(theme),
      if (clienteNaoAssinou) _customerNotSignedChip(theme),
      if (atendimento.assinaturaAprovada) _signedChip(theme),
      if (atendimento.requerNovaAssinatura) _pendingSignatureChip(theme),
      if (entregaAtrasada) _lateDeliveryChip(theme),
      _chip(theme, _statusLabel(atendimento, status), Icons.flag_outlined),
      _chip(theme, 'v${atendimento.versaoOrcamento}', Icons.tag_outlined),
      _chip(
        theme,
        '${atendimento.itens.length} item(ns)',
        Icons.inventory_2_outlined,
      ),
      _chip(
        theme,
        '${atendimento.historicoAuditoria.length} aud.',
        Icons.manage_history_rounded,
      ),
      _chip(
        theme,
        'Atualização ${_formatarDataCurta(atendimento.dataAtualizacao)}',
        Icons.update_rounded,
      ),
    ];
  }

  Widget _buildAcoesSecundariasDetalhesAtendimento(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status, {
    required bool isCompact,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      children: <Widget>[
        _actionButton(
          theme,
          label:
              _gerandoLinkStatus
                  ? context.t('common.generating', fallback: 'Gerando...')
                  : context.t(
                    'atendimentoTecnico.publicStatus.action',
                    fallback: 'Status público',
                  ),
          icon: Icons.ios_share_rounded,
          onPressed:
              _gerandoLinkStatus
                  ? null
                  : () async {
                    Navigator.of(context).maybePop();
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    await _gerarLinkStatusPublico(atendimento);
                  },
        ),
        _actionButton(
          theme,
          label: _gerandoLink ? 'Gerando...' : 'Link assinatura',
          icon: Icons.draw_outlined,
          onPressed:
              _gerandoLink
                  ? null
                  : () async {
                    Navigator.of(context).maybePop();
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    await _gerarLinkAssinatura(atendimento);
                  },
        ),
        _actionButton(
          theme,
          label: 'Mudar status',
          icon: Icons.swap_horiz_rounded,
          onPressed: () async {
            Navigator.of(context).maybePop();
            await Future<void>.delayed(Duration.zero);
            if (!mounted) return;
            await _abrirAlterarStatusDialog(atendimento, status);
          },
        ),
      ],
    );
  }

  Widget _buildDetalhesInlineAtendimento(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 860;
        final double spacing = 18;
        final double columnWidth =
            twoColumns
                ? ((constraints.maxWidth - spacing) / 2)
                : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: <Widget>[
            _inlineDetailSection('Resumo financeiro', <Widget>[
              _detailLine(
                'Liquidação',
                atendimento.operacaoLiquidada ? 'Liquidada' : 'Não liquidada',
              ),
              _detailLine(
                'Total',
                _formatarMoeda(atendimento.valorTotalAtendimento),
              ),
              _detailLine(
                'Recebido',
                _formatarMoeda(atendimento.valorRecebido),
              ),
              _detailLine(
                'Em aberto',
                _formatarMoeda(atendimento.valorEmAberto),
              ),
              if (atendimento.assinaturaAprovada)
                _detailLine('Assinatura', _assinaturaResumo(atendimento)),
              if (atendimento.requerNovaAssinatura)
                _detailLine(
                  'Assinatura',
                  'Pendente para a versão atual do orçamento',
                ),
            ], width: columnWidth),
            _inlineDetailSection('Atendimento', <Widget>[
              _detailLine('Cliente', _clienteLabelAtendimento(atendimento)),
              _detailLine('Técnico', _tecnicoLabelAtendimento(atendimento)),
              _detailLine('Status', _statusLabel(atendimento, status)),
              _detailLine(
                'Validade',
                _formatarDataCurta(atendimento.validadeOrcamentoEm),
              ),
              _detailLine(
                'Entrega prevista',
                _formatarDataCurta(atendimento.dataEntregaPrevista),
              ),
              if ((atendimento.descricao ?? '').trim().isNotEmpty)
                _detailLine('Descrição', atendimento.descricao!.trim()),
              if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty)
                _detailLine('Defeito', atendimento.defeitoRelatado!.trim()),
              if ((atendimento.diagnosticoTecnico ?? '').trim().isNotEmpty)
                _detailLine(
                  'Diagnóstico',
                  atendimento.diagnosticoTecnico!.trim(),
                ),
            ], width: columnWidth),
            _inlineDetailSection('Recebimentos', <Widget>[
              if (atendimento.recebimentos.isEmpty)
                _detailMutedText('Nenhum recebimento lançado.')
              else
                ...atendimento.recebimentos.reversed.map(
                  (item) => _detailLine(
                    item.nomeFormaRecebimento,
                    '${_formatarMoeda(item.valor)} • ${_formatarData(item.dataHora)}${(item.observacao ?? '').trim().isEmpty ? '' : ' • ${item.observacao}'}',
                  ),
                ),
            ], width: columnWidth),
            _inlineDetailSection('Itens', <Widget>[
              if (atendimento.itens.isEmpty)
                _detailMutedText('Nenhum item vinculado.')
              else
                ...atendimento.itens.map(
                  (item) => _detailLine(
                    item.tipoItemCodigo == 'SERVICE' ? 'Serviço' : 'Produto',
                    '${item.descricaoSnapshot} • ${_formatarInteiro(item.quantidade)} x ${_formatarMoeda(item.valorUnitario)}',
                  ),
                ),
            ], width: columnWidth),
            _inlineDetailSection(
              'Histórico de auditoria',
              <Widget>[
                if (atendimento.historicoAuditoria.isEmpty)
                  _detailMutedText('Nenhuma auditoria registrada.')
                else
                  ...atendimento.historicoAuditoria.reversed.map(
                    (item) => _detailLongText(
                      '${_formatarData(item.dataHora)} • v${item.versaoOrcamento} • ${item.tipo}${(item.observacao ?? '').trim().isEmpty ? '' : ' • ${item.observacao}'}',
                    ),
                  ),
              ],
              width: twoColumns ? constraints.maxWidth : columnWidth,
            ),
            _inlineDetailSection(
              'Histórico de status',
              <Widget>[
                if (atendimento.historicoStatus.isEmpty)
                  _detailMutedText('Nenhuma mudança registrada.')
                else
                  ...atendimento.historicoStatus.reversed.map((item) {
                    final anterior =
                        item.statusAnteriorNomePtBr ??
                        _statusLabelPorCodigo(
                          item.statusAnteriorCodigo,
                          status,
                        );
                    final novo =
                        item.statusNomePtBr ??
                        _statusLabelPorCodigo(item.statusCodigo, status);
                    final observacao = item.observacao?.trim() ?? '';
                    return _detailLongText(
                      '${_formatarData(item.dataHora)} • $anterior → $novo${observacao.isEmpty ? '' : ' • $observacao'}',
                    );
                  }),
              ],
              width: twoColumns ? constraints.maxWidth : columnWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _inlineDetailSection(
    String title,
    List<Widget> children, {
    required double width,
  }) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha:
                    theme.colorScheme.brightness == Brightness.dark
                        ? 0.10
                        : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  IconData _equipamentoIcon(AtendimentoTecnicoModel atendimento) {
    final String tipo =
        atendimento.equipamento?.tipo?.trim().toUpperCase() ?? '';
    if (tipo.contains('SMARTPHONE') ||
        tipo.contains('CELULAR') ||
        tipo.contains('PHONE') ||
        tipo.contains('IPHONE')) {
      return Icons.phone_iphone_rounded;
    }
    if (tipo.contains('NOTEBOOK') || tipo.contains('LAPTOP')) {
      return Icons.laptop_mac_rounded;
    }
    if (tipo.contains('TABLET')) return Icons.tablet_mac_rounded;
    if (tipo.contains('IMPRESSORA') || tipo.contains('PRINTER')) {
      return Icons.print_rounded;
    }
    if (tipo.contains('COMPUTADOR') ||
        tipo == 'PC' ||
        tipo.contains('DESKTOP')) {
      return Icons.computer_rounded;
    }
    if (tipo.contains('TV') || tipo.contains('TELEVISAO')) {
      return Icons.tv_rounded;
    }
    return Icons.devices_other_outlined;
  }

  Widget _detailLine(String label, String value) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: tokens.primaryText)),
          ),
        ],
      ),
    );
  }

  Widget _detailMutedText(String value) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(value, style: TextStyle(color: tokens.secondaryText)),
    );
  }

  Widget _detailLongText(String value) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value,
        style: TextStyle(color: tokens.primaryText, height: 1.35),
      ),
    );
  }

  Widget _statusProgressBar(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    if (status.isEmpty) return const SizedBox.shrink();
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final progress = _statusProgressValue(atendimento, status);
    final color = _statusProgressColor(theme, atendimento, status);
    final steps = _statusFlowSteps(status);
    if (steps.isEmpty) return const SizedBox.shrink();
    final current = _statusEtapaAtual(atendimento, steps);
    final String currentLabel =
        current == null
            ? _statusLabel(atendimento, status)
            : _statusOptionLabel(current);
    final String progressLabel = '${_formatarInteiro(progress * 100)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.route_outlined, size: 17, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        'atendimentoTecnico.publicStatus.progressShort',
                        fallback: 'Progresso do serviço',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Text(
                  progressLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _statusBulletProgressBar(
            theme: theme,
            tokens: tokens,
            progress: progress,
            steps: steps,
            color: color,
            valueKey:
                'web-status-progress-${atendimento.id}-'
                '${atendimento.statusCodigo}-${steps.length}',
          ),
        ],
      ),
    );
  }

  Widget _statusBulletProgressBar({
    required ThemeData theme,
    required WebThemeTokens tokens,
    required double progress,
    required List<DominioOpcaoModel> steps,
    required Color color,
    required String valueKey,
  }) {
    const double trackHeight = 10;
    const double bulletSize = 22;
    final int safeSteps = steps.isEmpty ? 1 : steps.length;
    final double safeProgress = progress.clamp(0, 1).toDouble();
    final double completedSteps = safeProgress * safeSteps;
    final int currentStep = completedSteps.ceil().clamp(0, safeSteps).toInt();
    final double lineProgress =
        safeSteps <= 1
            ? safeProgress
            : ((completedSteps - 1) / (safeSteps - 1)).clamp(0, 1).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) return const SizedBox.shrink();
        final bool showLabels = width >= 640 && steps.length <= 9;
        const double progressHeight = 32;
        return Column(
          children: <Widget>[
            SizedBox(
              height: progressHeight,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  Positioned(
                    left: bulletSize / 2,
                    right: bulletSize / 2,
                    top: (progressHeight - trackHeight) / 2,
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: tokens.cardBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tokens.cardBorder),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: bulletSize / 2,
                    top: (progressHeight - trackHeight) / 2,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<String>(valueKey),
                      tween: Tween<double>(begin: 0, end: lineProgress),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          width: (width - bulletSize) * value,
                          height: trackHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                color.withValues(alpha: 0.78),
                                color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: color.withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  for (int index = 0; index < safeSteps; index++)
                    _statusProgressBullet(
                      width: width,
                      height: progressHeight,
                      bulletSize: bulletSize,
                      index: index,
                      steps: safeSteps,
                      currentStep: currentStep,
                      color: color,
                      tokens: tokens,
                    ),
                ],
              ),
            ),
            if (showLabels) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int index = 0; index < steps.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right: index == steps.length - 1 ? 0 : 4,
                        ),
                        child: Text(
                          _statusOptionLabel(steps[index]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              index == 0
                                  ? TextAlign.left
                                  : index == steps.length - 1
                                  ? TextAlign.right
                                  : TextAlign.center,
                          style: TextStyle(
                            color:
                                index < currentStep
                                    ? tokens.primaryText
                                    : tokens.mutedText,
                            fontSize: 10.5,
                            fontWeight:
                                index < currentStep
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _statusProgressBullet({
    required double width,
    required double height,
    required double bulletSize,
    required int index,
    required int steps,
    required int currentStep,
    required Color color,
    required WebThemeTokens tokens,
  }) {
    final double position = steps == 1 ? 0 : index / (steps - 1);
    final bool reached = index < currentStep;
    final bool active = reached && index == currentStep - 1;
    return Positioned(
      left: (width - bulletSize) * position,
      top: (height - bulletSize) / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: bulletSize,
        height: bulletSize,
        decoration: BoxDecoration(
          color: reached ? color : tokens.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: reached ? color : tokens.cardBorder,
            width: reached ? (active ? 2.8 : 2) : 1.3,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (reached ? color : Colors.black).withValues(
                alpha: reached ? 0.20 : 0.08,
              ),
              blurRadius: reached ? (active ? 14 : 10) : 7,
              offset: const Offset(0, 3),
            ),
            if (active)
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 0,
                spreadRadius: 5,
              ),
          ],
        ),
        child:
            reached
                ? Icon(
                  Icons.check_rounded,
                  size: bulletSize * 0.62,
                  color: _foregroundForStatusColor(color),
                )
                : Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tokens.divider,
                    shape: BoxShape.circle,
                  ),
                ),
      ),
    );
  }

  Color _foregroundForStatusColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Widget _headerButton(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.info,
        backgroundColor: tokens.surfaceMuted,
        side: BorderSide(color: tokens.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _actionButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 13);
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(padding: padding, shape: shape),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.info,
        backgroundColor: tokens.surfaceMuted,
        side: BorderSide(color: tokens.cardBorder),
        padding: padding,
        shape: shape,
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (widget.onBack != null) {
            widget.onBack!.call();
            return;
          }
          Navigator.of(context).maybePop();
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.close_rounded,
            color: tokens.secondaryText,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _metricBadge(ThemeData theme, String label, IconData icon) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: tokens.secondaryText),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tokens.secondaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signedChip(ThemeData theme) => _coloredChip(
    theme,
    'Assinado',
    Icons.verified_rounded,
    WebThemeTokens.of(context).success,
  );

  Widget _pendingSignatureChip(ThemeData theme) => _coloredChip(
    theme,
    'Nova assinatura pendente',
    Icons.pending_actions_rounded,
    WebThemeTokens.of(context).warning,
  );

  Widget _customerNotSignedChip(ThemeData theme) => _coloredChip(
    theme,
    context.t(
      'atendimentoTecnico.customerNotSigned',
      fallback: 'Cliente não assinou',
    ),
    Icons.assignment_late_outlined,
    WebThemeTokens.of(context).warning,
  );

  Widget _lateDeliveryChip(ThemeData theme) => _coloredChip(
    theme,
    'Entrega atrasada',
    Icons.warning_amber_rounded,
    WebThemeTokens.of(context).danger,
  );

  Widget _liquidadaChip(ThemeData theme) => _coloredChip(
    theme,
    'Financeiro liquidado',
    Icons.price_check_rounded,
    WebThemeTokens.of(context).success,
  );

  Widget _naoLiquidadaChip(ThemeData theme) => _coloredChip(
    theme,
    'Financeiro aberto',
    Icons.account_balance_wallet_outlined,
    WebThemeTokens.of(context).financialNegative,
  );

  Widget _coloredChip(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AtendimentosTecnicosWebSkeleton extends StatefulWidget {
  const _AtendimentosTecnicosWebSkeleton({
    required this.semanticsLabel,
    required this.showCloseButton,
  });

  final String semanticsLabel;
  final bool showCloseButton;

  @override
  State<_AtendimentosTecnicosWebSkeleton> createState() =>
      _AtendimentosTecnicosWebSkeletonState();
}

class _AtendimentosTecnicosWebSkeletonState
    extends State<_AtendimentosTecnicosWebSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (motionDisabled == _motionDisabled) return;

    _motionDisabled = motionDisabled;
    if (_motionDisabled) {
      _pulseController
        ..stop()
        ..value = 0.45;
      return;
    }
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color skeletonBase = Color.alphaBlend(
      tokens.primaryText.withValues(alpha: dark ? 0.06 : 0.045),
      tokens.surfaceMuted,
    );
    final Color skeletonHighlight = Color.alphaBlend(
      tokens.primaryText.withValues(alpha: dark ? 0.14 : 0.09),
      tokens.surfaceMuted,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.semanticsLabel,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (BuildContext context, Widget? child) {
              final double pulse =
                  _motionDisabled
                      ? 0.45
                      : Curves.easeInOut.transform(_pulseController.value);
              final Color skeletonColor =
                  Color.lerp(skeletonBase, skeletonHighlight, pulse) ??
                  skeletonBase;
              return ColoredBox(
                color: tokens.workspaceBackground,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isCompact = constraints.maxWidth < 920;
                    final double horizontalPadding = isCompact ? 16 : 28;
                    return CustomScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: _buildHeader(tokens, skeletonColor, isCompact),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            10,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: <Widget>[
                                _buildSummary(tokens, skeletonColor, isCompact),
                                const SizedBox(height: 12),
                                _buildFilters(tokens, skeletonColor, isCompact),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            16,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == 3 ? 0 : 10,
                                ),
                                child: _buildServiceCard(
                                  tokens,
                                  skeletonColor,
                                  isCompact,
                                  index,
                                ),
                              ),
                              childCount: 4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    WebThemeTokens tokens,
    Color skeletonColor,
    bool isCompact,
  ) {
    final Widget titleBlock = Row(
      children: <Widget>[
        _block(skeletonColor, width: 50, height: 50, radius: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _line(skeletonColor, widthFactor: 0.54, height: 22),
              const SizedBox(height: 8),
              _line(skeletonColor, widthFactor: 0.82, height: 13),
            ],
          ),
        ),
      ],
    );
    final Widget actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: <Widget>[
        _block(skeletonColor, width: 112, height: 46, radius: 14),
        _block(skeletonColor, width: 172, height: 46, radius: 14),
        _block(skeletonColor, width: 92, height: 38, radius: 14),
        _block(skeletonColor, width: 108, height: 38, radius: 14),
        if (widget.showCloseButton)
          _block(skeletonColor, width: 42, height: 42, radius: 14),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
      ),
      child:
          isCompact
              ? Column(
                children: <Widget>[
                  titleBlock,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
    );
  }

  Widget _buildSummary(
    WebThemeTokens tokens,
    Color skeletonColor,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            isCompact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 36) / 4).clamp(
                  190.0,
                  constraints.maxWidth,
                );
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(
            4,
            (int index) => Container(
              width: cardWidth,
              height: 102,
              padding: const EdgeInsets.all(16),
              decoration: _panelDecoration(tokens, radius: 20),
              child: Row(
                children: <Widget>[
                  _block(skeletonColor, width: 42, height: 42, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _line(
                          skeletonColor,
                          widthFactor: 0.58 + ((index % 2) * 0.08),
                          height: 11,
                        ),
                        const SizedBox(height: 7),
                        _line(
                          skeletonColor,
                          widthFactor: index == 3 ? 0.76 : 0.34,
                          height: 20,
                        ),
                        const SizedBox(height: 6),
                        _line(skeletonColor, widthFactor: 0.68, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters(
    WebThemeTokens tokens,
    Color skeletonColor,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: _panelDecoration(tokens, radius: 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double fullWidth = constraints.maxWidth;
          final double searchWidth =
              isCompact ? fullWidth : (fullWidth * 0.42).clamp(320.0, 620.0);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _block(skeletonColor, width: searchWidth, height: 56, radius: 16),
              _block(
                skeletonColor,
                width: isCompact ? fullWidth : 220,
                height: 56,
                radius: 16,
              ),
              _block(
                skeletonColor,
                width: isCompact ? fullWidth : 250,
                height: 56,
                radius: 16,
              ),
              _block(
                skeletonColor,
                width: isCompact ? fullWidth : 250,
                height: 56,
                radius: 16,
              ),
              _block(
                skeletonColor,
                width: isCompact ? fullWidth : 230,
                height: 56,
                radius: 16,
              ),
              _block(
                skeletonColor,
                width: isCompact ? 132 : 128,
                height: 38,
                radius: 999,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(
    WebThemeTokens tokens,
    Color skeletonColor,
    bool isCompact,
    int index,
  ) {
    final Widget identity = Row(
      children: <Widget>[
        _block(skeletonColor, width: 46, height: 46, radius: 15),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _line(
                skeletonColor,
                widthFactor: 0.50 + ((index % 3) * 0.12),
                height: 16,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _block(skeletonColor, width: 132, height: 28, radius: 999),
                  _block(skeletonColor, width: 86, height: 28, radius: 999),
                  _block(skeletonColor, width: 92, height: 28, radius: 999),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    final Widget status = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _block(skeletonColor, width: 112, height: 30, radius: 999),
        _block(skeletonColor, width: 118, height: 30, radius: 999),
        _block(skeletonColor, width: 134, height: 30, radius: 999),
        _block(skeletonColor, width: 126, height: 30, radius: 999),
      ],
    );
    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: <Widget>[
        _block(skeletonColor, width: 104, height: 44, radius: 14),
        _block(skeletonColor, width: 82, height: 44, radius: 14),
        _block(skeletonColor, width: 44, height: 44, radius: 14),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: _panelDecoration(tokens, radius: 20),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  identity,
                  const SizedBox(height: 14),
                  status,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(flex: 5, child: identity),
                  const SizedBox(width: 18),
                  Expanded(flex: 6, child: status),
                  const SizedBox(width: 18),
                  actions,
                ],
              ),
    );
  }

  BoxDecoration _panelDecoration(
    WebThemeTokens tokens, {
    required double radius,
  }) {
    return BoxDecoration(
      color: tokens.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tokens.cardBorder),
    );
  }

  Widget _line(
    Color color, {
    required double widthFactor,
    required double height,
  }) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _block(color, height: height, radius: 999),
    );
  }

  Widget _block(
    Color color, {
    double? width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, color: tokens.info, size: 38),
            const SizedBox(height: 10),
            Text(
              'Nenhum atendimento encontrado.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: tokens.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajuste a busca ou atualize a lista.',
              style: TextStyle(color: tokens.secondaryText),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 38),
            const SizedBox(height: 10),
            Text(
              'Não foi possível carregar os atendimentos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: tokens.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.secondaryText),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _SalvarStatusAtendimento =
    Future<bool> Function(DominioOpcaoModel status, String? observacao);

enum _StatusSignatureGateAction {
  enviarLink,
  assinarNesteDispositivo,
  avancarSemAssinatura,
}

class _AssinaturaDispositivoWebResult {
  const _AssinaturaDispositivoWebResult({
    required this.nomeAssinante,
    required this.documentoAssinante,
    required this.assinaturaDataUrl,
    required this.observacao,
  });

  final String nomeAssinante;
  final String documentoAssinante;
  final String assinaturaDataUrl;
  final String observacao;
}

class _AssinaturaDispositivoWebDialog extends StatefulWidget {
  const _AssinaturaDispositivoWebDialog({
    required this.atendimento,
    required this.statusLabel,
  });

  final AtendimentoTecnicoModel atendimento;
  final String statusLabel;

  @override
  State<_AssinaturaDispositivoWebDialog> createState() =>
      _AssinaturaDispositivoWebDialogState();
}

class _AssinaturaDispositivoWebDialogState
    extends State<_AssinaturaDispositivoWebDialog> {
  late final TextEditingController _nomeController;
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  late final SignatureController _signatureController;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final String cliente = widget.atendimento.nomeClienteSnapshot?.trim() ?? '';
    _nomeController = TextEditingController(text: cliente);
    _signatureController = SignatureController(
      penStrokeWidth: 2.4,
      penColor: Colors.black87,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _observacaoController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignerRequired',
          fallback: 'Informe o nome de quem está assinando.',
        );
      });
      return;
    }
    if (_signatureController.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignatureRequired',
          fallback: 'Faça a assinatura no quadro indicado.',
        );
      });
      return;
    }
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String assinaturaDataUrl = _assinaturaSvgDataUrl(
      _signatureController,
      colorScheme.surface,
      colorScheme.onSurface,
    );
    if (assinaturaDataUrl.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignatureRequired',
          fallback: 'Faça a assinatura no quadro indicado.',
        );
      });
      return;
    }
    Navigator.of(context).pop(
      _AssinaturaDispositivoWebResult(
        nomeAssinante: nome,
        documentoAssinante: _documentoController.text.trim(),
        assinaturaDataUrl: assinaturaDataUrl,
        observacao: _observacaoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return AlertDialog(
      icon: Icon(Icons.draw_rounded, color: colorScheme.primary),
      title: Text(
        context.t(
          'atendimentoTecnico.signatureGate.deviceTitle',
          fallback: 'Coletar assinatura',
        ),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context
                    .t(
                      'atendimentoTecnico.signatureGate.deviceMessage',
                      fallback:
                          'Registre a assinatura para avançar para {status}.',
                    )
                    .replaceAll('{status}', widget.statusLabel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.t(
                    'atendimentoTecnico.signatureGate.deviceSigner',
                    fallback: 'Nome de quem assina',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _documentoController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.t(
                    'atendimentoTecnico.signatureGate.deviceDocument',
                    fallback: 'Documento opcional',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.t(
                  'atendimentoTecnico.signatureGate.deviceSignatureField',
                  fallback: 'Assinatura',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: colorScheme.surface,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    _signatureController.clear();
                    setState(() => _erro = null);
                  },
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: Text(context.t('common.clear', fallback: 'Limpar')),
                ),
              ),
              TextField(
                controller: _observacaoController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.t(
                    'atendimentoTecnico.signatureGate.deviceObservation',
                    fallback: 'Observação opcional',
                  ),
                ),
              ),
              if (_erro != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _erro!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('common.cancel', fallback: 'Cancelar')),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.check_rounded),
          label: Text(
            context.t(
              'atendimentoTecnico.signatureGate.deviceSave',
              fallback: 'Registrar assinatura',
            ),
          ),
        ),
      ],
    );
  }
}

String _assinaturaSvgDataUrl(
  SignatureController controller,
  Color backgroundColor,
  Color penColor,
) {
  if (controller.isEmpty) return '';

  final double minX = controller.minXValue ?? 0;
  final double minY = controller.minYValue ?? 0;
  final double stroke = controller.penStrokeWidth;
  final int width =
      ((controller.maxXValue ?? minX) - minX + stroke * 2)
          .ceil()
          .clamp(1, 4096)
          .toInt();
  final int height =
      ((controller.maxYValue ?? minY) - minY + stroke * 2)
          .ceil()
          .clamp(1, 4096)
          .toInt();
  final String points = controller.points
      .map((Point point) {
        final double dx = point.offset.dx - minX + stroke;
        final double dy = point.offset.dy - minY + stroke;
        return '${dx.toStringAsFixed(2)},${dy.toStringAsFixed(2)}';
      })
      .join(' ');

  if (points.trim().isEmpty) return '';

  final String svg =
      '<svg viewBox="0 0 $width $height" width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">'
      '<rect width="100%" height="100%" fill="${_svgColor(backgroundColor)}"/>'
      '<polyline fill="none" stroke="${_svgColor(penColor)}" stroke-linecap="round" stroke-linejoin="round" stroke-width="${stroke.toStringAsFixed(2)}" points="$points"/>'
      '</svg>';
  return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
}

String _svgColor(Color color) {
  return '#${_svgColorChannel(color.r).toRadixString(16).padLeft(2, '0')}'
      '${_svgColorChannel(color.g).toRadixString(16).padLeft(2, '0')}'
      '${_svgColorChannel(color.b).toRadixString(16).padLeft(2, '0')}';
}

int _svgColorChannel(double value) {
  return (value * 255).round().clamp(0, 255).toInt();
}

class _AlterarStatusAtendimentoWebDialog extends StatefulWidget {
  const _AlterarStatusAtendimentoWebDialog({
    required this.atendimento,
    required this.status,
    required this.statusAtual,
    required this.statusAtualLabel,
    required this.onSalvar,
  });

  final AtendimentoTecnicoModel atendimento;
  final List<DominioOpcaoModel> status;
  final DominioOpcaoModel? statusAtual;
  final String statusAtualLabel;
  final _SalvarStatusAtendimento onSalvar;

  @override
  State<_AlterarStatusAtendimentoWebDialog> createState() =>
      _AlterarStatusAtendimentoWebDialogState();
}

class _AlterarStatusAtendimentoWebDialogState
    extends State<_AlterarStatusAtendimentoWebDialog> {
  late DominioOpcaoModel? _statusSelecionado = widget.statusAtual;
  final TextEditingController _observacaoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final statusSelecionado = _statusSelecionado;
    if (statusSelecionado == null || _salvando) return;
    setState(() => _salvando = true);
    final observacao = _observacaoController.text.trim();
    final salvou = await widget.onSalvar(
      statusSelecionado,
      observacao.isEmpty ? null : observacao,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (salvou) {
      Navigator.of(context).pop(true);
    }
  }

  String get _cliente {
    final nome = widget.atendimento.nomeClienteSnapshot?.trim() ?? '';
    return nome.isEmpty ? 'Cliente não informado' : nome;
  }

  String get _equipamento {
    final equipamento = widget.atendimento.equipamento;
    final partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((parte) => parte.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? widget.atendimento.numero : partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: AnimatedContainer(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.cardBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha:
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.24
                        : 0.10,
              ),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 520;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 18 : 24,
                        compact ? 18 : 22,
                        compact ? 12 : 16,
                        compact ? 16 : 18,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceMuted,
                        border: Border(
                          bottom: BorderSide(color: tokens.cardBorder),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: tokens.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: tokens.info,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Mudar status',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: tokens.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Registre a próxima etapa do atendimento técnico.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: tokens.secondaryText,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed:
                                _salvando
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                            tooltip: 'Fechar',
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    ColoredBox(
                      color: tokens.surfaceElevated,
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 18 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _StatusContextCard(
                              numero: widget.atendimento.numero,
                              equipamento: _equipamento,
                              cliente: _cliente,
                              statusAtual: widget.statusAtualLabel,
                            ),
                            const SizedBox(height: 16),
                            _StatusWebSelector(
                              label: 'Novo status',
                              value: _statusSelecionado,
                              options: widget.status,
                              enabled: !_salvando,
                              onChanged:
                                  (value) => setState(
                                    () => _statusSelecionado = value,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _observacaoController,
                              enabled: !_salvando,
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Observação da mudança',
                                hintText:
                                    'Informe um detalhe útil para o histórico, se necessário.',
                                filled: true,
                                fillColor: tokens.inputBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 18 : 24,
                        14,
                        compact ? 18 : 24,
                        compact ? 18 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        border: Border(
                          top: BorderSide(color: tokens.cardBorder),
                        ),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment:
                            compact ? WrapAlignment.start : WrapAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed:
                                _salvando
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton.icon(
                            onPressed:
                                _statusSelecionado == null || _salvando
                                    ? null
                                    : _salvar,
                            icon:
                                _salvando
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                    : const Icon(Icons.check_rounded),
                            label: Text(_salvando ? 'Salvando...' : 'Salvar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusContextCard extends StatelessWidget {
  const _StatusContextCard({
    required this.numero,
    required this.equipamento,
    required this.cliente,
    required this.statusAtual,
  });

  final String numero;
  final String equipamento;
  final String cliente;
  final String statusAtual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.devices_other_outlined, color: tokens.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  equipamento,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$numero • $cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _StatusPill(
                      icon: Icons.flag_outlined,
                      label: 'Status atual',
                      value: statusAtual,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: tokens.info),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusWebSelector extends StatefulWidget {
  const _StatusWebSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DominioOpcaoModel? value;
  final List<DominioOpcaoModel> options;
  final ValueChanged<DominioOpcaoModel> onChanged;
  final bool enabled;

  @override
  State<_StatusWebSelector> createState() => _StatusWebSelectorState();
}

class _StatusWebSelectorState extends State<_StatusWebSelector> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _opened = false;

  Future<void> _openMenu() async {
    if (!widget.enabled) return;
    final context = _fieldKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    setState(() => _opened = true);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final selected = await showMenu<DominioOpcaoModel>(
      context: context,
      position: position,
      constraints: BoxConstraints.tightFor(width: renderBox.size.width),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: tokens.menuBackground,
      items:
          widget.options.map((option) {
            final bool selected = option.id == widget.value?.id;
            return PopupMenuItem<DominioOpcaoModel>(
              value: option,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: AnimatedContainer(
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? tokens.selectedBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      selected
                          ? Border.all(color: tokens.selectedBorder)
                          : null,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        option.nomePadraoPtBr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              selected
                                  ? tokens.primaryText
                                  : tokens.secondaryText,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_rounded, size: 18, color: tokens.info),
                  ],
                ),
              ),
            );
          }).toList(),
    );
    if (!mounted) return;
    setState(() => _opened = false);
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final value = widget.value?.nomePadraoPtBr ?? 'Selecione um status';
    return InkWell(
      key: _fieldKey,
      onTap: _openMenu,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              widget.enabled
                  ? tokens.inputBackground
                  : tokens.disabledBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _opened ? tokens.selectedBorder : tokens.cardBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.flag_outlined, color: tokens.info, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          widget.enabled
                              ? tokens.primaryText
                              : tokens.disabledForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedRotation(
              turns: _opened ? 0.5 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: tokens.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroMultiSelectDropdown extends StatefulWidget {
  const _FiltroMultiSelectDropdown({
    required this.width,
    required this.label,
    required this.displayValue,
    required this.tooltip,
    required this.icon,
    required this.selectedKeys,
    required this.allLabel,
    required this.itemIcon,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String displayValue;
  final String tooltip;
  final IconData icon;
  final Set<String> selectedKeys;
  final String allLabel;
  final IconData itemIcon;
  final List<_FiltroMultiSelectOption> options;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_FiltroMultiSelectDropdown> createState() =>
      _FiltroMultiSelectDropdownState();
}

class _FiltroMultiSelectDropdownState
    extends State<_FiltroMultiSelectDropdown> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _opened = false;
  bool _hovered = false;

  Future<void> _openMenu() async {
    final BuildContext? fieldContext = _fieldKey.currentContext;
    if (fieldContext == null) return;
    final RenderBox? renderBox = fieldContext.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final Offset offset = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _opened = true);
    final Set<String>? selected = await showMenu<Set<String>>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + renderBox.size.height + 8,
          renderBox.size.width,
          renderBox.size.height,
        ),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: renderBox.size.width,
        maxWidth: renderBox.size.width < 340 ? 340 : renderBox.size.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      elevation: 12,
      color: tokens.menuBackground,
      items: <PopupMenuEntry<Set<String>>>[
        _FiltroMultiSelectMenuEntry(
          title: widget.label,
          titleIcon: widget.icon,
          allLabel: widget.allLabel,
          itemIcon: widget.itemIcon,
          options: widget.options,
          selectedKeys: widget.selectedKeys,
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _opened = false);
    if (selected != null && !_sameStringSets(selected, widget.selectedKeys)) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.selectedKeys.isNotEmpty;
    final bool emphasized = _opened || _hovered || active;
    return SizedBox(
      key: _fieldKey,
      width: widget.width,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        value: widget.displayValue,
        child: Tooltip(
          message: widget.tooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        emphasized
                            ? tokens.hoverBackground
                            : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _opened
                              ? tokens.selectedBorder
                              : active
                              ? tokens.selectedBorder
                              : _hovered
                              ? tokens.selectedBorder.withValues(alpha: 0.52)
                              : tokens.cardBorder,
                      width: _opened ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(widget.icon, color: tokens.info, size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.displayValue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _opened ? 0.5 : 0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltroMultiSelectMenuEntry extends PopupMenuEntry<Set<String>> {
  const _FiltroMultiSelectMenuEntry({
    required this.title,
    required this.titleIcon,
    required this.allLabel,
    required this.itemIcon,
    required this.options,
    required this.selectedKeys,
  });

  final String title;
  final IconData titleIcon;
  final String allLabel;
  final IconData itemIcon;
  final List<_FiltroMultiSelectOption> options;
  final Set<String> selectedKeys;

  @override
  double get height {
    final int itemCount = options.length + 1;
    final double computed = 118 + (itemCount * 48);
    if (computed < 218) return 218;
    if (computed > 440) return 440;
    return computed;
  }

  @override
  bool represents(Set<String>? value) => false;

  @override
  State<_FiltroMultiSelectMenuEntry> createState() =>
      _FiltroMultiSelectMenuEntryState();
}

class _FiltroMultiSelectMenuEntryState
    extends State<_FiltroMultiSelectMenuEntry> {
  late final Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.selectedKeys);
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
    final String selectionText =
        _selection.isEmpty
            ? context.t('common.all', fallback: 'Todos')
            : context
                .t(
                  'atendimentoTecnico.filters.multiSelected',
                  fallback: '{count} selecionados',
                )
                .replaceAll('{count}', _selection.length.toString());

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
                Icon(widget.titleIcon, color: tokens.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.info.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selectionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.info,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _FiltroMultiSelectMenuTile(
                      label: widget.allLabel,
                      icon: Icons.select_all_rounded,
                      selected: _selection.isEmpty,
                      onTap: () => setState(_selection.clear),
                    ),
                    const SizedBox(height: 4),
                    ...widget.options.map(
                      (option) => _FiltroMultiSelectMenuTile(
                        label: option.label,
                        icon: widget.itemIcon,
                        count: option.count,
                        selected: _selection.contains(option.key),
                        onTap: () => _toggle(option.key),
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
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: Text(context.t('common.clear', fallback: 'Limpar')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(Set<String>.from(_selection)),
                  child: Text(context.t('common.apply', fallback: 'Aplicar')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroMultiSelectMenuTile extends StatelessWidget {
  const _FiltroMultiSelectMenuTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: tokens.selectedBorder) : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                size: 18,
                color: selected ? tokens.info : tokens.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? tokens.info : tokens.primaryText,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroMultiSelectOption {
  const _FiltroMultiSelectOption({
    required this.key,
    required this.label,
    this.count,
  });

  final String key;
  final String label;
  final int? count;
}

bool _sameStringSets(Set<String> first, Set<String> second) {
  return first.length == second.length && first.containsAll(second);
}

class _TecnicoFiltroDropdown extends StatefulWidget {
  const _TecnicoFiltroDropdown({
    required this.width,
    required this.label,
    required this.displayValue,
    required this.tooltip,
    required this.icon,
    required this.selectedKey,
    required this.todosKey,
    required this.options,
    required this.onChanged,
    this.todosLabel = 'Todos os técnicos',
    this.todosIcon = Icons.groups_2_outlined,
    this.itemIcon = Icons.engineering_outlined,
  });

  final double width;
  final String label;
  final String displayValue;
  final String tooltip;
  final IconData icon;
  final String? selectedKey;
  final String todosKey;
  final List<_TecnicoFiltroOption> options;
  final ValueChanged<String> onChanged;
  final String todosLabel;
  final IconData todosIcon;
  final IconData itemIcon;

  @override
  State<_TecnicoFiltroDropdown> createState() => _TecnicoFiltroDropdownState();
}

class _TecnicoFiltroDropdownState extends State<_TecnicoFiltroDropdown> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _opened = false;
  bool _hovered = false;

  Future<void> _openMenu() async {
    final fieldContext = _fieldKey.currentContext;
    if (fieldContext == null) return;
    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + renderBox.size.height + 8,
        renderBox.size.width,
        renderBox.size.height,
      ),
      Offset.zero & overlay.size,
    );
    final tokens = WebThemeTokens.of(context);

    setState(() => _opened = true);
    final selected = await showMenu<String>(
      context: context,
      position: position,
      constraints: BoxConstraints.tightFor(width: renderBox.size.width),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 12,
      color: tokens.menuBackground,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: widget.todosKey,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: _TecnicoFiltroMenuItem(
            label: widget.todosLabel,
            icon: widget.todosIcon,
            selected: widget.selectedKey == null,
            tokens: tokens,
          ),
        ),
        if (widget.options.isNotEmpty) const PopupMenuDivider(height: 8),
        ...widget.options.map(
          (option) => PopupMenuItem<String>(
            value: option.key,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: _TecnicoFiltroMenuItem(
              label: option.label,
              icon: widget.itemIcon,
              selected: widget.selectedKey == option.key,
              tokens: tokens,
            ),
          ),
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _opened = false);
    final currentKey = widget.selectedKey ?? widget.todosKey;
    if (selected != null && selected != currentKey) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final bool active = widget.selectedKey != null;
    final bool emphasized = _opened || _hovered || active;
    return SizedBox(
      key: _fieldKey,
      width: widget.width,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        value: widget.displayValue,
        child: Tooltip(
          message: widget.tooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        emphasized
                            ? tokens.hoverBackground
                            : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _opened
                              ? tokens.selectedBorder
                              : active
                              ? tokens.selectedBorder
                              : _hovered
                              ? tokens.selectedBorder.withValues(alpha: 0.52)
                              : tokens.cardBorder,
                      width: _opened ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(widget.icon, color: tokens.info, size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.displayValue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _opened ? 0.5 : 0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TecnicoFiltroMenuItem extends StatelessWidget {
  const _TecnicoFiltroMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tokens,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: selected ? tokens.info : tokens.secondaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? tokens.info : tokens.primaryText,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: Icon(Icons.check_rounded, size: 18, color: tokens.info),
          ),
        ],
      ),
    );
  }
}

class _TecnicoFiltroOption {
  const _TecnicoFiltroOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _StatusFiltroOption {
  const _StatusFiltroOption({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class _ListaAtendimentosState {
  const _ListaAtendimentosState({
    required this.dominios,
    required this.atendimentos,
    required this.tecnicos,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
  final List<ColaboradorUsuarioResumo> tecnicos;
}
