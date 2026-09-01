import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/catalogo_publico_service.dart';
import 'package:sixpos/core/services/catalogo_reserva_service.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/data/models/catalogo_reserva_model.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/screens/catalogo_publico_personalizacao_web.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

class CatalogoReservasWebPage extends StatefulWidget {
  const CatalogoReservasWebPage({super.key});

  @override
  State<CatalogoReservasWebPage> createState() =>
      _CatalogoReservasWebPageState();
}

class _CatalogoReservasWebPageState extends State<CatalogoReservasWebPage> {
  static const String _periodoHoje = 'Hoje';
  static const String _periodoProximos7Dias = 'Próximos 7 dias';
  static const String _periodoEsteMes = 'Este mês';
  static const String _periodoProximoMes = 'Próximo mês';
  static const String _periodoIntervaloPersonalizado =
      'Intervalo personalizado';
  static const List<String> _periodosFiltroData = <String>[
    _periodoHoje,
    _periodoProximos7Dias,
    _periodoEsteMes,
    _periodoProximoMes,
    _periodoIntervaloPersonalizado,
  ];

  final CatalogoReservaService _service = CatalogoReservaService();
  final CatalogoPublicoService _catalogoPublicoService =
      CatalogoPublicoService();
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  CatalogoReservaPaginaModel? _pagina;
  CatalogoReservaDetalheModel? _detalhe;
  CatalogoPublicoConfiguracaoModel? _configuracaoCatalogoVirtual;
  Set<CatalogoReservaStatus> _filtrosStatus = <CatalogoReservaStatus>{};
  DateTimeRange? _filtroPeriodo;
  String _periodoSelecionado = _periodoProximos7Dias;
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String? _idSelecionado;
  String? _erro;
  bool _carregando = true;
  bool _carregandoDetalhe = false;
  bool _atualizandoStatus = false;
  bool _convertendo = false;
  bool _abrindoCatalogoVirtual = false;
  bool _carregandoConfiguracaoCatalogoVirtual = true;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;

  List<_CatalogoReservaDropdownOption<CatalogoReservaStatus>>
  _statusDropdownOptions(BuildContext context) {
    return CatalogoReservaStatus.values
        .map(
          (CatalogoReservaStatus status) =>
              _CatalogoReservaDropdownOption<CatalogoReservaStatus>(
                value: status,
                label: _statusLabel(context, status),
                enabled: status != CatalogoReservaStatus.convertida,
              ),
        )
        .toList(growable: false);
  }

  List<_CatalogoReservaDropdownOption<CatalogoReservaStatus>>
  _statusFilterOptions(BuildContext context) {
    return CatalogoReservaStatus.values
        .map(
          (CatalogoReservaStatus status) =>
              _CatalogoReservaDropdownOption<CatalogoReservaStatus>(
                value: status,
                label: _statusLabel(context, status),
              ),
        )
        .toList(growable: false);
  }

  List<_CatalogoReservaDropdownOption<String>> _periodFilterOptions(
    BuildContext context,
  ) {
    return _periodosFiltroData
        .map(
          (String periodo) => _CatalogoReservaDropdownOption<String>(
            value: periodo,
            label: _periodoFiltroLabel(context, periodo),
          ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final DateTime hoje = _hojeNormalizado();
    _dataInicioPersonalizada = DateTime(hoje.year, hoje.month, 1);
    _dataFimPersonalizada = hoje;
    _filtroPeriodo = _resolverPeriodoSelecionado();
    Future<void>.microtask(() async {
      await _restaurarPreferenciasCatalogoReservas();
      await _restaurarPreferenciasCatalogoReservasBackend();
      await _carregar();
    });
    Future<void>.microtask(_carregarConfiguracaoCatalogoVirtual);
  }

  Future<void> _carregar({int pagina = 0, String? selecionarId}) async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final CatalogoReservaPaginaModel resultado = await _service.listar(
        status: _filtrosStatus.length == 1 ? _filtrosStatus.first : null,
        pagina: pagina,
      );
      final List<CatalogoReservaResumoModel> reservasFiltradas =
          _filtrarReservas(resultado.reservas);
      if (!mounted) return;
      final String? proximoId = _resolverIdSelecionado(
        reservasFiltradas,
        selecionarId ?? _idSelecionado,
      );
      setState(() {
        _pagina = resultado;
        _idSelecionado = proximoId;
        _detalhe = null;
        _carregando = false;
      });
      if (proximoId != null) {
        await _carregarDetalhe(proximoId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _abrirCatalogoVirtual() async {
    if (_abrindoCatalogoVirtual || _carregandoConfiguracaoCatalogoVirtual) {
      return;
    }
    setState(() => _abrindoCatalogoVirtual = true);
    try {
      await openCatalogoVirtualWeb(
        context,
        service: _catalogoPublicoService,
        initialConfiguration: _configuracaoCatalogoVirtual,
      );
      await _carregarConfiguracaoCatalogoVirtual(mostrarCarregamento: false);
    } finally {
      if (mounted) setState(() => _abrindoCatalogoVirtual = false);
    }
  }

  Future<void> _carregarConfiguracaoCatalogoVirtual({
    bool mostrarCarregamento = true,
  }) async {
    if (mostrarCarregamento && mounted) {
      setState(() => _carregandoConfiguracaoCatalogoVirtual = true);
    }
    try {
      final CatalogoPublicoConfiguracaoModel configuration =
          await loadCatalogoVirtualWebConfiguration(
            service: _catalogoPublicoService,
          );
      if (!mounted) return;
      setState(() => _configuracaoCatalogoVirtual = configuration);
    } catch (_) {
      if (!mounted) return;
      setState(() => _configuracaoCatalogoVirtual = null);
    } finally {
      if (mounted) {
        setState(() => _carregandoConfiguracaoCatalogoVirtual = false);
      }
    }
  }

  String? _resolverIdSelecionado(
    List<CatalogoReservaResumoModel> reservas,
    String? candidato,
  ) {
    if (candidato != null &&
        reservas.any(
          (CatalogoReservaResumoModel item) => item.idReserva == candidato,
        )) {
      return candidato;
    }
    return reservas.isEmpty ? null : reservas.first.idReserva;
  }

  Future<void> _carregarDetalhe(String idReserva) async {
    setState(() {
      _idSelecionado = idReserva;
      _carregandoDetalhe = true;
      _erro = null;
    });
    try {
      final CatalogoReservaDetalheModel detalhe = await _service.consultar(
        idReserva,
      );
      if (!mounted || _idSelecionado != idReserva) return;
      setState(() {
        _detalhe = detalhe;
        _carregandoDetalhe = false;
      });
    } catch (error) {
      if (!mounted || _idSelecionado != idReserva) return;
      setState(() {
        _erro = error.toString();
        _carregandoDetalhe = false;
      });
    }
  }

  Future<void> _atualizarStatus(CatalogoReservaStatus status) async {
    final CatalogoReservaDetalheModel? detalhe = _detalhe;
    if (detalhe == null || _atualizandoStatus || detalhe.status == status) {
      return;
    }
    setState(() {
      _atualizandoStatus = true;
      _erro = null;
    });
    try {
      final CatalogoReservaDetalheModel atualizado = await _service
          .atualizarStatus(idReserva: detalhe.idReserva, status: status);
      if (!mounted) return;
      setState(() => _detalhe = atualizado);
      await _carregar(
        pagina: _pagina?.pagina ?? 0,
        selecionarId: atualizado.idReserva,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = error.toString());
    } finally {
      if (mounted) setState(() => _atualizandoStatus = false);
    }
  }

  Future<void> _converterEmVenda() async {
    final CatalogoReservaDetalheModel? detalhe = _detalhe;
    if (detalhe == null || _convertendo) return;

    final bool confirmado =
        await showDialog<bool>(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: Text(
                  context.t(
                    'catalogReservations.convert.confirmTitle',
                    fallback: 'Converter reserva em venda?',
                  ),
                ),
                content: Text(
                  context.t(
                    'catalogReservations.convert.confirmMessage',
                    fallback:
                        'O estoque será validado e os itens serão enviados para uma venda a receber.',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      context.t('common.cancel', fallback: 'Cancelar'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.t(
                        'catalogReservations.convert.action',
                        fallback: 'Converter em venda',
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmado || !mounted) return;

    setState(() {
      _convertendo = true;
      _erro = null;
    });
    try {
      final CatalogoReservaConversaoModel conversao = await _service
          .converterEmVenda(detalhe.idReserva);
      if (!mounted) return;
      await _carregar(
        pagina: _pagina?.pagina ?? 0,
        selecionarId: conversao.idReserva,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'catalogReservations.convert.success',
              fallback: 'Reserva convertida em venda a receber.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErroConversao(error));
    } finally {
      if (mounted) setState(() => _convertendo = false);
    }
  }

  String _mensagemErroConversao(Object error) {
    if (error is CatalogoReservaServiceException) {
      return switch (error.codigo) {
        'ESTOQUE_INSUFICIENTE_PARA_RESERVA' => context.t(
          'catalogReservations.convert.error.stock',
          fallback: 'Estoque insuficiente para converter esta reserva.',
        ),
        'RESERVA_PRECISA_ESTAR_CONFIRMADA' => context.t(
          'catalogReservations.convert.error.confirmedOnly',
          fallback: 'Confirme a reserva antes de convertê-la em venda.',
        ),
        'CONVERSAO_RESERVA_EM_ANDAMENTO' => context.t(
          'catalogReservations.convert.error.processing',
          fallback: 'Esta reserva já está sendo convertida. Atualize a tela.',
        ),
        'VENDA_RESERVA_RECEBIMENTO_NAO_CONFIGURADO' => context.t(
          'catalogReservations.convert.error.paymentConfig',
          fallback:
              'Configure um tipo de recebimento futuro antes da conversão.',
        ),
        'PRODUTO_RESERVA_NAO_DISPONIVEL' => context.t(
          'catalogReservations.convert.error.product',
          fallback: 'Um dos produtos reservados não está mais disponível.',
        ),
        _ => context.t(
          'catalogReservations.convert.error.generic',
          fallback: 'Não foi possível converter a reserva em venda.',
        ),
      };
    }
    return context.t(
      'catalogReservations.convert.error.generic',
      fallback: 'Não foi possível converter a reserva em venda.',
    );
  }

  void _alterarFiltroStatus(Set<CatalogoReservaStatus> status) {
    if (setEquals(_filtrosStatus, status)) return;
    setState(() => _filtrosStatus = Set<CatalogoReservaStatus>.from(status));
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasCatalogoReservas();
    }
    _carregar();
  }

  bool get _usaPeriodoPersonalizado =>
      _periodoSelecionado == _periodoIntervaloPersonalizado;

  void _selecionarPeriodoFiltro(String? periodo) {
    if (periodo == null || !_periodosFiltroData.contains(periodo)) return;
    if (_periodoSelecionado == periodo) return;
    setState(() {
      _periodoSelecionado = periodo;
      if (_usaPeriodoPersonalizado) {
        _ajustarPeriodoPersonalizadoSeguro();
      }
      _filtroPeriodo = _resolverPeriodoSelecionado();
    });
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasCatalogoReservas();
    }
    _sincronizarSelecaoComFiltros();
  }

  Future<void> _selecionarDataInicioPersonalizada() async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: _dataInicioPersonalizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: context.t(
        'catalogReservations.filters.date.startHelpText',
        fallback: 'Selecionar data inicial',
      ),
    );
    if (selecionada == null || !mounted) return;
    setState(() {
      _dataInicioPersonalizada = _normalizarData(selecionada)!;
      _ajustarPeriodoPersonalizadoSeguro();
      _filtroPeriodo = _resolverPeriodoSelecionado();
    });
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasCatalogoReservas();
    }
    _sincronizarSelecaoComFiltros();
  }

  Future<void> _selecionarDataFimPersonalizada() async {
    final DateTime inicio = _normalizarData(_dataInicioPersonalizada)!;
    final DateTime limite = _limiteFimPeriodoPersonalizado(inicio);
    final DateTime fimAtual = _normalizarData(_dataFimPersonalizada)!;
    final DateTime initialDate =
        fimAtual.isBefore(inicio)
            ? inicio
            : (fimAtual.isAfter(limite) ? limite : fimAtual);
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: inicio,
      lastDate: limite,
      helpText: context.t(
        'catalogReservations.filters.date.endHelpText',
        fallback: 'Selecionar data final',
      ),
    );
    if (selecionada == null || !mounted) return;
    setState(() {
      _dataFimPersonalizada = _normalizarData(selecionada)!;
      _ajustarPeriodoPersonalizadoSeguro();
      _filtroPeriodo = _resolverPeriodoSelecionado();
    });
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasCatalogoReservas();
    }
    _sincronizarSelecaoComFiltros();
  }

  void _limparFiltros() {
    if (_filtrosStatus.isEmpty &&
        _periodoSelecionado == _periodoProximos7Dias) {
      return;
    }
    final DateTime hoje = _hojeNormalizado();
    setState(() {
      _filtrosStatus = <CatalogoReservaStatus>{};
      _periodoSelecionado = _periodoProximos7Dias;
      _dataInicioPersonalizada = DateTime(hoje.year, hoje.month, 1);
      _dataFimPersonalizada = hoje;
      _filtroPeriodo = _resolverPeriodoSelecionado();
    });
    if (!_aplicandoPreferencias) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasCatalogoReservas();
    }
    _carregar();
  }

  Future<void> _restaurarPreferenciasCatalogoReservas() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
      return;
    }
    _aplicarPreferenciasCatalogoReservas(
      preferencias.catalogoReservasFiltrosWeb,
    );
  }

  Future<void> _restaurarPreferenciasCatalogoReservasBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
        return;
      }
      _aplicarPreferenciasCatalogoReservas(
        preferencias.catalogoReservasFiltrosWeb,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar preferencias das reservas do catálogo: '
        '$error\n$stackTrace',
      );
    }
  }

  void _aplicarPreferenciasCatalogoReservas(
    CatalogoReservasFiltrosWebPreferencia filtros,
  ) {
    final Set<CatalogoReservaStatus> statusSelecionados =
        filtros.status
            .map(_statusFromPreferenceCode)
            .whereType<CatalogoReservaStatus>()
            .toSet();

    _aplicandoPreferencias = true;
    setState(() {
      _filtrosStatus = statusSelecionados;
      _periodoSelecionado = _periodoLabelPreferencia(filtros.periodo);
      if (filtros.periodo ==
          CatalogoReservasPeriodoWebPreferencia.personalizado) {
        if (filtros.dataInicio != null) {
          _dataInicioPersonalizada = filtros.dataInicio!;
        }
        if (filtros.dataFim != null) {
          _dataFimPersonalizada = filtros.dataFim!;
        }
        _ajustarPeriodoPersonalizadoSeguro();
      }
      _filtroPeriodo = _resolverPeriodoSelecionado();
    });
    _aplicandoPreferencias = false;
  }

  void _salvarPreferenciasCatalogoReservas() {
    final List<String> status = _filtrosStatus
      .map((CatalogoReservaStatus item) => item.apiValue)
      .toSet()
      .toList(growable: false)..sort();

    final CatalogoReservasFiltrosWebPreferencia filtros =
        CatalogoReservasFiltrosWebPreferencia(
          status: status,
          periodo: _periodoPreferenciaAtual(),
          dataInicio:
              _usaPeriodoPersonalizado
                  ? _normalizarData(_dataInicioPersonalizada)
                  : null,
          dataFim:
              _usaPeriodoPersonalizado
                  ? _normalizarData(_dataFimPersonalizada)
                  : null,
        );

    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            catalogoReservasFiltrosWeb: filtros.toJson(),
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar preferencias das reservas do catálogo: '
              '$error\n$stackTrace',
            );
          }),
    );
  }

  Future<void> _sincronizarSelecaoComFiltros() async {
    final CatalogoReservaPaginaModel? pagina = _pagina;
    if (pagina == null) return;
    final List<CatalogoReservaResumoModel> reservasFiltradas = _filtrarReservas(
      pagina.reservas,
    );
    final String? proximoId = _resolverIdSelecionado(
      reservasFiltradas,
      _idSelecionado,
    );
    final bool mudouSelecao = proximoId != _idSelecionado;
    if (!mounted) return;
    setState(() {
      _idSelecionado = proximoId;
      if (mudouSelecao) {
        _detalhe = null;
      }
      if (proximoId == null) {
        _carregandoDetalhe = false;
      }
    });
    if (mudouSelecao && proximoId != null) {
      await _carregarDetalhe(proximoId);
    }
  }

  bool get _temFiltrosAtivos =>
      _filtrosStatus.isNotEmpty || _periodoSelecionado != _periodoProximos7Dias;

  List<CatalogoReservaResumoModel> _filtrarReservas(
    List<CatalogoReservaResumoModel> reservas,
  ) {
    return reservas.where(_reservaCombinaFiltros).toList(growable: false);
  }

  bool _reservaCombinaFiltros(CatalogoReservaResumoModel reserva) {
    if (_filtrosStatus.isNotEmpty && !_filtrosStatus.contains(reserva.status)) {
      return false;
    }
    if (_filtroPeriodo != null) {
      final DateTime? criadaEm = reserva.criadaEm;
      final DateTime? dataReserva = _normalizarData(criadaEm);
      if (criadaEm == null ||
          dataReserva == null ||
          !_periodoContemData(_filtroPeriodo!, dataReserva)) {
        return false;
      }
    }
    return true;
  }

  String _statusFiltroLabel(BuildContext context) {
    if (_filtrosStatus.isEmpty) {
      return context.t('common.all', fallback: 'Todos');
    }
    if (_filtrosStatus.length == 1) {
      return _statusLabel(context, _filtrosStatus.first);
    }
    return context
        .t(
          'catalogReservations.filters.status.selectedCount',
          fallback: '{count} selecionados',
        )
        .replaceAll('{count}', _filtrosStatus.length.toString());
  }

  String _dataFiltroLabel(
    BuildContext context,
    LocaleSettingsProvider regionalizacao,
  ) {
    if (_usaPeriodoPersonalizado) {
      return '${regionalizacao.formatDate(_dataInicioPersonalizada)} '
          '${context.t('common.rangeTo', fallback: 'a')} '
          '${regionalizacao.formatDate(_dataFimPersonalizada)}';
    }
    return _periodoFiltroLabel(context, _periodoSelecionado);
  }

  String _periodoFiltroLabel(BuildContext context, String periodo) {
    switch (periodo) {
      case _periodoHoje:
        return context.t(
          'catalogReservations.filters.date.today',
          fallback: 'Hoje',
        );
      case _periodoProximos7Dias:
        return context.t(
          'catalogReservations.filters.date.next7Days',
          fallback: 'Próximos 7 dias',
        );
      case _periodoEsteMes:
        return context.t(
          'catalogReservations.filters.date.thisMonth',
          fallback: 'Este mês',
        );
      case _periodoProximoMes:
        return context.t(
          'catalogReservations.filters.date.nextMonth',
          fallback: 'Próximo mês',
        );
      case _periodoIntervaloPersonalizado:
        return context.t(
          'catalogReservations.filters.date.customRange',
          fallback: 'Intervalo personalizado',
        );
      default:
        return periodo;
    }
  }

  String _periodoLabelPreferencia(
    CatalogoReservasPeriodoWebPreferencia periodo,
  ) {
    switch (periodo) {
      case CatalogoReservasPeriodoWebPreferencia.hoje:
        return _periodoHoje;
      case CatalogoReservasPeriodoWebPreferencia.proximos7Dias:
        return _periodoProximos7Dias;
      case CatalogoReservasPeriodoWebPreferencia.esteMes:
        return _periodoEsteMes;
      case CatalogoReservasPeriodoWebPreferencia.proximoMes:
        return _periodoProximoMes;
      case CatalogoReservasPeriodoWebPreferencia.personalizado:
        return _periodoIntervaloPersonalizado;
    }
  }

  CatalogoReservasPeriodoWebPreferencia _periodoPreferenciaAtual() {
    switch (_periodoSelecionado) {
      case _periodoHoje:
        return CatalogoReservasPeriodoWebPreferencia.hoje;
      case _periodoEsteMes:
        return CatalogoReservasPeriodoWebPreferencia.esteMes;
      case _periodoProximoMes:
        return CatalogoReservasPeriodoWebPreferencia.proximoMes;
      case _periodoIntervaloPersonalizado:
        return CatalogoReservasPeriodoWebPreferencia.personalizado;
      case _periodoProximos7Dias:
        return CatalogoReservasPeriodoWebPreferencia.proximos7Dias;
      default:
        return CatalogoReservasPeriodoWebPreferencia.proximos7Dias;
    }
  }

  CatalogoReservaStatus? _statusFromPreferenceCode(String code) {
    final String normalizado = code.trim().toUpperCase();
    for (final CatalogoReservaStatus status in CatalogoReservaStatus.values) {
      if (status.apiValue == normalizado) {
        return status;
      }
    }
    return null;
  }

  DateTime? _normalizarData(DateTime? value) {
    if (value == null) return null;
    final DateTime base = value.toLocal();
    return DateTime(base.year, base.month, base.day);
  }

  DateTime _hojeNormalizado() => _normalizarData(DateTime.now())!;

  DateTimeRange _resolverPeriodoSelecionado() {
    final DateTime base = _hojeNormalizado();
    switch (_periodoSelecionado) {
      case _periodoHoje:
        return DateTimeRange(start: base, end: base);
      case _periodoEsteMes:
        return DateTimeRange(
          start: DateTime(base.year, base.month, 1),
          end: DateTime(base.year, base.month + 1, 0),
        );
      case _periodoProximoMes:
        return DateTimeRange(
          start: DateTime(base.year, base.month + 1, 1),
          end: DateTime(base.year, base.month + 2, 0),
        );
      case _periodoIntervaloPersonalizado:
        return DateTimeRange(
          start: _normalizarData(_dataInicioPersonalizada)!,
          end: _normalizarData(_dataFimPersonalizada)!,
        );
      case _periodoProximos7Dias:
        return DateTimeRange(
          start: base,
          end: base.add(const Duration(days: 7)),
        );
      default:
        return DateTimeRange(
          start: base,
          end: base.add(const Duration(days: 7)),
        );
    }
  }

  DateTime _limiteFimPeriodoPersonalizado(DateTime inicio) {
    final DateTime inicioNormalizado = _normalizarData(inicio)!;
    final DateTime limite = DateTime(
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

  void _ajustarPeriodoPersonalizadoSeguro() {
    _dataInicioPersonalizada = _normalizarData(_dataInicioPersonalizada)!;
    _dataFimPersonalizada = _normalizarData(_dataFimPersonalizada)!;
    if (_dataFimPersonalizada.isBefore(_dataInicioPersonalizada)) {
      _dataFimPersonalizada = _dataInicioPersonalizada;
    }
    final DateTime limite = _limiteFimPeriodoPersonalizado(
      _dataInicioPersonalizada,
    );
    if (_dataFimPersonalizada.isAfter(limite)) {
      _dataFimPersonalizada = limite;
    }
  }

  bool _periodoContemData(DateTimeRange periodo, DateTime data) {
    return !data.isBefore(periodo.start) && !data.isAfter(periodo.end);
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          _buildHeader(context, tokens),
          Expanded(child: _buildBody(context, tokens)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      decoration: BoxDecoration(
        color: tokens.headerBackground,
        border: Border(bottom: BorderSide(color: tokens.headerBorder)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.bookmarks_outlined, color: tokens.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'catalogReservations.title',
                    fallback: 'Reservas do catálogo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t(
                    'catalogReservations.subtitle',
                    fallback:
                        'Acompanhe solicitações recebidas pelo catálogo virtual.',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed:
                    _abrindoCatalogoVirtual ||
                            _carregandoConfiguracaoCatalogoVirtual
                        ? null
                        : _abrirCatalogoVirtual,
                icon:
                    _abrindoCatalogoVirtual ||
                            _carregandoConfiguracaoCatalogoVirtual
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.storefront_outlined, size: 18),
                label: Text(
                  context.t(
                    _configuracaoCatalogoVirtual?.ativo == false
                        ? 'catalogReservations.configureCatalog'
                        : 'catalogReservations.openCatalog',
                    fallback: _configuracaoCatalogoVirtual?.ativo == false
                        ? 'Configurar catálogo virtual'
                        : 'Ver catálogo virtual',
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    _carregando
                        ? null
                        : () => _carregar(
                          pagina: _pagina?.pagina ?? 0,
                          selecionarId: _idSelecionado,
                        ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  context.t('common.refresh', fallback: 'Atualizar'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.info,
                  backgroundColor: tokens.surfaceMuted.withValues(alpha: 0.35),
                  side: BorderSide(color: tokens.selectedBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WebThemeTokens tokens) {
    if (_carregando && _pagina == null) {
      return _buildReservationsLoading(tokens);
    }

    if (_erro != null && _pagina == null) {
      return _buildError(context, tokens);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 860;
        final Widget lista = _buildListPanel(context, tokens);
        final Widget detalhe = _buildDetailPanel(context, tokens);
        if (compacto) {
          return Column(
            children: <Widget>[
              Expanded(child: lista),
              if (_idSelecionado != null)
                SizedBox(height: constraints.maxHeight * 0.48, child: detalhe),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 430, child: lista),
            VerticalDivider(width: 1, color: tokens.divider),
            Expanded(child: detalhe),
          ],
        );
      },
    );
  }

  Widget _buildReservationsLoading(WebThemeTokens tokens) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 860;
        final Widget lista = _buildListLoading(tokens);
        final Widget detalhe = _buildDetailLoading(tokens);

        if (compacto) {
          return lista;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 430, child: lista),
            VerticalDivider(width: 1, color: tokens.divider),
            Expanded(child: detalhe),
          ],
        );
      },
    );
  }

  Widget _buildListLoading(WebThemeTokens tokens) {
    return ColoredBox(
      color: tokens.surface,
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SixWebLoadingBlock(height: 94, highlight: true),
            SizedBox(height: 14),
            SixWebLoadingBlock(height: 104),
            SizedBox(height: 10),
            SixWebLoadingBlock(height: 104),
            SizedBox(height: 10),
            SixWebLoadingBlock(height: 104),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLoading(WebThemeTokens tokens) {
    return ColoredBox(
      color: tokens.workspaceBackground,
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SixWebLoadingBlock(height: 72, highlight: true),
            SizedBox(height: 20),
            SixWebLoadingBlock(height: 112),
            SizedBox(height: 18),
            SixWebLoadingBlock(height: 104),
            SizedBox(height: 18),
            SixWebLoadingBlock(height: 92),
          ],
        ),
      ),
    );
  }

  Widget _buildListPanel(BuildContext context, WebThemeTokens tokens) {
    final CatalogoReservaPaginaModel pagina =
        _pagina ??
        const CatalogoReservaPaginaModel(
          reservas: <CatalogoReservaResumoModel>[],
          pagina: 0,
          tamanho: 20,
          totalPaginas: 0,
          totalElementos: 0,
        );
    final List<CatalogoReservaResumoModel> reservasFiltradas = _filtrarReservas(
      pagina.reservas,
    );
    return Container(
      color: tokens.surface,
      child: Column(
        children: <Widget>[
          _buildFilters(context, tokens),
          if (_erro != null)
            _buildInlineError(context, tokens)
          else if (reservasFiltradas.isEmpty)
            Expanded(child: _buildEmpty(context, tokens))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: reservasFiltradas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  return _buildReservaCard(
                    context,
                    tokens,
                    reservasFiltradas[index],
                  );
                },
              ),
            ),
          _buildPagination(context, tokens, pagina),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WebThemeTokens tokens) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double filterSpacing = 10;
            final bool usarUmaColuna = constraints.maxWidth < 520;
            double larguraCampoFiltro;
            if (usarUmaColuna) {
              larguraCampoFiltro = constraints.maxWidth;
            } else {
              larguraCampoFiltro = (constraints.maxWidth - filterSpacing) / 2;
              if (larguraCampoFiltro < 220) {
                larguraCampoFiltro = 220;
              } else if (larguraCampoFiltro > 320) {
                larguraCampoFiltro = 320;
              }
            }
            return Wrap(
              spacing: filterSpacing,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: larguraCampoFiltro,
                  child: _CatalogoReservaMultiSelectDropdown<
                    CatalogoReservaStatus
                  >(
                    label: context.t(
                      'catalogReservations.status',
                      fallback: 'Status',
                    ),
                    valueLabel: _statusFiltroLabel(context),
                    icon: Icons.flag_outlined,
                    options: _statusFilterOptions(context),
                    selectedValues: _filtrosStatus,
                    allLabel: context.t('common.all', fallback: 'Todos'),
                    cancelLabel: context.t(
                      'common.cancel',
                      fallback: 'Cancelar',
                    ),
                    clearLabel: context.t('common.clear', fallback: 'Limpar'),
                    applyLabel: context.t(
                      'catalogReservations.filters.apply',
                      fallback: 'Aplicar',
                    ),
                    onChanged: _alterarFiltroStatus,
                  ),
                ),
                SizedBox(
                  width: larguraCampoFiltro,
                  child: _CatalogoReservaPeriodDropdown(
                    label: context.t(
                      'catalogReservations.filters.period',
                      fallback: 'Período',
                    ),
                    valueLabel: _dataFiltroLabel(context, regionalizacao),
                    options: _periodFilterOptions(context),
                    selectedValue: _periodoSelecionado,
                    onChanged: _selecionarPeriodoFiltro,
                  ),
                ),
                if (_usaPeriodoPersonalizado) ...<Widget>[
                  SizedBox(
                    width: larguraCampoFiltro,
                    child: _CatalogoReservaDateField(
                      label: context.t(
                        'catalogReservations.filters.start',
                        fallback: 'Início',
                      ),
                      value: regionalizacao.formatDate(
                        _dataInicioPersonalizada,
                      ),
                      onTap: _selecionarDataInicioPersonalizada,
                    ),
                  ),
                  SizedBox(
                    width: larguraCampoFiltro,
                    child: _CatalogoReservaDateField(
                      label: context.t(
                        'catalogReservations.filters.end',
                        fallback: 'Fim',
                      ),
                      value: regionalizacao.formatDate(_dataFimPersonalizada),
                      onTap: _selecionarDataFimPersonalizada,
                    ),
                  ),
                ],
                if (_temFiltrosAtivos)
                  TextButton.icon(
                    onPressed: _limparFiltros,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: Text(
                      context.t(
                        'catalogReservations.filters.clear',
                        fallback: 'Limpar filtros',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.secondaryText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservaCard(
    BuildContext context,
    WebThemeTokens tokens,
    CatalogoReservaResumoModel reserva,
  ) {
    final bool selecionada = reserva.idReserva == _idSelecionado;
    final Color statusColor = _statusColor(tokens, reserva.status);
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return Material(
      color: selecionada ? tokens.selectedBackground : tokens.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _carregarDetalhe(reserva.idReserva),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionada ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      reserva.nomeCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusBadge(
                    _statusLabel(context, reserva.status),
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(regionalizacao, reserva.criadaEm),
                style: TextStyle(color: tokens.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: tokens.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${reserva.quantidadeTotal} ${context.t('catalogReservations.items', fallback: 'itens')}',
                    style: TextStyle(color: tokens.secondaryText),
                  ),
                  const Spacer(),
                  Text(
                    regionalizacao.formatCurrency(reserva.valorTotal),
                    style: TextStyle(
                      color: tokens.financialPositive,
                      fontWeight: FontWeight.w900,
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

  Widget _buildDetailPanel(BuildContext context, WebThemeTokens tokens) {
    if (_idSelecionado == null) {
      return _buildEmpty(context, tokens);
    }
    if (_carregandoDetalhe || _detalhe == null) {
      return _buildDetailLoading(tokens);
    }

    final CatalogoReservaDetalheModel detalhe = _detalhe!;
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return Container(
      color: tokens.workspaceBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          'catalogReservations.detailTitle',
                          fallback: 'Detalhes da reserva',
                        ),
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${_idReservaCurto(detalhe.idReserva)}',
                        style: TextStyle(color: tokens.mutedText),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: _CatalogoReservaDropdown<CatalogoReservaStatus>(
                    label: context.t(
                      'catalogReservations.status',
                      fallback: 'Status',
                    ),
                    value: detalhe.status,
                    valueLabel: _statusLabel(context, detalhe.status),
                    options: _statusDropdownOptions(context),
                    enabled:
                        !_atualizandoStatus &&
                        !_convertendo &&
                        detalhe.status != CatalogoReservaStatus.convertida,
                    onSelected: _atualizarStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoCard(
              tokens,
              icon: Icons.person_outline_rounded,
              title: detalhe.cliente.nome,
              lines: <String>[
                if (detalhe.cliente.telefone.isNotEmpty)
                  detalhe.cliente.telefone,
                if (detalhe.cliente.email.isNotEmpty) detalhe.cliente.email,
                _formatDateTime(regionalizacao, detalhe.criadaEm),
              ],
            ),
            const SizedBox(height: 18),
            _buildConversionCard(context, tokens, regionalizacao, detalhe),
            const SizedBox(height: 18),
            Text(
              context.t(
                'catalogReservations.products',
                fallback: 'Produtos reservados',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final CatalogoReservaItemModel item in detalhe.itens)
              _buildItem(context, tokens, regionalizacao, item),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '${detalhe.quantidadeTotal} ${context.t('catalogReservations.items', fallback: 'itens')}',
                    style: TextStyle(color: tokens.secondaryText),
                  ),
                  const Spacer(),
                  Text(
                    regionalizacao.formatCurrency(detalhe.valorTotal),
                    style: TextStyle(
                      color: tokens.financialPositive,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.t('catalogReservations.notes', fallback: 'Observação'),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalhe.observacao.isEmpty
                  ? context.t(
                    'catalogReservations.noNotes',
                    fallback: 'Nenhuma observação informada.',
                  )
                  : detalhe.observacao,
              style: TextStyle(color: tokens.secondaryText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    CatalogoReservaDetalheModel detalhe,
  ) {
    final bool convertida = detalhe.status == CatalogoReservaStatus.convertida;
    final bool podeConverter =
        detalhe.status == CatalogoReservaStatus.confirmada;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            convertida
                ? tokens.success.withValues(alpha: 0.08)
                : tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              convertida
                  ? tokens.success.withValues(alpha: 0.35)
                  : tokens.cardBorder,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  convertida
                      ? Icons.check_circle_outline_rounded
                      : Icons.point_of_sale_outlined,
                  color: convertida ? tokens.success : tokens.info,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          convertida
                              ? 'catalogReservations.convert.convertedTitle'
                              : 'catalogReservations.convert.title',
                          fallback:
                              convertida
                                  ? 'Venda criada'
                                  : 'Converter em venda',
                        ),
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        convertida
                            ? '${context.t('catalogReservations.convert.saleId', fallback: 'Venda')} #${_idReservaCurto(detalhe.idOperacaoVenda)}${detalhe.convertidaEm == null ? '' : ' • ${_formatDateTime(regionalizacao, detalhe.convertidaEm)}'}'
                            : context.t(
                              'catalogReservations.convert.description',
                              fallback:
                                  'Valida o estoque e cria uma venda a receber com estes produtos.',
                            ),
                        style: TextStyle(
                          color: tokens.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!convertida)
            FilledButton.icon(
              onPressed:
                  podeConverter && !_convertendo ? _converterEmVenda : null,
              icon:
                  _convertendo
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.point_of_sale_outlined),
              label: Text(
                context.t(
                  _convertendo
                      ? 'catalogReservations.convert.processing'
                      : 'catalogReservations.convert.action',
                  fallback:
                      _convertendo ? 'Convertendo...' : 'Converter em venda',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    CatalogoReservaItemModel item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.quantidade}×',
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nomeProduto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.modeloProduto.isNotEmpty)
                  Text(
                    item.modeloProduto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.mutedText, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            regionalizacao.formatCurrency(item.valorTotal),
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(
    BuildContext context,
    WebThemeTokens tokens,
    CatalogoReservaPaginaModel pagina,
  ) {
    final int paginaExibida = pagina.totalPaginas == 0 ? 0 : pagina.pagina + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed:
                pagina.pagina > 0
                    ? () => _carregar(pagina: pagina.pagina - 1)
                    : null,
            tooltip: context.t(
              'catalogReservations.previous',
              fallback: 'Página anterior',
            ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '$paginaExibida / ${pagina.totalPaginas}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed:
                pagina.pagina + 1 < pagina.totalPaginas
                    ? () => _carregar(pagina: pagina.pagina + 1)
                    : null,
            tooltip: context.t(
              'catalogReservations.next',
              fallback: 'Próxima página',
            ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 42),
            const SizedBox(height: 12),
            Text(
              context.t(
                'catalogReservations.error',
                fallback: 'Não foi possível carregar as reservas.',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _carregar(),
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

  Widget _buildInlineError(BuildContext context, WebThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _carregar(),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(Icons.refresh_rounded, color: tokens.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t(
                      'catalogReservations.error',
                      fallback: 'Não foi possível carregar as reservas.',
                    ),
                    style: TextStyle(color: tokens.danger),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, color: tokens.mutedText, size: 44),
            const SizedBox(height: 12),
            Text(
              context.t(
                'catalogReservations.empty',
                fallback: 'Nenhuma reserva encontrada.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    WebThemeTokens tokens, {
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tokens.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                for (final String line in lines.where(
                  (String item) => item.isNotEmpty,
                ))
                  Text(line, style: TextStyle(color: tokens.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, CatalogoReservaStatus status) {
    return switch (status) {
      CatalogoReservaStatus.recebida => context.t(
        'catalogReservations.status.received',
        fallback: 'Recebida',
      ),
      CatalogoReservaStatus.emAnalise => context.t(
        'catalogReservations.status.analysis',
        fallback: 'Em análise',
      ),
      CatalogoReservaStatus.confirmada => context.t(
        'catalogReservations.status.confirmed',
        fallback: 'Confirmada',
      ),
      CatalogoReservaStatus.cancelada => context.t(
        'catalogReservations.status.cancelled',
        fallback: 'Cancelada',
      ),
      CatalogoReservaStatus.convertida => context.t(
        'catalogReservations.status.converted',
        fallback: 'Convertida em venda',
      ),
    };
  }

  Color _statusColor(WebThemeTokens tokens, CatalogoReservaStatus status) {
    return switch (status) {
      CatalogoReservaStatus.recebida => tokens.info,
      CatalogoReservaStatus.emAnalise => tokens.warning,
      CatalogoReservaStatus.confirmada => tokens.success,
      CatalogoReservaStatus.cancelada => tokens.danger,
      CatalogoReservaStatus.convertida => tokens.financialPositive,
    };
  }

  String _formatDateTime(
    LocaleSettingsProvider regionalizacao,
    DateTime? value,
  ) {
    if (value == null) return '';
    final DateTime local = value.toLocal();
    return '${regionalizacao.formatDate(local)} • ${regionalizacao.formatTime(local)}';
  }

  String _idReservaCurto(String idReserva) {
    return idReserva.length <= 12 ? idReserva : idReserva.substring(0, 12);
  }
}

class _CatalogoReservaDropdownOption<T> {
  const _CatalogoReservaDropdownOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

class _CatalogoReservaFilterTrigger extends StatefulWidget {
  const _CatalogoReservaFilterTrigger({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.open = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool enabled;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_CatalogoReservaFilterTrigger> createState() =>
      _CatalogoReservaFilterTriggerState();
}

class _CatalogoReservaFilterTriggerState
    extends State<_CatalogoReservaFilterTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.enabled && (widget.open || _hovered);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: widget.value,
      child: AnimatedOpacity(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        opacity: widget.enabled ? 1 : 0.6,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Tooltip(
            message: widget.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.enabled ? widget.onTap : null,
                child: AnimatedContainer(
                  duration: WebThemeTokens.transitionDuration,
                  curve: WebThemeTokens.transitionCurve,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                  decoration: BoxDecoration(
                    color:
                        active ? tokens.surfaceMuted : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? tokens.selectedBorder : tokens.cardBorder,
                      width: active ? 1.4 : 1,
                    ),
                    boxShadow:
                        active
                            ? <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: active ? tokens.info : tokens.secondaryText,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: tokens.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: widget.open ? 0.5 : 0,
                        duration: WebThemeTokens.transitionDuration,
                        curve: WebThemeTokens.transitionCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: active ? tokens.info : tokens.secondaryText,
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

class _CatalogoReservaMultiSelectDropdown<T> extends StatefulWidget {
  const _CatalogoReservaMultiSelectDropdown({
    required this.label,
    required this.valueLabel,
    required this.options,
    required this.selectedValues,
    required this.allLabel,
    required this.cancelLabel,
    required this.clearLabel,
    required this.applyLabel,
    required this.onChanged,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final String valueLabel;
  final List<_CatalogoReservaDropdownOption<T>> options;
  final Set<T> selectedValues;
  final String allLabel;
  final String cancelLabel;
  final String clearLabel;
  final String applyLabel;
  final ValueChanged<Set<T>> onChanged;
  final IconData? icon;
  final bool enabled;

  @override
  State<_CatalogoReservaMultiSelectDropdown<T>> createState() =>
      _CatalogoReservaMultiSelectDropdownState<T>();
}

class _CatalogoReservaMultiSelectDropdownState<T>
    extends State<_CatalogoReservaMultiSelectDropdown<T>> {
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.options.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _open = true);
    final Set<T>? selected = await showMenu<Set<T>>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      color: tokens.menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width < 320 ? 320 : fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: <PopupMenuEntry<Set<T>>>[
        _CatalogoReservaMultiSelectMenuEntry<T>(
          label: widget.label,
          icon: widget.icon,
          options: widget.options,
          selectedValues: widget.selectedValues,
          allLabel: widget.allLabel,
          cancelLabel: widget.cancelLabel,
          clearLabel: widget.clearLabel,
          applyLabel: widget.applyLabel,
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && !setEquals(selected, widget.selectedValues)) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogoReservaFilterTrigger(
      label: widget.label,
      value: widget.valueLabel,
      icon: widget.icon,
      enabled: widget.enabled,
      open: _open,
      onTap: _openMenu,
    );
  }
}

class _CatalogoReservaMultiSelectMenuEntry<T> extends PopupMenuEntry<Set<T>> {
  const _CatalogoReservaMultiSelectMenuEntry({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.allLabel,
    required this.cancelLabel,
    required this.clearLabel,
    required this.applyLabel,
    this.icon,
  });

  final String label;
  final List<_CatalogoReservaDropdownOption<T>> options;
  final Set<T> selectedValues;
  final String allLabel;
  final String cancelLabel;
  final String clearLabel;
  final String applyLabel;
  final IconData? icon;

  @override
  double get height {
    final int itemCount = options.length + 1;
    final double computed = 112 + (itemCount * 46);
    if (computed < 214) return 214;
    if (computed > 420) return 420;
    return computed;
  }

  @override
  bool represents(Set<T>? value) => false;

  @override
  State<_CatalogoReservaMultiSelectMenuEntry<T>> createState() =>
      _CatalogoReservaMultiSelectMenuEntryState<T>();
}

class _CatalogoReservaMultiSelectMenuEntryState<T>
    extends State<_CatalogoReservaMultiSelectMenuEntry<T>> {
  late final Set<T> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set<T>.from(widget.selectedValues);
  }

  void _toggle(T value) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  widget.icon ?? Icons.filter_alt_outlined,
                  color: tokens.info,
                  size: 18,
                ),
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
                  _selection.isEmpty
                      ? widget.allLabel
                      : _selection.length.toString(),
                  style: TextStyle(
                    color: tokens.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _CatalogoReservaMultiSelectMenuTile(
                      label: widget.allLabel,
                      selected: _selection.isEmpty,
                      onTap: () => setState(_selection.clear),
                    ),
                    const SizedBox(height: 4),
                    for (final _CatalogoReservaDropdownOption<T> option
                        in widget.options) ...<Widget>[
                      _CatalogoReservaMultiSelectMenuTile(
                        label: option.label,
                        selected: _selection.contains(option.value),
                        enabled: option.enabled,
                        onTap:
                            option.enabled ? () => _toggle(option.value) : null,
                      ),
                      const SizedBox(height: 4),
                    ],
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
                  child: Text(widget.cancelLabel),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: Text(widget.clearLabel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      () => Navigator.of(context).pop(Set<T>.from(_selection)),
                  child: Text(widget.applyLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogoReservaMultiSelectMenuTile extends StatelessWidget {
  const _CatalogoReservaMultiSelectMenuTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color:
                    selected ? tokens.selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected ? tokens.info : tokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogoReservaPeriodDropdown extends StatefulWidget {
  const _CatalogoReservaPeriodDropdown({
    required this.label,
    required this.valueLabel,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final List<_CatalogoReservaDropdownOption<String>> options;
  final String selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  State<_CatalogoReservaPeriodDropdown> createState() =>
      _CatalogoReservaPeriodDropdownState();
}

class _CatalogoReservaPeriodDropdownState
    extends State<_CatalogoReservaPeriodDropdown> {
  bool _open = false;

  Future<void> _openMenu() async {
    if (widget.options.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _open = true);
    final String? selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      color: tokens.menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.options
          .map(
            (_CatalogoReservaDropdownOption<String> option) =>
                PopupMenuItem<String>(
                  value: option.value,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: _CatalogoReservaFilterMenuItem(
                    label: option.label,
                    selected: option.value == widget.selectedValue,
                  ),
                ),
          )
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.selectedValue) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogoReservaFilterTrigger(
      label: widget.label,
      value: widget.valueLabel,
      icon: Icons.calendar_today_outlined,
      open: _open,
      onTap: _openMenu,
    );
  }
}

class _CatalogoReservaDateField extends StatelessWidget {
  const _CatalogoReservaDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CatalogoReservaFilterTrigger(
      label: label,
      value: value,
      icon: Icons.event_outlined,
      onTap: onTap,
    );
  }
}

class _CatalogoReservaFilterMenuItem extends StatelessWidget {
  const _CatalogoReservaFilterMenuItem({
    required this.label,
    required this.selected,
  });

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

class _CatalogoReservaDropdown<T> extends StatefulWidget {
  const _CatalogoReservaDropdown({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.options,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final T value;
  final String valueLabel;
  final List<_CatalogoReservaDropdownOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  State<_CatalogoReservaDropdown<T>> createState() =>
      _CatalogoReservaDropdownState<T>();
}

class _CatalogoReservaDropdownState<T>
    extends State<_CatalogoReservaDropdown<T>> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.options.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _open = true);
    final T? selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      color: tokens.menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.options
          .map((_CatalogoReservaDropdownOption<T> option) {
            final bool selected = option.value == widget.value;
            final ThemeData theme = Theme.of(context);

            return PopupMenuItem<T>(
              value: option.enabled ? option.value : null,
              enabled: option.enabled,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Opacity(
                opacity: option.enabled ? 1 : 0.55,
                child: Row(
                  children: <Widget>[
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: selected ? tokens.info : tokens.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.enabled && (_hovered || _open);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: widget.valueLabel,
      child: AnimatedOpacity(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        opacity: widget.enabled ? 1 : 0.6,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Tooltip(
            message: widget.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.enabled ? _openMenu : null,
                child: AnimatedContainer(
                  duration: WebThemeTokens.transitionDuration,
                  curve: WebThemeTokens.transitionCurve,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                  decoration: BoxDecoration(
                    color:
                        active ? tokens.surfaceMuted : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? tokens.selectedBorder : tokens.cardBorder,
                      width: active ? 1.4 : 1,
                    ),
                    boxShadow:
                        active
                            ? <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: tokens.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.valueLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: WebThemeTokens.transitionDuration,
                        curve: WebThemeTokens.transitionCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: active ? tokens.info : tokens.secondaryText,
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
