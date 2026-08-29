import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/cliente_cadastro_quality.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/sub_painel_cadastro_cliente.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

typedef ClienteUsuarioSavedCallback =
    Future<void> Function(ClienteUsuario cliente);

Future<ClienteUsuario?> showClienteUsuarioCadastroWebDialog(
  BuildContext context, {
  ClienteUsuario? cliente,
  ClienteUsuarioApiClient? apiClient,
  ClienteUsuarioSavedCallback? onSaved,
}) async {
  final WebThemeTokens tokens = WebThemeTokens.of(context);
  final double barrierAlpha = Theme.of(context).brightness == Brightness.dark
      ? 0.70
      : 0.42;
  ClienteUsuario? savedClient;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: tokens.workspaceBackground.withValues(alpha: barrierAlpha),
    builder: (_) => SubPainelCadastroCliente(
      textoDaAppBar: cliente == null
          ? 'Cadastro de Clientes'
          : 'Edição de Clientes',
      body: _ClienteUsuarioCadastroWebBody(
        cliente: cliente,
        apiClient: apiClient,
        onSaved: (ClienteUsuario clienteSalvo) async {
          savedClient = clienteSalvo;
          await onSaved?.call(clienteSalvo);
        },
      ),
    ),
  );
  return savedClient;
}

class _ClienteUsuarioCadastroWebBody extends StatefulWidget {
  const _ClienteUsuarioCadastroWebBody({
    this.cliente,
    this.apiClient,
    this.onSaved,
  });

  final ClienteUsuario? cliente;
  final ClienteUsuarioApiClient? apiClient;
  final ClienteUsuarioSavedCallback? onSaved;

  @override
  State<_ClienteUsuarioCadastroWebBody> createState() =>
      _ClienteUsuarioCadastroWebBodyState();
}

class _ClienteUsuarioCadastroWebBodyState
    extends State<_ClienteUsuarioCadastroWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ClienteUsuarioApiClient _api;
  late final TextEditingController _nome;
  late final TextEditingController _documento;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _cep;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;
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
  String _tipoCadastro = ClienteCadastroQuality.tipoSimples;
  int _etapaAtual = 0;

  bool get _cadastroCompleto =>
      _tipoCadastro == ClienteCadastroQuality.tipoCompleto;
  List<String> get _etapas => _cadastroCompleto
      ? <String>[
          _t('clientes.journey.stepEssential', 'Essenciais'),
          _t('clientes.journey.stepAddress', 'Endereço'),
          _t('clientes.journey.stepRelationship', 'Crédito e relacionamento'),
        ]
      : <String>[_t('clientes.journey.stepEssential', 'Essenciais')];

  QualidadeCadastroCliente get _qualidade => ClienteCadastroQuality.calcular(
    tipoCadastro: _tipoCadastro,
    entrada: EntradaQualidadeCadastroCliente(
      nomeInformado: _nome.text.trim().isNotEmpty,
      documentoInformado: _documento.text.trim().isNotEmpty,
      telefoneInformado:
          _telefone.text.replaceAll(RegExp(r'\D'), '').length > 2,
      emailInformado: _email.text.trim().contains('@'),
      cepInformado: _cep.text.trim().isNotEmpty,
      enderecoInformado: <String>[
        _logradouro.text,
        _numero.text,
        _bairro.text,
        _cidade.text,
        _uf.text,
      ].every((String value) => value.trim().isNotEmpty),
      creditoConfigurado:
          !_permiteFiado ||
          (_money(_limite.text) > 0 &&
              (int.tryParse(_prazo.text.trim()) ?? 0) > 0),
      observacoesInformadas: _observacoes.text.trim().isNotEmpty,
    ),
  );

  @override
  void initState() {
    super.initState();
    final ClienteUsuario? c = widget.cliente;
    _api = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _tipoPessoa = c?.tipoPessoa == 'PJ' ? 'PJ' : 'PF';
    _tipoCadastro = c?.tipoCadastro == ClienteCadastroQuality.tipoCompleto
        ? ClienteCadastroQuality.tipoCompleto
        : ClienteCadastroQuality.tipoSimples;
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
    _complemento = TextEditingController(text: c?.complemento ?? '');
    _bairro = TextEditingController(text: c?.bairro ?? '');
    _cidade = TextEditingController(text: c?.cidade ?? '');
    _uf = TextEditingController(text: c?.uf ?? '');
    _limite = TextEditingController(
      text: (c?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','),
    );
    _prazo = TextEditingController(
      text: '${c?.prazoPagamentoDias == 0 ? 30 : c?.prazoPagamentoDias ?? 30}',
    );
    _observacoes = TextEditingController(text: c?.observacoes ?? '');
    for (final TextEditingController controller in <TextEditingController>[
      _nome,
      _documento,
      _telefone,
      _email,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _uf,
      _limite,
      _prazo,
      _observacoes,
    ]) {
      controller.addListener(_refreshJourney);
    }
  }

  void _refreshJourney() {
    if (mounted) setState(() {});
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
      _complemento,
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

  LocaleSettingsProvider? _regionalizacaoOrNull() {
    try {
      return context.read<LocaleSettingsProvider>();
    } catch (_) {
      return null;
    }
  }

  double _money(String value) {
    String raw = value.trim().replaceAll(RegExp(r'\s'), '');
    final LocaleSettingsProvider? regionalizacao = _regionalizacaoOrNull();
    if (regionalizacao != null) {
      raw = raw
          .replaceAll(regionalizacao.thousandSeparator, '')
          .replaceAll(regionalizacao.decimalSeparator, '.');
    } else {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  String _formatCurrency(num value) =>
      _regionalizacaoOrNull()?.formatCurrency(value) ??
      value.toStringAsFixed(2);
  String? _required(String? value) => value == null || value.trim().isEmpty
      ? _t('common.requiredField', 'Campo obrigatório')
      : null;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  String? _emailValidator(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isNotEmpty && !normalized.contains('@')
        ? _t('clientes.form.invalidEmail', 'Informe um e-mail válido')
        : null;
  }

  bool _validateEssentials() {
    if (_nome.text.trim().isNotEmpty &&
        _documento.text.trim().isNotEmpty &&
        _emailValidator(_email.text) == null) {
      return true;
    }
    setState(() => _etapaAtual = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.validate();
    });
    return false;
  }

  void _selectJourney(String tipoCadastro) {
    if (_saving || tipoCadastro == _tipoCadastro) return;
    setState(() {
      _tipoCadastro = tipoCadastro;
      _etapaAtual = 0;
    });
  }

  void _advance() {
    if (_etapaAtual == 0 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_etapaAtual < _etapas.length - 1) {
      setState(() => _etapaAtual += 1);
      return;
    }
    _save();
  }

  void _goBackOrCancel() {
    if (_etapaAtual > 0) {
      setState(() => _etapaAtual -= 1);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!_validateEssentials()) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;
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
        complemento: _complemento.text.trim(),
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        uf: _uf.text.trim().toUpperCase(),
        observacoes: _observacoes.text.trim(),
        foto: widget.cliente?.foto ?? '',
        permiteCompraFiado: _permiteFiado,
        limiteFiado: _permiteFiado ? _money(_limite.text) : 0,
        prazoPagamentoDias: _permiteFiado
            ? int.tryParse(_prazo.text.trim()) ?? 0
            : 0,
        bloqueadoFiado: _permiteFiado && _bloqueadoFiado,
        tipoCadastro: _tipoCadastro,
        percentualQualidadeCadastro: _qualidade.percentual,
      );
      final ClienteUsuario saved = widget.cliente == null
          ? await _api.cadastrarClienteUsuario(request)
          : await _api.atualizarClienteUsuario(widget.cliente!.id, request);
      await widget.onSaved?.call(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente salvo com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o cliente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _fieldWidth({
    required bool telaGrande,
    required bool telaMedia,
    required double grande,
    required double media,
  }) {
    if (telaGrande) return grande;
    if (telaMedia) return media;
    return double.infinity;
  }

  InputDecoration _dec(String label, IconData icon) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: tokens.info),
      filled: true,
      fillColor: tokens.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.danger, width: 1.4),
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

  Widget _journeySelector(bool compact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget simple = _journeyOption(
      type: ClienteCadastroQuality.tipoSimples,
      title: _t('clientes.journey.simpleTitle', 'Cadastro simples'),
      subtitle: _t(
        'clientes.journey.simpleSubtitle',
        'Nome, documento, telefone e e-mail para cadastrar sem atrito.',
      ),
      icon: Icons.bolt_rounded,
    );
    final Widget complete = _journeyOption(
      type: ClienteCadastroQuality.tipoCompleto,
      title: _t('clientes.journey.completeTitle', 'Cadastro completo'),
      subtitle: _t(
        'clientes.journey.completeSubtitle',
        'Endereço, crédito e contexto para uma operação mais preparada.',
      ),
      icon: Icons.fact_check_outlined,
    );
    return SixWebEntry(
      order: 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t('clientes.journey.title', 'Escolha a jornada de cadastro'),
              style: TextStyle(
                color: tokens.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _t(
                'clientes.journey.subtitle',
                'Você pode salvar só o essencial ou enriquecer o cadastro agora.',
              ),
              style: TextStyle(color: tokens.secondaryText, height: 1.35),
            ),
            const SizedBox(height: 16),
            if (compact)
              Column(
                children: <Widget>[
                  simple,
                  const SizedBox(height: 12),
                  complete,
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(child: simple),
                  const SizedBox(width: 14),
                  Expanded(child: complete),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _journeyOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool selected = _tipoCadastro == type;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _selectJourney(type),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? tokens.selectedBorder : tokens.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tokens.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Icon(icon, color: tokens.info),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.secondaryText,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? tokens.info : tokens.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qualityAndStepsCard() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final QualidadeCadastroCliente quality = _qualidade;
    final List<MelhoriaQualidadeCadastroCliente> improvements = quality
        .melhorias
        .take(3)
        .toList(growable: false);
    return SixWebEntry(
      order: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _t('clientes.quality.title', 'Qualidade do cadastro'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _qualityLevel(quality.nivel),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${quality.percentual}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: quality.percentual / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(tokens.info),
              ),
            ),
            if (improvements.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...improvements.map(
                (MelhoriaQualidadeCadastroCliente item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '+${item.pontos} ${_improvementLabel(item.criterio)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
            const SizedBox(height: 14),
            Text(
              '${_t('clientes.journey.step', 'Etapa')} ${_etapaAtual + 1} '
              '${_t('clientes.journey.of', 'de')} ${_etapas.length} · ${_etapas[_etapaAtual]}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: List<Widget>.generate(_etapas.length, (int index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index == _etapas.length - 1 ? 0 : 6,
                    ),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index <= _etapaAtual
                          ? tokens.info
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLevel(NivelQualidadeCadastroCliente level) => switch (level) {
    NivelQualidadeCadastroCliente.inicial => _t(
      'clientes.quality.levelInitial',
      'Começando agora',
    ),
    NivelQualidadeCadastroCliente.essencial => _t(
      'clientes.quality.levelEssential',
      'Base essencial pronta',
    ),
    NivelQualidadeCadastroCliente.bemDetalhado => _t(
      'clientes.quality.levelDetailed',
      'Cadastro bem detalhado',
    ),
    NivelQualidadeCadastroCliente.excelente => _t(
      'clientes.quality.levelExcellent',
      'Cadastro excelente',
    ),
  };

  String _improvementLabel(CriterioQualidadeCadastroCliente criterio) =>
      switch (criterio) {
        CriterioQualidadeCadastroCliente.nome => _t(
          'clientes.quality.actionName',
          'informar nome',
        ),
        CriterioQualidadeCadastroCliente.documento => _t(
          'clientes.quality.actionDocument',
          'informar documento',
        ),
        CriterioQualidadeCadastroCliente.telefone => _t(
          'clientes.quality.actionPhone',
          'informar telefone',
        ),
        CriterioQualidadeCadastroCliente.email => _t(
          'clientes.quality.actionEmail',
          'informar e-mail',
        ),
        CriterioQualidadeCadastroCliente.cep => _t(
          'clientes.quality.actionZip',
          'informar CEP',
        ),
        CriterioQualidadeCadastroCliente.endereco => _t(
          'clientes.quality.actionAddress',
          'completar endereço',
        ),
        CriterioQualidadeCadastroCliente.credito => _t(
          'clientes.quality.actionCredit',
          'configurar crédito',
        ),
        CriterioQualidadeCadastroCliente.observacoes => _t(
          'clientes.quality.actionNotes',
          'adicionar contexto',
        ),
      };

  Widget _introCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editing = widget.cliente != null;
    return SixWebEntry(
      order: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.cardBorder),
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
                    color: tokens.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    editing
                        ? Icons.edit_outlined
                        : Icons.person_add_alt_1_rounded,
                    color: tokens.info,
                  ),
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
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dados essenciais para vendas, assistência técnica, relacionamento e compras a prazo.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
            _statusPill(
              editing ? 'Atualizando cadastro' : 'Pronto para cadastro',
              editing
                  ? Icons.manage_accounts_outlined
                  : Icons.verified_user_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, IconData icon) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tokens.info),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: tokens.info, fontWeight: FontWeight.w800),
          ),
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? tokens.selectedBackground : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.secondaryText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: _saving
                ? null
                : (bool newValue) => setState(() => onChanged(newValue)),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String nome = _nome.text.trim().isEmpty
        ? 'Cliente sem nome'
        : _nome.text.trim();
    final String documento = _documento.text.trim().isEmpty
        ? 'Documento não informado'
        : _documento.text.trim();
    final bool creditoLiberado = _permiteFiado && !_bloqueadoFiado;

    return SixWebEntry(
      order: 5,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: tokens.info.withValues(alpha: 0.10),
                  child: Text(
                    _initials(nome),
                    style: TextStyle(
                      color: tokens.info,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resumo do cadastro',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Conferência rápida antes de salvar.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _summaryRow('Nome', nome),
            _summaryRow('Documento', '$_tipoPessoa • $documento'),
            _summaryRow(
              'Contato',
              _telefone.text.trim().isEmpty
                  ? 'Telefone não informado'
                  : _telefone.text.trim(),
            ),
            _summaryRow(
              'Cidade/UF',
              _cidade.text.trim().isEmpty && _uf.text.trim().isEmpty
                  ? 'Endereço incompleto'
                  : '${_cidade.text.trim()} ${_uf.text.trim().toUpperCase()}'
                        .trim(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: creditoLiberado
                    ? tokens.success.withValues(alpha: 0.08)
                    : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: creditoLiberado
                      ? tokens.success.withValues(alpha: 0.24)
                      : tokens.cardBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.request_quote_outlined,
                    color: creditoLiberado
                        ? tokens.success
                        : tokens.statusNeutral,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      creditoLiberado
                          ? 'Compra a prazo liberada com limite de ${_formatCurrency(_money(_limite.text))} e prazo de ${_prazo.text.trim()} dias.'
                          : 'Compra a prazo indisponível para este cadastro.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty || name == 'Cliente sem nome') return 'CL';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'
        .toUpperCase();
  }

  Widget _actionsBar(BuildContext context, bool compact) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool last = _etapaAtual == _etapas.length - 1;
    final Widget actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: <Widget>[
        SizedBox(
          width: compact ? double.infinity : null,
          child: OutlinedButton(
            onPressed: _saving ? null : _goBackOrCancel,
            child: Text(
              _etapaAtual == 0
                  ? _t('common.cancel', 'Cancelar')
                  : _t('common.back', 'Voltar'),
            ),
          ),
        ),
        SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: _saving ? null : _advance,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    last ? Icons.save_outlined : Icons.arrow_forward_rounded,
                  ),
            label: Text(
              _saving
                  ? _t('clientes.form.saving', 'Salvando...')
                  : last
                  ? _t('clientes.form.saveCustomer', 'Salvar cliente')
                  : _t('common.continue', 'Continuar'),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            ),
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
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    last
                        ? _t(
                            'clientes.journey.reviewBeforeSave',
                            'Revise os dados antes de salvar.',
                          )
                        : _t(
                            'clientes.journey.continueHint',
                            'Avance quando esta etapa estiver pronta.',
                          ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  actions,
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      last
                          ? _t(
                              'clientes.journey.reviewBeforeSave',
                              'Revise os dados antes de salvar.',
                            )
                          : _t(
                              'clientes.journey.continueHint',
                              'Avance quando esta etapa estiver pronta.',
                            ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
          subtitle:
              'Dados principais usados para localizar o cliente nas vendas e atendimentos.',
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 380,
                  media: 340,
                ),
                child: _field(
                  _nome,
                  'Nome completo / Razão social',
                  Icons.person_outline,
                  validator: _required,
                ),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 240,
                  media: 240,
                ),
                child: _field(
                  _documento,
                  'CPF/CNPJ',
                  Icons.badge_outlined,
                  validator: _required,
                ),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 190,
                  media: 180,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _tipoPessoa,
                  isExpanded: true,
                  decoration: _dec('Tipo pessoa', Icons.apartment_outlined),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'PF', child: Text('PF')),
                    DropdownMenuItem<String>(value: 'PJ', child: Text('PJ')),
                  ],
                  onChanged: _saving
                      ? null
                      : (String? value) =>
                            setState(() => _tipoPessoa = value ?? 'PF'),
                ),
              ),
            ],
          ),
        );

        final Widget contato = _section(
          order: 2,
          title: 'Contato e relacionamento',
          subtitle:
              'Canais de comunicação para orçamento, assistência técnica e cobrança.',
          icon: Icons.phone_in_talk_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: _fieldWidth(
                      telaGrande: telaGrande,
                      telaMedia: telaMedia,
                      grande: 260,
                      media: 260,
                    ),
                    child: _field(
                      _telefone,
                      'Telefone principal',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(
                    width: _fieldWidth(
                      telaGrande: telaGrande,
                      telaMedia: telaMedia,
                      grande: 360,
                      media: 340,
                    ),
                    child: _field(
                      _email,
                      'E-mail',
                      Icons.email_outlined,
                      validator: _emailValidator,
                      keyboardType: TextInputType.emailAddress,
                    ),
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
                    subtitle:
                        'Define se o cadastro pode ser usado em vendas e assistências.',
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
          subtitle:
              'Informações para entrega, cobrança e emissão de documentos.',
          icon: Icons.location_on_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 180,
                  media: 180,
                ),
                child: _field(_cep, 'CEP', Icons.pin_drop_outlined),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 360,
                  media: 340,
                ),
                child: _field(_logradouro, 'Logradouro', Icons.home_outlined),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 150,
                  media: 150,
                ),
                child: _field(_numero, 'Número', Icons.format_list_numbered),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 260,
                  media: 260,
                ),
                child: _field(_bairro, 'Bairro', Icons.location_city_outlined),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 260,
                  media: 260,
                ),
                child: _field(_cidade, 'Cidade', Icons.location_city),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 120,
                  media: 120,
                ),
                child: _field(_uf, 'UF', Icons.map_outlined),
              ),
              SizedBox(
                width: _fieldWidth(
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                  grande: 320,
                  media: 300,
                ),
                child: _field(
                  _complemento,
                  _t('clientes.form.complement', 'Complemento'),
                  Icons.apartment_outlined,
                ),
              ),
            ],
          ),
        );

        final Widget financeiro = _section(
          order: 4,
          title: 'Financeiro e limite de crédito',
          subtitle:
              'Parâmetros para venda a prazo e controle de inadimplência.',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: _fieldWidth(
                      telaGrande: telaGrande,
                      telaMedia: telaMedia,
                      grande: 240,
                      media: 240,
                    ),
                    child: _field(
                      _limite,
                      'Limite de crédito',
                      Icons.credit_score_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: _fieldWidth(
                      telaGrande: telaGrande,
                      telaMedia: telaMedia,
                      grande: 220,
                      media: 220,
                    ),
                    child: _field(
                      _prazo,
                      'Prazo pagamento',
                      Icons.timelapse_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
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
                      subtitle:
                          'Libera uso do limite de crédito em vendas futuras.',
                      value: _permiteFiado,
                      onChanged: (bool value) => _permiteFiado = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 360 : double.infinity,
                    child: _switchCard(
                      title: 'Bloqueado por inadimplência',
                      subtitle:
                          'Impede novas compras a prazo até regularização.',
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
          child: _field(
            _observacoes,
            'Observações',
            Icons.note_alt_outlined,
            maxLines: 4,
          ),
        );

        final Widget formColumn = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey<String>('$_tipoCadastro-$_etapaAtual'),
            child: _etapaAtual == 0
                ? Column(
                    children: <Widget>[
                      identidade,
                      const SizedBox(height: 18),
                      contato,
                    ],
                  )
                : _etapaAtual == 1
                ? endereco
                : Column(
                    children: <Widget>[
                      financeiro,
                      const SizedBox(height: 18),
                      observacoes,
                    ],
                  ),
          ),
        );

        final Widget sideColumn = Column(
          children: <Widget>[
            _qualityAndStepsCard(),
            const SizedBox(height: 18),
            _summaryCard(context),
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
                    _journeySelector(compact),
                    const SizedBox(height: 22),
                    if (telaMedia)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: telaGrande ? 7 : 8, child: formColumn),
                          const SizedBox(width: 20),
                          Expanded(flex: telaGrande ? 3 : 4, child: sideColumn),
                        ],
                      )
                    else
                      Column(
                        children: <Widget>[
                          formColumn,
                          const SizedBox(height: 18),
                          sideColumn,
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
