import 'package:flutter/material.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/sub_painel_cadastro_cliente.dart';

typedef ClienteUsuarioSavedCallback = Future<void> Function(ClienteUsuario cliente);

void showClienteUsuarioCadastroWebDialog(
  BuildContext context, {
  ClienteUsuario? cliente,
  ClienteUsuarioApiClient? apiClient,
  ClienteUsuarioSavedCallback? onSaved,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SubPainelCadastroCliente(
      textoDaAppBar: cliente == null ? 'Cadastro de Clientes' : 'Edição de Clientes',
      body: _ClienteUsuarioCadastroWebBody(
        cliente: cliente,
        apiClient: apiClient,
        onSaved: onSaved,
      ),
    ),
  );
}

class _ClienteUsuarioCadastroWebBody extends StatefulWidget {
  const _ClienteUsuarioCadastroWebBody({this.cliente, this.apiClient, this.onSaved});

  final ClienteUsuario? cliente;
  final ClienteUsuarioApiClient? apiClient;
  final ClienteUsuarioSavedCallback? onSaved;

  @override
  State<_ClienteUsuarioCadastroWebBody> createState() => _ClienteUsuarioCadastroWebBodyState();
}

class _ClienteUsuarioCadastroWebBodyState extends State<_ClienteUsuarioCadastroWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ClienteUsuarioApiClient _api;
  late final TextEditingController _nome;
  late final TextEditingController _documento;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _cep;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  late final TextEditingController _uf;
  late final TextEditingController _limite;
  late final TextEditingController _prazo;
  late final TextEditingController _observacoes;

  String _tipoPessoa = 'PF';
  bool _ativo = true;
  bool _permiteFiado = true;
  bool _bloqueadoFiado = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ClienteUsuario? c = widget.cliente;
    _api = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _tipoPessoa = c?.tipoPessoa == 'PJ' ? 'PJ' : 'PF';
    _ativo = c?.ativo ?? true;
    _permiteFiado = c?.permiteCompraFiado ?? true;
    _bloqueadoFiado = c?.bloqueadoFiado ?? false;
    _nome = TextEditingController(text: c?.nome ?? '');
    _documento = TextEditingController(text: c?.documento ?? '');
    _telefone = TextEditingController(text: c?.telefone ?? '+55');
    _email = TextEditingController(text: c?.email ?? '');
    _cep = TextEditingController(text: c?.cep ?? '');
    _logradouro = TextEditingController(text: c?.logradouro ?? '');
    _numero = TextEditingController(text: c?.numero ?? '');
    _bairro = TextEditingController(text: c?.bairro ?? '');
    _cidade = TextEditingController(text: c?.cidade ?? '');
    _uf = TextEditingController(text: c?.uf ?? '');
    _limite = TextEditingController(text: (c?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','));
    _prazo = TextEditingController(text: '${c?.prazoPagamentoDias == 0 ? 30 : c?.prazoPagamentoDias ?? 30}');
    _observacoes = TextEditingController(text: c?.observacoes ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _nome,
      _documento,
      _telefone,
      _email,
      _cep,
      _logradouro,
      _numero,
      _bairro,
      _cidade,
      _uf,
      _limite,
      _prazo,
      _observacoes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _money(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '.').trim()) ?? 0;
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final ClienteUsuarioRequest request = ClienteUsuarioRequest(
        ativo: _ativo,
        tipoPessoa: _tipoPessoa,
        documento: _documento.text.trim(),
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        email: _email.text.trim(),
        cep: _cep.text.trim(),
        logradouro: _logradouro.text.trim(),
        numero: _numero.text.trim(),
        complemento: '',
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        uf: _uf.text.trim().toUpperCase(),
        observacoes: _observacoes.text.trim(),
        foto: widget.cliente?.foto ?? '',
        permiteCompraFiado: _permiteFiado,
        limiteFiado: _permiteFiado ? _money(_limite.text) : 0,
        prazoPagamentoDias: _permiteFiado ? int.tryParse(_prazo.text.trim()) ?? 0 : 0,
        bloqueadoFiado: _permiteFiado && _bloqueadoFiado,
      );
      final ClienteUsuario saved = widget.cliente == null ? await _api.cadastrarClienteUsuario(request) : await _api.atualizarClienteUsuario(widget.cliente!.id, request);
      await widget.onSaved?.call(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente salvo com sucesso.'), behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o cliente.'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _fieldWidth({required bool telaGrande, required bool telaMedia, required double grande, required double media}) {
    if (telaGrande) return grande;
    if (telaMedia) return media;
    return double.infinity;
  }

  InputDecoration _dec(String label, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: _saving,
      keyboardType: keyboardType,
      decoration: _dec(label, icon),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _section({
    required int order,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return SixWebEntry(
      order: order,
      child: SixWebSectionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        child: child,
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool editing = widget.cliente != null;
    return SixWebEntry(
      order: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(editing ? Icons.edit_outlined : Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        editing ? 'Editar cliente' : 'Novo cliente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dados essenciais para vendas, assistência técnica, relacionamento e compras a prazo.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _statusPill(editing ? 'Atualizando cadastro' : 'Pronto para cadastro', editing ? Icons.manage_accounts_outlined : Icons.verified_user_outlined),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? colorScheme.primary.withValues(alpha: 0.05) : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: value ? colorScheme.primary.withValues(alpha: 0.18) : colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: value, onChanged: _saving ? null : (bool newValue) => setState(() => onChanged(newValue))),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String nome = _nome.text.trim().isEmpty ? 'Cliente sem nome' : _nome.text.trim();
    final String documento = _documento.text.trim().isEmpty ? 'Documento não informado' : _documento.text.trim();
    final bool creditoLiberado = _permiteFiado && !_bloqueadoFiado;

    return SixWebEntry(
      order: 5,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
                  child: Text(_initials(nome), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Resumo do cadastro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text('Conferência rápida antes de salvar.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _summaryRow('Nome', nome),
            _summaryRow('Documento', '$_tipoPessoa • $documento'),
            _summaryRow('Contato', _telefone.text.trim().isEmpty ? 'Telefone não informado' : _telefone.text.trim()),
            _summaryRow('Cidade/UF', _cidade.text.trim().isEmpty && _uf.text.trim().isEmpty ? 'Endereço incompleto' : '${_cidade.text.trim()} ${_uf.text.trim().toUpperCase()}'.trim()),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: creditoLiberado ? Colors.green.withValues(alpha: 0.08) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: creditoLiberado ? Colors.green.withValues(alpha: 0.24) : theme.colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.request_quote_outlined, color: creditoLiberado ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      creditoLiberado ? 'Compra a prazo liberada com limite de R\$ ${_limite.text.trim()} e prazo de ${_prazo.text.trim()} dias.' : 'Compra a prazo indisponível para este cadastro.',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
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

  Widget _summaryRow(String label, String value) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty || name == 'Cliente sem nome') return 'CL';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'.toUpperCase();
  }

  Widget _actionsBar(BuildContext context, bool compact) {
    final ThemeData theme = Theme.of(context);
    final Widget actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: <Widget>[
        SizedBox(
          width: compact ? double.infinity : null,
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Salvando...' : 'Salvar cliente'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
          ),
        ),
      ],
    );

    return SixWebEntry(
      order: 8,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                Text('Revise os dados obrigatórios antes de salvar.', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                actions,
              ])
            : Row(
                children: <Widget>[
                  Expanded(child: Text('Revise os dados obrigatórios antes de salvar.', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool telaGrande = constraints.maxWidth >= 1120;
        final bool telaMedia = constraints.maxWidth >= 760;
        final bool compact = constraints.maxWidth < 760;

        final Widget identidade = _section(
          order: 1,
          title: 'Identidade do cadastro',
          subtitle: 'Dados principais usados para localizar o cliente nas vendas e atendimentos.',
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 380, media: 340),
                child: _field(_nome, 'Nome completo / Razão social', Icons.person_outline, validator: _required),
              ),
              SizedBox(
                width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 240, media: 240),
                child: _field(_documento, 'CPF/CNPJ', Icons.badge_outlined, validator: _required),
              ),
              SizedBox(
                width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 190, media: 180),
                child: DropdownButtonFormField<String>(
                  initialValue: _tipoPessoa,
                  isExpanded: true,
                  decoration: _dec('Tipo pessoa', Icons.apartment_outlined),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'PF', child: Text('PF')),
                    DropdownMenuItem<String>(value: 'PJ', child: Text('PJ')),
                  ],
                  onChanged: _saving ? null : (String? value) => setState(() => _tipoPessoa = value ?? 'PF'),
                ),
              ),
            ],
          ),
        );

        final Widget contato = _section(
          order: 2,
          title: 'Contato e relacionamento',
          subtitle: 'Canais de comunicação para orçamento, assistência técnica e cobrança.',
          icon: Icons.phone_in_talk_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 260, media: 260),
                    child: _field(_telefone, 'Telefone principal', Icons.phone_outlined, validator: _required, keyboardType: TextInputType.phone),
                  ),
                  SizedBox(
                    width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 360, media: 340),
                    child: _field(_email, 'E-mail', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: telaGrande ? 330 : double.infinity,
                  child: _switchCard(
                    title: 'Cliente ativo',
                    subtitle: 'Define se o cadastro pode ser usado em vendas e assistências.',
                    value: _ativo,
                    onChanged: (bool value) => _ativo = value,
                  ),
                ),
              ),
            ],
          ),
        );

        final Widget endereco = _section(
          order: 3,
          title: 'Endereço',
          subtitle: 'Informações para entrega, cobrança e emissão de documentos.',
          icon: Icons.location_on_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 180, media: 180), child: _field(_cep, 'CEP', Icons.pin_drop_outlined, validator: _required)),
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 360, media: 340), child: _field(_logradouro, 'Logradouro', Icons.home_outlined, validator: _required)),
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 150, media: 150), child: _field(_numero, 'Número', Icons.format_list_numbered, validator: _required)),
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 260, media: 260), child: _field(_bairro, 'Bairro', Icons.location_city_outlined, validator: _required)),
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 260, media: 260), child: _field(_cidade, 'Cidade', Icons.location_city, validator: _required)),
              SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 120, media: 120), child: _field(_uf, 'UF', Icons.map_outlined, validator: _required)),
            ],
          ),
        );

        final Widget financeiro = _section(
          order: 4,
          title: 'Financeiro e limite de crédito',
          subtitle: 'Parâmetros para venda a prazo e controle de inadimplência.',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 240, media: 240), child: _field(_limite, 'Limite de crédito', Icons.credit_score_outlined, keyboardType: TextInputType.number)),
                  SizedBox(width: _fieldWidth(telaGrande: telaGrande, telaMedia: telaMedia, grande: 220, media: 220), child: _field(_prazo, 'Prazo pagamento', Icons.timelapse_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _switchCard(
                      title: 'Permite compra a prazo',
                      subtitle: 'Libera uso do limite de crédito em vendas futuras.',
                      value: _permiteFiado,
                      onChanged: (bool value) => _permiteFiado = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 360 : double.infinity,
                    child: _switchCard(
                      title: 'Bloqueado por inadimplência',
                      subtitle: 'Impede novas compras a prazo até regularização.',
                      value: _bloqueadoFiado,
                      onChanged: (bool value) => _bloqueadoFiado = value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget observacoes = _section(
          order: 6,
          title: 'Observações comerciais',
          subtitle: 'Notas internas para atendimento, venda e pós-venda.',
          icon: Icons.notes_outlined,
          child: _field(_observacoes, 'Observações', Icons.note_alt_outlined, maxLines: 4),
        );

        final Widget formColumn = Column(
          children: <Widget>[
            identidade,
            const SizedBox(height: 18),
            contato,
            const SizedBox(height: 18),
            endereco,
            const SizedBox(height: 18),
            financeiro,
            const SizedBox(height: 18),
            observacoes,
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _introCard(context),
                    const SizedBox(height: 22),
                    if (telaMedia)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: telaGrande ? 7 : 8, child: formColumn),
                          const SizedBox(width: 20),
                          Expanded(flex: telaGrande ? 3 : 4, child: _summaryCard(context)),
                        ],
                      )
                    else
                      Column(
                        children: <Widget>[
                          formColumn,
                          const SizedBox(height: 18),
                          _summaryCard(context),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _actionsBar(context, compact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
