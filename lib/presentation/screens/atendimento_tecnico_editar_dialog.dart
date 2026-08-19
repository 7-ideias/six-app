import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import 'produto_lista_sub_painel_web.dart';

class AtendimentoTecnicoEditarDialog extends StatefulWidget {
  const AtendimentoTecnicoEditarDialog({super.key, required this.atendimento});

  final AtendimentoTecnicoModel atendimento;

  @override
  State<AtendimentoTecnicoEditarDialog> createState() =>
      _AtendimentoTecnicoEditarDialogState();
}

class _AtendimentoTecnicoEditarDialogState
    extends State<AtendimentoTecnicoEditarDialog> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ClienteUsuarioApiClient _clienteApiClient =
      HttpClienteUsuarioApiClient();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();
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
    final selecionada = await showDatePicker(
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
    final selecionada = await showDatePicker(
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
    final selecionada = await showDatePicker(
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

  Future<void> _abrirSelecaoResponsavel() async {
    if (_carregandoResponsaveis) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.loadingTechnicians',
          'Carregando técnicos autorizados.',
        ),
      );
      return;
    }
    if (_responsaveis.isEmpty) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.edit.noTechnicians',
          'Nenhum responsável técnico disponível para seleção.',
        ),
      );
      return;
    }

    final _ResponsavelTecnicoWeb? responsavel =
        await showDialog<_ResponsavelTecnicoWeb>(
          context: context,
          builder: (BuildContext context) {
            return _ResponsavelTecnicoEditarWebDialog(
              responsaveis: _responsaveis,
              responsavelSelecionado: _responsavelSelecionado,
            );
          },
        );

    if (responsavel == null || !mounted) return;
    setState(() => _responsavelSelecionado = responsavel);
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
          observacaoAuditoria: _textoOuNulo(
            _observacaoAuditoriaController.text,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar as alterações: $error');
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

  String _formatarData(DateTime value) {
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarMoeda(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  double get _total =>
      _itens.fold<double>(0, (total, item) => total + item.total);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.edit_note_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Editar ${widget.atendimento.numero}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  if (widget.atendimento.assinaturaAprovada ||
                      widget.atendimento.requerNovaAssinatura)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Ao salvar alterações de produtos, serviços, validade, entrega prevista, vencimento financeiro ou observações, esta versão do orçamento exigirá nova assinatura do cliente.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  _grid(<Widget>[
                    TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição interna',
                      ),
                    ),
                    _clienteSelectorField(theme),
                    _responsavelSelectorField(theme),
                    InkWell(
                      onTap: _selecionarValidade,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Validade do orçamento',
                          helperText: 'Prazo para aprovação do cliente.',
                          suffixIcon: Icon(Icons.event_available_outlined),
                        ),
                        child: Text(
                          _formatarData(_validadeOrcamentoEm),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _selecionarVencimentoFinanceiro,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Vencimento financeiro',
                          helperText: 'Data usada na agenda financeira.',
                          suffixIcon: Icon(Icons.event_note_outlined),
                        ),
                        child: Text(
                          _formatarData(_dataVencimentoEm),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _selecionarDataEntregaPrevista,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Entrega prevista',
                          helperText:
                              'Prazo operacional para término ou entrega.',
                          suffixIcon: Icon(Icons.assignment_turned_in_outlined),
                        ),
                        child: Text(
                          _formatarData(_dataEntregaPrevista),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _tipoEquipamentoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de equipamento',
                      ),
                    ),
                    TextField(
                      controller: _marcaController,
                      decoration: const InputDecoration(labelText: 'Marca'),
                    ),
                    TextField(
                      controller: _modeloController,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                    ),
                    TextField(
                      controller: _numeroSerieController,
                      decoration: const InputDecoration(
                        labelText: 'Número de série',
                      ),
                    ),
                    TextField(
                      controller: _imeiController,
                      decoration: const InputDecoration(labelText: 'IMEI'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _acessoriosController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Acessórios / observações de entrada',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _defeitoController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Defeito relatado',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diagnosticoController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Diagnóstico / novas observações técnicas',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _observacaoAuditoriaController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observação de auditoria da alteração',
                      hintText:
                          'Ex.: cliente solicitou incluir película e retirar limpeza interna',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Produtos e serviços',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _abrirSelecaoItens('PRODUTO'),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Adicionar peça'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _abrirSelecaoItens('SERVICO'),
                        icon: const Icon(Icons.handyman_outlined),
                        label: const Text('Adicionar serviço'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_itens.isEmpty)
                    Text(
                      'Nenhum item vinculado.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._itens.map((item) => _itemRow(theme, item)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Total: ${_formatarMoeda(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _salvando
                            ? null
                            : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon:
                        _salvando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save_outlined),
                    label: Text(
                      _salvando ? 'Salvando...' : 'Salvar alterações',
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

  Widget _clienteSelectorField(ThemeData theme) {
    final _ClienteAtendimentoWeb? cliente = _clienteSelecionado;
    final bool hasSelection = cliente != null;
    final ColorScheme colorScheme = theme.colorScheme;
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
              Icon(Icons.person_search_outlined, color: colorScheme.primary),
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
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
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

  Widget _responsavelSelectorField(ThemeData theme) {
    final _ResponsavelTecnicoWeb? responsavel = _responsavelSelecionado;
    final bool hasSelection = responsavel != null;
    final ColorScheme colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _salvando ? null : _abrirSelecaoResponsavel,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isEmpty: !hasSelection,
          decoration: InputDecoration(
            labelText: _t(
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
            suffixIcon:
                _carregandoResponsaveis
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
              Icon(Icons.engineering_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSelection
                      ? responsavel.nome
                      : _t(
                        'atendimentoTecnico.edit.selectResponsible',
                        'Selecione o responsável',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        hasSelection
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
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

  Widget _itemRow(ThemeData theme, _AtendimentoItemEditavel item) {
    final servico = item.tipoCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.38,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            servico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.descricao,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: () => _alterarQuantidade(item, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            item.quantidade.toString(),
            style: const TextStyle(fontWeight: FontWeight.w900),
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
              style: const TextStyle(fontWeight: FontWeight.w900),
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

class _ResponsavelTecnicoEditarWebDialog extends StatefulWidget {
  const _ResponsavelTecnicoEditarWebDialog({
    required this.responsaveis,
    required this.responsavelSelecionado,
  });

  final List<_ResponsavelTecnicoWeb> responsaveis;
  final _ResponsavelTecnicoWeb? responsavelSelecionado;

  @override
  State<_ResponsavelTecnicoEditarWebDialog> createState() =>
      _ResponsavelTecnicoEditarWebDialogState();
}

class _ResponsavelTecnicoEditarWebDialogState
    extends State<_ResponsavelTecnicoEditarWebDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ResponsavelTecnicoWeb> get _responsaveisFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.responsaveis;
    return widget.responsaveis
        .where((_ResponsavelTecnicoWeb item) {
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
    final List<_ResponsavelTecnicoWeb> responsaveis = _responsaveisFiltrados;
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
                      Icons.engineering_outlined,
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
                            'atendimentoTecnico.edit.selectResponsibleTitle',
                            fallback: 'Selecionar responsável técnico',
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
                            'atendimentoTecnico.edit.selectResponsibleSubtitle',
                            fallback:
                                'Busque e selecione um técnico autorizado para assistência.',
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
                    'atendimentoTecnico.edit.searchResponsible',
                    fallback: 'Buscar responsável',
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
                  responsaveis.isEmpty
                      ? _ResponsavelTecnicoWebEmptyState(
                        text: context.t(
                          'atendimentoTecnico.edit.noResponsibleFound',
                          fallback: 'Nenhum técnico autorizado encontrado.',
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: responsaveis.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final _ResponsavelTecnicoWeb responsavel =
                              responsaveis[index];
                          final bool selected =
                              widget.responsavelSelecionado?.id ==
                              responsavel.id;
                          return _ResponsavelTecnicoWebItem(
                            responsavel: responsavel,
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(responsavel),
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

class _ResponsavelTecnicoWebItem extends StatelessWidget {
  const _ResponsavelTecnicoWebItem({
    required this.responsavel,
    required this.selected,
    required this.onTap,
  });

  final _ResponsavelTecnicoWeb responsavel;
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
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      responsavel.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (responsavel.subtitulo.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        responsavel.subtitulo,
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
}

class _ResponsavelTecnicoWebEmptyState extends StatelessWidget {
  const _ResponsavelTecnicoWebEmptyState({required this.text});

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
              Icons.engineering_outlined,
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
