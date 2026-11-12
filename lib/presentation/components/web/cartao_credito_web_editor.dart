import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

class CartaoCreditoWebEditor extends StatefulWidget {
  const CartaoCreditoWebEditor({super.key, required this.espaco, required this.client, this.item, this.contasService});
  final String espaco;
  final CartaoCreditoApiClient client;
  final CartaoCredito? item;
  final ConfiguracaoFinanceiraService? contasService;
  @override
  State<CartaoCreditoWebEditor> createState() => _CartaoCreditoWebEditorState();
}

class _CartaoCreditoWebEditorState extends State<CartaoCreditoWebEditor> {
  final _form = GlobalKey<FormState>();
  late final _id = widget.item?.id ?? gerarUuidV4();
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _instituicao = TextEditingController(text: widget.item?.instituicao ?? '');
  late final _fechamento = TextEditingController(text: widget.item?.diaFechamento.toString() ?? '');
  late final _vencimento = TextEditingController(text: widget.item?.diaVencimento.toString() ?? '');
  late final _contasService = widget.contasService ?? ConfiguracaoFinanceiraService(widget.espaco);
  late bool _ativo = widget.item?.ativo ?? true;
  late String? _contaId = widget.item?.contaPrevistaId;
  List<ConfiguracaoFinanceira> _contas = [];
  bool _saving = false, _loadingAccounts = true, _accountsError = false, _conflict = false;
  String? _error;
  CartaoCreditoRequest? _uncertainRequest;

  @override
  void initState() { super.initState(); _loadAccounts(); }

  @override
  void dispose() {
    _nome.dispose(); _instituicao.dispose(); _fechamento.dispose(); _vencimento.dispose();
    if (widget.contasService == null) _contasService.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() { _loadingAccounts = true; _accountsError = false; });
    try {
      final contas = await _contasService.listar('CONTAS').timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _contas = contas);
    } catch (_) {
      if (mounted) setState(() => _accountsError = true);
    } finally {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _conflict || !_form.currentState!.validate()) return;
    final request = _uncertainRequest ?? CartaoCreditoRequest(
      id: _id, nome: _nome.text, instituicao: _instituicao.text,
      diaFechamento: int.parse(_fechamento.text), diaVencimento: int.parse(_vencimento.text),
      contaPrevistaId: _contaId, ativo: _ativo, versao: widget.item?.versao,
    );
    setState(() { _saving = true; _error = null; });
    try {
      final result = await widget.client.salvar(request);
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      final apiError = error is CartaoCreditoApiException ? error : const CartaoCreditoApiException('server');
      setState(() {
        _saving = false;
        _error = apiError.messageKey;
        _conflict = apiError.kind == 'conflict';
        // An uncertain response may already be committed. Retry the exact same
        // command and ID before allowing a different edit; never invent success.
        if (['connection', 'server', 'invalidResponse'].contains(apiError.kind)) {
          _uncertainRequest = request;
        } else {
          _uncertainRequest = null;
        }
      });
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? context.t('space.required') : null;
  Widget _dayField(TextEditingController controller, String key) => TextFormField(
    key: ValueKey(key), controller: controller,
    enabled: !_saving && _uncertainRequest == null,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
    decoration: InputDecoration(labelText: context.t(key)),
    validator: (text) {
      final day = int.tryParse(text ?? '');
      return day == null || day < 1 || day > 31 ? context.t('cards.dayValidation') : null;
    },
  );

  @override
  Widget build(BuildContext context) {
    final enabled = !_saving && _uncertainRequest == null;
    final options = _contas.where((c) => c.ativo || c.id == _contaId).toList();
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.t(widget.item == null ? 'cards.new' : 'cards.edit'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(context.t('space.${widget.espaco}')),
          const SizedBox(height: 24),
          TextFormField(key: const ValueKey('cards-name'), controller: _nome, enabled: enabled,
            autofocus: true, maxLength: 120, decoration: InputDecoration(labelText: context.t('space.name')), validator: _required),
          const SizedBox(height: 12),
          TextFormField(key: const ValueKey('cards-institution'), controller: _instituicao, enabled: enabled,
            maxLength: 120, decoration: InputDecoration(labelText: context.t('cards.institution')), validator: _required),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final fields = [_dayField(_fechamento, 'cards.closing'), _dayField(_vencimento, 'cards.due')];
            if (constraints.maxWidth < 400) {
              return Column(children: [fields[0], const SizedBox(height: 16), fields[1]]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: fields[0]), const SizedBox(width: 16), Expanded(child: fields[1])]);
          }),
          const SizedBox(height: 12),
          Text(context.t('cards.daysHint'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          if (_loadingAccounts)
            SixBackendLoading(title: context.t('space.loading'), subtitle: context.t('cards.account'), compact: true)
          else if (_accountsError) ...[
            Text(context.t('cards.accountsError')),
            TextButton(onPressed: _saving ? null : _loadAccounts, child: Text(context.t('space.retry'))),
          ],
          DropdownButtonFormField<String>(
            key: ValueKey('cards-account-${_contaId ?? 'none'}-${_contas.length}'),
            initialValue: _contaId ?? '',
            isExpanded: true,
            decoration: InputDecoration(labelText: context.t('cards.account')),
            items: [
              DropdownMenuItem(value: '', child: Text(context.t('space.none'))),
              if (_contaId != null && !options.any((c) => c.id == _contaId))
                DropdownMenuItem(value: _contaId, child: Text(widget.item?.contaPrevistaNome ?? context.t('cards.linkedAccount'), overflow: TextOverflow.ellipsis)),
              for (final conta in options)
                DropdownMenuItem(value: conta.id, child: Text('${conta.nome}${conta.ativo ? '' : ' (${context.t('space.inactive')})'}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: enabled && !_loadingAccounts && !_accountsError
                ? (value) => setState(() => _contaId = value == '' ? null : value) : null,
          ),
          const SizedBox(height: 8),
          Text(context.t('cards.accountHint'), style: Theme.of(context).textTheme.bodySmall),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
            title: Text(context.t('space.active')), subtitle: Text(context.t('cards.activeHint')),
            value: _ativo, onChanged: enabled ? (value) => setState(() => _ativo = value) : null),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Text(context.t(_error!), style: TextStyle(color: Theme.of(context).colorScheme.error))),
            if (_uncertainRequest != null) Text(context.t('cards.retrySaveHint')),
          ],
          const SizedBox(height: 24),
          Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 8, children: [
            TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(context.t('space.cancel'))),
            FilledButton(key: const ValueKey('cards-save'), onPressed: _saving || _conflict ? null : _save,
              child: Text(context.t(_saving ? 'space.loading' : _uncertainRequest != null ? 'space.retry' : 'space.save'))),
          ]),
        ]),
      )),
    );
  }
}
