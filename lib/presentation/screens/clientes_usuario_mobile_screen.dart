import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_link_section.dart';
import 'package:sixpos/presentation/screens/cliente_usuario_cadastro_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class ClientesUsuarioMobileScreen extends StatefulWidget {
  const ClientesUsuarioMobileScreen({super.key, this.apiClient});

  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClientesUsuarioMobileScreen> createState() =>
      _ClientesUsuarioMobileScreenState();
}

class _ClientesUsuarioMobileScreenState
    extends State<ClientesUsuarioMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static const Color _successColor = Color(0xFF16A34A);

  late final ClienteUsuarioApiClient _api;
  final TextEditingController _search = TextEditingController();

  bool _loading = false;
  String? _erro;
  ClienteUsuarioListResponse? _response;
  String _filter = '';

  List<ClienteUsuario> get _clientes =>
      _response?.clientes ?? <ClienteUsuario>[];

  List<ClienteUsuario> get _items {
    final String term = _filter.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (term.isEmpty) return _clientes;

    return _clientes
        .where((ClienteUsuario cliente) {
          final String source =
              '${cliente.nome} ${cliente.documento} ${cliente.telefone} ${cliente.email} ${cliente.cidade} ${cliente.uf}'
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]'), '');
          return source.contains(term);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final ClienteUsuarioListResponse data =
          await _api.listarClientesUsuario();
      if (!mounted) return;
      setState(() {
        _response = data;
        _loading = false;
      });
    } on ClienteUsuarioApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _message(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar a lista de clientes.';
      });
    }
  }

  String _message(int code) {
    switch (code) {
      case 400:
        return 'Dados inválidos ou empresa não informada.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Usuário sem vínculo com a empresa.';
      case 409:
        return 'Já existe cliente com documento ou e-mail informado.';
      default:
        return 'Erro ao carregar clientes (HTTP $code).';
    }
  }

  Future<void> _openForm({ClienteUsuario? cliente}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => ClienteUsuarioCadastroMobileScreen(
              cliente: cliente,
              apiClient: _api,
            ),
      ),
    );

    if (saved == true && mounted) {
      _reload();
    }
  }

  void _openAutoCadastro() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x47000000),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
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
                              'Auto cadastro',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Gere, copie ou compartilhe o link.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  ClienteAutoCadastroLinkSection(
                    showAsCard: true,
                    actionsOnly: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.thousandSeparator}|${provider.decimalSeparator}|${provider.currencyCode}',
    );

    return SixMobilePageShell(
      title: 'Clientes',
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      actions: <Widget>[
        IconButton(
          tooltip: 'Auto cadastro',
          onPressed: _loading ? null : _openAutoCadastro,
          icon: Icon(Icons.link_outlined),
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: Stack(
            children: <Widget>[
              _body(scrollController, topInset),
              Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  minimum: EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.extended(
                    backgroundColor: _accentColor,
                    foregroundColor: SixMobilePalette.onPrimary,
                    elevation: 5,
                    onPressed: _loading ? null : () => _openForm(),
                    icon: Icon(Icons.person_add_alt_1_rounded),
                    label: Text('Novo cliente'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(ScrollController scrollController, double topInset) {
    if (_loading && _response == null) {
      return _MobileClientesLoading(
        controller: scrollController,
        topPadding: topInset + 12,
      );
    }

    if (_erro != null && _response == null) {
      return _errorState(scrollController, topInset);
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 96),
        children: <Widget>[
          SixStaggeredEntry(child: _headerCard()),
          SizedBox(height: 14),
          SixStaggeredEntry(
            delay: Duration(milliseconds: 60),
            child: _summaryBar(),
          ),
          SizedBox(height: 14),
          SixStaggeredEntry(
            delay: Duration(milliseconds: 100),
            child: _searchBox(),
          ),
          if (_erro != null) ...<Widget>[
            SizedBox(height: 12),
            _inlineError(_erro!),
          ],
          SizedBox(height: 16),
          SixStaggeredEntry(
            delay: Duration(milliseconds: 140),
            child: _listTitle(),
          ),
          SizedBox(height: 12),
          if (_items.isEmpty)
            _emptyState()
          else
            ..._items.asMap().entries.map(
              (MapEntry<int, ClienteUsuario> entry) => SixStaggeredEntry(
                delay: Duration(
                  milliseconds: 180 + ((entry.key * 24).clamp(0, 160)).toInt(),
                ),
                child: _clientCard(entry.value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _listTitle() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Clientes encontrados',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            _formatInt(_items.length),
            style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x220B1F3A),
            blurRadius: 18,
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
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(Icons.groups_2_outlined, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Base de clientes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Cadastre, edite e acompanhe relacionamento e fiado.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
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

  Widget _summaryBar() {
    final double saldo = _clientes.fold<double>(
      0,
      (double total, ClienteUsuario cliente) => total + cliente.saldoFiado,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _summaryMetric(
              label: 'Clientes',
              value: _formatInt(_clientes.length),
            ),
          ),
          Container(width: 1, height: 34, color: _borderColor),
          Expanded(
            child: _summaryMetric(
              label: 'Em aberto',
              value: _formatMoney(saldo),
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: _titleTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: Icon(Icons.search_rounded),
          suffixIcon:
              _search.text.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() => _filter = '');
                    },
                  ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _softSurfaceColor,
        ),
      ),
    );
  }

  Widget _clientCard(ClienteUsuario cliente) {
    final bool fiadoOk = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 23,
                backgroundColor: _softAccentColor,
                child: Text(
                  _initials(cliente.nome),
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome,
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
                      '${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? 'Documento não informado' : cliente.documento}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _status(cliente.ativo),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(
                Icons.phone_outlined,
                cliente.telefone.isEmpty ? 'Sem telefone' : cliente.telefone,
              ),
              _chip(
                Icons.mail_outline,
                cliente.email.isEmpty ? 'Sem e-mail' : cliente.email,
              ),
              _chip(Icons.location_on_outlined, _location(cliente)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  fiadoOk
                      ? _successColor.withValues(alpha: 0.08)
                      : _softSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    fiadoOk
                        ? _successColor.withValues(alpha: 0.24)
                        : _borderColor,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.request_quote_outlined,
                  color: fiadoOk ? _successColor : _mutedTextColor,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente.permiteCompraFiado
                        ? 'Fiado: ${_formatMoney(cliente.limiteFiado)} • ${cliente.prazoPagamentoDias} dias'
                        : 'Fiado não liberado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _history(cliente),
                  icon: Icon(Icons.timeline_outlined, size: 18),
                  label: Text('Histórico'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openForm(cliente: cliente),
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Editar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _primaryColor),
          SizedBox(width: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(bool ativo) {
    final Color color = ativo ? _successColor : SixMobilePalette.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _softAccentColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: _accentColor),
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum cliente encontrado',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Cadastre clientes para vender, atender e controlar fiado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ScrollController scrollController, double topInset) {
    return ListView(
      controller: scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, topInset + 40, 24, 96),
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cloud_off_rounded, size: 44, color: _accentColor),
              SizedBox(height: 12),
              Text(
                _erro ?? 'Não foi possível carregar os clientes.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _reload,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inlineError(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.35),
      ),
      child: Text(message),
    );
  }

  void _history(ClienteUsuario cliente) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x47000000),
      builder: (BuildContext bottomSheetContext) {
        return Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                cliente.nome.isEmpty ? 'Cliente' : cliente.nome,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 14),
              _historyRow(
                'Telefone',
                cliente.telefone.isEmpty ? '-' : cliente.telefone,
              ),
              _historyRow(
                'E-mail',
                cliente.email.isEmpty ? '-' : cliente.email,
              ),
              _historyRow('Endereço', _address(cliente)),
              _historyRow(
                'Fiado',
                cliente.permiteCompraFiado
                    ? _formatMoney(cliente.limiteFiado)
                    : 'não liberado',
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  child: Text('Fechar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _location(ClienteUsuario cliente) {
    if (cliente.cidade.isEmpty && cliente.uf.isEmpty) return 'Sem cidade';
    if (cliente.uf.isEmpty) return cliente.cidade;
    if (cliente.cidade.isEmpty) return cliente.uf;
    return '${cliente.cidade}/${cliente.uf}';
  }

  String _address(ClienteUsuario cliente) {
    final String value = <String>[
      cliente.logradouro,
      cliente.numero,
      cliente.bairro,
      cliente.cidade,
      cliente.uf,
      cliente.cep,
    ].where((String item) => item.trim().isNotEmpty).join(', ');
    return value.isEmpty ? 'Endereço não informado.' : value;
  }

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) return 'CL';
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatMoney(num value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  String _formatInt(int value) {
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    final String sign = value < 0 ? '-' : '';
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index += 1) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(localeSettings.thousandSeparator);
      }
      buffer.write(digits[index]);
    }

    return '$sign$buffer';
  }
}

class _MobileClientesLoading extends StatelessWidget {
  const _MobileClientesLoading({
    required this.controller,
    required this.topPadding,
  });

  final ScrollController controller;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 96),
      children: List<Widget>.generate(
        5,
        (int index) => Container(
          height: index == 0 ? 118 : 132,
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SixMobilePalette.activeBorder),
          ),
        ),
      ),
    );
  }
}
