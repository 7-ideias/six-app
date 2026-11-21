import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/cliente_usuario_module.dart';
import '../../../core/services/cliente_usuario_service.dart';
import '../../../data/models/cliente_usuario_model.dart';
import '../../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../../l10n/six_i18n.dart';
import '../../screens/cliente_usuario_cadastro_web_dialog.dart';
import '../../theme/web_theme_tokens.dart';
import 'six_web_animated_dialog.dart';

class ClienteIdentificacaoVendaResult {
  const ClienteIdentificacaoVendaResult({this.cliente, this.limpar = false});

  final ClienteUsuario? cliente;
  final bool limpar;
}

typedef SixWebCreateCustomerFlow =
    Future<ClienteUsuario?> Function(BuildContext context);

Future<ClienteIdentificacaoVendaResult?>
showSixWebCustomerIdentificationDialog({
  required BuildContext context,
  bool barrierDismissible = false,
  ClienteUsuario? clienteAtual,
  ClienteUsuarioApiClient? apiClient,
  ClienteUsuarioService? clienteUsuarioService,
  SixWebCreateCustomerFlow? onCreateCustomer,
}) {
  final compact = MediaQuery.sizeOf(context).width < 600;
  return showSixWebAnimatedDialog<ClienteIdentificacaoVendaResult>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    padding: EdgeInsets.all(compact ? 12 : 24),
    builder:
        (_) => _CustomerIdentificationDialog(
          clienteAtual: clienteAtual,
          apiClient: apiClient,
          clienteUsuarioService: clienteUsuarioService,
          onCreateCustomer: onCreateCustomer,
        ),
  );
}

class _CustomerIdentificationDialog extends StatefulWidget {
  const _CustomerIdentificationDialog({
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
  State<_CustomerIdentificationDialog> createState() =>
      _CustomerIdentificationDialogState();
}

class _CustomerIdentificationDialogState
    extends State<_CustomerIdentificationDialog>
    with SingleTickerProviderStateMixin {
  late final ClienteUsuarioService _clienteUsuarioService;
  late final AnimationController _iconController;
  final TextEditingController _buscaController = TextEditingController();

  bool _loading = true;
  bool _openingCreateFlow = false;
  bool _loadFailed = false;
  bool _createFailed = false;
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
      _loadFailed = false;
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
        _loadFailed = true;
      });
    }
  }

  List<ClienteUsuario> get _clientesFiltrados {
    return _clienteUsuarioService.filtrarClientes(_clientes, _filtro);
  }

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
    setState(() {
      _openingCreateFlow = true;
      _createFailed = false;
    });
    try {
      final ClienteUsuario? cliente =
          await (widget.onCreateCustomer?.call(context) ??
              showClienteUsuarioCadastroWebDialog(
                context,
                apiClient: widget.apiClient,
              ));
      if (!mounted || cliente == null) return;
      _selecionar(cliente);
    } catch (_) {
      if (!mounted) return;
      setState(() => _createFailed = true);
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
              label: context.t('pdv.customerIdentification.title'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 660,
                  maxHeight: 640,
                ),
                child: Material(
                  key: const ValueKey('pdv-identificar-cliente-painel'),
                  elevation: 18,
                  color: tokens.surfaceElevated,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: tokens.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final short =
                          bounds.maxHeight < 440 ||
                          MediaQuery.textScalerOf(context).scale(16) > 22;
                      final filters =
                          _clientes.isNotEmpty && !_loading && !_loadFailed;
                      final clientes = _clientesFiltrados;
                      final header = _buildHeader(theme, tokens);
                      final footer = _buildFooter(tokens);
                      final search = filters ? _buildSearchField(tokens) : null;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!short) header,
                          if (!short && search != null) search,
                          Flexible(
                            child: CustomScrollView(
                              shrinkWrap: true,
                              slivers: [
                                if (short) SliverToBoxAdapter(child: header),
                                if (short && search != null)
                                  SliverToBoxAdapter(child: search),
                                if (_createFailed)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      child: _inlineError(
                                        tokens,
                                        context.t(
                                          'pdv.customerIdentification.createError',
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_loading || _loadFailed || clientes.isEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildStatus(theme, tokens),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      2,
                                      20,
                                      16,
                                    ),
                                    sliver: SliverList.separated(
                                      itemCount: clientes.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 8),
                                      itemBuilder:
                                          (_, index) => _clienteTile(
                                            theme,
                                            tokens,
                                            clientes[index],
                                          ),
                                    ),
                                  ),
                                if (short) SliverToBoxAdapter(child: footer),
                              ],
                            ),
                          ),
                          if (!short) footer,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, WebThemeTokens tokens) {
    final current = widget.clienteAtual;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CustomerSearchIcon(
                animation: _iconController,
                accent: tokens.info,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t('pdv.customerIdentification.title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.t('common.close'),
                onPressed: _canDismiss ? _cancel : null,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${context.t('pdv.customerIdentification.currentCustomer')} · ${current.nome.trim().isEmpty ? current.documento : current.nome}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.t(
                      'pdv.customerIdentification.removeCustomer',
                    ),
                    onPressed: _canDismiss ? _limparCliente : null,
                    icon: const Icon(Icons.person_remove_outlined),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(WebThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: TextField(
        key: const ValueKey('customer-identification-search-field'),
        controller: _buscaController,
        autofocus: true,
        enabled: _canDismiss,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
          suffixIcon:
              _buscaController.text.isEmpty
                  ? null
                  : IconButton(
                    tooltip: context.t('common.clear'),
                    onPressed: () {
                      _buscaController.clear();
                      setState(() => _filtro = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          labelText: context.t('pdv.customerIdentification.searchLabel'),
          filled: true,
          fillColor: tokens.inputBackground,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: tokens.selectedBorder, width: 1.5),
          ),
        ),
        onChanged: (value) => setState(() => _filtro = value),
      ),
    );
  }

  Widget _buildStatus(ThemeData theme, WebThemeTokens tokens) {
    final searching = _filtro.trim().isNotEmpty;
    final title =
        _loading
            ? 'loading'
            : _loadFailed
            ? 'errorTitle'
            : searching
            ? 'emptySearchTitle'
            : 'emptyTitle';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: tokens.info,
              ),
            )
          else
            Icon(
              _loadFailed
                  ? Icons.cloud_off_outlined
                  : searching
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 32,
              color: _loadFailed ? tokens.danger : tokens.mutedText,
            ),
          const SizedBox(height: 10),
          Text(
            context.t('pdv.customerIdentification.$title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!_loading && !_loadFailed) ...[
            const SizedBox(height: 6),
            Text(
              context.t(
                searching
                    ? 'pdv.customerIdentification.emptySearchMessage'
                    : 'pdv.customerIdentification.emptyMessage',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
              ),
            ),
          ],
          if (_loadFailed)
            TextButton.icon(
              onPressed: _canDismiss ? _carregarClientes : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t('common.tryAgain')),
            ),
        ],
      ),
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

    return Semantics(
      button: true,
      selected: selecionado,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _canDismiss ? () => _selecionar(cliente) : null,
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
                            ? context.t(
                              'pdv.customerIdentification.unnamedCustomer',
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
                        '${cliente.tipoPessoa.isEmpty ? context.t('pdv.customerIdentification.personTypeFallback') : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? context.t('pdv.customerIdentification.noDocument') : cliente.documento}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fiadoLiberado
                            ? context.t(
                              'pdv.customerIdentification.creditEnabled',
                            )
                            : cliente.permiteCompraFiado
                            ? context.t(
                              'pdv.customerIdentification.creditBlocked',
                            )
                            : context.t(
                              'pdv.customerIdentification.creditDisabled',
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
                Tooltip(
                  message: context.t(
                    selecionado
                        ? 'pdv.customerIdentification.selected'
                        : 'pdv.customerIdentification.select',
                  ),
                  child: Icon(
                    selecionado
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selecionado ? tokens.info : tokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: _canDismiss ? _cancel : null,
            child: Text(context.t('common.cancel')),
          ),
          FilledButton.icon(
            onPressed: _openingCreateFlow ? null : _cadastrarCliente,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(
              context.t(
                _openingCreateFlow
                    ? 'pdv.customerIdentification.openingCreate'
                    : 'pdv.customerIdentification.newCustomer',
              ),
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
      width: 48,
      height: 48,
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
                  width: 46,
                  height: 46,
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
                width: 38,
                height: 38,
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
                    size: 22,
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
