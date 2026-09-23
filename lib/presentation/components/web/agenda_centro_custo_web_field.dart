import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_centro_custo_rename_dialog.dart';

class AgendaCentroCustoWebField extends StatefulWidget {
  const AgendaCentroCustoWebField({
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
  State<AgendaCentroCustoWebField> createState() =>
      _AgendaCentroCustoWebFieldState();
}

class _AgendaCentroCustoWebFieldState extends State<AgendaCentroCustoWebField> {
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  final GlobalKey _fieldKey = GlobalKey();
  List<CentroCustoModel> _centros = <CentroCustoModel>[];
  String? _selecionadoId;
  bool _carregando = true;
  bool _menuAberto = false;

  @override
  void initState() {
    super.initState();
    _selecionadoId = _idValido(widget.initialId);
    _carregar();
  }

  @override
  void didUpdateWidget(covariant AgendaCentroCustoWebField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialId != oldWidget.initialId) {
      _selecionadoId = _idValido(widget.initialId);
    }
  }

  String? _idValido(String? id) => (id ?? '').trim().isEmpty ? null : id;

  CentroCustoModel? get _selecionado {
    for (final CentroCustoModel centro in _centros) {
      if (centro.id == _selecionadoId) return centro;
    }
    return null;
  }

  Future<void> _carregar() async {
    try {
      final List<CentroCustoModel> centros = await _service
          .listarCentrosCusto();
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

  Future<void> _abrirMenu() async {
    if (!widget.enabled || _carregando) return;
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final Offset topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    setState(() => _menuAberto = true);
    final _CentroMenuResult? result = await showMenu<_CentroMenuResult>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints.tightFor(
        width: box.size.width.clamp(320.0, 420.0).toDouble(),
      ),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: _menuItems(),
    );
    if (mounted) setState(() => _menuAberto = false);
    if (result == null || !mounted) return;
    switch (result.action) {
      case _CentroMenuAction.select:
        _selecionar(result.centro);
        break;
      case _CentroMenuAction.clear:
        _selecionar(null);
        break;
      case _CentroMenuAction.create:
        await _cadastrar();
        break;
      case _CentroMenuAction.edit:
        if (result.centro != null) await _editar(result.centro!);
        break;
    }
  }

  List<PopupMenuEntry<_CentroMenuResult>> _menuItems() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return <PopupMenuEntry<_CentroMenuResult>>[
      PopupMenuItem<_CentroMenuResult>(
        value: const _CentroMenuResult.clear(),
        height: 52,
        child: _menuRow(
          title: context.t(
            'agenda.costCenter.none',
            fallback: 'Sem centro de custos',
          ),
          selected: _selecionadoId == null,
          icon: Icons.remove_circle_outline_rounded,
        ),
      ),
      const PopupMenuDivider(height: 1),
      ..._centros.map(
        (CentroCustoModel centro) => PopupMenuItem<_CentroMenuResult>(
          value: _CentroMenuResult.select(centro),
          height: 64,
          child: Row(
            children: <Widget>[
              Icon(
                centro.id == _selecionadoId
                    ? Icons.check_circle_rounded
                    : Icons.account_tree_outlined,
                color: centro.id == _selecionadoId
                    ? colors.primary
                    : colors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      centro.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_mostrarCodigo(centro)) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        centro.codigo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: context.t(
                  'agenda.costCenter.edit',
                  fallback: 'Editar centro de custos',
                ),
                onPressed: () =>
                    Navigator.of(context).pop(_CentroMenuResult.edit(centro)),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem<_CentroMenuResult>(
        value: const _CentroMenuResult.create(),
        height: 54,
        child: _menuRow(
          title: context.t(
            'agenda.costCenter.create',
            fallback: 'Novo centro de custos',
          ),
          selected: false,
          icon: Icons.add_circle_outline_rounded,
        ),
      ),
    ];
  }

  Widget _menuRow({
    required String title,
    required bool selected,
    required IconData icon,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(
          selected ? Icons.check_circle_rounded : icon,
          color: selected ? colors.primary : colors.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  bool _mostrarCodigo(CentroCustoModel centro) =>
      centro.codigo.trim().isNotEmpty &&
      centro.codigo.trim().toUpperCase() != centro.nome.trim().toUpperCase();

  void _selecionar(CentroCustoModel? centro) {
    setState(() => _selecionadoId = centro?.id);
    widget.onChanged(centro);
  }

  Future<void> _editar(CentroCustoModel centro) async {
    final CentroCustoModel? atualizado =
        await showSixWebCentroCustoRenameDialog(
          context: context,
          centro: centro,
          onConfirm: (String nome) =>
              _service.atualizarCentroCusto(centro: centro, nome: nome),
        );
    if (atualizado == null || !mounted) return;
    setState(() {
      _centros =
          _centros
              .map((item) => item.id == atualizado.id ? atualizado : item)
              .toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));
    });
    if (_selecionadoId == atualizado.id) widget.onChanged(atualizado);
  }

  Future<void> _cadastrar() async {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController codigoController = TextEditingController();
    String tipo = 'AMBOS';
    bool salvando = false;
    final CentroCustoModel?
    criado = await showSixWebAnimatedDialog<CentroCustoModel>(
      context: context,
      barrierDismissible: false,
      barrierLabel: context.t(
        'agenda.costCenter.create',
        fallback: 'Novo centro de custos',
      ),
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text(
              context.t(
                'agenda.costCenter.create',
                fallback: 'Novo centro de custos',
              ),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nomeController,
                    autofocus: true,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'agenda.costCenter.name',
                        fallback: 'Nome',
                      ),
                      prefixIcon: const Icon(Icons.account_tree_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codigoController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'agenda.costCenter.codeOptional',
                        fallback: 'Código (opcional)',
                      ),
                      hintText: context.t(
                        'agenda.costCenter.codeHint',
                        fallback: 'Ex.: ADM, LOJA-01',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'agenda.costCenter.type',
                        fallback: 'Tipo',
                      ),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'AMBOS',
                        child: Text(
                          context.t(
                            'agenda.costCenter.type.both',
                            fallback: 'Custo e resultado',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'CUSTO',
                        child: Text(
                          context.t(
                            'agenda.costCenter.type.cost',
                            fallback: 'Somente custo',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'RESULTADO',
                        child: Text(
                          context.t(
                            'agenda.costCenter.type.result',
                            fallback: 'Somente resultado',
                          ),
                        ),
                      ),
                    ],
                    onChanged: salvando
                        ? null
                        : (value) =>
                              setDialogState(() => tipo = value ?? 'AMBOS'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: salvando
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(context.t('common.cancel', fallback: 'Cancelar')),
              ),
              FilledButton(
                onPressed: salvando
                    ? null
                    : () async {
                        final String nome = nomeController.text.trim();
                        if (nome.isEmpty) return;
                        setDialogState(() => salvando = true);
                        try {
                          final CentroCustoModel centro = await _service
                              .criarCentroCusto(
                                nome: nome,
                                codigo: codigoController.text,
                                tipo: tipo,
                              );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(centro);
                          }
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => salvando = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.t(
                                  'agenda.costCenter.createError',
                                  fallback:
                                      'Não foi possível cadastrar o centro de custos.',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                child: salvando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        context.t(
                          'agenda.costCenter.createAction',
                          fallback: 'Cadastrar',
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
    nomeController.dispose();
    codigoController.dispose();
    if (criado == null || !mounted) return;
    setState(() {
      _centros = <CentroCustoModel>[..._centros, criado]
        ..sort((a, b) => a.nome.compareTo(b.nome));
      _selecionadoId = criado.id;
    });
    widget.onChanged(criado);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String legado = widget.initialName?.trim() ?? '';
    final String nome =
        _selecionado?.nome ??
        (legado.isEmpty
            ? context.t(
                'agenda.costCenter.none',
                fallback: 'Sem centro de custos',
              )
            : legado);
    return Semantics(
      button: true,
      enabled: widget.enabled && !_carregando,
      label:
          '${context.t('agenda.costCenter.label', fallback: 'Centro de custos')}. $nome',
      child: Material(
        key: _fieldKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: _abrirMenu,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _menuAberto ? colors.primary : colors.outlineVariant,
                width: _menuAberto ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.account_tree_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          'agenda.costCenter.label',
                          fallback: 'Centro de custos',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_carregando)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AnimatedRotation(
                    turns: _menuAberto ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.onSurfaceVariant,
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

enum _CentroMenuAction { select, clear, create, edit }

class _CentroMenuResult {
  const _CentroMenuResult._(this.action, this.centro);

  const _CentroMenuResult.select(CentroCustoModel centro)
    : this._(_CentroMenuAction.select, centro);
  const _CentroMenuResult.edit(CentroCustoModel centro)
    : this._(_CentroMenuAction.edit, centro);
  const _CentroMenuResult.clear() : this._(_CentroMenuAction.clear, null);
  const _CentroMenuResult.create() : this._(_CentroMenuAction.create, null);

  final _CentroMenuAction action;
  final CentroCustoModel? centro;
}
