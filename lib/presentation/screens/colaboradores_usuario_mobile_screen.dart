import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/colaborador_convite_web_service.dart';
import 'package:sixpos/data/models/colaborador_convite_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class ColaboradoresUsuarioMobileScreen extends StatefulWidget {
  const ColaboradoresUsuarioMobileScreen({super.key, this.apiClient});

  final ColaboradorUsuarioApiClient? apiClient;

  @override
  State<ColaboradoresUsuarioMobileScreen> createState() =>
      _ColaboradoresUsuarioMobileScreenState();
}

class _ColaboradoresUsuarioMobileScreenState
    extends State<ColaboradoresUsuarioMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;

  late final ColaboradorUsuarioApiClient _api;
  final TextEditingController _search = TextEditingController();

  bool _loading = false;
  String? _erro;
  String _filter = '';
  List<ColaboradorUsuarioResumo> _colaboradores = <ColaboradorUsuarioResumo>[];

  List<ColaboradorUsuarioResumo> get _items {
    final String term = _filter.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    if (term.isEmpty) {
      return _colaboradores;
    }

    return _colaboradores
        .where((ColaboradorUsuarioResumo colaborador) {
          final String source =
              '${colaborador.nome} ${colaborador.nomeDeGuerra} ${colaborador.email} ${colaborador.celularDeAcesso}'
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]'), '');
          return source.contains(term);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpColaboradorUsuarioApiClient();
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
      final List<ColaboradorUsuarioResumo> data =
          await _api.listarColaboradores();
      if (!mounted) {
        return;
      }
      setState(() {
        _colaboradores = data;
        _loading = false;
      });
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _erro = _message(error.statusCode);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _erro = _t(
          'colaboradores.loadListError',
          'Não foi possível carregar a lista de colaboradores.',
        );
      });
    }
  }

  String _message(int code) {
    switch (code) {
      case 400:
        return _t(
          'colaboradores.invalidCompanyData',
          'Dados inválidos ou empresa não informada.',
        );
      case 401:
        return _t(
          'auth.sessionExpiredLoginAgain',
          'Sessão expirada. Faça login novamente.',
        );
      case 403:
        return _t(
          'colaboradores.userWithoutCompanyLink',
          'Usuário sem vínculo com a empresa.',
        );
      default:
        return _t(
          'colaboradores.loadHttpError',
          'Erro ao carregar colaboradores (HTTP $code).',
        );
    }
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  String _formatCount(num value) {
    final String separator =
        context.read<LocaleSettingsProvider>().thousandSeparator;
    final int rounded = value.round();
    final String digits = rounded.abs().toString();
    if (separator.isEmpty || digits.length <= 3) {
      return '${rounded < 0 ? '-' : ''}$digits';
    }

    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < digits.length; index += 1) {
      final int remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(separator);
      }
    }

    return '${rounded < 0 ? '-' : ''}$buffer';
  }

  String _formatDate(DateTime value) =>
      context.read<LocaleSettingsProvider>().formatDate(value);

  Future<void> _openNovoColaborador() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
          ),
          child: const _ColaboradorConviteMobileSheet(),
        );
      },
    );

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openEditar(ColaboradorUsuarioResumo resumo) async {
    try {
      final ColaboradorUsuarioDetalhe detalhe = await _api.buscarColaborador(
        resumo.idUnicoPessoal,
      );
      if (!mounted) {
        return;
      }

      final Map<String, dynamic>? payload =
          await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            barrierColor: Colors.black.withValues(alpha: 0.36),
            backgroundColor: Colors.transparent,
            builder: (BuildContext bottomSheetContext) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
                ),
                child: _EditarColaboradorMobileSheet(
                  resumo: resumo,
                  detalhe: detalhe,
                ),
              );
            },
          );

      if (payload == null) {
        return;
      }

      await _api.editarColaborador(payload);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'colaboradores.updatedSuccessfully',
              'Colaborador atualizado com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(error.statusCode)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider>();

    return SixMobilePageShell(
      title: _t('colaboradores.title', 'Colaboradores'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      actions: <Widget>[
        IconButton(
          tooltip: _t('common.refresh', 'Atualizar'),
          onPressed: _loading ? null : _reload,
          icon: Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: _t('colaboradores.newCollaborator', 'Novo colaborador'),
          onPressed: _loading ? null : _openNovoColaborador,
          icon: Icon(Icons.group_add_outlined),
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(top: false, child: _body(scrollController, topInset));
      },
    );
  }

  Widget _body(ScrollController scrollController, double topInset) {
    if (_loading && _colaboradores.isEmpty) {
      return _MobileColaboradoresLoading(topInset: topInset);
    }

    if (_erro != null && _colaboradores.isEmpty) {
      return _errorState();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
        children: <Widget>[
          _entry(order: 0, child: _headerCard()),
          SizedBox(height: 14),
          _entry(order: 1, child: _summaryRow()),
          SizedBox(height: 14),
          _entry(order: 2, child: _searchBox()),
          if (_erro != null) ...<Widget>[
            SizedBox(height: 12),
            _inlineError(_erro!),
          ],
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _t(
                    'colaboradores.foundCollaborators',
                    'Colaboradores encontrados',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _borderColor),
                ),
                child: Text(
                  _formatCount(_items.length),
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_items.isEmpty)
            _emptyState()
          else
            ..._items.toList().asMap().entries.map(
              (MapEntry<int, ColaboradorUsuarioResumo> entry) => _entry(
                order: entry.key + 3,
                child: _colaboradorCard(entry.value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entry({required int order, required Widget child}) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) return child;
    return SixStaggeredEntry(
      delay: Duration(milliseconds: 45 * order.clamp(0, 8)),
      beginOffset: Offset(0, 0.035),
      child: child,
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
            color: SixMobilePalette.heroShadow,
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
            child: Icon(Icons.badge_outlined, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _t('colaboradores.businessTeam', 'Equipe do comércio'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _t(
                    'colaboradores.businessTeamSubtitle',
                    'Convide, acompanhe e ajuste permissões dos colaboradores.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _loading ? null : _openNovoColaborador,
                  icon: Icon(Icons.group_add_outlined, size: 18),
                  label: Text(
                    _t('colaboradores.newCollaborator', 'Novo colaborador'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: SixMobilePalette.onPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final int comEmail =
        _colaboradores
            .where(
              (ColaboradorUsuarioResumo item) => item.email.trim().isNotEmpty,
            )
            .length;
    final int comCelular =
        _colaboradores
            .where(
              (ColaboradorUsuarioResumo item) =>
                  item.celularDeAcesso.trim().isNotEmpty,
            )
            .length;
    final int incompletos =
        _colaboradores
            .where((ColaboradorUsuarioResumo item) => item.nome.trim().isEmpty)
            .length;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _summaryCard(
                Icons.groups_2_outlined,
                _t('colaboradores.team', 'Equipe'),
                _formatCount(_colaboradores.length),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                Icons.alternate_email_rounded,
                _t('colaboradores.withEmail', 'Com e-mail'),
                _formatCount(comEmail),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _summaryCard(
                Icons.phone_iphone_rounded,
                _t('colaboradores.withPhone', 'Com celular'),
                _formatCount(comCelular),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                Icons.manage_accounts_outlined,
                _t('colaboradores.incomplete', 'Incompleto'),
                _formatCount(incompletos),
                highlight: incompletos > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final Color iconColor = highlight ? Colors.orange.shade800 : _primaryColor;
    final Color bgColor = highlight ? Color(0xFFFFF7ED) : _softAccentColor;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: _t(
            'colaboradores.searchCollaborator',
            'Buscar colaborador...',
          ),
          prefixIcon: Icon(Icons.search_rounded),
          suffixIcon:
              _search.text.isEmpty
                  ? null
                  : IconButton(
                    tooltip: _t('common.clear', 'Limpar'),
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

  Widget _colaboradorCard(ColaboradorUsuarioResumo colaborador) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  _initials(colaborador.nome),
                  style: TextStyle(
                    color: _primaryColor,
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
                      colaborador.nome.isEmpty
                          ? _t(
                            'colaboradores.unnamedCollaborator',
                            'Colaborador sem nome',
                          )
                          : colaborador.nome,
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
                      colaborador.nomeDeGuerra.isEmpty
                          ? _t('colaboradores.noNickname', 'Sem nome de guerra')
                          : colaborador.nomeDeGuerra,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _status(_t('common.active', 'Ativo')),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(
                Icons.mail_outline,
                colaborador.email.isEmpty
                    ? _t('colaboradores.noEmail', 'Sem e-mail')
                    : colaborador.email,
              ),
              _chip(
                Icons.phone_outlined,
                colaborador.celularDeAcesso.isEmpty
                    ? _t('colaboradores.noPhone', 'Sem celular')
                    : colaborador.celularDeAcesso,
              ),
              _chip(Icons.badge_outlined, colaborador.idUnicoPessoal),
            ],
          ),
          SizedBox(height: 12),
          _accessHint(colaborador),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetails(colaborador),
                  icon: Icon(Icons.info_outline_rounded, size: 18),
                  label: Text(_t('colaboradores.summary', 'Resumo')),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditar(colaborador),
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text(_t('common.edit', 'Editar')),
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
        color: Color(0xFFF8FAFC),
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

  Widget _status(String label) {
    final Color color = Colors.green.shade700;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _accessHint(ColaboradorUsuarioResumo colaborador) {
    final bool semEmail = colaborador.email.trim().isEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semEmail ? Color(0xFFFFF7ED) : Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: semEmail ? Color(0xFFFED7AA) : Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            semEmail
                ? Icons.warning_amber_rounded
                : Icons.admin_panel_settings_outlined,
            color: semEmail ? Colors.orange.shade800 : _primaryColor,
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              semEmail
                  ? _t(
                    'colaboradores.emailRequiredForAccess',
                    'Informe um e-mail para liberar vínculo de acesso.',
                  )
                  : _t(
                    'colaboradores.accessControlledByInvite',
                    'Acesso controlado por convite e permissões.',
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.group_add_outlined, color: _primaryColor),
          ),
          SizedBox(height: 12),
          Text(
            _t(
              'colaboradores.noCollaboratorFound',
              'Nenhum colaborador encontrado',
            ),
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _t(
              'colaboradores.emptySubtitle',
              'Convide colaboradores para vendas, atendimento e gestão diária.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
          SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openNovoColaborador,
            icon: Icon(Icons.group_add_outlined),
            label: Text(
              _t('colaboradores.newCollaborator', 'Novo colaborador'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 44, color: _primaryColor),
            SizedBox(height: 12),
            Text(
              _erro ??
                  _t(
                    'colaboradores.unableToLoadCollaborators',
                    'Não foi possível carregar os colaboradores.',
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _reload,
              icon: Icon(Icons.refresh_rounded),
              label: Text(_t('common.tryAgain', 'Tentar novamente')),
            ),
          ],
        ),
      ),
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

  void _showDetails(ColaboradorUsuarioResumo colaborador) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                colaborador.nome.isEmpty
                    ? _t('colaboradores.collaborator', 'Colaborador')
                    : colaborador.nome,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 14),
              _detailRow(
                _t('colaboradores.nickname', 'Nome de guerra'),
                colaborador.nomeDeGuerra.isEmpty
                    ? '-'
                    : colaborador.nomeDeGuerra,
              ),
              _detailRow(
                _t('colaboradores.phone', 'Celular'),
                colaborador.celularDeAcesso.isEmpty
                    ? '-'
                    : colaborador.celularDeAcesso,
              ),
              _detailRow(
                _t('colaboradores.email', 'E-mail'),
                colaborador.email.isEmpty ? '-' : colaborador.email,
              ),
              _detailRow(
                _t('colaboradores.createdAt', 'Cadastro'),
                colaborador.dataCadastro == null
                    ? '-'
                    : _formatDate(colaborador.dataCadastro!),
              ),
              _detailRow(
                _t('colaboradores.identifier', 'Identificador'),
                colaborador.idUnicoPessoal,
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  child: Text(_t('common.close', 'Fechar')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
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

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'CO';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ColaboradorConviteMobileSheet extends StatefulWidget {
  const _ColaboradorConviteMobileSheet();

  @override
  State<_ColaboradorConviteMobileSheet> createState() =>
      _ColaboradorConviteMobileSheetState();
}

class _ColaboradorConviteMobileSheetState
    extends State<_ColaboradorConviteMobileSheet> {
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _celular = TextEditingController(text: '+55');

  bool _fazVenda = true;
  bool _lancaServico = true;
  bool _editaCliente = true;
  bool _acessaFinanceiro = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _loading = false;
  ColaboradorConviteResponse? _convite;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _celular.dispose();
    super.dispose();
  }

  Future<void> _criarConvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _convite = null;
    });

    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        ColaboradorConviteRequest(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          celular: _celular.text.trim(),
          permissoes: _permissoesSelecionadas(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() => _convite = response);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'colaboradores.inviteCreatedSuccessfully',
              'Convite de colaborador criado com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> _permissoesSelecionadas() {
    return <String>[
      if (_fazVenda) 'VENDAS_CRIAR',
      if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
      if (_editaCliente) 'CLIENTES_EDITAR',
      if (_acessaFinanceiro) 'FINANCEIRO_ACESSAR',
      if (_geraRelatorio) 'RELATORIOS_GERAR',
      if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
    ];
  }

  String _linkConvite(ColaboradorConviteResponse convite) {
    final Uri publicUrl = Uri.parse(AppConfig.autoCustomerBaseUrl);
    final String origin =
        publicUrl.hasScheme && publicUrl.host.isNotEmpty
            ? publicUrl.origin
            : Uri.base.origin;
    return '$origin/colaborador/convites/${convite.codigo}';
  }

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _convite;
    if (convite == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _linkConvite(convite)));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t('colaboradores.inviteLinkCopied', 'Link do convite copiado.'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    final ColaboradorConviteResponse? convite = _convite;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
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
                    child: Icon(Icons.group_add_outlined, color: _accentColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _t(
                            'colaboradores.newCollaborator',
                            'Novo colaborador',
                          ),
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          _t(
                            'colaboradores.createInviteSubtitle',
                            'Gere um convite com permissões iniciais.',
                          ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: _nome,
                decoration: _input(
                  _t('colaboradores.collaboratorName', 'Nome do colaborador'),
                  Icons.person_outline,
                ),
                validator:
                    (String? value) =>
                        value == null || value.trim().isEmpty
                            ? _t(
                              'colaboradores.nameRequired',
                              'Informe o nome.',
                            )
                            : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: _input(
                  _t('colaboradores.loginEmail', 'E-mail de login'),
                  Icons.email_outlined,
                ),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (String? value) =>
                        value == null || value.trim().isEmpty
                            ? _t(
                              'colaboradores.emailRequired',
                              'Informe o e-mail.',
                            )
                            : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _celular,
                decoration: _input(
                  _t('colaboradores.phone', 'Celular'),
                  Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 18),
              Text(
                _t('colaboradores.initialPermissions', 'Permissões iniciais'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              _switchCard(
                _t('colaboradores.sales', 'Vendas'),
                _t('colaboradores.canCreateSales', 'Pode criar vendas.'),
                _fazVenda,
                (bool value) => setState(() => _fazVenda = value),
              ),
              _switchCard(
                _t('colaboradores.technicalAssistance', 'Assistência técnica'),
                _t(
                  'colaboradores.canCreateTechnicalServices',
                  'Pode lançar atendimentos técnicos.',
                ),
                _lancaServico,
                (bool value) => setState(() => _lancaServico = value),
              ),
              _switchCard(
                _t('colaboradores.customers', 'Clientes'),
                _t('colaboradores.canEditCustomers', 'Pode editar clientes.'),
                _editaCliente,
                (bool value) => setState(() => _editaCliente = value),
              ),
              _switchCard(
                _t('colaboradores.finance', 'Financeiro'),
                _t(
                  'colaboradores.canAccessFinance',
                  'Pode acessar financeiro.',
                ),
                _acessaFinanceiro,
                (bool value) => setState(() => _acessaFinanceiro = value),
              ),
              _switchCard(
                _t('colaboradores.reports', 'Relatórios'),
                _t(
                  'colaboradores.canGenerateReports',
                  'Pode gerar relatórios.',
                ),
                _geraRelatorio,
                (bool value) => setState(() => _geraRelatorio = value),
              ),
              _switchCard(
                _t('colaboradores.permissions', 'Permissões'),
                _t(
                  'colaboradores.canManagePermissions',
                  'Pode gerenciar permissões.',
                ),
                _gerenciaPermissoes,
                (bool value) => setState(() => _gerenciaPermissoes = value),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _criarConvite,
                  icon:
                      _loading
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Icons.send_outlined),
                  label: Text(
                    _loading
                        ? _t(
                          'colaboradores.generatingInvite',
                          'Gerando convite...',
                        )
                        : _t('colaboradores.generateInvite', 'Gerar convite'),
                  ),
                ),
              ),
              if (convite != null) ...<Widget>[
                SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _softAccentColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: SixMobilePalette.highlightedBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _t('colaboradores.inviteCreated', 'Convite criado'),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 8),
                      SelectableText(
                        _linkConvite(convite),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copiarLink,
                          icon: Icon(Icons.copy_outlined),
                          label: Text(_t('common.copy', 'Copiar')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: _surfaceColor,
    );
  }

  Widget _switchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EditarColaboradorMobileSheet extends StatefulWidget {
  const _EditarColaboradorMobileSheet({
    required this.resumo,
    required this.detalhe,
  });

  final ColaboradorUsuarioResumo resumo;
  final ColaboradorUsuarioDetalhe detalhe;

  @override
  State<_EditarColaboradorMobileSheet> createState() =>
      _EditarColaboradorMobileSheetState();
}

class _EditarColaboradorMobileSheetState
    extends State<_EditarColaboradorMobileSheet> {
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _nomeDeGuerra;
  late final TextEditingController _email;
  late final TextEditingController _celular;

  bool _podeVender = false;
  bool _podeServico = false;
  bool _podeEditarCliente = false;
  bool _podeRelatorio = false;
  bool _podeFinanceiro = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(
      text:
          widget.detalhe.nome.isNotEmpty
              ? widget.detalhe.nome
              : widget.resumo.nome,
    );
    _nomeDeGuerra = TextEditingController(
      text:
          widget.detalhe.nomeDeGuerra.isNotEmpty
              ? widget.detalhe.nomeDeGuerra
              : widget.resumo.nomeDeGuerra,
    );
    _email = TextEditingController(
      text:
          widget.detalhe.email.isNotEmpty
              ? widget.detalhe.email
              : widget.resumo.email,
    );
    _celular = TextEditingController(
      text:
          widget.detalhe.celularDeAcesso.isNotEmpty
              ? widget.detalhe.celularDeAcesso
              : widget.resumo.celularDeAcesso,
    );

    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> autorizacoes = _ensureMap(
      json['objAutorizacoes'],
    );
    _podeVender = _ensureMap(autorizacoes['objVendasPode'])['fazVenda'] == true;
    _podeServico =
        _ensureMap(autorizacoes['objAssistenciaTecnicaPode'])['lancaServico'] ==
        true;
    _podeEditarCliente =
        _ensureMap(autorizacoes['objClientesPode'])['podeEditarCliente'] ==
        true;
    _podeRelatorio =
        _ensureMap(
          autorizacoes['objRelatoriosPode'],
        )['geraRelatorioDeVendas'] ==
        true;
    final Map<String, dynamic> financeiro = _ensureMap(
      autorizacoes['objLancamentosFinanceirosPode'],
    );
    _podeFinanceiro =
        financeiro['podeReceberNoCaixa'] == true ||
        financeiro['podeVerQuantoVendeu'] == true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _nomeDeGuerra.dispose();
    _email.dispose();
    _celular.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> info = _ensureMap(
      json['objInformacoesDoCadastro'],
    );
    info['idUnicoDoUsuario'] = widget.resumo.idUnicoPessoal;
    json['objInformacoesDoCadastro'] = info;
    json['celularDeAcesso'] = _celular.text.trim();
    json['senhaParaPermitirOAcessoDoColaborador'] = null;

    final Map<String, dynamic> pessoa = _ensureMap(json['objPessoa']);
    pessoa['nome'] = _nome.text.trim();
    pessoa['nomeDeGuerra'] = _nomeDeGuerra.text.trim();
    pessoa['email'] = _email.text.trim();
    pessoa['celular'] = _celular.text.trim();
    pessoa['senha'] = null;
    json['objPessoa'] = pessoa;

    final Map<String, dynamic> autorizacoes = _ensureMap(
      json['objAutorizacoes'],
    );
    autorizacoes['podeCadastrarProduto'] =
        autorizacoes['podeCadastrarProduto'] ?? false;
    autorizacoes['podeFazerDevolucao'] =
        autorizacoes['podeFazerDevolucao'] ?? false;
    autorizacoes['objVendasPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objVendasPode']),
      'fazVenda': _podeVender,
    };
    autorizacoes['objAssistenciaTecnicaPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objAssistenciaTecnicaPode']),
      'lancaServico': _podeServico,
    };
    autorizacoes['objClientesPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objClientesPode']),
      'podeEditarCliente': _podeEditarCliente,
    };
    autorizacoes['objRelatoriosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objRelatoriosPode']),
      'geraRelatorioDeVendas': _podeRelatorio,
    };
    autorizacoes['objLancamentosFinanceirosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objLancamentosFinanceirosPode']),
      'podeReceberNoCaixa': _podeFinanceiro,
      'podeVerQuantoVendeu': _podeFinanceiro,
    };
    json['objAutorizacoes'] = autorizacoes;
    return json;
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
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
                    child: Icon(Icons.edit_outlined, color: _accentColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _t(
                            'colaboradores.editCollaborator',
                            'Editar colaborador',
                          ),
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          _t(
                            'colaboradores.editCollaboratorSubtitle',
                            'Atualize dados de acesso e permissões.',
                          ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: _nome,
                decoration: _input(
                  _t('colaboradores.name', 'Nome'),
                  Icons.person_outline,
                ),
                validator:
                    (String? value) =>
                        value == null || value.trim().isEmpty
                            ? _t(
                              'colaboradores.nameRequired',
                              'Informe o nome.',
                            )
                            : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nomeDeGuerra,
                decoration: _input(
                  _t('colaboradores.nickname', 'Nome de guerra'),
                  Icons.badge_outlined,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: _input(
                  _t('colaboradores.email', 'E-mail'),
                  Icons.email_outlined,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _celular,
                decoration: _input(
                  _t('colaboradores.phone', 'Celular'),
                  Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 18),
              Text(
                _t(
                  'colaboradores.operationalPermissions',
                  'Permissões operacionais',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              _switchCard(
                _t('colaboradores.sales', 'Vendas'),
                _t(
                  'colaboradores.canMakeSalesInBusiness',
                  'Pode realizar vendas no comércio.',
                ),
                _podeVender,
                (bool value) => setState(() => _podeVender = value),
              ),
              _switchCard(
                _t('colaboradores.technicalAssistance', 'Assistência técnica'),
                _t(
                  'colaboradores.canCreateTechnicalWork',
                  'Pode lançar serviços técnicos.',
                ),
                _podeServico,
                (bool value) => setState(() => _podeServico = value),
              ),
              _switchCard(
                _t('colaboradores.customers', 'Clientes'),
                _t(
                  'colaboradores.canEditCustomerData',
                  'Pode editar dados de clientes.',
                ),
                _podeEditarCliente,
                (bool value) => setState(() => _podeEditarCliente = value),
              ),
              _switchCard(
                _t('colaboradores.reports', 'Relatórios'),
                _t(
                  'colaboradores.canGenerateSalesReports',
                  'Pode gerar relatórios de vendas.',
                ),
                _podeRelatorio,
                (bool value) => setState(() => _podeRelatorio = value),
              ),
              _switchCard(
                _t('colaboradores.finance', 'Financeiro'),
                _t(
                  'colaboradores.canAccessReceivablesAndSalesAmounts',
                  'Pode acessar recebimentos e valores vendidos.',
                ),
                _podeFinanceiro,
                (bool value) => setState(() => _podeFinanceiro = value),
              ),
              SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_t('common.cancel', 'Cancelar')),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        Navigator.of(context).pop(_payload());
                      },
                      icon: Icon(Icons.save_outlined, size: 18),
                      label: Text(_t('common.save', 'Salvar')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: _surfaceColor,
    );
  }

  Widget _switchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  static Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class _MobileColaboradoresLoading extends StatelessWidget {
  const _MobileColaboradoresLoading({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t('common.loading', fallback: 'Carregando...'),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
        children: <Widget>[
          _LoadingBlock(height: 130),
          SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: _LoadingBlock(height: 104)),
              SizedBox(width: 10),
              Expanded(child: _LoadingBlock(height: 104)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(child: _LoadingBlock(height: 104)),
              SizedBox(width: 10),
              Expanded(child: _LoadingBlock(height: 104)),
            ],
          ),
          SizedBox(height: 14),
          _LoadingBlock(height: 76),
          SizedBox(height: 16),
          _LoadingBlock(height: 190),
          SizedBox(height: 12),
          _LoadingBlock(height: 190),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.border),
      ),
    );
  }
}
