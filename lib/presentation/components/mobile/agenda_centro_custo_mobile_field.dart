import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_selection_sheet.dart';

class AgendaCentroCustoMobileField extends StatefulWidget {
  const AgendaCentroCustoMobileField({
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
  State<AgendaCentroCustoMobileField> createState() =>
      _AgendaCentroCustoMobileFieldState();
}

class _AgendaCentroCustoMobileFieldState
    extends State<AgendaCentroCustoMobileField> {
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  List<CentroCustoModel> _centros = <CentroCustoModel>[];
  String? _selecionadoId;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _selecionadoId = _idValido(widget.initialId);
    _carregar();
  }

  @override
  void didUpdateWidget(covariant AgendaCentroCustoMobileField oldWidget) {
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

  Future<void> _abrirSeletor() async {
    if (!widget.enabled || _carregando) return;
    final _CentroMobileResult? result =
        await showModalBottomSheet<_CentroMobileResult>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          builder: (BuildContext context) => _CentroCustoSelectionSheet(
            centros: _centros,
            selecionadoId: _selecionadoId,
          ),
        );
    if (result == null || !mounted) return;
    switch (result.action) {
      case _CentroMobileAction.select:
        _selecionar(result.centro);
        break;
      case _CentroMobileAction.clear:
        _selecionar(null);
        break;
      case _CentroMobileAction.create:
        await _cadastrar();
        break;
      case _CentroMobileAction.edit:
        if (result.centro != null) await _editar(result.centro!);
        break;
    }
  }

  void _selecionar(CentroCustoModel? centro) {
    setState(() => _selecionadoId = centro?.id);
    widget.onChanged(centro);
  }

  Future<void> _cadastrar() async {
    final CentroCustoModel? criado =
        await showModalBottomSheet<CentroCustoModel>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          builder: (BuildContext context) => _CentroCustoCreateSheet(
            onSave:
                ({
                  required String nome,
                  required String codigo,
                  required String tipo,
                }) => _service.criarCentroCusto(
                  nome: nome,
                  codigo: codigo,
                  tipo: tipo,
                ),
          ),
        );
    if (criado == null || !mounted) return;
    setState(() {
      _centros = <CentroCustoModel>[..._centros, criado]
        ..sort((a, b) => a.nome.compareTo(b.nome));
      _selecionadoId = criado.id;
    });
    widget.onChanged(criado);
  }

  Future<void> _editar(CentroCustoModel centro) async {
    final CentroCustoModel? atualizado =
        await showModalBottomSheet<CentroCustoModel>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          isDismissible: false,
          enableDrag: false,
          builder: (BuildContext context) => _CentroCustoRenameSheet(
            centro: centro,
            onConfirm: (String nome) =>
                _service.atualizarCentroCusto(centro: centro, nome: nome),
          ),
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

  @override
  Widget build(BuildContext context) {
    final String legado = widget.initialName?.trim() ?? '';
    final String? nome = _selecionado?.nome ?? (legado.isEmpty ? null : legado);
    return SixMobileSelectionField(
      label: context.t('agenda.costCenter.label', fallback: 'Centro de custos'),
      value: nome,
      hint: _carregando
          ? context.t('common.loading', fallback: 'Carregando...')
          : context.t(
              'agenda.costCenter.none',
              fallback: 'Sem centro de custos',
            ),
      icon: Icons.account_tree_outlined,
      enabled: widget.enabled && !_carregando,
      onTap: _abrirSeletor,
    );
  }
}

class _CentroCustoSelectionSheet extends StatelessWidget {
  const _CentroCustoSelectionSheet({
    required this.centros,
    required this.selecionadoId,
  });

  final List<CentroCustoModel> centros;
  final String? selecionadoId;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.strongBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.t(
                              'agenda.costCenter.selectTitle',
                              fallback: 'Selecionar centro de custos',
                            ),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colors.titleText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t(
                              'agenda.costCenter.selectHint',
                              fallback: 'Toque no lápis para editar um nome.',
                            ),
                            style: TextStyle(color: colors.mutedText),
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: <Widget>[
                    _CentroCustoMobileTile(
                      title: context.t(
                        'agenda.costCenter.none',
                        fallback: 'Sem centro de custos',
                      ),
                      selected: selecionadoId == null,
                      icon: Icons.remove_circle_outline_rounded,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(const _CentroMobileResult.clear()),
                    ),
                    ...centros.map(
                      (CentroCustoModel centro) => _CentroCustoMobileTile(
                        title: centro.nome,
                        subtitle: _mostrarCodigo(centro) ? centro.codigo : null,
                        selected: centro.id == selecionadoId,
                        icon: Icons.account_tree_outlined,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_CentroMobileResult.select(centro)),
                        onEdit: () => Navigator.of(
                          context,
                        ).pop(_CentroMobileResult.edit(centro)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const _CentroMobileResult.create()),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(
                        context.t(
                          'agenda.costCenter.create',
                          fallback: 'Novo centro de custos',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _mostrarCodigo(CentroCustoModel centro) =>
      centro.codigo.trim().isNotEmpty &&
      centro.codigo.trim().toUpperCase() != centro.nome.trim().toUpperCase();
}

class _CentroCustoMobileTile extends StatelessWidget {
  const _CentroCustoMobileTile({
    required this.title,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? Icons.check_circle_rounded : icon,
                  color: selected ? colors.accent : colors.mutedText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((subtitle ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: context.t(
                      'agenda.costCenter.edit',
                      fallback: 'Editar centro de custos',
                    ),
                    onPressed: onEdit,
                    color: colors.accent,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _CreateCentroCallback =
    Future<CentroCustoModel> Function({
      required String nome,
      required String codigo,
      required String tipo,
    });

class _CentroCustoCreateSheet extends StatefulWidget {
  const _CentroCustoCreateSheet({required this.onSave});

  final _CreateCentroCallback onSave;

  @override
  State<_CentroCustoCreateSheet> createState() =>
      _CentroCustoCreateSheetState();
}

class _CentroCustoCreateSheetState extends State<_CentroCustoCreateSheet> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  String _tipo = 'AMBOS';
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final String nome = _nomeController.text.trim();
    if (_salvando || nome.isEmpty) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final CentroCustoModel centro = await widget.onSave(
        nome: nome,
        codigo: _codigoController.text,
        tipo: _tipo,
      );
      if (mounted) Navigator.of(context).pop(centro);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = context.t(
          'agenda.costCenter.createError',
          fallback: 'Não foi possível cadastrar o centro de custos.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.t(
                    'agenda.costCenter.create',
                    fallback: 'Novo centro de custos',
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nomeController,
                  autofocus: true,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'agenda.costCenter.name',
                      fallback: 'Nome',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codigoController,
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _tipoChip(
                      'AMBOS',
                      'agenda.costCenter.type.both',
                      'Custo e resultado',
                    ),
                    _tipoChip(
                      'CUSTO',
                      'agenda.costCenter.type.cost',
                      'Somente custo',
                    ),
                    _tipoChip(
                      'RESULTADO',
                      'agenda.costCenter.type.result',
                      'Somente resultado',
                    ),
                  ],
                ),
                if (_erro != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(_erro!, style: TextStyle(color: colors.error)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    context.t(
                      'agenda.costCenter.createAction',
                      fallback: 'Cadastrar',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _salvando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipoChip(String value, String key, String fallback) {
    return ChoiceChip(
      label: Text(context.t(key, fallback: fallback)),
      selected: _tipo == value,
      onSelected: _salvando ? null : (_) => setState(() => _tipo = value),
    );
  }
}

enum _RenameMobileStep { edit, review, processing, success, error }

class _CentroCustoRenameSheet extends StatefulWidget {
  const _CentroCustoRenameSheet({
    required this.centro,
    required this.onConfirm,
  });

  final CentroCustoModel centro;
  final Future<CentroCustoModel> Function(String nome) onConfirm;

  @override
  State<_CentroCustoRenameSheet> createState() =>
      _CentroCustoRenameSheetState();
}

class _CentroCustoRenameSheetState extends State<_CentroCustoRenameSheet> {
  late final TextEditingController _controller;
  _RenameMobileStep _step = _RenameMobileStep.edit;
  String _novoNome = '';

  bool get _busy =>
      _step == _RenameMobileStep.processing ||
      _step == _RenameMobileStep.success;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.centro.nome);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _revisar() {
    final String nome = _controller.text.trim();
    if (nome.isEmpty || nome == widget.centro.nome.trim()) return;
    setState(() {
      _novoNome = nome;
      _step = _RenameMobileStep.review;
    });
  }

  Future<void> _confirmar() async {
    if (_busy) return;
    setState(() => _step = _RenameMobileStep.processing);
    try {
      final CentroCustoModel atualizado = await widget.onConfirm(_novoNome);
      if (!mounted) return;
      setState(() => _step = _RenameMobileStep.success);
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      await Future<void>.delayed(
        Duration(milliseconds: reduceMotion ? 1 : 650),
      );
      if (mounted) Navigator.of(context).pop(atualizado);
    } catch (_) {
      if (mounted) setState(() => _step = _RenameMobileStep.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _content(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(SixMobileColorScheme colors) {
    if (_step == _RenameMobileStep.processing ||
        _step == _RenameMobileStep.success) {
      final bool success = _step == _RenameMobileStep.success;
      return Padding(
        key: ValueKey<_RenameMobileStep>(_step),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            success
                ? Icon(
                    Icons.check_circle_outline_rounded,
                    color: colors.accent,
                    size: 54,
                  )
                : CircularProgressIndicator(color: colors.accent),
            const SizedBox(height: 18),
            Text(
              success
                  ? context.t(
                      'agenda.costCenter.rename.success',
                      fallback: 'Nome atualizado',
                    )
                  : context.t(
                      'agenda.costCenter.rename.processing',
                      fallback: 'Atualizando centro de custos...',
                    ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      key: ValueKey<_RenameMobileStep>(_step),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.strongBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _step == _RenameMobileStep.edit
                ? context.t(
                    'agenda.costCenter.rename.title',
                    fallback: 'Alterar nome do centro de custos',
                  )
                : context.t(
                    'agenda.costCenter.rename.confirmTitle',
                    fallback: 'Confirmar alteração?',
                  ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (_step == _RenameMobileStep.edit)
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 120,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.t(
                  'agenda.costCenter.name',
                  fallback: 'Nome',
                ),
              ),
            )
          else ...<Widget>[
            _renameValue(
              colors,
              'agenda.costCenter.rename.current',
              'Nome atual',
              widget.centro.nome,
            ),
            const SizedBox(height: 8),
            _renameValue(
              colors,
              'agenda.costCenter.rename.new',
              'Novo nome',
              _novoNome,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.softAccentSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.accent),
              ),
              child: Text(
                context.t(
                  'agenda.costCenter.rename.impact',
                  fallback:
                      'Os lançamentos já vinculados passarão a exibir o novo nome. Valores, datas e vínculos não serão alterados.',
                ),
                style: TextStyle(color: colors.titleText, height: 1.4),
              ),
            ),
            if (_step == _RenameMobileStep.error) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                context.t(
                  'agenda.costCenter.rename.error',
                  fallback: 'Não foi possível alterar o nome. Tente novamente.',
                ),
                style: TextStyle(color: colors.error),
              ),
            ],
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _step == _RenameMobileStep.edit
                ? (_controller.text.trim().isEmpty ||
                          _controller.text.trim() == widget.centro.nome.trim()
                      ? null
                      : _revisar)
                : _confirmar,
            icon: Icon(
              _step == _RenameMobileStep.edit
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded,
            ),
            label: Text(
              _step == _RenameMobileStep.edit
                  ? context.t(
                      'agenda.costCenter.rename.reviewAction',
                      fallback: 'Revisar alteração',
                    )
                  : context.t(
                      'agenda.costCenter.rename.confirmAction',
                      fallback: 'Confirmar alteração',
                    ),
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    if (_step == _RenameMobileStep.edit) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _step = _RenameMobileStep.edit);
                    }
                  },
            child: Text(
              _step == _RenameMobileStep.edit
                  ? context.t('common.cancel', fallback: 'Cancelar')
                  : context.t('common.back', fallback: 'Voltar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renameValue(
    SixMobileColorScheme colors,
    String key,
    String fallback,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(key, fallback: fallback),
            style: TextStyle(color: colors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _CentroMobileAction { select, clear, create, edit }

class _CentroMobileResult {
  const _CentroMobileResult._(this.action, this.centro);

  const _CentroMobileResult.select(CentroCustoModel centro)
    : this._(_CentroMobileAction.select, centro);
  const _CentroMobileResult.edit(CentroCustoModel centro)
    : this._(_CentroMobileAction.edit, centro);
  const _CentroMobileResult.clear() : this._(_CentroMobileAction.clear, null);
  const _CentroMobileResult.create() : this._(_CentroMobileAction.create, null);

  final _CentroMobileAction action;
  final CentroCustoModel? centro;
}
