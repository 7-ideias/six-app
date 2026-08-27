import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/admin_planos_service.dart';
import '../../core/services/auth_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';

class AdminPlanosWebPage extends StatefulWidget {
  const AdminPlanosWebPage({super.key});

  @override
  State<AdminPlanosWebPage> createState() => _AdminPlanosWebPageState();
}

class _AdminPlanosWebPageState extends State<AdminPlanosWebPage> {
  final AdminPlanosService _service = AdminPlanosService();
  final AuthService _authService = AuthService();

  bool _carregando = true;
  bool _saindo = false;
  String? _erro;
  String? _userName;
  String? _userEmail;
  List<AdminPlanoPublico> _planos = const <AdminPlanoPublico>[];

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final List<AdminPlanoPublico> planos = await _service.listar();
      if (!mounted) return;
      setState(() {
        _planos = planos;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;
      final String message = error.toString().replaceAll('Exception: ', '');
      if (_erroDeSessao(message)) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
        return;
      }
      setState(() {
        _erro = message;
        _carregando = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    try {
      await _authService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
    }
  }

  Future<void> _editar({AdminPlanoPublico? plano}) async {
    final _PlansTexts texts = _PlansTexts.of(context);
    final AdminPlanoSalvarInput? input =
        await showDialog<AdminPlanoSalvarInput>(
          context: context,
          barrierDismissible: false,
          builder:
              (BuildContext context) =>
                  _PlanoEditorDialog(plano: plano, texts: texts),
        );
    if (input == null || !mounted) return;

    try {
      await _service.salvar(id: plano?.id, input: input);
      if (!mounted) return;
      _mostrarMensagem(plano == null ? texts.created : texts.updated);
      await _carregar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        error.toString().replaceAll('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _arquivar(AdminPlanoPublico plano) async {
    final _PlansTexts texts = _PlansTexts.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(texts.archiveTitle),
            content: Text(texts.archiveBody(plano.codigo)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(texts.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(texts.archive),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.arquivar(plano.id);
      if (!mounted) return;
      _mostrarMensagem(texts.archived);
      await _carregar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        error.toString().replaceAll('Exception: ', ''),
        error: true,
      );
    }
  }

  void _mostrarMensagem(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade800 : AdminPalette.dark,
      ),
    );
  }

  bool _erroDeSessao(String message) {
    final String normalized = message.toLowerCase();
    return normalized.contains('sessão') ||
        normalized.contains('sessao') ||
        normalized.contains('faça login');
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;
    return normalized
        .split('@')
        .first
        .replaceAll('.', ' ')
        .replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final String profileType = context
        .select<ColaboradorAutorizacoesProvider, String>(
          (ColaboradorAutorizacoesProvider provider) =>
              provider.tipoPerfilUnificado,
        );
    final AdminPortalTexts portalTexts = AdminPortalTexts.of(context);
    final _PlansTexts texts = _PlansTexts.of(context);
    return AdminNavigationShell(
      texts: portalTexts,
      userInfo: AdminPortalUserInfo(
        name: _userName,
        email: _userEmail,
        profileType: profileType,
      ),
      currentRoute: '/admin/planos',
      pageTitle: texts.title,
      onLogout: _logout,
      onRefresh: _carregar,
      refreshing: _carregando,
      loggingOut: _saindo,
      child: AnimatedSwitcher(
        duration: AdminMotion.medium,
        child: _buildContent(texts),
      ),
    );
  }

  Widget _buildContent(_PlansTexts texts) {
    if (_carregando) {
      return const _PlansLoading(key: ValueKey<String>('plans-loading'));
    }
    if (_erro != null) {
      return _PlansError(
        key: const ValueKey<String>('plans-error'),
        message: _erro!,
        retry: texts.retry,
        onRetry: _carregar,
      );
    }

    final int published =
        _planos
            .where((AdminPlanoPublico item) => item.status == 'PUBLICADO')
            .length;
    return Column(
      key: ValueKey<String>('plans-${_planos.length}-$published'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PlansHeader(
          texts: texts,
          total: _planos.length,
          published: published,
          onCreate: () => _editar(),
        ),
        const SizedBox(height: AdminSpacing.lg),
        if (_planos.isEmpty)
          _PlansEmpty(texts: texts, onCreate: () => _editar())
        else
          ..._planos.map(
            (AdminPlanoPublico plano) => Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.md),
              child: _PlanCard(
                plano: plano,
                texts: texts,
                onEdit: () => _editar(plano: plano),
                onArchive:
                    plano.status == 'ARQUIVADO' ? null : () => _arquivar(plano),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlansHeader extends StatelessWidget {
  const _PlansHeader({
    required this.texts,
    required this.total,
    required this.published,
    required this.onCreate,
  });

  final _PlansTexts texts;
  final int total;
  final int published;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;
          final Widget heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                texts.eyebrow,
                style: const TextStyle(
                  color: AdminPalette.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texts.heading,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AdminPalette.dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texts.subtitle,
                style: const TextStyle(
                  color: AdminPalette.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _SummaryChip(label: '${texts.total}: $total'),
                  _SummaryChip(label: '${texts.published}: $published'),
                ],
              ),
            ],
          );
          final Widget action = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(texts.newPlan),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heading, const SizedBox(height: 20), action],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: heading),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plano,
    required this.texts,
    required this.onEdit,
    required this.onArchive,
  });

  final AdminPlanoPublico plano;
  final _PlansTexts texts;
  final VoidCallback onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final String locale =
        language == 'en'
            ? 'en-US'
            : language == 'es'
            ? 'es-ES'
            : 'pt-BR';
    final AdminPlanoTraducao? translation =
        plano.traducoes[locale] ?? plano.traducoes['pt-BR'];
    return AdminSurfaceCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 760;
          final Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _StatusChip(status: plano.status, texts: texts),
                  if (plano.destaque)
                    _TagChip(icon: Icons.star_rounded, label: texts.featured),
                  _TagChip(
                    icon: Icons.swap_vert_rounded,
                    label: '${texts.order}: ${plano.ordemExibicao}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                translation?.nome.trim().isNotEmpty == true
                    ? translation!.nome
                    : plano.codigo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AdminPalette.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plano.codigo,
                style: const TextStyle(
                  color: AdminPalette.mutedText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              if (translation?.descricao.trim().isNotEmpty == true) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  translation!.descricao,
                  style: const TextStyle(color: AdminPalette.bodyText),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: plano.precos
                    .map((AdminPlanoPreco price) => _PricePill(price: price))
                    .toList(growable: false),
              ),
            ],
          );
          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(texts.edit),
              ),
              if (onArchive != null)
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: Text(texts.archive),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[content, const SizedBox(height: 18), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: content),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});
  final AdminPlanoPreco price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Text(
        '${LocaleSettingsProvider.currencySymbolForCode(price.currencyCode)} ${price.valor.toStringAsFixed(2)} · ${price.periodicidade}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.texts});
  final String status;
  final _PlansTexts texts;

  @override
  Widget build(BuildContext context) {
    final bool published = status == 'PUBLICADO';
    final bool archived = status == 'ARQUIVADO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color:
            published
                ? AdminPalette.activeGreen
                : archived
                ? Colors.grey.shade200
                : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Text(
        texts.statusLabel(status),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AdminPalette.border),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AdminPalette.mutedText),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PlanoEditorDialog extends StatefulWidget {
  const _PlanoEditorDialog({required this.plano, required this.texts});

  final AdminPlanoPublico? plano;
  final _PlansTexts texts;

  @override
  State<_PlanoEditorDialog> createState() => _PlanoEditorDialogState();
}

class _PlanoEditorDialogState extends State<_PlanoEditorDialog> {
  static const List<String> _locales = <String>['pt-BR', 'en-US', 'es-ES'];
  static const List<String> _status = <String>[
    'RASCUNHO',
    'PUBLICADO',
    'ARQUIVADO',
  ];
  static const List<String> _periodicities = <String>[
    'GRATUITO',
    'MENSAL',
    'ANUAL',
    'UNICO',
  ];

  late final TextEditingController _code;
  late final TextEditingController _order;
  late final TextEditingController _trialDays;
  late final TextEditingController _userLimit;
  late final TextEditingController _loyaltyMonths;
  late final Map<String, _TranslationDraft> _translations;
  late List<_PriceDraft> _prices;
  late String _selectedStatus;
  late bool _featured;
  late bool _cancelAnytime;
  String? _error;

  @override
  void initState() {
    super.initState();
    final AdminPlanoPublico? plan = widget.plano;
    _code = TextEditingController(text: plan?.codigo ?? '');
    _order = TextEditingController(text: '${plan?.ordemExibicao ?? 0}');
    _trialDays = TextEditingController(
      text: '${plan?.condicoes.diasTeste ?? 0}',
    );
    _userLimit = TextEditingController(
      text: plan?.condicoes.limiteUsuarios?.toString() ?? '',
    );
    _loyaltyMonths = TextEditingController(
      text: '${plan?.condicoes.mesesFidelidade ?? 0}',
    );
    _selectedStatus = plan?.status ?? 'RASCUNHO';
    _featured = plan?.destaque ?? false;
    _cancelAnytime = plan?.condicoes.cancelamentoLivre ?? false;
    _prices =
        (plan?.precos.isNotEmpty ?? false)
            ? plan!.precos.map(_PriceDraft.fromModel).toList(growable: true)
            : <_PriceDraft>[_PriceDraft.empty()];
    _translations = <String, _TranslationDraft>{
      for (final String locale in _locales)
        locale: _TranslationDraft.fromModel(plan?.traducoes[locale]),
    };
  }

  @override
  void dispose() {
    _code.dispose();
    _order.dispose();
    _trialDays.dispose();
    _userLimit.dispose();
    _loyaltyMonths.dispose();
    for (final _PriceDraft price in _prices) {
      price.dispose();
    }
    for (final _TranslationDraft translation in _translations.values) {
      translation.dispose();
    }
    super.dispose();
  }

  void _addPrice() {
    setState(() => _prices.add(_PriceDraft.empty()));
  }

  void _removePrice(int index) {
    if (_prices.length == 1) return;
    final _PriceDraft removed = _prices.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _submit() {
    final String code = _code.text.trim().toUpperCase();
    final int? order = int.tryParse(_order.text.trim());
    if (!RegExp(r'^[A-Z0-9_]{2,40}$').hasMatch(code)) {
      setState(() => _error = widget.texts.invalidCode);
      return;
    }
    if (order == null || order < 0) {
      setState(() => _error = widget.texts.invalidOrder);
      return;
    }

    final List<AdminPlanoPreco> prices = <AdminPlanoPreco>[];
    for (final _PriceDraft draft in _prices) {
      final String currency = draft.currency.text.trim().toUpperCase();
      final double? amount = double.tryParse(
        draft.amount.text.trim().replaceAll(',', '.'),
      );
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency) ||
          amount == null ||
          amount < 0) {
        setState(() => _error = widget.texts.invalidPrice);
        return;
      }
      prices.add(
        AdminPlanoPreco(
          currencyCode: currency,
          valor: amount,
          periodicidade: draft.periodicity,
        ),
      );
    }

    final Map<String, AdminPlanoTraducao> translations =
        <String, AdminPlanoTraducao>{};
    for (final String locale in _locales) {
      final _TranslationDraft draft = _translations[locale]!;
      if (draft.name.text.trim().isEmpty || draft.cta.text.trim().isEmpty) {
        setState(() => _error = widget.texts.incompleteTranslation(locale));
        return;
      }
      translations[locale] = AdminPlanoTraducao(
        nome: draft.name.text,
        descricao: draft.description.text,
        chamadaAcao: draft.cta.text,
        beneficios: draft.features.text
            .split('\n')
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList(growable: false),
      );
    }

    final int? limit =
        _userLimit.text.trim().isEmpty
            ? null
            : int.tryParse(_userLimit.text.trim());
    final int? trial = int.tryParse(_trialDays.text.trim());
    final int? loyalty = int.tryParse(_loyaltyMonths.text.trim());
    if ((limit != null && limit < 1) ||
        trial == null ||
        trial < 0 ||
        loyalty == null ||
        loyalty < 0) {
      setState(() => _error = widget.texts.invalidConditions);
      return;
    }

    Navigator.of(context).pop(
      AdminPlanoSalvarInput(
        codigo: code,
        status: _selectedStatus,
        destaque: _featured,
        ordemExibicao: order,
        precos: prices,
        condicoes: AdminPlanoCondicoes(
          diasTeste: trial,
          limiteUsuarios: limit,
          mesesFidelidade: loyalty,
          cancelamentoLivre: _cancelAnytime,
        ),
        traducoes: translations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.plano == null
                              ? widget.texts.newPlan
                              : widget.texts.editPlan,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.texts.editorSubtitle),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.texts.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _sectionTitle(widget.texts.identification),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        _field(_code, widget.texts.code, width: 260),
                        _field(
                          _order,
                          widget.texts.order,
                          width: 160,
                          numeric: true,
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: widget.texts.status,
                            ),
                            items: _status
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      widget.texts.statusLabel(value),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (String? value) {
                              if (value != null)
                                setState(() => _selectedStatus = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _featured,
                      title: Text(widget.texts.featured),
                      subtitle: Text(widget.texts.featuredHelp),
                      onChanged:
                          (bool value) => setState(() => _featured = value),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(child: _sectionTitle(widget.texts.prices)),
                        TextButton.icon(
                          onPressed: _addPrice,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(widget.texts.addPrice),
                        ),
                      ],
                    ),
                    ..._prices.asMap().entries.map((
                      MapEntry<int, _PriceDraft> entry,
                    ) {
                      final _PriceDraft price = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _field(
                              price.currency,
                              widget.texts.currency,
                              width: 140,
                            ),
                            _field(
                              price.amount,
                              widget.texts.amount,
                              width: 180,
                              numeric: true,
                            ),
                            SizedBox(
                              width: 190,
                              child: DropdownButtonFormField<String>(
                                value: price.periodicity,
                                decoration: InputDecoration(
                                  labelText: widget.texts.periodicity,
                                ),
                                items: _periodicities
                                    .map(
                                      (String value) =>
                                          DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              widget.texts.periodicityLabel(
                                                value,
                                              ),
                                            ),
                                          ),
                                    )
                                    .toList(growable: false),
                                onChanged: (String? value) {
                                  if (value != null)
                                    setState(() => price.periodicity = value);
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: widget.texts.removePrice,
                              onPressed:
                                  _prices.length == 1
                                      ? null
                                      : () => _removePrice(entry.key),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    _sectionTitle(widget.texts.conditions),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        _field(
                          _trialDays,
                          widget.texts.trialDays,
                          width: 180,
                          numeric: true,
                        ),
                        _field(
                          _userLimit,
                          widget.texts.userLimit,
                          width: 210,
                          numeric: true,
                        ),
                        _field(
                          _loyaltyMonths,
                          widget.texts.loyaltyMonths,
                          width: 210,
                          numeric: true,
                        ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _cancelAnytime,
                      title: Text(widget.texts.cancelAnytime),
                      onChanged:
                          (bool value) =>
                              setState(() => _cancelAnytime = value),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(widget.texts.translations),
                    DefaultTabController(
                      length: _locales.length,
                      child: Column(
                        children: <Widget>[
                          TabBar(
                            tabs:
                                _locales
                                    .map((String locale) => Tab(text: locale))
                                    .toList(),
                          ),
                          SizedBox(
                            height: 390,
                            child: TabBarView(
                              children: _locales
                                  .map((String locale) {
                                    final _TranslationDraft draft =
                                        _translations[locale]!;
                                    return ListView(
                                      padding: const EdgeInsets.only(top: 18),
                                      children: <Widget>[
                                        TextField(
                                          controller: draft.name,
                                          decoration: InputDecoration(
                                            labelText: widget.texts.name,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller: draft.description,
                                          minLines: 2,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: widget.texts.description,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller: draft.cta,
                                          decoration: InputDecoration(
                                            labelText: widget.texts.cta,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller: draft.features,
                                          minLines: 5,
                                          maxLines: 7,
                                          decoration: InputDecoration(
                                            labelText: widget.texts.features,
                                            helperText:
                                                widget.texts.featuresHelp,
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                      ],
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.texts.cancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(widget.texts.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required double width,
    bool numeric = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType:
            numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _sectionTitle(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _PriceDraft {
  _PriceDraft({
    required this.currency,
    required this.amount,
    required this.periodicity,
  });

  factory _PriceDraft.empty() => _PriceDraft(
    currency: TextEditingController(text: 'BRL'),
    amount: TextEditingController(text: '0'),
    periodicity: 'MENSAL',
  );

  factory _PriceDraft.fromModel(AdminPlanoPreco price) => _PriceDraft(
    currency: TextEditingController(text: price.currencyCode),
    amount: TextEditingController(text: price.valor.toString()),
    periodicity: price.periodicidade,
  );

  final TextEditingController currency;
  final TextEditingController amount;
  String periodicity;

  void dispose() {
    currency.dispose();
    amount.dispose();
  }
}

class _TranslationDraft {
  _TranslationDraft({
    required this.name,
    required this.description,
    required this.cta,
    required this.features,
  });

  factory _TranslationDraft.fromModel(AdminPlanoTraducao? translation) {
    return _TranslationDraft(
      name: TextEditingController(text: translation?.nome ?? ''),
      description: TextEditingController(text: translation?.descricao ?? ''),
      cta: TextEditingController(text: translation?.chamadaAcao ?? ''),
      features: TextEditingController(
        text: translation?.beneficios.join('\n') ?? '',
      ),
    );
  }

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController cta;
  final TextEditingController features;

  void dispose() {
    name.dispose();
    description.dispose();
    cta.dispose();
    features.dispose();
  }
}

class _PlansLoading extends StatelessWidget {
  const _PlansLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        AdminSkeletonCard(height: 190),
        SizedBox(height: 16),
        AdminSkeletonCard(height: 150),
        SizedBox(height: 16),
        AdminSkeletonCard(height: 150),
      ],
    );
  }
}

class _PlansError extends StatelessWidget {
  const _PlansError({
    super.key,
    required this.message,
    required this.retry,
    required this.onRetry,
  });
  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(retry)),
        ],
      ),
    );
  }
}

class _PlansEmpty extends StatelessWidget {
  const _PlansEmpty({required this.texts, required this.onCreate});
  final _PlansTexts texts;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        children: <Widget>[
          const Icon(Icons.sell_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            texts.empty,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(texts.newPlan),
          ),
        ],
      ),
    );
  }
}

class _PlansTexts {
  const _PlansTexts(this.language);
  final String language;

  factory _PlansTexts.of(BuildContext context) =>
      _PlansTexts(Localizations.localeOf(context).languageCode);

  bool get en => language == 'en';
  bool get es => language == 'es';
  String get title =>
      en
          ? 'Public plans'
          : es
          ? 'Planes públicos'
          : 'Planos públicos';
  String get eyebrow =>
      en
          ? 'COMMERCIAL CATALOG'
          : es
          ? 'CATÁLOGO COMERCIAL'
          : 'CATÁLOGO COMERCIAL';
  String get heading =>
      en
          ? 'Plans shown on the website'
          : es
          ? 'Planes exhibidos en el sitio'
          : 'Planos exibidos no site';
  String get subtitle =>
      en
          ? 'Manage prices, conditions and content without a new deployment.'
          : es
          ? 'Administra precios, condiciones y contenido sin un nuevo despliegue.'
          : 'Gerencie preços, condições e conteúdo sem realizar um novo deploy.';
  String get total =>
      en
          ? 'Total'
          : es
          ? 'Total'
          : 'Total';
  String get published =>
      en
          ? 'Published'
          : es
          ? 'Publicados'
          : 'Publicados';
  String get newPlan =>
      en
          ? 'New plan'
          : es
          ? 'Nuevo plan'
          : 'Novo plano';
  String get editPlan =>
      en
          ? 'Edit plan'
          : es
          ? 'Editar plan'
          : 'Editar plano';
  String get editorSubtitle =>
      en
          ? 'Changes are persisted in MongoDB.'
          : es
          ? 'Los cambios se guardan en MongoDB.'
          : 'As alterações são persistidas no MongoDB.';
  String get edit =>
      en
          ? 'Edit'
          : es
          ? 'Editar'
          : 'Editar';
  String get archive =>
      en
          ? 'Archive'
          : es
          ? 'Archivar'
          : 'Arquivar';
  String get archiveTitle =>
      en
          ? 'Archive plan?'
          : es
          ? '¿Archivar el plan?'
          : 'Arquivar plano?';
  String archiveBody(String code) =>
      en
          ? '$code will no longer be displayed publicly.'
          : es
          ? '$code dejará de mostrarse públicamente.'
          : '$code deixará de ser exibido publicamente.';
  String get archived =>
      en
          ? 'Plan archived.'
          : es
          ? 'Plan archivado.'
          : 'Plano arquivado.';
  String get created =>
      en
          ? 'Plan created.'
          : es
          ? 'Plan creado.'
          : 'Plano criado.';
  String get updated =>
      en
          ? 'Plan updated.'
          : es
          ? 'Plan actualizado.'
          : 'Plano atualizado.';
  String get cancel =>
      en
          ? 'Cancel'
          : es
          ? 'Cancelar'
          : 'Cancelar';
  String get save =>
      en
          ? 'Save'
          : es
          ? 'Guardar'
          : 'Salvar';
  String get retry =>
      en
          ? 'Try again'
          : es
          ? 'Intentar de nuevo'
          : 'Tentar novamente';
  String get empty =>
      en
          ? 'No plans registered yet.'
          : es
          ? 'Aún no hay planes registrados.'
          : 'Nenhum plano cadastrado ainda.';
  String get identification =>
      en
          ? 'Identification and publication'
          : es
          ? 'Identificación y publicación'
          : 'Identificação e publicação';
  String get code =>
      en
          ? 'Stable code'
          : es
          ? 'Código estable'
          : 'Código estável';
  String get order =>
      en
          ? 'Order'
          : es
          ? 'Orden'
          : 'Ordem';
  String get status =>
      en
          ? 'Status'
          : es
          ? 'Estado'
          : 'Status';
  String get featured =>
      en
          ? 'Featured plan'
          : es
          ? 'Plan destacado'
          : 'Plano em destaque';
  String get featuredHelp =>
      en
          ? 'Only one published plan is highlighted at a time.'
          : es
          ? 'Solo un plan publicado se destaca a la vez.'
          : 'Somente um plano publicado fica destacado por vez.';
  String get prices =>
      en
          ? 'Prices by currency'
          : es
          ? 'Precios por moneda'
          : 'Preços por moeda';
  String get addPrice =>
      en
          ? 'Add price'
          : es
          ? 'Agregar precio'
          : 'Adicionar preço';
  String get removePrice =>
      en
          ? 'Remove price'
          : es
          ? 'Eliminar precio'
          : 'Remover preço';
  String get currency =>
      en
          ? 'Currency code'
          : es
          ? 'Código de moneda'
          : 'Código da moeda';
  String get amount =>
      en
          ? 'Amount'
          : es
          ? 'Valor'
          : 'Valor';
  String get periodicity =>
      en
          ? 'Billing period'
          : es
          ? 'Periodicidad'
          : 'Periodicidade';
  String get conditions =>
      en
          ? 'Commercial conditions'
          : es
          ? 'Condiciones comerciales'
          : 'Condições comerciais';
  String get trialDays =>
      en
          ? 'Trial days'
          : es
          ? 'Días de prueba'
          : 'Dias de teste';
  String get userLimit =>
      en
          ? 'User limit (empty = unlimited)'
          : es
          ? 'Límite de usuarios (vacío = ilimitado)'
          : 'Limite de usuários (vazio = ilimitado)';
  String get loyaltyMonths =>
      en
          ? 'Lock-in months'
          : es
          ? 'Meses de permanencia'
          : 'Meses de fidelidade';
  String get cancelAnytime =>
      en
          ? 'Free cancellation'
          : es
          ? 'Cancelación libre'
          : 'Cancelamento livre';
  String get translations =>
      en
          ? 'Public content by language'
          : es
          ? 'Contenido público por idioma'
          : 'Conteúdo público por idioma';
  String get name =>
      en
          ? 'Plan name'
          : es
          ? 'Nombre del plan'
          : 'Nome do plano';
  String get description =>
      en
          ? 'Short description'
          : es
          ? 'Descripción breve'
          : 'Descrição curta';
  String get cta =>
      en
          ? 'Button text'
          : es
          ? 'Texto del botón'
          : 'Texto do botão';
  String get features =>
      en
          ? 'Benefits'
          : es
          ? 'Beneficios'
          : 'Benefícios';
  String get featuresHelp =>
      en
          ? 'One benefit per line.'
          : es
          ? 'Un beneficio por línea.'
          : 'Um benefício por linha.';
  String get invalidCode =>
      en
          ? 'Use 2 to 40 uppercase letters, numbers or underscores in the code.'
          : es
          ? 'Usa entre 2 y 40 letras mayúsculas, números o guiones bajos.'
          : 'Use de 2 a 40 letras maiúsculas, números ou sublinhados no código.';
  String get invalidOrder =>
      en
          ? 'Enter a valid non-negative order.'
          : es
          ? 'Ingresa un orden válido no negativo.'
          : 'Informe uma ordem válida e não negativa.';
  String get invalidPrice =>
      en
          ? 'Check currency, amount and billing period.'
          : es
          ? 'Revisa la moneda, el valor y la periodicidad.'
          : 'Revise a moeda, o valor e a periodicidade.';
  String get invalidConditions =>
      en
          ? 'Check the commercial conditions.'
          : es
          ? 'Revisa las condiciones comerciales.'
          : 'Revise as condições comerciais.';
  String incompleteTranslation(String locale) =>
      en
          ? 'Complete name and button for $locale.'
          : es
          ? 'Completa nombre y botón para $locale.'
          : 'Preencha nome e botão para $locale.';
  String statusLabel(String value) {
    if (value == 'PUBLICADO')
      return en
          ? 'Published'
          : es
          ? 'Publicado'
          : 'Publicado';
    if (value == 'ARQUIVADO')
      return en
          ? 'Archived'
          : es
          ? 'Archivado'
          : 'Arquivado';
    return en
        ? 'Draft'
        : es
        ? 'Borrador'
        : 'Rascunho';
  }

  String periodicityLabel(String value) {
    if (value == 'GRATUITO')
      return en
          ? 'Free'
          : es
          ? 'Gratuito'
          : 'Gratuito';
    if (value == 'ANUAL')
      return en
          ? 'Yearly'
          : es
          ? 'Anual'
          : 'Anual';
    if (value == 'UNICO')
      return en
          ? 'One time'
          : es
          ? 'Pago único'
          : 'Pagamento único';
    return en
        ? 'Monthly'
        : es
        ? 'Mensual'
        : 'Mensal';
  }
}
