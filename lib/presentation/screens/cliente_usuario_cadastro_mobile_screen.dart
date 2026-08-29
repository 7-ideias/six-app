import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/cliente_cadastro_quality.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_link_section.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class ClienteUsuarioCadastroMobileScreen extends StatefulWidget {
  const ClienteUsuarioCadastroMobileScreen({
    super.key,
    this.cliente,
    this.apiClient,
    this.returnSavedCliente = false,
  });

  final ClienteUsuario? cliente;
  final ClienteUsuarioApiClient? apiClient;
  final bool returnSavedCliente;

  @override
  State<ClienteUsuarioCadastroMobileScreen> createState() =>
      _ClienteUsuarioCadastroMobileScreenState();
}

class _ClienteUsuarioCadastroMobileScreenState
    extends State<ClienteUsuarioCadastroMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _activeBorderColor => SixMobilePalette.activeBorder;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;

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
  bool _limitInitialized = false;
  String _tipoCadastro = ClienteCadastroQuality.tipoSimples;
  int _etapaAtual = 0;

  bool get _editing => widget.cliente != null;
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
    _limite = TextEditingController();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_limitInitialized) return;
    _limite.text = _formatEditableMoney(widget.cliente?.limiteFiado ?? 0);
    _limitInitialized = true;
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

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  LocaleSettingsProvider? _regionalizacaoOrNull() {
    try {
      return context.read<LocaleSettingsProvider>();
    } catch (_) {
      return null;
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('common.requiredField', 'Campo obrigatório');
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty && !normalized.contains('@')) {
      return _t('clientes.form.invalidEmail', 'Informe um e-mail válido');
    }
    return null;
  }

  String _formatEditableMoney(num value) {
    final LocaleSettingsProvider? regionalizacao = _regionalizacaoOrNull();
    if (regionalizacao != null) {
      return regionalizacao.formatDecimal(value);
    }
    return value.toStringAsFixed(2);
  }

  double _money(String value) {
    String raw = value.trim().replaceAll(RegExp(r'\s'), '');
    if (raw.isEmpty) return 0;

    final LocaleSettingsProvider? regionalizacao = _regionalizacaoOrNull();
    if (regionalizacao != null) {
      final String thousand = regionalizacao.thousandSeparator;
      final String decimal = regionalizacao.decimalSeparator;
      if (thousand.isNotEmpty) raw = raw.replaceAll(thousand, '');
      if (decimal.isNotEmpty) raw = raw.replaceAll(decimal, '.');
    } else if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (raw.contains(',')) {
      raw = raw.replaceAll(',', '.');
    }

    raw = raw.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(raw) ?? 0;
  }

  String _tipoPessoaLabel(String value) {
    return value == 'PJ'
        ? _t('clientes.form.legalPerson', 'Pessoa jurídica (PJ)')
        : _t('clientes.form.naturalPerson', 'Pessoa física (PF)');
  }

  OutlineInputBorder _inputBorder([Color? color]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color ?? _borderColor),
    );
  }

  InputDecoration _dec(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: _secondaryColor),
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: _inputBorder(_activeBorderColor),
      disabledBorder: _inputBorder(_borderColor),
      focusedBorder: _inputBorder(_accentColor),
      errorBorder: _inputBorder(SixMobilePalette.errorBorder),
      focusedErrorBorder: _inputBorder(SixMobilePalette.error),
      labelStyle: TextStyle(color: _mutedTextColor),
      hintStyle: TextStyle(color: _mutedTextColor),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    final TextInputType effectiveKeyboardType =
        maxLines > 1 && keyboardType == TextInputType.text
        ? TextInputType.multiline
        : keyboardType;

    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      keyboardType: effectiveKeyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: _dec(label, icon, hintText: hintText),
      validator: validator,
      onChanged: onChanged,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
    );
  }

  Widget _staggered(int order, Widget child) {
    return SixStaggeredEntry(
      delay: Duration(milliseconds: 55 * order),
      child: child,
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _activeBorderColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _softAccentColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _activeBorderColor),
                  ),
                  child: Icon(icon, color: _accentColor, size: 21),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? _softAccentColor : _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? SixMobilePalette.highlightedBorder
              : _activeBorderColor,
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
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedTextColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeThumbColor: _accentColor,
            activeTrackColor: SixMobilePalette.highlightedBorder,
            onChanged: _saving
                ? null
                : (bool newValue) => setState(() => onChanged(newValue)),
          ),
        ],
      ),
    );
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
    Navigator.of(context).pop(false);
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
      final ClienteUsuario saved = _editing
          ? await _api.atualizarClienteUsuario(widget.cliente!.id, request)
          : await _api.cadastrarClienteUsuario(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('clientes.form.savedSuccessfully', 'Cliente salvo com sucesso.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(widget.returnSavedCliente ? saved : true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('clientes.form.saveError', 'Não foi possível salvar o cliente.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openTipoPessoaSheet() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return _PessoaTipoBottomSheet(
          selected: _tipoPessoa,
          naturalPersonLabel: _tipoPessoaLabel('PF'),
          legalPersonLabel: _tipoPessoaLabel('PJ'),
          onClose: () => Navigator.of(sheetContext).pop(),
        );
      },
    );

    if (selected == null || selected == _tipoPessoa) return;
    setState(() => _tipoPessoa = selected);
  }

  Future<void> _openAutoCadastroSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (BuildContext bottomSheetContext) {
        return _MobileBottomSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _MobileSheetHandle(),
              SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _softAccentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.link_outlined, color: _accentColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _t('clientes.form.autoSignupTitle', 'Auto cadastro'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          _t(
                            'clientes.form.autoSignupSubtitle',
                            'Gere, copie ou compartilhe o link.',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedTextColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _t('common.close', 'Fechar'),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 18),
              ClienteAutoCadastroLinkSection(
                key: ValueKey<String>('$_tipoPessoa-${_documento.text.trim()}'),
                initialTipoPessoa: _tipoPessoa,
                initialDocumento: _documento.text.trim(),
                showAsCard: true,
                actionsOnly: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJourneySelector() {
    return _section(
      title: _t('clientes.journey.title', 'Escolha a jornada'),
      subtitle: _t(
        'clientes.journey.subtitle',
        'Comece rápido ou organize um cadastro completo para a operação.',
      ),
      icon: Icons.route_outlined,
      child: Column(
        children: <Widget>[
          _journeyOption(
            type: ClienteCadastroQuality.tipoSimples,
            title: _t('clientes.journey.simpleTitle', 'Cadastro simples'),
            subtitle: _t(
              'clientes.journey.simpleSubtitle',
              'Nome, documento, telefone e e-mail. Ideal para cadastrar agora.',
            ),
            icon: Icons.bolt_rounded,
          ),
          SizedBox(height: 10),
          _journeyOption(
            type: ClienteCadastroQuality.tipoCompleto,
            title: _t('clientes.journey.completeTitle', 'Cadastro completo'),
            subtitle: _t(
              'clientes.journey.completeSubtitle',
              'Inclui endereço, crédito e informações de relacionamento.',
            ),
            icon: Icons.fact_check_outlined,
          ),
        ],
      ),
    );
  }

  Widget _journeyOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _tipoCadastro == type;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? _softAccentColor : _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _selectJourney(type),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? SixMobilePalette.highlightedBorder
                    : _activeBorderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _accentColor, size: 21),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? _accentColor : _mutedTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityCard() {
    final QualidadeCadastroCliente quality = _qualidade;
    final List<MelhoriaQualidadeCadastroCliente> improvements = quality
        .melhorias
        .take(2)
        .toList(growable: false);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
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
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _qualityLevel(quality.nivel),
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary.withValues(
                          alpha: 0.72,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${quality.percentual}%',
                style: TextStyle(
                  color: SixMobilePalette.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: quality.percentual / 100),
              duration: Duration(milliseconds: 260),
              builder: (BuildContext context, double value, Widget? child) {
                return LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                );
              },
            ),
          ),
          if (improvements.isNotEmpty) ...<Widget>[
            SizedBox(height: 12),
            Text(
              improvements
                  .map(
                    (MelhoriaQualidadeCadastroCliente item) =>
                        '+${item.pontos} ${_improvementLabel(item.criterio)}',
                  )
                  .join('  •  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.78),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${_t('clientes.journey.step', 'Etapa')} ${_etapaAtual + 1} '
          '${_t('clientes.journey.of', 'de')} ${_etapas.length} · ${_etapas[_etapaAtual]}',
          style: TextStyle(
            color: _titleTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: List<Widget>.generate(_etapas.length, (int index) {
            return Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                margin: EdgeInsets.only(
                  right: index == _etapas.length - 1 ? 0 : 6,
                ),
                height: 5,
                decoration: BoxDecoration(
                  color: index <= _etapaAtual ? _accentColor : _borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _currentStepContent(String currencySymbol) {
    if (_etapaAtual == 0) {
      return Column(
        children: <Widget>[
          _buildMainDataSection(),
          SizedBox(height: 16),
          _buildContactSection(),
        ],
      );
    }
    if (_etapaAtual == 1) return _buildAddressSection();
    return Column(
      children: <Widget>[
        _buildCreditSection(currencySymbol),
        SizedBox(height: 16),
        _buildNotesSection(),
      ],
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              _editing ? Icons.edit_outlined : Icons.person_add_alt_1_rounded,
              color: SixMobilePalette.onPrimary,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _editing
                      ? _t('clientes.form.editTitle', 'Editar cliente')
                      : _t('clientes.form.createTitle', 'Novo cliente'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _t(
                    'clientes.form.headerSubtitle',
                    'Cadastro rápido para vendas, assistência e compras a prazo.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoPessoaField() {
    return Semantics(
      button: true,
      label: _t('clientes.form.personType', 'Tipo de pessoa'),
      value: _tipoPessoaLabel(_tipoPessoa),
      child: InkWell(
        onTap: _saving ? null : _openTipoPessoaSheet,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration:
              _dec(
                _t('clientes.form.personType', 'Tipo de pessoa'),
                Icons.apartment_outlined,
              ).copyWith(
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _secondaryColor,
                ),
              ),
          child: Text(
            _tipoPessoaLabel(_tipoPessoa),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCadastroCard() {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _saving ? null : _openAutoCadastroSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _activeBorderColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softAccentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.link_outlined, color: _accentColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _t('clientes.form.autoSignupTitle', 'Auto cadastro'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _t(
                        'clientes.form.autoSignupCardSubtitle',
                        'Gere um link para o cliente completar os dados.',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: _secondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDataSection() {
    return _section(
      title: _t('clientes.form.mainDataTitle', 'Dados principais'),
      subtitle: _t(
        'clientes.form.mainDataSubtitle',
        'Identifique o cliente para atendimento e relacionamento.',
      ),
      icon: Icons.badge_outlined,
      child: Column(
        children: <Widget>[
          _field(
            _nome,
            _t('clientes.form.name', 'Nome completo / Razão social'),
            Icons.person_outline,
            validator: _required,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 14),
          _buildTipoPessoaField(),
          SizedBox(height: 14),
          _field(
            _documento,
            _t('clientes.form.document', 'CPF/CNPJ'),
            Icons.badge_outlined,
            validator: _required,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14),
          _switchCard(
            title: _t('clientes.form.activeCustomer', 'Cliente ativo'),
            subtitle: _t(
              'clientes.form.activeCustomerSubtitle',
              'Permite usar o cadastro em vendas e assistências.',
            ),
            value: _ativo,
            onChanged: (bool value) => _ativo = value,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _section(
      title: _t('clientes.form.contactTitle', 'Contato'),
      subtitle: _t(
        'clientes.form.contactSubtitle',
        'Canais usados em orçamentos, ordens de serviço e cobrança.',
      ),
      icon: Icons.phone_in_talk_outlined,
      child: Column(
        children: <Widget>[
          _field(
            _telefone,
            _t('clientes.form.mainPhone', 'Telefone principal'),
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 14),
          _field(
            _email,
            _t('clientes.form.email', 'E-mail'),
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return _section(
      title: _t('clientes.form.addressTitle', 'Endereço'),
      subtitle: _t(
        'clientes.form.addressSubtitle',
        'Informações para entrega, cobrança e emissão de documentos.',
      ),
      icon: Icons.location_on_outlined,
      child: Column(
        children: <Widget>[
          _field(
            _cep,
            _t('clientes.form.zipCode', 'CEP'),
            Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 14),
          _field(
            _uf,
            _t('clientes.form.state', 'UF'),
            Icons.map_outlined,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(2),
              UpperCaseTextFormatter(),
            ],
          ),
          SizedBox(height: 14),
          _field(
            _cidade,
            _t('clientes.form.city', 'Cidade'),
            Icons.location_city,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 14),
          _field(
            _logradouro,
            _t('clientes.form.street', 'Logradouro'),
            Icons.home_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 14),
          _field(
            _numero,
            _t('common.number', 'Número'),
            Icons.format_list_numbered,
          ),
          SizedBox(height: 14),
          _field(
            _bairro,
            _t('clientes.form.neighborhood', 'Bairro'),
            Icons.location_city_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 14),
          _field(
            _complemento,
            _t('clientes.form.complement', 'Complemento'),
            Icons.apartment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditSection(String currencySymbol) {
    return _section(
      title: _t('clientes.form.creditTitle', 'Crédito / Fiado'),
      subtitle: _t(
        'clientes.form.creditSubtitle',
        'Parâmetros para compra a prazo e inadimplência.',
      ),
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: <Widget>[
          _field(
            _limite,
            _t('clientes.form.creditLimit', 'Limite de crédito'),
            Icons.credit_score_outlined,
            hintText: currencySymbol,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 14),
          _field(
            _prazo,
            _t('clientes.form.paymentDeadline', 'Prazo pagamento'),
            Icons.timelapse_outlined,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 14),
          _switchCard(
            title: _t(
              'clientes.form.allowCreditPurchase',
              'Permite compra a prazo',
            ),
            subtitle: _t(
              'clientes.form.allowCreditPurchaseSubtitle',
              'Libera uso do limite de crédito em vendas futuras.',
            ),
            value: _permiteFiado,
            onChanged: (bool value) => _permiteFiado = value,
          ),
          SizedBox(height: 12),
          _switchCard(
            title: _t(
              'clientes.form.blockedByDebt',
              'Bloqueado por inadimplência',
            ),
            subtitle: _t(
              'clientes.form.blockedByDebtSubtitle',
              'Impede novas compras até regularização.',
            ),
            value: _bloqueadoFiado,
            onChanged: (bool value) => _bloqueadoFiado = value,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _section(
      title: _t('clientes.form.notesTitle', 'Observações'),
      subtitle: _t(
        'clientes.form.notesSubtitle',
        'Notas internas para atendimento e pós-venda.',
      ),
      icon: Icons.notes_outlined,
      child: _field(
        _observacoes,
        _t('clientes.form.notes', 'Observações'),
        Icons.note_alt_outlined,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final bool last = _etapaAtual == _etapas.length - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(top: BorderSide(color: _activeBorderColor)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _goBackOrCancel,
                child: Text(
                  _etapaAtual == 0
                      ? _t('common.cancel', 'Cancelar')
                      : _t('common.back', 'Voltar'),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _saving ? null : _advance,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SixMobilePalette.onPrimary,
                        ),
                      )
                    : Icon(
                        last
                            ? Icons.save_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                label: AnimatedSwitcher(
                  duration: Duration(milliseconds: 180),
                  child: Text(
                    _saving
                        ? _t('clientes.form.saving', 'Salvando...')
                        : last
                        ? _t('clientes.form.saveCustomer', 'Salvar cliente')
                        : _t('common.continue', 'Continuar'),
                    key: ValueKey<bool>(_saving),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currencySymbol = context
        .select<LocaleSettingsProvider, String>(
          (LocaleSettingsProvider provider) => provider.currencySymbol,
        );
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.thousandSeparator}|${provider.decimalSeparator}|${provider.currencyCode}|${provider.currencySymbol}|${provider.decimalPlaces}',
    );

    return SixMobilePageShell(
      title: _editing
          ? _t('clientes.form.editAppBarTitle', 'Editar cliente')
          : _t('clientes.form.createAppBarTitle', 'Cadastro de clientes'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      toolbarHeight: 48,
      initialContentSpacing: 6,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      bodyBuilder:
          (
            BuildContext context,
            ScrollController scrollController,
            double topInset,
          ) {
            return SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 112),
                  children: <Widget>[
                    _staggered(0, _buildHeaderCard()),
                    SizedBox(height: 16),
                    _staggered(1, _buildJourneySelector()),
                    SizedBox(height: 16),
                    _staggered(2, _buildQualityCard()),
                    SizedBox(height: 16),
                    _staggered(3, _buildAutoCadastroCard()),
                    SizedBox(height: 16),
                    _staggered(4, _buildStepProgress()),
                    SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey<String>('$_tipoCadastro-$_etapaAtual'),
                        child: _currentStepContent(currencySymbol),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }
}

class _PessoaTipoBottomSheet extends StatelessWidget {
  const _PessoaTipoBottomSheet({
    required this.selected,
    required this.naturalPersonLabel,
    required this.legalPersonLabel,
    required this.onClose,
  });

  final String selected;
  final String naturalPersonLabel;
  final String legalPersonLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _MobileBottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _MobileSheetHandle(),
          SizedBox(height: 18),
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SixMobilePalette.softAccentSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.apartment_outlined,
                  color: SixMobilePalette.accent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        'clientes.form.selectPersonType',
                        fallback: 'Tipo de pessoa',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      context.t(
                        'clientes.form.selectPersonTypeSubtitle',
                        fallback: 'Escolha como o cadastro será identificado.',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.t('common.close', fallback: 'Fechar'),
                onPressed: onClose,
                icon: Icon(Icons.close_rounded),
              ),
            ],
          ),
          SizedBox(height: 16),
          _PessoaTipoOption(
            value: 'PF',
            title: naturalPersonLabel,
            subtitle: context.t(
              'clientes.form.naturalPersonSubtitle',
              fallback: 'Cliente pessoa física com CPF.',
            ),
            icon: Icons.person_outline,
            selected: selected == 'PF',
          ),
          SizedBox(height: 10),
          _PessoaTipoOption(
            value: 'PJ',
            title: legalPersonLabel,
            subtitle: context.t(
              'clientes.form.legalPersonSubtitle',
              fallback: 'Empresa ou organização com CNPJ.',
            ),
            icon: Icons.storefront_outlined,
            selected: selected == 'PJ',
          ),
        ],
      ),
    );
  }
}

class _PessoaTipoOption extends StatelessWidget {
  const _PessoaTipoOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? SixMobilePalette.softAccentSurface
            : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(value),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? SixMobilePalette.highlightedBorder
                    : SixMobilePalette.activeBorder,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SixMobilePalette.activeBorder),
                  ),
                  child: Icon(icon, color: SixMobilePalette.accent, size: 21),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? SixMobilePalette.accent
                      : SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileBottomSheetFrame extends StatelessWidget {
  const _MobileBottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.heroShadow,
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MobileSheetHandle extends StatelessWidget {
  const _MobileSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: SixMobilePalette.activeBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
