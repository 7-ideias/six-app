import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/web/six_web_animated_dialog.dart';
import '../theme/web_theme_tokens.dart';
import 'produto_lista_sub_painel_web.dart';

Future<bool> showAtendimentoTecnicoEditarDialog({
  required BuildContext context,
  required AtendimentoTecnicoModel atendimento,
  AtendimentoTecnicoService? service,
  ClienteUsuarioApiClient? clienteApiClient,
  ColaboradorUsuarioApiClient? colaboradorApiClient,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showSixWebAnimatedDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: context.t(
      'atendimentoTecnico.edit.dialogBarrierLabel',
      fallback: 'Fechar edição do atendimento técnico',
    ),
    overlayColor: const Color(0xBF0A1324),
    overlayBlurSigma: 12,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 320),
    builder:
        (_) => AtendimentoTecnicoEditarDialog(
          atendimento: atendimento,
          service: service,
          clienteApiClient: clienteApiClient,
          colaboradorApiClient: colaboradorApiClient,
        ),
  );

  return result ?? false;
}

class AtendimentoTecnicoEditarDialog extends StatefulWidget {
  const AtendimentoTecnicoEditarDialog({
    super.key,
    required this.atendimento,
    this.service,
    this.clienteApiClient,
    this.colaboradorApiClient,
  });

  final AtendimentoTecnicoModel atendimento;
  final AtendimentoTecnicoService? service;
  final ClienteUsuarioApiClient? clienteApiClient;
  final ColaboradorUsuarioApiClient? colaboradorApiClient;

  @override
  State<AtendimentoTecnicoEditarDialog> createState() =>
      _AtendimentoTecnicoEditarDialogState();
}

class _AtendimentoTecnicoEditarDialogState
    extends State<AtendimentoTecnicoEditarDialog> {
  late final AtendimentoTecnicoService _service =
      widget.service ?? AtendimentoTecnicoService();
  late final ClienteUsuarioApiClient _clienteApiClient =
      widget.clienteApiClient ?? HttpClienteUsuarioApiClient();
  late final ColaboradorUsuarioApiClient _colaboradorApiClient =
      widget.colaboradorApiClient ?? HttpColaboradorUsuarioApiClient();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tipoEquipamentoController =
      TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _acessoriosController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _observacaoAuditoriaController =
      TextEditingController();

  late DateTime _validadeOrcamentoEm;
  late DateTime _validadeOrcamentoOriginalEm;
  late DateTime _dataVencimentoEm;
  late DateTime _dataEntregaPrevista;
  final List<_AtendimentoItemEditavel> _itens = <_AtendimentoItemEditavel>[];
  List<_ClienteAtendimentoWeb> _clientes = const <_ClienteAtendimentoWeb>[];
  List<_ResponsavelTecnicoWeb> _responsaveis = const <_ResponsavelTecnicoWeb>[];
  _ClienteAtendimentoWeb? _clienteSelecionado;
  _ResponsavelTecnicoWeb? _responsavelSelecionado;
  bool _salvando = false;
  bool _carregandoClientes = false;
  bool _carregandoResponsaveis = false;
  bool _exibindoModalErro = false;

  @override
  void initState() {
    super.initState();
    final atendimento = widget.atendimento;
    final equipamento = atendimento.equipamento;
    _clienteSelecionado = _clienteInicial(atendimento);
    _clientes = <_ClienteAtendimentoWeb>[
      if (_clienteSelecionado != null) _clienteSelecionado!,
    ];
    _responsavelSelecionado = _responsavelInicial(atendimento);
    _descricaoController.text = atendimento.descricao ?? '';
    _tipoEquipamentoController.text = equipamento?.tipo ?? '';
    _marcaController.text = equipamento?.marca ?? '';
    _modeloController.text = equipamento?.modelo ?? '';
    _numeroSerieController.text = equipamento?.numeroSerie ?? '';
    _imeiController.text = equipamento?.imei ?? '';
    _acessoriosController.text =
        equipamento?.acessorios ?? equipamento?.observacoesEntrada ?? '';
    _defeitoController.text = atendimento.defeitoRelatado ?? '';
    _diagnosticoController.text = atendimento.diagnosticoTecnico ?? '';
    _validadeOrcamentoEm = _normalizarData(
      atendimento.validadeOrcamentoEm ??
          DateTime.now().add(const Duration(days: 7)),
    );
    _validadeOrcamentoOriginalEm = _validadeOrcamentoEm;
    _dataVencimentoEm = _normalizarData(
      atendimento.dataVencimentoEm ??
          atendimento.validadeOrcamentoEm ??
          DateTime.now().add(const Duration(days: 7)),
    );
    _dataEntregaPrevista = _normalizarData(
      atendimento.dataEntregaPrevista ??
          atendimento.validadeOrcamentoEm ??
          DateTime.now().add(const Duration(days: 7)),
    );
    _itens.addAll(atendimento.itens.map(_AtendimentoItemEditavel.fromModel));
    _carregarClientes();
    _carregarResponsaveis();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _tipoEquipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _imeiController.dispose();
    _acessoriosController.dispose();
    _defeitoController.dispose();
    _diagnosticoController.dispose();
    _observacaoAuditoriaController.dispose();
    super.dispose();
  }

  DateTime _normalizarData(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  Future<void> _carregarClientes() async {
    setState(() => _carregandoClientes = true);
    try {
      final ClienteUsuarioListResponse response =
          await _clienteApiClient.listarClientesUsuario();
      final List<_ClienteAtendimentoWeb> clientes =
          response.clientes
              .where((ClienteUsuario cliente) => cliente.ativo)
              .map(_ClienteAtendimentoWeb.fromCliente)
              .toList();

      final _ClienteAtendimentoWeb? clienteAtual = _clienteSelecionado;
      if (clienteAtual != null &&
          !clientes.any(
            (_ClienteAtendimentoWeb item) => item.id == clienteAtual.id,
          )) {
        clientes.insert(0, clienteAtual);
      }

      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _clienteSelecionado = _resolverClienteSelecionado(clientes);
        _carregandoClientes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoClientes = false);
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.clientsLoadError',
          'Não foi possível carregar os clientes.',
        ),
      );
    }
  }

  _ClienteAtendimentoWeb? _clienteInicial(AtendimentoTecnicoModel atendimento) {
    final String id = atendimento.idCliente?.trim() ?? '';
    final String nome = atendimento.nomeClienteSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ClienteAtendimentoWeb(
      id: id,
      nome: nome.isEmpty ? 'Cliente não informado' : nome,
      subtitulo:
          id.isEmpty ? 'Snapshot do atendimento' : 'Cliente do atendimento',
      nomeInformado: nome.isNotEmpty,
    );
  }

  _ClienteAtendimentoWeb? _resolverClienteSelecionado(
    List<_ClienteAtendimentoWeb> clientes,
  ) {
    if (clientes.isEmpty) return null;
    final _ClienteAtendimentoWeb? atual = _clienteSelecionado;
    if (atual == null) return null;
    for (final _ClienteAtendimentoWeb cliente in clientes) {
      if (cliente.id == atual.id) return cliente;
    }
    return clientes.first;
  }

  Future<void> _carregarResponsaveis() async {
    setState(() => _carregandoResponsaveis = true);
    try {
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApiClient.listarTecnicosAssistenciaTecnica();
      final List<_ResponsavelTecnicoWeb> responsaveis = _montarResponsaveis(
        colaboradores,
      );
      if (!mounted) return;
      setState(() {
        _responsaveis = responsaveis;
        _responsavelSelecionado = _resolverResponsavelSelecionado(responsaveis);
        _carregandoResponsaveis = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoResponsaveis = false);
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.techniciansLoadError',
          'Não foi possível carregar os técnicos autorizados.',
        ),
      );
    }
  }

  _ResponsavelTecnicoWeb? _responsavelInicial(
    AtendimentoTecnicoModel atendimento,
  ) {
    final String id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ResponsavelTecnicoWeb(
      id: id,
      nome: nome.isEmpty ? 'Responsável não informado' : nome,
      subtitulo:
          id.isEmpty ? 'Snapshot do atendimento' : 'Responsável do atendimento',
    );
  }

  _ResponsavelTecnicoWeb? _resolverResponsavelSelecionado(
    List<_ResponsavelTecnicoWeb> responsaveis,
  ) {
    if (responsaveis.isEmpty) return null;
    final _ResponsavelTecnicoWeb? atual = _responsavelSelecionado;
    if (atual == null) return responsaveis.first;
    for (final _ResponsavelTecnicoWeb responsavel in responsaveis) {
      if (responsavel.id == atual.id) return responsavel;
    }
    return responsaveis.first;
  }

  List<_ResponsavelTecnicoWeb> _montarResponsaveis(
    List<ColaboradorUsuarioResumo> colaboradores,
  ) {
    final Map<String, _ResponsavelTecnicoWeb> mapa =
        <String, _ResponsavelTecnicoWeb>{};

    void add(_ResponsavelTecnicoWeb responsavel) {
      final String key =
          responsavel.id.trim().isNotEmpty
              ? responsavel.id.trim()
              : responsavel.nome.toLowerCase().trim();
      if (key.isEmpty || mapa.containsKey(key)) return;
      mapa[key] = responsavel;
    }

    for (final ColaboradorUsuarioResumo colaborador in colaboradores) {
      if (!colaborador.ehTecnicoAssistenciaTecnica) continue;
      final String id =
          colaborador.idUnicoPessoal.trim().isNotEmpty
              ? colaborador.idUnicoPessoal.trim()
              : colaborador.email.trim();
      final String nome =
          colaborador.nomeDeGuerra.trim().isNotEmpty
              ? colaborador.nomeDeGuerra.trim()
              : colaborador.nome.trim().isNotEmpty
              ? colaborador.nome.trim()
              : colaborador.email.trim();
      if (id.isEmpty && nome.isEmpty) continue;

      final String subtitulo = <String>[
        'Técnico autorizado',
        colaborador.email,
        colaborador.celularDeAcesso,
      ].where((String item) => item.trim().isNotEmpty).join(' • ');

      add(
        _ResponsavelTecnicoWeb(
          id: id.isEmpty ? nome : id,
          nome: nome.isEmpty ? 'Técnico autorizado' : nome,
          subtitulo: subtitulo,
        ),
      );
    }

    return mapa.values.toList(growable: false);
  }

  Future<void> _selecionarValidade() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final selecionada = await _showThemedDatePicker(
      context: context,
      initialDate:
          _validadeOrcamentoEm.isBefore(inicio) ? inicio : _validadeOrcamentoEm,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
      helpText: 'Validade do orçamento',
    );
    if (selecionada == null) return;
    setState(() {
      _validadeOrcamentoEm = _normalizarData(selecionada);
    });
  }

  Future<void> _selecionarVencimentoFinanceiro() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final selecionada = await _showThemedDatePicker(
      context: context,
      initialDate:
          _dataVencimentoEm.isBefore(inicio) ? inicio : _dataVencimentoEm,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 3650)),
      helpText: 'Vencimento financeiro',
    );
    if (selecionada == null) return;
    setState(() {
      _dataVencimentoEm = _normalizarData(selecionada);
    });
  }

  Future<void> _selecionarDataEntregaPrevista() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final primeiraData = DateTime(2000);
    final selecionada = await _showThemedDatePicker(
      context: context,
      initialDate:
          _dataEntregaPrevista.isBefore(primeiraData)
              ? primeiraData
              : _dataEntregaPrevista,
      firstDate: primeiraData,
      lastDate: inicio.add(const Duration(days: 3650)),
      helpText: 'Entrega prevista',
    );
    if (selecionada == null) return;
    setState(() {
      _dataEntregaPrevista = _normalizarData(selecionada);
    });
  }

  Future<void> _abrirSelecaoItens(String tipoInicial) async {
    final result = await showProdutoListaSelecaoWebDialog<dynamic>(
      context: context,
      permitirSelecaoMultipla: true,
      tipoInicial: tipoInicial,
      widthFactor: 0.88,
      heightFactor: 0.86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    );

    if (!mounted || result == null) return;
    final produtos =
        result is List
            ? result.whereType<ProdutoModel>().toList(growable: false)
            : <ProdutoModel>[if (result is ProdutoModel) result];
    if (produtos.isEmpty) return;
    setState(() {
      for (final produto in produtos) {
        _adicionarProduto(produto);
      }
    });
  }

  Future<void> _abrirSelecaoCliente() async {
    if (_carregandoClientes) {
      _mostrarMensagem(
        _t('atendimentoTecnico.edit.loadingClients', 'Carregando clientes.'),
      );
      return;
    }
    if (_clientes.isEmpty) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.noClients',
          'Nenhum cliente disponível para seleção.',
        ),
      );
      return;
    }

    final _ClienteAtendimentoWeb? cliente =
        await showDialog<_ClienteAtendimentoWeb>(
          context: context,
          builder: (BuildContext context) {
            return _ClienteAtendimentoEditarWebDialog(
              clientes: _clientes,
              clienteSelecionado: _clienteSelecionado,
            );
          },
        );

    if (cliente == null || !mounted) return;
    setState(() => _clienteSelecionado = cliente);
  }

  void _adicionarProduto(ProdutoModel produto) {
    final tipoCodigo = _ehServico(produto) ? 'SERVICE' : 'PRODUCT';
    final chave =
        '$tipoCodigo:${produto.id ?? produto.codigoDeBarras}:${produto.nomeProduto}';
    final index = _itens.indexWhere((item) => item.chave == chave);
    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }
    _itens.add(
      _AtendimentoItemEditavel(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto,
        tipoCodigo: tipoCodigo,
        quantidade: 1,
        valorUnitario: produto.precoVenda,
        idTecnicoResponsavel: _responsavelSelecionado?.id,
        nomeTecnicoResponsavel: _responsavelSelecionado?.nome,
      ),
    );
  }

  bool _ehServico(ProdutoModel produto) {
    final tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  void _alterarQuantidade(_AtendimentoItemEditavel item, int delta) {
    setState(() {
      final index = _itens.indexWhere((element) => element.chave == item.chave);
      if (index < 0) return;
      final quantidade = _itens[index].quantidade + delta;
      if (quantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: quantidade);
    });
  }

  void _removerItem(_AtendimentoItemEditavel item) {
    setState(
      () => _itens.removeWhere((element) => element.chave == item.chave),
    );
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final validadeAlterada =
        !_mesmaData(_validadeOrcamentoEm, _validadeOrcamentoOriginalEm);
    if (validadeAlterada && _validadeOrcamentoEm.isBefore(inicioHoje)) {
      _mostrarMensagem(
        'A validade do orçamento não pode ser anterior à data atual.',
      );
      return;
    }
    if (_dataVencimentoEm.isBefore(inicioHoje)) {
      _mostrarMensagem(
        'O vencimento financeiro não pode ser anterior à data atual.',
      );
      return;
    }
    final _ClienteAtendimentoWeb? cliente = _clienteSelecionado;
    if (cliente == null) {
      _mostrarMensagem('Selecione um cliente antes de salvar.');
      return;
    }
    final String? idCliente = _textoOuNulo(cliente.id);
    final String? nomeClienteSnapshot =
        cliente.nomeInformado ? _textoOuNulo(cliente.nome) : null;
    final _ResponsavelTecnicoWeb? responsavel = _responsavelSelecionado;
    final bool responsavelAlterado = _responsavelTecnicoAlterado(responsavel);

    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.atendimento.id,
        dataVencimentoEm: _dataVencimentoEm,
        input: AtendimentoTecnicoUpdateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          dataEntregaPrevista: _dataEntregaPrevista,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: idCliente,
          nomeClienteSnapshot: nomeClienteSnapshot,
          idTecnicoResponsavel: responsavel?.id,
          nomeTecnicoResponsavelSnapshot: responsavel?.nome,
          equipamento: AtendimentoTecnicoEquipamentoModel(
            tipo: _textoOuNulo(_tipoEquipamentoController.text),
            marca: _textoOuNulo(_marcaController.text),
            modelo: _textoOuNulo(_modeloController.text),
            numeroSerie: _textoOuNulo(_numeroSerieController.text),
            imei: _textoOuNulo(_imeiController.text),
            acessorios: _textoOuNulo(_acessoriosController.text),
            observacoesEntrada: _textoOuNulo(_acessoriosController.text),
          ),
          defeitoRelatado: _textoOuNulo(_defeitoController.text),
          diagnosticoTecnico: _textoOuNulo(_diagnosticoController.text),
          itens: _itens
              .map((item) => item.toInput(responsavel: responsavel))
              .toList(growable: false),
          observacaoAuditoria: _montarObservacaoAuditoria(
            observacaoDigitada: _observacaoAuditoriaController.text,
            responsavel: responsavel,
            responsavelAlterado: responsavelAlterado,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AtendimentoTecnicoApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_resolverMensagemErroAtualizacao(error));
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.genericSaveError',
          'Não foi possível salvar as alterações agora. Revise os dados e tente novamente.',
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _textoOuNulo(String value) {
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _responsavelTecnicoAlterado(_ResponsavelTecnicoWeb? responsavel) {
    final String atualId =
        widget.atendimento.idTecnicoResponsavel?.trim() ?? '';
    final String atualNome =
        widget.atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    final String novoId = responsavel?.id.trim() ?? '';
    final String novoNome = responsavel?.nome.trim() ?? '';
    return atualId != novoId || atualNome != novoNome;
  }

  String? _montarObservacaoAuditoria({
    required String observacaoDigitada,
    required _ResponsavelTecnicoWeb? responsavel,
    required bool responsavelAlterado,
  }) {
    final String textoBase = observacaoDigitada.trim();
    if (!responsavelAlterado) {
      return textoBase.isEmpty ? null : textoBase;
    }

    final String anterior =
        widget.atendimento.nomeTecnicoResponsavelSnapshot?.trim().isNotEmpty ==
                true
            ? widget.atendimento.nomeTecnicoResponsavelSnapshot!.trim()
            : _t(
              'atendimentoTecnico.edit.unassignedResponsible',
              'Sem responsável anterior',
            );
    final String atual =
        responsavel?.nome.trim().isNotEmpty == true
            ? responsavel!.nome.trim()
            : _t(
              'atendimentoTecnico.edit.unassignedResponsibleCurrent',
              'Sem responsável definido',
            );
    final String notaTecnica =
        'Responsável técnico alterado de "$anterior" para "$atual".';

    if (textoBase.isEmpty) {
      return notaTecnica;
    }

    return '$notaTecnica $textoBase';
  }

  String _formatarData(DateTime value) {
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarMoeda(double value) =>
      context.read<LocaleSettingsProvider>().formatCurrency(value);

  Future<DateTime?> _showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    final ThemeData baseTheme = Theme.of(context);
    final ThemeData themedBase = WebThemeTokens.applyTo(baseTheme);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final bool dark = themedBase.colorScheme.brightness == Brightness.dark;
    final ColorScheme colorScheme =
        dark
            ? themedBase.colorScheme.copyWith(
              surface: tokens.surfaceElevated,
              onSurface: tokens.primaryText,
              onSurfaceVariant: tokens.secondaryText,
              primary: accent,
              onPrimary: Colors.white,
              outline: tokens.cardBorder,
            )
            : themedBase.colorScheme;

    final ThemeData pickerTheme = themedBase.copyWith(
      colorScheme: colorScheme,
      dividerColor: tokens.divider,
      dialogTheme: themedBase.dialogTheme.copyWith(
        backgroundColor: tokens.surface,
      ),
      datePickerTheme: themedBase.datePickerTheme.copyWith(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor:
            dark ? tokens.surface : accent.withValues(alpha: 0.08),
        headerForegroundColor: tokens.primaryText,
        weekdayStyle: themedBase.textTheme.bodySmall?.copyWith(
          color: tokens.secondaryText,
          fontWeight: FontWeight.w700,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.mutedText;
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return tokens.primaryText;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.transparent;
        }),
        dayOverlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return accent.withValues(alpha: 0.12);
          }
          return null;
        }),
        todayForegroundColor: WidgetStatePropertyAll<Color>(accent),
        todayBorder: BorderSide(color: accent.withValues(alpha: 0.72)),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: accent),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: accent),
        yearForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return tokens.primaryText;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.transparent;
        }),
        rangeSelectionBackgroundColor: accent.withValues(alpha: 0.16),
        rangePickerBackgroundColor: tokens.surface,
      ),
    );

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: pickerTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  String _resolverMensagemErroAtualizacao(
    AtendimentoTecnicoApiException error,
  ) {
    final String mensagemNegocio = _extrairMensagemNegocio(error.body);
    if (mensagemNegocio.isNotEmpty) {
      return mensagemNegocio;
    }

    if (error.statusCode == 400 ||
        error.statusCode == 409 ||
        error.statusCode == 422) {
      return _t(
        'atendimentoTecnico.edit.businessSaveError',
        'Não foi possível salvar porque os dados informados não atendem às regras do atendimento.',
      );
    }

    return _t(
      'atendimentoTecnico.edit.genericSaveError',
      'Não foi possível salvar as alterações agora. Revise os dados e tente novamente.',
    );
  }

  String _extrairMensagemNegocio(String body) {
    final String texto = body.trim();
    if (texto.isEmpty) return '';

    try {
      return _coletarMensagemErro(jsonDecode(texto)).trim();
    } catch (_) {
      return texto;
    }
  }

  String _coletarMensagemErro(dynamic value) {
    if (value is Map<String, dynamic>) {
      for (final String key in <String>[
        'message',
        'mensagem',
        'error',
        'erro',
        'detail',
        'details',
      ]) {
        final String nested = _coletarMensagemErro(value[key]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }

      for (final String key in <String>[
        'errors',
        'fieldErrors',
        'violations',
      ]) {
        final String nested = _coletarMensagemErro(value[key]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }

      for (final dynamic entry in value.values) {
        final String nested = _coletarMensagemErro(entry);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
      return '';
    }

    if (value is List) {
      for (final dynamic item in value) {
        final String nested = _coletarMensagemErro(item);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
      return '';
    }

    if (value is String) {
      final String texto = value.trim();
      if (texto.isEmpty) return '';
      if (texto.startsWith('{') || texto.startsWith('[')) {
        try {
          return _coletarMensagemErro(jsonDecode(texto));
        } catch (_) {
          return texto;
        }
      }
      return texto;
    }

    return '';
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted || _exibindoModalErro) return;

    _exibindoModalErro = true;
    final ThemeData theme = WebThemeTokens.applyTo(Theme.of(context));
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Theme(
          data: theme,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: tokens.surfaceElevated,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: tokens.cardBorder),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tokens.danger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: tokens.danger,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _t(
                              'atendimentoTecnico.edit.errorDialogTitle',
                              'Nao foi possivel concluir a edicao',
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: tokens.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mensagem,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: tokens.info,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_t('common.ok', 'Entendi')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _exibindoModalErro = false;
    });
  }

  void _cancelar() {
    if (_salvando) return;
    Navigator.of(context).pop(false);
  }

  double get _total =>
      _itens.fold<double>(0, (total, item) => total + item.total);

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = Theme.of(context);
    final ThemeData theme = WebThemeTokens.applyTo(baseTheme);
    final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Size size = MediaQuery.sizeOf(context);
    final double maxHeight = size.height > 96 ? size.height - 48 : size.height;
    final Color accent = tokens.info;
    final ThemeData dialogTheme = theme.copyWith(
      inputDecorationTheme: _buildInputDecorationTheme(theme, tokens),
      dividerTheme: theme.dividerTheme.copyWith(color: tokens.divider),
      textSelectionTheme: theme.textSelectionTheme.copyWith(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.24),
        selectionHandleColor: accent,
      ),
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancelar,
      },
      child: Focus(
        autofocus: true,
        child: Theme(
          data: dialogTheme,
          child: PopScope(
            canPop: !_salvando,
            child: Semantics(
              namesRoute: true,
              label: _t(
                'atendimentoTecnico.edit.dialogTitle',
                'Editar atendimento técnico',
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 980,
                  maxHeight: maxHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.34),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      key: const ValueKey<String>(
                        'atendimento-tecnico-edit-dialog',
                      ),
                      color: tokens.surfaceElevated,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
                          ),
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  16,
                                  18,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _AtendimentoTecnicoEditImpactIcon(
                                      accent: accent,
                                      reduceMotion: reduceMotion,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _t(
                                              'atendimentoTecnico.edit.dialogHeadline',
                                              'Editar ${widget.atendimento.numero}',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  color: tokens.primaryText,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.15,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _t(
                                              'atendimentoTecnico.edit.dialogSubtitle',
                                              'Revise dados, prazos e itens antes de salvar a nova versão do atendimento.',
                                            ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: tokens.secondaryText,
                                                  height: 1.45,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _t('common.close', 'Fechar'),
                                      onPressed: _salvando ? null : _cancelar,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: tokens.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  18,
                                ),
                                child: _buildSummary(theme, tokens),
                              ),
                              Divider(height: 1, color: tokens.divider),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.all(20),
                                  children: <Widget>[
                                    if (widget.atendimento.assinaturaAprovada ||
                                        widget.atendimento.requerNovaAssinatura)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: accent.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          _t(
                                            'atendimentoTecnico.edit.signatureWarning',
                                            'Ao salvar alterações de produtos, serviços, validade, entrega prevista, vencimento financeiro ou observações, esta versão do orçamento exigirá nova assinatura do cliente.',
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: tokens.secondaryText,
                                                fontWeight: FontWeight.w700,
                                                height: 1.45,
                                              ),
                                        ),
                                      ),
                                    _grid(<Widget>[
                                      TextField(
                                        controller: _descricaoController,
                                        decoration: InputDecoration(
                                          labelText: _t(
                                            'atendimentoTecnico.edit.internalDescription',
                                            'Descrição interna',
                                          ),
                                        ),
                                      ),
                                      _clienteSelectorField(theme, tokens),
                                      _responsavelSelectorField(theme, tokens),
                                      InkWell(
                                        onTap:
                                            _salvando
                                                ? null
                                                : _selecionarValidade,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              'atendimentoTecnico.edit.validityLabel',
                                              'Validade do orçamento',
                                            ),
                                            helperText: _t(
                                              'atendimentoTecnico.edit.validityHelper',
                                              'Prazo para aprovação do cliente.',
                                            ),
                                            suffixIcon: Icon(
                                              Icons.event_available_outlined,
                                              color: tokens.secondaryText,
                                            ),
                                          ),
                                          child: Text(
                                            _formatarData(_validadeOrcamentoEm),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: tokens.primaryText,
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap:
                                            _salvando
                                                ? null
                                                : _selecionarVencimentoFinanceiro,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              'atendimentoTecnico.edit.dueDateLabel',
                                              'Vencimento financeiro',
                                            ),
                                            helperText: _t(
                                              'atendimentoTecnico.edit.dueDateHelper',
                                              'Data usada na agenda financeira.',
                                            ),
                                            suffixIcon: Icon(
                                              Icons.event_note_outlined,
                                              color: tokens.secondaryText,
                                            ),
                                          ),
                                          child: Text(
                                            _formatarData(_dataVencimentoEm),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: tokens.primaryText,
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap:
                                            _salvando
                                                ? null
                                                : _selecionarDataEntregaPrevista,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              'atendimentoTecnico.edit.deliveryDateLabel',
                                              'Entrega prevista',
                                            ),
                                            helperText: _t(
                                              'atendimentoTecnico.edit.deliveryDateHelper',
                                              'Prazo operacional para término ou entrega.',
                                            ),
                                            suffixIcon: Icon(
                                              Icons
                                                  .assignment_turned_in_outlined,
                                              color: tokens.secondaryText,
                                            ),
                                          ),
                                          child: Text(
                                            _formatarData(_dataEntregaPrevista),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: tokens.primaryText,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _tipoEquipamentoController,
                                        decoration: InputDecoration(
                                          labelText: _t(
                                            'atendimentoTecnico.edit.equipmentType',
                                            'Tipo de equipamento',
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _marcaController,
                                        decoration: InputDecoration(
                                          labelText: _t(
                                            'common.brand',
                                            'Marca',
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _modeloController,
                                        decoration: InputDecoration(
                                          labelText: _t(
                                            'common.model',
                                            'Modelo',
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _numeroSerieController,
                                        decoration: InputDecoration(
                                          labelText: _t(
                                            'atendimentoTecnico.edit.serialNumber',
                                            'Número de série',
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _imeiController,
                                        decoration: const InputDecoration(
                                          labelText: 'IMEI',
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _acessoriosController,
                                      minLines: 2,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        labelText: _t(
                                          'atendimentoTecnico.edit.accessories',
                                          'Acessórios / observações de entrada',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _defeitoController,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: _t(
                                          'atendimentoTecnico.edit.defectReported',
                                          'Defeito relatado',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _diagnosticoController,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: _t(
                                          'atendimentoTecnico.edit.diagnosis',
                                          'Diagnóstico / novas observações técnicas',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller:
                                          _observacaoAuditoriaController,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: _t(
                                          'atendimentoTecnico.edit.auditObservation',
                                          'Observação de auditoria da alteração',
                                        ),
                                        hintText: _t(
                                          'atendimentoTecnico.edit.auditObservationHint',
                                          'Ex.: cliente solicitou incluir película e retirar limpeza interna',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            _t(
                                              'atendimentoTecnico.edit.itemsSection',
                                              'Produtos e serviços',
                                            ),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: tokens.primaryText,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed:
                                              _salvando
                                                  ? null
                                                  : () => _abrirSelecaoItens(
                                                    'PRODUTO',
                                                  ),
                                          icon: const Icon(
                                            Icons.inventory_2_outlined,
                                          ),
                                          label: Text(
                                            _t(
                                              'atendimentoTecnico.edit.addPart',
                                              'Adicionar peça',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          onPressed:
                                              _salvando
                                                  ? null
                                                  : () => _abrirSelecaoItens(
                                                    'SERVICO',
                                                  ),
                                          icon: const Icon(
                                            Icons.handyman_outlined,
                                          ),
                                          label: Text(
                                            _t(
                                              'atendimentoTecnico.edit.addService',
                                              'Adicionar serviço',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (_itens.isEmpty)
                                      Text(
                                        _t(
                                          'atendimentoTecnico.edit.noItems',
                                          'Nenhum item vinculado.',
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tokens.secondaryText,
                                            ),
                                      )
                                    else
                                      ..._itens.map(
                                        (item) => _itemRow(theme, tokens, item),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceMuted.withValues(
                                    alpha: 0.56,
                                  ),
                                  border: Border(
                                    top: BorderSide(color: tokens.divider),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        '${_t('common.total', 'Total')}: ${_formatarMoeda(_total)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: tokens.primaryText,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _salvando ? null : _cancelar,
                                      child: Text(
                                        _t('common.cancel', 'Cancelar'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: _salvando ? null : _salvar,
                                      icon:
                                          _salvando
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : const Icon(Icons.save_outlined),
                                      label: Text(
                                        _salvando
                                            ? _t('common.saving', 'Salvando...')
                                            : _t(
                                              'empresa.configuracao.saveChanges',
                                              'Salvar alterações',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecorationThemeData _buildInputDecorationTheme(
    ThemeData theme,
    WebThemeTokens tokens,
  ) {
    return theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: tokens.inputBackground,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.mutedText),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.mutedText,
        height: 1.35,
      ),
      suffixIconColor: tokens.secondaryText,
      prefixIconColor: tokens.secondaryText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.info, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, WebThemeTokens tokens) {
    final _ClienteAtendimentoWeb? cliente = _clienteSelecionado;
    final _ResponsavelTecnicoWeb? responsavel = _responsavelSelecionado;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _summaryTile(
          theme,
          tokens,
          icon: Icons.person_search_outlined,
          label: _t('atendimentoTecnico.edit.clientLabel', 'Cliente'),
          value:
              cliente?.nome ??
              _t('atendimentoTecnico.edit.selectClient', 'Selecione o cliente'),
        ),
        _summaryTile(
          theme,
          tokens,
          icon: Icons.engineering_outlined,
          label: _t(
            'atendimentoTecnico.edit.responsibleLabel',
            'Responsável técnico',
          ),
          value:
              responsavel?.nome ??
              _t(
                'atendimentoTecnico.edit.selectResponsible',
                'Selecione o responsável',
              ),
        ),
        _summaryTile(
          theme,
          tokens,
          icon: Icons.payments_outlined,
          label: _t('common.total', 'Total'),
          value: _formatarMoeda(_total),
          emphasize: true,
        ),
      ],
    );
  }

  Widget _summaryTile(
    ThemeData theme,
    WebThemeTokens tokens, {
    required IconData icon,
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 292),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tokens.info, size: 18),
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
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        emphasize ? tokens.primaryText : tokens.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children:
                children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: child,
                      ),
                    )
                    .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              children
                  .map(
                    (child) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: child,
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _clienteSelectorField(ThemeData theme, WebThemeTokens tokens) {
    final _ClienteAtendimentoWeb? cliente = _clienteSelecionado;
    final bool hasSelection = cliente != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _salvando ? null : _abrirSelecaoCliente,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isEmpty: !hasSelection,
          decoration: InputDecoration(
            labelText: _t('atendimentoTecnico.edit.clientLabel', 'Cliente'),
            helperText:
                _carregandoClientes
                    ? _t(
                      'atendimentoTecnico.edit.loadingClients',
                      'Carregando clientes.',
                    )
                    : _t(
                      'atendimentoTecnico.edit.clientHelper',
                      'Cliente vinculado ao atendimento técnico.',
                    ),
            suffixIcon:
                _carregandoClientes
                    ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.person_search_outlined, color: tokens.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSelection
                      ? cliente.nome
                      : _t(
                        'atendimentoTecnico.edit.selectClient',
                        'Selecione o cliente',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        hasSelection
                            ? tokens.primaryText
                            : tokens.secondaryText,
                    fontWeight:
                        hasSelection ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _responsavelSelectorField(ThemeData theme, WebThemeTokens tokens) {
    final _ResponsavelTecnicoWeb? responsavel = _responsavelSelecionado;
    return _ResponsavelTecnicoDropdownField(
      label: _t(
        'atendimentoTecnico.edit.responsibleLabel',
        'Responsável técnico',
      ),
      helperText:
          _carregandoResponsaveis
              ? _t(
                'atendimentoTecnico.edit.loadingTechnicians',
                'Carregando técnicos autorizados.',
              )
              : _t(
                'atendimentoTecnico.edit.responsibleHelper',
                'Apenas técnicos autorizados para assistência.',
              ),
      placeholder: _t(
        'atendimentoTecnico.edit.selectResponsible',
        'Selecione o responsável',
      ),
      selected: responsavel,
      items: _responsaveis,
      loading: _carregandoResponsaveis,
      enabled:
          !_salvando && !_carregandoResponsaveis && _responsaveis.isNotEmpty,
      onSelected:
          (_ResponsavelTecnicoWeb value) =>
              setState(() => _responsavelSelecionado = value),
    );
  }

  Widget _itemRow(
    ThemeData theme,
    WebThemeTokens tokens,
    _AtendimentoItemEditavel item,
  ) {
    final servico = item.tipoCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            servico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
            color: tokens.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.descricao,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _alterarQuantidade(item, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            item.quantidade.toString(),
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: () => _alterarQuantidade(item, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
          SizedBox(
            width: 96,
            child: Text(
              _formatarMoeda(item.total),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _removerItem(item),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ClienteAtendimentoWeb {
  const _ClienteAtendimentoWeb({
    required this.id,
    required this.nome,
    required this.subtitulo,
    required this.nomeInformado,
  });

  final String id;
  final String nome;
  final String subtitulo;
  final bool nomeInformado;

  factory _ClienteAtendimentoWeb.fromCliente(ClienteUsuario cliente) {
    final String nome = cliente.nome.trim();
    final String subtitulo = <String>[
      cliente.documento,
      cliente.telefone,
      cliente.email,
    ].where((String item) => item.trim().isNotEmpty).join(' • ');
    return _ClienteAtendimentoWeb(
      id: cliente.id,
      nome: nome.isEmpty ? 'Cliente sem nome' : nome,
      subtitulo: subtitulo.isEmpty ? 'Cliente cadastrado' : subtitulo,
      nomeInformado: nome.isNotEmpty,
    );
  }
}

class _AtendimentoTecnicoEditImpactIcon extends StatelessWidget {
  const _AtendimentoTecnicoEditImpactIcon({
    required this.accent,
    required this.reduceMotion,
  });

  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : 0.92, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 1 : 700),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: reduceMotion ? 1 : (0.72 + (value - 0.92) * 3.5),
            child: child,
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accent.withValues(alpha: 0.20),
              tokens.surfaceMuted.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(Icons.edit_note_rounded, color: accent, size: 28),
      ),
    );
  }
}

class _ClienteAtendimentoEditarWebDialog extends StatefulWidget {
  const _ClienteAtendimentoEditarWebDialog({
    required this.clientes,
    required this.clienteSelecionado,
  });

  final List<_ClienteAtendimentoWeb> clientes;
  final _ClienteAtendimentoWeb? clienteSelecionado;

  @override
  State<_ClienteAtendimentoEditarWebDialog> createState() =>
      _ClienteAtendimentoEditarWebDialogState();
}

class _ClienteAtendimentoEditarWebDialogState
    extends State<_ClienteAtendimentoEditarWebDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ClienteAtendimentoWeb> get _clientesFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.clientes;
    return widget.clientes
        .where((_ClienteAtendimentoWeb item) {
          return _normalize('${item.nome} ${item.subtitulo}').contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<_ClienteAtendimentoWeb> clientes = _clientesFiltrados;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_search_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(
                            'atendimentoTecnico.edit.selectClientTitle',
                            fallback: 'Selecionar cliente',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.t(
                            'atendimentoTecnico.edit.selectClientSubtitle',
                            fallback:
                                'Busque e selecione o cliente vinculado ao atendimento.',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('common.close', fallback: 'Fechar'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) => setState(() => _filter = value),
                decoration: InputDecoration(
                  hintText: context.t(
                    'atendimentoTecnico.edit.searchClient',
                    fallback: 'Buscar cliente',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: context.t(
                              'common.clear',
                              fallback: 'Limpar',
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filter = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  filled: true,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  clientes.isEmpty
                      ? _ClienteAtendimentoWebEmptyState(
                        text: context.t(
                          'atendimentoTecnico.edit.noClientFound',
                          fallback: 'Nenhum cliente encontrado.',
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: clientes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final _ClienteAtendimentoWeb cliente =
                              clientes[index];
                          final bool selected =
                              widget.clienteSelecionado?.id == cliente.id;
                          return _ClienteAtendimentoWebItem(
                            cliente: cliente,
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(cliente),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ClienteAtendimentoWebItem extends StatelessWidget {
  const _ClienteAtendimentoWebItem({
    required this.cliente,
    required this.selected,
    required this.onTap,
  });

  final _ClienteAtendimentoWeb cliente;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? colorScheme.primary.withValues(alpha: 0.38)
                      : colorScheme.outline.withValues(alpha: 0.18),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
                child: Text(
                  _iniciais(cliente.nome),
                  style: TextStyle(
                    color: colorScheme.primary,
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
                      cliente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (cliente.subtitulo.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        cliente.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iniciais(String nome) {
    final List<String> partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (partes.isEmpty) return 'CL';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first.substring(0, 1)}${partes.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ClienteAtendimentoWebEmptyState extends StatelessWidget {
  const _ClienteAtendimentoWebEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.person_search_outlined,
              size: 36,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsavelTecnicoWeb {
  const _ResponsavelTecnicoWeb({
    required this.id,
    required this.nome,
    required this.subtitulo,
  });

  final String id;
  final String nome;
  final String subtitulo;
}

class _ResponsavelTecnicoDropdownField extends StatefulWidget {
  const _ResponsavelTecnicoDropdownField({
    required this.label,
    required this.helperText,
    required this.placeholder,
    required this.selected,
    required this.items,
    required this.loading,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final String helperText;
  final String placeholder;
  final _ResponsavelTecnicoWeb? selected;
  final List<_ResponsavelTecnicoWeb> items;
  final bool loading;
  final bool enabled;
  final ValueChanged<_ResponsavelTecnicoWeb> onSelected;

  @override
  State<_ResponsavelTecnicoDropdownField> createState() =>
      _ResponsavelTecnicoDropdownFieldState();
}

class _ResponsavelTecnicoDropdownFieldState
    extends State<_ResponsavelTecnicoDropdownField> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.items.isEmpty) return;

    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ThemeData theme = Theme.of(context);
    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final RelativeRect position = RelativeRect.fromLTRB(
      fieldOffset.dx,
      fieldOffset.dy + fieldSize.height + 6,
      overlayBox.size.width - fieldOffset.dx - fieldSize.width,
      0,
    );

    setState(() => _open = true);
    final _ResponsavelTecnicoWeb?
    selected = await showMenu<_ResponsavelTecnicoWeb>(
      context: context,
      position: position,
      color: tokens.menuBackground,
      elevation: 12,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.items
          .map((_ResponsavelTecnicoWeb item) {
            final bool isSelected = widget.selected?.id == item.id;
            return PopupMenuItem<_ResponsavelTecnicoWeb>(
              value: item,
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? tokens.selectedBackground
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? tokens.selectedBorder : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: tokens.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.engineering_outlined,
                        size: 18,
                        color: isSelected ? tokens.info : tokens.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            item.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                            ),
                          ),
                          if (item.subtitulo.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 3),
                            Text(
                              item.subtitulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: isSelected ? tokens.info : tokens.secondaryText,
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
    if (selected != null && selected.id != widget.selected?.id) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.enabled && (_hovered || _open);
    final _ResponsavelTecnicoWeb? selected = widget.selected;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: selected?.nome ?? widget.placeholder,
      child: AnimatedOpacity(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        opacity: widget.enabled || widget.loading ? 1 : 0.58,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.loading ? null : _openMenu,
              child: AnimatedContainer(
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                constraints: const BoxConstraints(minHeight: 74),
                padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                decoration: BoxDecoration(
                  color:
                      active ? tokens.surfaceElevated : tokens.inputBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? tokens.selectedBorder : tokens.cardBorder,
                    width: active ? 1.4 : 1,
                  ),
                  boxShadow:
                      active
                          ? <BoxShadow>[
                            BoxShadow(
                              color: tokens.info.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tokens.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          widget.loading
                              ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.info,
                                ),
                              )
                              : Icon(
                                Icons.engineering_outlined,
                                size: 18,
                                color:
                                    active ? tokens.info : tokens.secondaryText,
                              ),
                    ),
                    const SizedBox(width: 12),
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
                            selected?.nome ?? widget.placeholder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  selected != null
                                      ? tokens.primaryText
                                      : tokens.secondaryText,
                              fontWeight:
                                  selected != null
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected?.subtitulo.trim().isNotEmpty == true
                                ? selected!.subtitulo
                                : widget.helperText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.mutedText,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class _AtendimentoItemEditavel {
  const _AtendimentoItemEditavel({
    required this.chave,
    required this.idSku,
    required this.descricao,
    required this.tipoCodigo,
    required this.quantidade,
    required this.valorUnitario,
    required this.idTecnicoResponsavel,
    required this.nomeTecnicoResponsavel,
  });

  final String chave;
  final String? idSku;
  final String descricao;
  final String tipoCodigo;
  final int quantidade;
  final double valorUnitario;
  final String? idTecnicoResponsavel;
  final String? nomeTecnicoResponsavel;

  double get total => quantidade * valorUnitario;

  factory _AtendimentoItemEditavel.fromModel(AtendimentoTecnicoItemModel item) {
    return _AtendimentoItemEditavel(
      chave:
          '${item.tipoItemCodigo}:${item.idSku ?? item.id}:${item.descricaoSnapshot}',
      idSku: item.idSku,
      descricao: item.descricaoSnapshot,
      tipoCodigo: item.tipoItemCodigo,
      quantidade: item.quantidade <= 0 ? 1 : item.quantidade.round(),
      valorUnitario: item.valorUnitario,
      idTecnicoResponsavel: item.idTecnicoResponsavel,
      nomeTecnicoResponsavel: item.nomeTecnicoResponsavel,
    );
  }

  _AtendimentoItemEditavel copyWith({int? quantidade}) {
    return _AtendimentoItemEditavel(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoCodigo: tipoCodigo,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
      idTecnicoResponsavel: idTecnicoResponsavel,
      nomeTecnicoResponsavel: nomeTecnicoResponsavel,
    );
  }

  AtendimentoTecnicoItemInput toInput({_ResponsavelTecnicoWeb? responsavel}) {
    final produto = tipoCodigo == 'PRODUCT';
    return AtendimentoTecnicoItemInput(
      tipoItemId: produto ? 10 : 20,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      idTecnicoResponsavel: responsavel?.id ?? idTecnicoResponsavel,
      nomeTecnicoResponsavel: responsavel?.nome ?? nomeTecnicoResponsavel,
      movimentaEstoque: produto,
    );
  }
}
