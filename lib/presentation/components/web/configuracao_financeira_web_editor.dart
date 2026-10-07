import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'conta_financeira_web_field.dart';

class ConfiguracaoFinanceiraWebEditor extends StatefulWidget {
  const ConfiguracaoFinanceiraWebEditor({
    super.key,
    required this.service,
    required this.grupo,
    this.item,
    this.selecionarAoCriar = false,
  }) : assert(!selecionarAoCriar || (grupo == 'CONTAS' && item == null));
  final ConfiguracaoFinanceiraService service;
  final String grupo;
  final ConfiguracaoFinanceira? item;
  final bool selecionarAoCriar;
  @override
  State<ConfiguracaoFinanceiraWebEditor> createState() =>
      _ConfiguracaoFinanceiraWebEditorState();
}

class _ConfiguracaoFinanceiraWebEditorState
    extends State<ConfiguracaoFinanceiraWebEditor> {
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _instituicao = TextEditingController(
    text: widget.item?.instituicao ?? '',
  );
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
              if (widget.grupo == 'CONTAS' || widget.grupo == 'MAQUININHAS')
                TextField(
                  controller: _instituicao,
                  enabled: !_saving,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.t(
                      widget.grupo == 'MAQUININHAS'
                          ? 'machine.operator'
                          : 'space.institution',
                    ),
                  ),
                ),
              if (widget.grupo == 'MAQUININHAS')
                ContaFinanceiraWebField(
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
                                : (_) => setState(() => _tipo = tipo),
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
