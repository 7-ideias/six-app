import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'conta_financeira_mobile_field.dart';
import 'marca_financeira_mobile_selector.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/data/models/marca_financeira_catalogo.dart';
import 'package:sixpos/presentation/components/marca_financeira_avatar.dart';

class ConfiguracaoFinanceiraMobileEditor extends StatefulWidget {
  const ConfiguracaoFinanceiraMobileEditor({
    super.key,
    required this.service,
    required this.grupo,
    this.item,
    this.selecionarAoCriar = false,
    this.catalogo = CatalogoInstituicoesBrasil.vazio,
  }) : assert(!selecionarAoCriar || (grupo == 'CONTAS' && item == null));
  final ConfiguracaoFinanceiraService service;
  final String grupo;
  final ConfiguracaoFinanceira? item;
  final bool selecionarAoCriar;
  final CatalogoInstituicoesBrasil catalogo;
  @override
  State<ConfiguracaoFinanceiraMobileEditor> createState() =>
      _ConfiguracaoFinanceiraMobileEditorState();
}

class _ConfiguracaoFinanceiraMobileEditorState
    extends State<ConfiguracaoFinanceiraMobileEditor> {
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _instituicao = TextEditingController(
    text: widget.item?.instituicao ?? '',
  );
  late String? _marcaId = widget.item?.marcaId;
  late String _tipo =
      widget.item?.tipo ?? (widget.grupo == 'CONTAS' ? 'BANCO' : 'AMBOS');
  late bool _ativo = widget.item?.ativo ?? true;
  late String? _contaDestinoId = widget.item?.contaDestinoId;
  bool _saving = false;
  bool _error = false;
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _nome.dispose();
    _instituicao.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      if (widget.selecionarAoCriar) {
        final conta = await widget.service.criarConta(
          nome: _nome.text,
          tipo: _tipo,
          instituicao: _instituicao.text,
          marcaId: _marcaId,
        );
        if (mounted) Navigator.of(context).pop(conta);
        return;
      }
      await widget.service.salvar(
        widget.grupo,
        original: widget.item,
        nome: _nome.text,
        tipo: widget.grupo == 'MAQUININHAS' ? 'MAQUININHA' : _tipo,
        contaDestinoId: _contaDestinoId,
        instituicao: _instituicao.text,
        marcaId: _marcaId,
        ativo: _ativo,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = true;
        });
    }
  }

  bool get _podeEscolherMarca =>
      widget.catalogo.habilitado &&
      ((widget.grupo == 'CONTAS' && _tipo == 'BANCO' &&
          widget.catalogo.instituicoes.isNotEmpty) ||
          widget.grupo == 'MAQUININHAS');

  String? get _logoAtual {
    if (!_podeEscolherMarca) return null;
    if (widget.grupo == 'MAQUININHAS') {
      return MarcaFinanceiraCatalogo.logoOperadora(
        _instituicao.text, _marcaId, habilitadoBrasil: true,
      );
    }
    return widget.catalogo.logotipoDe(
      _instituicao.text,
      marcaOpenFinanceId:
          _marcaId?.startsWith('OF:') == true ? _marcaId!.substring(3) : null,
    );
  }

  Future<void> _escolherMarca() async {
    if (_saving || !_podeEscolherMarca) return;
    final maquininha = widget.grupo == 'MAQUININHAS';
    final opcoes = maquininha
        ? MarcaFinanceiraCatalogo.operadorasParaSelecao()
        : widget.catalogo.instituicoes;
    final selecionada = await selecionarMarcaFinanceiraMobile(
      context,
      titulo: context.t(maquininha
          ? 'financialBrand.searchOperator'
          : 'financialBrand.searchBank'),
      tipo: maquininha ? 'MAQUININHA' : 'BANCO',
      instituicoes: opcoes,
    );
    if (!mounted || selecionada == null) return;
    setState(() {
      _instituicao.text = selecionada.nome;
      final codigo = selecionada.marcaOpenFinanceId;
      _marcaId = codigo == null || codigo.isEmpty
          ? null : maquininha ? codigo : 'OF:$codigo';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t(
                  widget.selecionarAoCriar
                      ? 'space.createAccount'
                      : 'space.' + widget.grupo,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.selecionarAoCriar) ...[
                const SizedBox(height: 8),
                Text(context.t('space.' + widget.service.espaco)),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                enabled: !_saving,
                maxLength: 120,
                decoration: InputDecoration(labelText: context.t('space.name')),
                validator:
                    (s) =>
                        s == null || s.trim().isEmpty
                            ? context.t('space.required')
                            : null,
              ),
              if (widget.grupo == 'CONTAS' || widget.grupo == 'MAQUININHAS') ...[
                TextField(
                  key: const ValueKey('financial-brand-institution-mobile'),
                  controller: _instituicao,
                  enabled: !_saving,
                  onChanged: (_) => setState(() => _marcaId = null),
                  maxLength: 120,
                  decoration: InputDecoration(
                    prefixIcon: _logoAtual == null ? null : Padding(
                      padding: const EdgeInsets.all(7),
                      child: MarcaFinanceiraAvatar(
                        key: const ValueKey('financial-brand-preview-mobile'),
                        nome: _instituicao.text,
                        tipo: widget.grupo == 'MAQUININHAS'
                            ? 'MAQUININHA' : 'BANCO',
                        logotipoUrl: _logoAtual,
                        size: 36,
                      ),
                    ),
                    labelText: context.t(widget.grupo == 'MAQUININHAS'
                        ? 'machine.operator' : 'space.institution'),
                  ),
                ),
                if (_podeEscolherMarca) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('financial-brand-choose-mobile'),
                    onPressed: _saving ? null : _escolherMarca,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(context.t(widget.grupo == 'MAQUININHAS'
                        ? 'financialBrand.chooseOperator'
                        : 'financialBrand.chooseBank')),
                  ),
                  const SizedBox(height: 6),
                  Text(context.t(widget.grupo == 'MAQUININHAS'
                      ? 'financialBrand.operatorHint'
                      : 'financialBrand.bankHint'),
                    style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 14),
                ],
              ],
              if (widget.grupo == 'MAQUININHAS')
                ContaFinanceiraMobileField(
                  espaco: widget.service.espaco,
                  service: widget.service,
                  value: _contaDestinoId,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _contaDestinoId = v),
                ),
              if (widget.grupo != 'MAQUININHAS')
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tipo
                        in (widget.grupo == 'CONTAS'
                            ? ['BANCO', 'CARTEIRA', 'CAIXA']
                            : widget.grupo == 'CENTROS'
                            ? ['CUSTO', 'RESULTADO', 'AMBOS']
                            : ['RECEITA', 'DESPESA', 'AMBOS']))
                      ChoiceChip(
                        label: Text(context.t('space.' + tipo)),
                        selected: tipo == _tipo,
                        onSelected:
                            _saving
                                ? null
                                : (_) => setState(() {
                                  _tipo = tipo;
                                  if (_tipo != 'BANCO') _marcaId = null;
                                }),
                      ),
                  ],
                ),
              if (!widget.selecionarAoCriar)
                SwitchListTile.adaptive(
                  title: Text(context.t('space.active')),
                  value: _ativo,
                  onChanged: _saving ? null : (v) => setState(() => _ativo = v),
                ),
              if (!widget.selecionarAoCriar) Text(context.t('space.history')),
              if (_error)
                Text(
                  context.t('space.saveError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  context.t(_saving ? 'space.loading' : 'space.save'),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(context.t('space.cancel')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
