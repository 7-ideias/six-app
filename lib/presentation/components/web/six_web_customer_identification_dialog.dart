import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/cliente_usuario_module.dart';
import '../../../core/services/cliente_usuario_service.dart';
import '../../../data/models/cliente_usuario_model.dart';
import '../../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../../l10n/six_i18n.dart';
import '../../screens/cliente_usuario_cadastro_web_dialog.dart';
import '../../theme/web_theme_tokens.dart';

class ClienteIdentificacaoVendaResult {
  const ClienteIdentificacaoVendaResult({this.cliente, this.limpar = false});

  final ClienteUsuario? cliente;
  final bool limpar;
}

typedef SixWebCreateCustomerFlow =
    Future<ClienteUsuario?> Function(BuildContext context);

enum _SummaryPillVariant { info, neutral, highlight }

Future<ClienteIdentificacaoVendaResult?>
showSixWebCustomerIdentificationDialog({
  required BuildContext context,
  ClienteUsuario? clienteAtual,
  ClienteUsuarioApiClient? apiClient,
  ClienteUsuarioService? clienteUsuarioService,
  SixWebCreateCustomerFlow? onCreateCustomer,
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<ClienteIdentificacaoVendaResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 280),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _CustomerIdentificationRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: PdvClienteIdentificacaoDialog(
          clienteAtual: clienteAtual,
          apiClient: apiClient,
          clienteUsuarioService: clienteUsuarioService,
          onCreateCustomer: onCreateCustomer,
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class PdvClienteIdentificacaoDialog extends StatefulWidget {
  const PdvClienteIdentificacaoDialog({
    super.key,
    this.clienteAtual,
    this.apiClient,
    this.clienteUsuarioService,
    this.onCreateCustomer,
  });

  final ClienteUsuario? clienteAtual;
  final ClienteUsuarioApiClient? apiClient;
  final ClienteUsuarioService? clienteUsuarioService;
  final SixWebCreateCustomerFlow? onCreateCustomer;

  @override
  State<PdvClienteIdentificacaoDialog> createState() =>
      _PdvClienteIdentificacaoDialogState();
}

class _PdvClienteIdentificacaoDialogState
    extends State<PdvClienteIdentificacaoDialog>
    with SingleTickerProviderStateMixin {
  late final ClienteUsuarioService _clienteUsuarioService;
  late final AnimationController _iconController;
  final TextEditingController _buscaController = TextEditingController();

  bool _loading = true;
  bool _openingCreateFlow = false;
  String? _erro;
  List<ClienteUsuario> _clientes = <ClienteUsuario>[];
  String _filtro = '';

  bool get _canDismiss => !_openingCreateFlow;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _clienteUsuarioService =
        widget.clienteUsuarioService ??
        (widget.apiClient != null
            ? ClienteUsuarioService(apiClient: widget.apiClient!)
            : ClienteUsuarioModule.clienteUsuarioService);
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
    _carregarClientes();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final List<ClienteUsuario> clientes =
          await _clienteUsuarioService.listarClientesAtivos();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _txt(
          'pdv.customerIdentification.loadError',
          'Não foi possível carregar os clientes.',
        );
      });
    }
  }

  List<ClienteUsuario> get _clientesFiltrados {
    return _clienteUsuarioService.filtrarClientes(_clientes, _filtro);
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  void _selecionar(ClienteUsuario cliente) {
    Navigator.of(
      context,
    ).pop(ClienteIdentificacaoVendaResult(cliente: cliente));
  }

  void _limparCliente() {
    Navigator.of(
      context,
    ).pop(const ClienteIdentificacaoVendaResult(limpar: true));
  }

  void _cancel() {
    if (_openingCreateFlow) return;
    Navigator.of(context).pop();
  }

  Future<void> _cadastrarCliente() async {
    if (_openingCreateFlow) return;
    setState(() => _openingCreateFlow = true);
    try {
      final ClienteUsuario? cliente =
          await (widget.onCreateCustomer?.call(context) ??
              showClienteUsuarioCadastroWebDialog(
                context,
                apiClient: widget.apiClient,
              ));
      if (!mounted || cliente == null) return;
      setState(() {
        _erro = null;
        _loading = false;
        _filtro = '';
        _buscaController.clear();
        _clientes = <ClienteUsuario>[
          cliente,
          ..._clientes.where((ClienteUsuario item) => item.id != cliente.id),
        ];
      });
      _selecionar(cliente);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = _txt(
          'pdv.customerIdentification.createError',
          'Não foi possível abrir o cadastro de cliente agora.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _openingCreateFlow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              if (_canDismiss) {
                _cancel();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: _canDismiss,
            child: Semantics(
              namesRoute: true,
              label: _txt(
                'pdv.customerIdentification.title',
                'Identificar cliente',
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.28),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: tokens.surfaceElevated,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          SizedBox(
                            width: 980,
                            height: 680,
                            child: Column(
                              children: <Widget>[
                                _buildHeader(theme, tokens, accent),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    20,
                                    24,
                                    14,
                                  ),
                                  child: _buildSearchField(theme, tokens),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      16,
                                    ),
                                    child: _buildBody(theme, tokens),
                                  ),
                                ),
                                _buildFooter(theme, tokens),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
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

  Widget _buildHeader(ThemeData theme, WebThemeTokens tokens, Color accent) {
    final int total = _clientes.length;
    final String currentCustomer =
        widget.clienteAtual?.nome.trim().isNotEmpty == true
            ? widget.clienteAtual!.nome
            : _txt(
              'pdv.customerIdentification.currentEmpty',
              'Nenhum cliente vinculado',
            );

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
      decoration: BoxDecoration(
        color: tokens.selectedBackground.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tokens.selectedBorder.withValues(alpha: 0.82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CustomerSearchIcon(
                animation: _iconController,
                accent: accent,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'pdv.customerIdentification.title',
                        'Identificar cliente',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'pdv.customerIdentification.subtitle',
                        'Selecione um cliente cadastrado ou crie um novo sem sair do atendimento.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _txt('common.close', 'Fechar'),
                onPressed: _canDismiss ? _cancel : null,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _summaryPill(
                tokens: tokens,
                icon: Icons.groups_2_outlined,
                label: _txt(
                  'pdv.customerIdentification.availableCustomers',
                  'Clientes ativos',
                ),
                value: '$total',
                variant: _SummaryPillVariant.info,
              ),
              _summaryPill(
                tokens: tokens,
                icon: Icons.person_outline_rounded,
                label: _txt(
                  'pdv.customerIdentification.currentCustomer',
                  'Cliente atual',
                ),
                value: currentCustomer,
                variant:
                    widget.clienteAtual == null
                        ? _SummaryPillVariant.neutral
                        : _SummaryPillVariant.highlight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: TextField(
        key: const ValueKey<String>('customer-identification-search-field'),
        controller: _buscaController,
        autofocus: true,
        enabled: !_openingCreateFlow,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
          suffixIcon:
              _buscaController.text.trim().isEmpty
                  ? null
                  : IconButton(
                    tooltip: _txt('common.clear', 'Limpar'),
                    onPressed:
                        _openingCreateFlow
                            ? null
                            : () {
                              _buscaController.clear();
                              setState(() => _filtro = '');
                            },
                    icon: const Icon(Icons.close_rounded),
                  ),
          labelText: _txt(
            'pdv.customerIdentification.searchLabel',
            'Buscar cliente por nome, documento, telefone ou e-mail',
          ),
          filled: true,
          fillColor: tokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
          ),
        ),
        onChanged: (String value) => setState(() => _filtro = value),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, WebThemeTokens tokens) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: tokens.info),
            ),
            const SizedBox(height: 14),
            Text(
              _txt(
                'pdv.customerIdentification.loading',
                'Carregando clientes ativos...',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    if (_erro != null && _clientes.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tokens.danger.withValues(alpha: 0.26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.cloud_off_rounded, size: 42, color: tokens.danger),
                const SizedBox(height: 12),
                Text(
                  _txt(
                    'pdv.customerIdentification.errorTitle',
                    'Não foi possível carregar os clientes',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: tokens.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _carregarClientes,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_txt('common.tryAgain', 'Tentar novamente')),
                    ),
                    FilledButton.icon(
                      onPressed: _openingCreateFlow ? null : _cadastrarCliente,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        _txt(
                          'pdv.customerIdentification.newCustomer',
                          'Cadastrar cliente',
                        ),
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

    final List<ClienteUsuario> clientes = _clientesFiltrados;
    if (clientes.isEmpty) {
      final bool emptySearch = _filtro.trim().isNotEmpty;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  emptySearch
                      ? Icons.search_off_rounded
                      : Icons.person_off_outlined,
                  size: 42,
                  color: tokens.mutedText,
                ),
                const SizedBox(height: 12),
                Text(
                  _txt(
                    emptySearch
                        ? 'pdv.customerIdentification.emptySearchTitle'
                        : 'pdv.customerIdentification.emptyTitle',
                    emptySearch
                        ? 'Nenhum cliente encontrado'
                        : 'Nenhum cliente ativo cadastrado',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: tokens.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _txt(
                    emptySearch
                        ? 'pdv.customerIdentification.emptySearchMessage'
                        : 'pdv.customerIdentification.emptyMessage',
                    emptySearch
                        ? 'Revise os termos da busca ou cadastre um novo cliente para continuar.'
                        : 'Cadastre o cliente agora para seguir com o atendimento sem sair desta etapa.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openingCreateFlow ? null : _cadastrarCliente,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    _txt(
                      'pdv.customerIdentification.newCustomer',
                      'Cadastrar cliente',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: _inlineError(tokens, _erro!),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              return _clienteTile(theme, tokens, clientes[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _clienteTile(
    ThemeData theme,
    WebThemeTokens tokens,
    ClienteUsuario cliente,
  ) {
    final bool selecionado = widget.clienteAtual?.id == cliente.id;
    final bool fiadoLiberado =
        cliente.permiteCompraFiado && !cliente.bloqueadoFiado;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selecionar(cliente),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selecionado ? tokens.selectedBackground : tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selecionado ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    selecionado
                        ? tokens.selectedBackground
                        : tokens.surfaceMuted,
                child: Text(
                  _iniciais(cliente.nome),
                  style: TextStyle(
                    color: tokens.info,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cliente.nome.isEmpty
                          ? _txt(
                            'pdv.customerIdentification.unnamedCustomer',
                            'Cliente sem nome',
                          )
                          : cliente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cliente.tipoPessoa.isEmpty ? _txt('pdv.customerIdentification.personTypeFallback', 'PF') : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? _txt('pdv.customerIdentification.noDocument', 'Sem documento') : cliente.documento}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fiadoLiberado
                          ? _txt(
                            'pdv.customerIdentification.creditEnabled',
                            'Fiado liberado',
                          )
                          : cliente.permiteCompraFiado
                          ? _txt(
                            'pdv.customerIdentification.creditBlocked',
                            'Fiado bloqueado para novas vendas',
                          )
                          : _txt(
                            'pdv.customerIdentification.creditDisabled',
                            'Cliente sem fiado liberado',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            cliente.bloqueadoFiado
                                ? tokens.danger
                                : tokens.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: () => _selecionar(cliente),
                icon: Icon(
                  selecionado
                      ? Icons.check_circle_outline_rounded
                      : Icons.person_add_alt_1_rounded,
                ),
                label: Text(
                  selecionado
                      ? _txt(
                        'pdv.customerIdentification.selected',
                        'Selecionado',
                      )
                      : _txt('pdv.customerIdentification.select', 'Selecionar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _openingCreateFlow ? null : _cadastrarCliente,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  _openingCreateFlow
                      ? _txt(
                        'pdv.customerIdentification.openingCreate',
                        'Abrindo cadastro...',
                      )
                      : _txt(
                        'pdv.customerIdentification.newCustomer',
                        'Cadastrar cliente',
                      ),
                ),
              ),
              if (widget.clienteAtual != null)
                OutlinedButton.icon(
                  onPressed: _openingCreateFlow ? null : _limparCliente,
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(
                    _txt(
                      'pdv.customerIdentification.removeCustomer',
                      'Remover cliente do atendimento',
                    ),
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: _openingCreateFlow ? null : _cancel,
            child: Text(_txt('common.cancel', 'Cancelar')),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({
    required WebThemeTokens tokens,
    required IconData icon,
    required String label,
    required String value,
    required _SummaryPillVariant variant,
  }) {
    final ({Color background, Color border, Color icon, Color iconBackground})
    colors = switch (variant) {
      _SummaryPillVariant.info => (
        background: tokens.surfaceMuted,
        border: tokens.cardBorder,
        icon: tokens.info,
        iconBackground: tokens.info.withValues(alpha: 0.12),
      ),
      _SummaryPillVariant.neutral => (
        background: tokens.surfaceMuted,
        border: tokens.cardBorder,
        icon: tokens.statusNeutral,
        iconBackground: tokens.statusNeutral.withValues(alpha: 0.14),
      ),
      _SummaryPillVariant.highlight => (
        background: tokens.selectedBackground,
        border: tokens.selectedBorder.withValues(alpha: 0.90),
        icon: tokens.info,
        iconBackground: tokens.info.withValues(alpha: 0.14),
      ),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.icon, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    );
  }

  Widget _inlineError(WebThemeTokens tokens, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

class _CustomerSearchIcon extends StatelessWidget {
  const _CustomerSearchIcon({
    required this.animation,
    required this.accent,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SizedBox(
      width: 74,
      height: 74,
      child: AnimatedBuilder(
        animation: curved,
        builder: (BuildContext context, Widget? child) {
          final double progress = curved.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.scale(
                scale: 0.9 + (progress * 0.1),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.20 + (progress * 0.22)),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16 * progress),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.20 + (progress * 0.16)),
                  ),
                ),
                child: Transform.rotate(
                  angle: (1 - progress) * -0.18,
                  child: Icon(
                    Icons.person_search_outlined,
                    color: accent,
                    size: 28,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerIdentificationRouteSurface extends StatelessWidget {
  const _CustomerIdentificationRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: child,
        builder: (BuildContext context, Widget? dialogChild) {
          final double progress = curvedAnimation.value;
          final double blur = reduceMotion ? 0 : 12 * progress;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: ColoredBox(
                      color: const Color(0xCC08111F).withValues(
                        alpha: reduceMotion ? 0.78 : 0.78 * progress,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          reduceMotion ? 0 : (1 - progress) * 22,
                        ),
                        child: Transform.scale(
                          scale: reduceMotion ? 1 : 0.96 + (0.04 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
