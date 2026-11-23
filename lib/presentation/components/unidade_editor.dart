import 'package:flutter/material.dart';
import '../../data/services/unidades/catalogo_unidades.dart';
import '../../l10n/six_i18n.dart';
import 'web/six_web_select_field.dart';
import 'mobile/six_mobile_selection_sheet.dart';

Future<CatalogoUnidades?> editarUnidade(
  BuildContext context,
  CatalogoUnidades catalogo, {
  Unidade? unidade,
  required bool mobile,
}) {
  return showDialog<CatalogoUnidades>(
    context: context,
    builder:
        (_) => _Editor(catalogo: catalogo, unidade: unidade, mobile: mobile),
  );
}

class _Editor extends StatefulWidget {
  const _Editor({
    required this.catalogo,
    required this.unidade,
    required this.mobile,
  });
  final CatalogoUnidades catalogo;
  final Unidade? unidade;
  final bool mobile;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late String codigo = widget.unidade?.codigo ?? '';
  late String categoria = widget.unidade?.categoria ?? 'UNIDADE';
  String nome = '';
  String? nomeOriginal;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nomeOriginal == null) {
      nomeOriginal =
          widget.unidade?.nome(Localizations.localeOf(context).languageCode) ??
          '';
      nome = nomeOriginal!;
    }
  }

  late bool ativa = widget.unidade?.ativa ?? true;
  late bool padrao = codigo == widget.catalogo.padrao;
  bool ocupado = false;
  String? erro;
  static const categorias = [
    'UNIDADE',
    'AREA',
    'DISTANCIA',
    'VOLUME',
    'TEMPO',
    'PESO',
    'MOEDA',
  ];

  Future<void> salvar() async {
    if (codigo.trim().isEmpty ||
        (nome.trim().isEmpty && widget.unidade?.dados['pt'] == null) ||
        (widget.unidade == null &&
            widget.catalogo.buscar(codigo.trim()) != null)) {
      setState(() => erro = 'invalid');
      return;
    }
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      final atualizado = await UnidadesApi.salvar(widget.catalogo, {
        'codigo': codigo.trim(),
        'categoria': categoria,
        'nome':
            nome == nomeOriginal &&
                    (widget.unidade?.dados['nome'] as String? ?? '').isEmpty
                ? ''
                : nome.trim(),
        'ativa': ativa,
        'padrao': padrao,
      });
      if (mounted) Navigator.pop(context, atualizado);
    } catch (e) {
      if (mounted)
        setState(() {
          ocupado = false;
          erro = e is UnidadeApiErro && e.status == 409 ? 'conflict' : 'error';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final idioma = Localizations.localeOf(context).languageCode;
    final editar = widget.unidade != null;
    final categoriaEditavel =
        !editar || widget.catalogo.buscar(widget.unidade!.codigo) == null;
    String titulo(String cat) =>
        context.t('produto.unitCategory.${cat.toLowerCase()}', fallback: cat);
    final categoriaLabel = context.t('produto.fields.unitCategory');
    return AlertDialog(
      title: Text(context.t(editar ? 'units.edit' : 'units.add')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nome,
                autofocus: true,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: context.t('units.name'),
                  hintText: widget.unidade?.nome(idioma),
                ),
                onChanged: (v) => nome = v,
              ),
              TextFormField(
                initialValue: codigo,
                enabled: !editar,
                maxLength: 24,
                decoration: InputDecoration(
                  labelText: context.t('units.symbol'),
                ),
                onChanged: (v) => codigo = v,
              ),
              if (widget.mobile)
                SixMobileSelectionField(
                  label: categoriaLabel,
                  value: titulo(categoria),
                  icon: Icons.straighten,
                  enabled: categoriaEditavel,
                  onTap: () async {
                    final v = await showSixMobileSelectionSheet<String>(
                      context: context,
                      title: categoriaLabel,
                      options:
                          categorias
                              .map(
                                (c) => SixMobileSelectionOption(
                                  value: c,
                                  title: titulo(c),
                                ),
                              )
                              .toList(),
                      selectedValue: categoria,
                      emptyTitle: categoriaLabel,
                    );
                    if (v != null && mounted) setState(() => categoria = v);
                  },
                )
              else
                SixWebSelectField(
                  label: categoriaLabel,
                  value: titulo(categoria),
                  items: categorias.map(titulo).toList(),
                  enabled: categoriaEditavel,
                  onSelected:
                      (v) => setState(
                        () =>
                            categoria = categorias.firstWhere(
                              (c) => titulo(c) == v,
                            ),
                      ),
                ),
              SwitchListTile(
                title: Text(context.t('units.active')),
                value: ativa,
                onChanged:
                    !widget.catalogo.podeConfigurar || padrao
                        ? null
                        : (v) => setState(() => ativa = v),
              ),
              SwitchListTile(
                title: Text(context.t('units.default')),
                value: padrao,
                onChanged:
                    !widget.catalogo.podeConfigurar ||
                            codigo == widget.catalogo.padrao
                        ? null
                        : (v) => setState(() {
                          padrao = v;
                          if (v) ativa = true;
                        }),
              ),
              if (editar) Text(context.t('units.history')),
              if (erro != null)
                Text(
                  context.t('units.$erro'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: ocupado ? null : () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: ocupado ? null : salvar,
          child: Text(context.t('common.save')),
        ),
      ],
    );
  }
}
