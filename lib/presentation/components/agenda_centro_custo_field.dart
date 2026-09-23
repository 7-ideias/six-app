import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class AgendaCentroCustoField extends StatefulWidget {
  const AgendaCentroCustoField({
    super.key,
    this.initialId,
    this.initialName,
    required this.onChanged,
    this.enabled = true,
  });

  final String? initialId;
  final String? initialName;
  final ValueChanged<CentroCustoModel?> onChanged;
  final bool enabled;

  @override
  State<AgendaCentroCustoField> createState() => _AgendaCentroCustoFieldState();
}

class _AgendaCentroCustoFieldState extends State<AgendaCentroCustoField> {
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  List<CentroCustoModel> _centros = <CentroCustoModel>[];
  String? _selecionadoId;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _selecionadoId =
        widget.initialId?.trim().isEmpty == true ? null : widget.initialId;
    _carregar();
  }

  @override
  void didUpdateWidget(covariant AgendaCentroCustoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialId != oldWidget.initialId) {
      _selecionadoId =
          widget.initialId?.trim().isEmpty == true ? null : widget.initialId;
    }
  }

  Future<void> _carregar() async {
    try {
      final centros = await _service.listarCentrosCusto();
      if (!mounted) return;
      setState(() {
        _centros = centros;
        if (_selecionadoId != null &&
            !_centros.any((centro) => centro.id == _selecionadoId)) {
          _selecionadoId = null;
        }
      });
    } catch (_) {
      // O lançamento continua disponível sem centro de custos.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cadastrar() async {
    if (!kIsWeb) {
      await _cadastrarMobile();
      return;
    }

    final String barrierLabel = context.t(
      'agenda.costCenter.closeCreate',
      fallback: 'Fechar cadastro de centro de custos',
    );
    Future<CentroCustoModel> onCreate({
      required String nome,
      required String codigo,
      required String tipo,
    }) {
      return _service.criarCentroCusto(nome: nome, codigo: codigo, tipo: tipo);
    }

    final CentroCustoModel? criado;
    criado = await showSixWebAnimatedDialog<CentroCustoModel>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      builder:
          (BuildContext dialogContext) =>
              _AgendaCentroCustoCreateDialog(onCreate: onCreate),
    );
    _aplicarCentroCriado(criado);
  }

  Future<void> _cadastrarMobile() async {
    Future<CentroCustoModel> onCreate({
      required String nome,
      required String codigo,
      required String tipo,
    }) {
      return _service.criarCentroCusto(nome: nome, codigo: codigo, tipo: tipo);
    }

    final CentroCustoModel? criado = await showDialog<CentroCustoModel>(
      context: context,
      builder:
          (BuildContext dialogContext) =>
              _AgendaCentroCustoCreateDialog(onCreate: onCreate),
    );
    _aplicarCentroCriado(criado);
  }

  void _aplicarCentroCriado(CentroCustoModel? criado) {
    if (criado == null || !mounted) return;
    final CentroCustoModel novoCentro = criado;
    setState(() {
      _centros = <CentroCustoModel>[..._centros, novoCentro]
        ..sort((a, b) => a.nome.compareTo(b.nome));
      _selecionadoId = novoCentro.id;
    });
    widget.onChanged(novoCentro);
  }

  @override
  Widget build(BuildContext context) {
    final String legado = widget.initialName?.trim() ?? '';
    return DropdownButtonFormField<String>(
      key: ValueKey('${widget.initialId}|$legado|${_centros.length}'),
      initialValue:
          _centros.any((centro) => centro.id == _selecionadoId)
              ? _selecionadoId
              : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Centro de custos',
        hintText: legado.isEmpty ? 'Sem centro de custos' : legado,
        prefixIcon: const Icon(Icons.account_tree_outlined),
        suffixIcon:
            _carregando
                ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : IconButton(
                  tooltip: 'Cadastrar centro de custos',
                  onPressed: widget.enabled ? _cadastrar : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Sem centro de custos'),
        ),
        ..._centros.map(
          (centro) => DropdownMenuItem<String>(
            value: centro.id,
            child: Text(centro.descricao, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged:
          !widget.enabled || _carregando
              ? null
              : (value) {
                final id = value?.trim() ?? '';
                setState(() => _selecionadoId = id.isEmpty ? null : id);
                CentroCustoModel? centro;
                for (final item in _centros) {
                  if (item.id == id) {
                    centro = item;
                    break;
                  }
                }
                widget.onChanged(centro);
              },
    );
  }
}

class _AgendaCentroCustoCreateDialog extends StatefulWidget {
  const _AgendaCentroCustoCreateDialog({required this.onCreate});

  final Future<CentroCustoModel> Function({
    required String nome,
    required String codigo,
    required String tipo,
  })
  onCreate;

  @override
  State<_AgendaCentroCustoCreateDialog> createState() =>
      _AgendaCentroCustoCreateDialogState();
}

class _AgendaCentroCustoCreateDialogState
    extends State<_AgendaCentroCustoCreateDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final FocusNode _nomeFocusNode = FocusNode();

  String _tipo = 'AMBOS';
  bool _saving = false;
  String? _error;

  bool get _isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nomeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _error = context.t(
          'agenda.costCenter.nameRequired',
          fallback: 'Informe o nome do centro de custos.',
        );
      });
      _nomeFocusNode.requestFocus();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final CentroCustoModel centro = await widget.onCreate(
        nome: nome,
        codigo: _codigoController.text.trim(),
        tipo: _tipo,
      );
      if (mounted) Navigator.of(context).pop(centro);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.t(
          'agenda.costCenter.createError',
          fallback: 'Não foi possível cadastrar o centro de custos.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ThemeData theme = Theme.of(context);

    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 488),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(_isWeb ? 24 : 20),
          border: Border.all(color: tokens.cardBorder),
          boxShadow:
              _isWeb
                  ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF020617).withValues(alpha: 0.24),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ]
                  : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isWeb ? 24 : 20),
          child: Material(
            color: tokens.surfaceElevated,
            surfaceTintColor: Colors.transparent,
            child: Semantics(
              namesRoute: true,
              label: context.t(
                'agenda.costCenter.newTitle',
                fallback: 'Novo centro de custos',
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _isWeb ? 26 : 24,
                  _isWeb ? 26 : 24,
                  _isWeb ? 26 : 24,
                  _isWeb ? 22 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              tokens.info.withValues(alpha: 0.12),
                              tokens.surfaceMuted,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: tokens.selectedBorder),
                          ),
                          child: Icon(
                            Icons.account_tree_outlined,
                            color: tokens.info,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                context.t(
                                  'agenda.costCenter.newTitle',
                                  fallback: 'Novo centro de custos',
                                ),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.t(
                                  'agenda.costCenter.newSubtitle',
                                  fallback:
                                      'Organize lançamentos por área, loja ou resultado.',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.secondaryText,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildTextField(
                      controller: _nomeController,
                      focusNode: _nomeFocusNode,
                      label: context.t(
                        'agenda.costCenter.nameLabel',
                        fallback: 'Nome',
                      ),
                      icon: Icons.account_tree_outlined,
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _codigoController,
                      label: context.t(
                        'agenda.costCenter.codeLabel',
                        fallback: 'Código (opcional)',
                      ),
                      hint: 'Ex.: ADM, LOJA-01',
                      icon: Icons.tag_outlined,
                    ),
                    const SizedBox(height: 12),
                    _CentroCustoTipoSelect(
                      value: _tipo,
                      enabled: !_saving,
                      onChanged:
                          (String value) => setState(() {
                            _tipo = value;
                            _error = null;
                          }),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed:
                              _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: tokens.info,
                            backgroundColor: tokens.info.withValues(
                              alpha: 0.08,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.t('common.cancel', fallback: 'Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon:
                              _saving
                                  ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.check_rounded),
                          label: Text(
                            context.t('common.create', fallback: 'Cadastrar'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.info,
                            foregroundColor: tokens.onInfo,
                            disabledBackgroundColor: tokens.disabledBackground,
                            disabledForegroundColor: tokens.disabledForeground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
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
              ),
            ),
          ),
        ),
      ),
    );

    if (_isWeb) return content;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: content,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    String? hint,
    bool autofocus = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: !_saving,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: tokens.inputBackground,
        labelStyle: TextStyle(color: tokens.secondaryText),
        floatingLabelStyle: TextStyle(color: tokens.info),
        hintStyle: TextStyle(color: tokens.mutedText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _CentroCustoTipoSelect extends StatefulWidget {
  const _CentroCustoTipoSelect({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<_CentroCustoTipoSelect> createState() => _CentroCustoTipoSelectState();
}

class _CentroCustoTipoSelectState extends State<_CentroCustoTipoSelect> {
  final GlobalKey _triggerKey = GlobalKey();
  bool _hovered = false;
  bool _open = false;

  static const List<String> _values = <String>['AMBOS', 'CUSTO', 'RESULTADO'];

  Future<void> _showMenu() async {
    if (!widget.enabled) return;
    final RenderObject? renderObject =
        _triggerKey.currentContext?.findRenderObject();
    final RenderObject? overlayObject =
        Navigator.of(context).overlay?.context.findRenderObject();
    if (renderObject is! RenderBox || overlayObject is! RenderBox) return;

    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Offset offset = renderObject.localToGlobal(Offset.zero);
    final Size size = renderObject.size;

    setState(() => _open = true);
    final String? selected = await showMenu<String>(
      context: context,
      color: tokens.menuBackground,
      elevation: 14,
      constraints: BoxConstraints.tightFor(width: size.width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.cardBorder),
      ),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy + size.height + 8, size.width, 1),
        Offset.zero & overlayObject.size,
      ),
      items: <PopupMenuEntry<String>>[
        for (final String value in _values)
          PopupMenuItem<String>(
            value: value,
            padding: EdgeInsets.zero,
            child: _CentroCustoTipoMenuItem(
              value: value,
              selected: value == widget.value,
            ),
          ),
      ],
    );
    if (mounted) setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool highlighted = _hovered || _open;
    final Color borderColor =
        _open
            ? tokens.selectedBorder
            : highlighted
            ? tokens.info.withValues(alpha: 0.34)
            : tokens.cardBorder;
    final Color background =
        highlighted
            ? Color.alphaBlend(
              tokens.info.withValues(alpha: 0.06),
              tokens.inputBackground,
            )
            : tokens.inputBackground;

    return Semantics(
      button: true,
      label: context.t('agenda.costCenter.typeLabel', fallback: 'Tipo'),
      value: _label(context, widget.value),
      enabled: widget.enabled,
      child: Tooltip(
        message: _label(context, widget.value),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: _triggerKey,
              borderRadius: BorderRadius.circular(16),
              onTap: widget.enabled ? _showMenu : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: _open ? 1.4 : 1,
                  ),
                  boxShadow:
                      highlighted
                          ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFF020617,
                              ).withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.info.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: tokens.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            context.t(
                              'agenda.costCenter.typeLabel',
                              fallback: 'Tipo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _label(context, widget.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
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
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _open ? tokens.info : tokens.secondaryText,
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

  static String _label(BuildContext context, String value) {
    switch (value) {
      case 'CUSTO':
        return context.t(
          'agenda.costCenter.typeCost',
          fallback: 'Somente custo',
        );
      case 'RESULTADO':
        return context.t(
          'agenda.costCenter.typeResult',
          fallback: 'Somente resultado',
        );
      case 'AMBOS':
      default:
        return context.t(
          'agenda.costCenter.typeBoth',
          fallback: 'Custo e resultado',
        );
    }
  }
}

class _CentroCustoTipoMenuItem extends StatelessWidget {
  const _CentroCustoTipoMenuItem({required this.value, required this.selected});

  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? tokens.selectedBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: selected ? tokens.info : tokens.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _CentroCustoTipoSelectState._label(context, value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? tokens.primaryText : tokens.secondaryText,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
