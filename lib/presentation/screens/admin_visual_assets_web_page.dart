import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/admin_visual_assets_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/admin_visual_assets_models.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';
import '../admin/admin_visual_assets_catalog.dart';
import '../layouts/six_web_page_shell.dart';
import '../admin/admin_web_hero_appearance_card.dart';
import '../admin/admin_visual_asset_settings_texts.dart';
import '../components/web/six_web_delete_visual_asset_dialog.dart';

class AdminVisualAssetsWebPage extends StatefulWidget {
  const AdminVisualAssetsWebPage({
    super.key,
    this.embeddedInMainShell = false,
  });

  final bool embeddedInMainShell;

  @override
  State<AdminVisualAssetsWebPage> createState() =>
      _AdminVisualAssetsWebPageState();
}

class _AdminVisualAssetsWebPageState extends State<AdminVisualAssetsWebPage> {
  final AuthService _authService = AuthService();
  final AdminVisualAssetsService _service = AdminVisualAssetsService();

  bool _checkingAccess = true;
  bool _loading = false;
  bool _forcing = false;
  bool _loggingOut = false;
  String? _userName;
  String? _userEmail;
  String? _error;
  String _scope = 'GLOBAL';
  String? _companyId;
  String? _segment;
  String? _subsegment;
  List<AdminVisualAssetCompany> _companies =
      const <AdminVisualAssetCompany>[];
  AdminVisualAssetPanel? _panel;

  AdminVisualAssetCompany? get _selectedCompany {
    for (final AdminVisualAssetCompany company in _companies) {
      if (company.id == _companyId) return company;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadUser());
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateSuper());
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _userName = _displayName(email);
    });
  }

  Future<void> _validateSuper() async {
    final ColaboradorAutorizacoesProvider provider =
        context.read<ColaboradorAutorizacoesProvider>();
    await provider.carregarAutorizacoesDoUsuarioLogado(force: true);
    if (!mounted) return;

    if (!provider.ehSuperUsuario) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/app',
        (Route<dynamic> route) => false,
      );
      return;
    }

    setState(() => _checkingAccess = false);
    await _reload(loadCompanies: true);
  }

  Future<void> _reload({bool loadCompanies = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<AdminVisualAssetCompany> companies = _companies;
      if (loadCompanies || companies.isEmpty) {
        companies = await _service.companies();
      }
      String? companyId = _companyId;
      if (_scope == 'EMPRESA' &&
          (companyId == null ||
              !companies.any((AdminVisualAssetCompany c) => c.id == companyId))) {
        companyId = companies.isEmpty ? null : companies.first.id;
      }

      final AdminVisualAssetPanel panel = await _service.panel(
        scope: _scope,
        companyId: _scope == 'EMPRESA' ? companyId : null,
        segment: _scope == 'GLOBAL' ? _segment : null,
        subsegment: _scope == 'GLOBAL' ? _subsegment : null,
      );

      if (!mounted) return;
      setState(() {
        _companies = companies;
        _companyId = companyId;
        _panel = panel;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeScope(String scope) async {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _error = null;
    });
    await _reload();
  }

  Future<void> _forceRefresh() async {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => _VisualAssetsDialogTheme(
            child: AlertDialog(
            title: Text(texts.forceTitle),
            content: Text(texts.forceDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(texts.cancel),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.sync_rounded),
                label: Text(texts.force),
              ),
            ],
          ),
        ),
      ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _forcing = true);
    try {
      await _service.forceRefresh();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.forceSuccess)),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _cleanError(error));
      }
    } finally {
      if (mounted) setState(() => _forcing = false);
    }
  }

  Future<void> _upload(AdminVisualAssetSlotPanel slot) async {
    final bool? changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _UploadAssetDialog(
        service: _service,
        slot: slot,
        scope: _scope,
        company: _selectedCompany,
        segment: _scope == 'GLOBAL' ? _segment : null,
        subsegment: _scope == 'GLOBAL' ? _subsegment : null,
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _deleteImage(AdminVisualAssetSlotPanel slot) async {
    final item = slot.current;
    if (item == null) return;
    final texts = _VisualAssetsTexts.of(context);
    final changed = await showSixWebDeleteVisualAssetDialog(
      context: context,
      title: texts.slotTitle(context, slot),
      target: [_segment, _subsegment]
          .whereType<String>()
          .map(_prettyCode)
          .join(' · '),
      onConfirm: () => _service.delete(item.id, subsegment: _subsegment),
    );
    if (changed && mounted) await _reload();
  }

  Future<void> _showHistory(AdminVisualAssetSlotPanel slot) async {
    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _AssetHistoryDialog(
        service: _service,
        slot: slot,
        scope: _scope,
        backendEnvironment: _panel?.environment ?? 'DEV',
        company: _selectedCompany,
        segment: _scope == 'GLOBAL' ? _segment : null,
        subsegment: _scope == 'GLOBAL' ? _subsegment : null,
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    if (_checkingAccess) {
      return _loadingAccess(texts);
    }

    final ColaboradorAutorizacoesProvider auth =
        context.watch<ColaboradorAutorizacoesProvider>();
    if (!auth.ehSuperUsuario) return const SizedBox.shrink();

    final Widget content = _buildContent(texts);
    if (widget.embeddedInMainShell) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SixWebPageShell(
          child: SingleChildScrollView(
            padding: SixWebPageShell.scrollPadding,
            child: content,
          ),
        ),
      );
    }

    return AdminNavigationShell(
      texts: AdminPortalTexts.of(context),
      userInfo: AdminPortalUserInfo(
        name: _userName,
        email: _userEmail,
        profileType: auth.tipoPerfilUnificado,
      ),
      currentRoute: '/admin/imagens-contextuais',
      pageTitle: texts.title,
      onLogout: _logout,
      onRefresh: () => _reload(loadCompanies: true),
      refreshing: _loading,
      loggingOut: _loggingOut,
      standardPageSpacing: true,
      child: content,
    );
  }

  Widget _loadingAccess(_VisualAssetsTexts texts) {
    final Widget loading = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _VisualAssetsSurfaceCard(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                Text(
                  texts.checkingAccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.embeddedInMainShell) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: loading);
    }
    return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: loading);
  }

  Widget _buildContent(_VisualAssetsTexts texts) {
    final AdminVisualAssetPanel? panel = _panel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    texts.eyebrow.toUpperCase(),
                    style: TextStyle(
                      color: AdminPalette.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texts.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texts.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            FilledButton.tonalIcon(
              onPressed: _forcing ? null : _forceRefresh,
              icon: _forcing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.sync_rounded),
              label: Text(texts.force),
            ),
          ],
        ),
        SixWebPageShell.sectionGap,
        _VisualAssetsSurfaceCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                _ScopeSelector(
                  value: _scope,
                  onChanged: _loading ? null : _changeScope,
                  texts: texts,
                ),
                if (_scope == 'EMPRESA')
                  _AdminVisualSelectField<String?>(
                    width: 310,
                    label: texts.company,
                    icon: Icons.storefront_rounded,
                    value: _companyId,
                    options: _companies
                        .map(
                          (AdminVisualAssetCompany company) =>
                              _AdminVisualSelectOption<String?>(
                            value: company.id,
                            label: '${company.name} · ${company.timeZone}',
                          ),
                        )
                        .toList(growable: false),
                    enabled: !_loading && _companies.isNotEmpty,
                    onSelected: (String? value) {
                      setState(() => _companyId = value);
                      unawaited(_reload());
                    },
                  ),
                if (_scope == 'GLOBAL') ...<Widget>[
                  _AdminVisualSelectField<String?>(
                    width: 250,
                    label: texts.segment,
                    icon: Icons.category_rounded,
                    value: _segment,
                    options: <_AdminVisualSelectOption<String?>>[
                      _AdminVisualSelectOption<String?>(
                        value: null,
                        label: texts.globalDefault,
                      ),
                      ...AdminVisualAssetsCatalog.segmentos.keys.map(
                        (String segment) =>
                            _AdminVisualSelectOption<String?>(
                          value: segment,
                          label: _prettyCode(segment),
                        ),
                      ),
                    ],
                    enabled: !_loading,
                    onSelected: (String? value) {
                      setState(() {
                        _segment = value;
                        _subsegment = null;
                      });
                      unawaited(_reload());
                    },
                  ),
                  _AdminVisualSelectField<String?>(
                    width: 250,
                    label: texts.specialty,
                    icon: Icons.auto_awesome_motion_rounded,
                    value: _subsegment,
                    options: <_AdminVisualSelectOption<String?>>[
                      _AdminVisualSelectOption<String?>(
                        value: null,
                        label: texts.noSpecialty,
                      ),
                      ...AdminVisualAssetsCatalog.subsegmentosDe(_segment).map(
                        (String sub) => _AdminVisualSelectOption<String?>(
                          value: sub,
                          label: _prettyCode(sub),
                        ),
                      ),
                    ],
                    enabled: _segment != null && !_loading,
                    onSelected: (String? value) {
                      setState(() => _subsegment = value);
                      unawaited(_reload());
                    },
                  ),
                ],
                _VersionBadge(
                  version: panel?.assetsVersion ?? '—',
                  texts: texts,
                ),
                _EnvironmentBadge(
                  environment: panel?.environment ?? '—',
                  texts: texts,
                ),
              ],
            ),
          ),
        ),
        if (panel?.environment == 'DEV') ...<Widget>[
          SixWebPageShell.sectionGap,
          _EnvironmentNotice(texts: texts),
        ],
        if (_error != null) ...<Widget>[
          SixWebPageShell.sectionGap,
          _ErrorBanner(
            message: _error!,
            retry: () => _reload(loadCompanies: true),
          ),
        ],
        SixWebPageShell.sectionGap,
        if (_loading && panel == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_scope == 'EMPRESA' && _selectedCompany == null)
          _EmptyState(
            icon: Icons.storefront_outlined,
            title: texts.noCompanies,
            subtitle: texts.noCompaniesSubtitle,
          )
        else if (panel != null) ...<Widget>[
          AdminWebHeroAppearanceCard(
            key: ValueKey(panel.environment),
            service: _service,
            imageUrl: panel.slots
                .where((slot) => slot.platform == 'WEB' &&
                    (slot.current ?? slot.fallback) != null)
                .map((slot) => (slot.current ?? slot.fallback)!.imageUrl)
                .firstOrNull,
          ),
          SixWebPageShell.sectionGap,
          _PlatformSection(
            title: 'Web',
            icon: Icons.language_rounded,
            slots: panel.slots
                .where((AdminVisualAssetSlotPanel slot) => slot.platform == 'WEB')
                .toList(growable: false),
            companyScope: _scope == 'EMPRESA',
            texts: texts,
            onUpload: _upload,
            onHistory: _showHistory,
            onDelete: _scope == 'GLOBAL' && _segment != null ? _deleteImage : null,
            environment: panel.environment,
          ),
          SixWebPageShell.sectionGap,
          _PlatformSection(
            title: 'Mobile',
            icon: Icons.phone_iphone_rounded,
            slots: panel.slots
                .where(
                  (AdminVisualAssetSlotPanel slot) => slot.platform == 'MOBILE',
                )
                .toList(growable: false),
            companyScope: _scope == 'EMPRESA',
            texts: texts,
            onUpload: _upload,
            onHistory: _showHistory,
            onDelete: _scope == 'GLOBAL' && _segment != null ? _deleteImage : null,
            environment: panel.environment,
          ),
        ],
      ],
    );
  }
}

class _VisualAssetsDialogTheme extends StatelessWidget {
  const _VisualAssetsDialogTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final bool dark = base.brightness == Brightness.dark;
    final ColorScheme colors = base.colorScheme;

    return Theme(
      data: base.copyWith(
        dialogTheme: base.dialogTheme.copyWith(
          backgroundColor: dark
              ? colors.surfaceContainerHigh
              : colors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: dark
              ? colors.surfaceContainerHighest
              : colors.surfaceContainerLowest,
          labelStyle: TextStyle(color: colors.onSurfaceVariant),
          helperStyle: TextStyle(color: colors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
        ),
        dividerColor: colors.outlineVariant,
      ),
      child: child,
    );
  }
}

class _VisualAssetsSurfaceCard extends StatelessWidget {
  const _VisualAssetsSurfaceCard({
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? colors.surfaceContainer
            : colors.surface,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.shadowColor.withValues(
              alpha: dark ? 0.28 : 0.05,
            ),
            blurRadius: dark ? 28 : 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 22),
        child: child,
      ),
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.value,
    required this.onChanged,
    required this.texts,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final _VisualAssetsTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ScopeOption(
            icon: Icons.public_rounded,
            label: texts.global,
            selected: value == 'GLOBAL',
            enabled: onChanged != null,
            onTap: () => onChanged?.call('GLOBAL'),
          ),
          const SizedBox(width: 4),
          _ScopeOption(
            icon: Icons.storefront_rounded,
            label: texts.company,
            selected: value == 'EMPRESA',
            enabled: onChanged != null,
            onTap: () => onChanged?.call('EMPRESA'),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatefulWidget {
  const _ScopeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ScopeOption> createState() => _ScopeOptionState();
}

class _ScopeOptionState extends State<_ScopeOption> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.selected || _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedOpacity(
        duration: AdminMotion.fast,
        opacity: widget.enabled ? 1 : 0.55,
        child: AnimatedContainer(
          duration: AdminMotion.fast,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.selected
                ? Theme.of(context).colorScheme.primary
                : active
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AdminRadius.md),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AdminRadius.md),
              onTap: widget.enabled ? widget.onTap : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminVisualSelectOption<T> {
  const _AdminVisualSelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _AdminVisualSelectField<T> extends StatefulWidget {
  const _AdminVisualSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.icon,
    this.width = 260,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<_AdminVisualSelectOption<T>> options;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final double width;
  final bool enabled;

  @override
  State<_AdminVisualSelectField<T>> createState() =>
      _AdminVisualSelectFieldState<T>();
}

class _AdminVisualSelectFieldState<T>
    extends State<_AdminVisualSelectField<T>> {
  bool _hovering = false;
  bool _open = false;

  _AdminVisualSelectOption<T> get _selectedOption {
    for (final _AdminVisualSelectOption<T> option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return widget.options.isNotEmpty
        ? widget.options.first
        : _AdminVisualSelectOption<T>(value: widget.value, label: '—');
  }

  Future<void> _showOptions() async {
    if (!widget.enabled || widget.options.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset offset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size size = fieldBox.size;

    setState(() => _open = true);
    final _AdminVisualSelectOption<T>? selected =
        await showMenu<_AdminVisualSelectOption<T>>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8,
        overlayBox.size.width - offset.dx - size.width,
        0,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 10,
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      items: widget.options
          .map(
            (_AdminVisualSelectOption<T> option) =>
                PopupMenuItem<_AdminVisualSelectOption<T>>(
              value: option,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: _AdminVisualSelectMenuItem(
                label: option.label,
                selected: option.value == widget.value,
              ),
            ),
          )
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected.value != widget.value) {
      widget.onSelected(selected.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _AdminVisualSelectOption<T> selected = _selectedOption;
    final bool active = widget.enabled && (_hovering || _open);

    return SizedBox(
      width: widget.width,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.label,
        value: selected.label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedOpacity(
            duration: AdminMotion.fast,
            opacity: widget.enabled ? 1 : 0.58,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AdminRadius.lg),
                onTap: widget.enabled ? _showOptions : null,
                child: Tooltip(
                  message: '${widget.label}: ${selected.label}',
                  waitDuration: const Duration(milliseconds: 450),
                  child: AnimatedContainer(
                    duration: AdminMotion.fast,
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 58),
                    padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AdminRadius.lg),
                      border: Border.all(
                        color: active
                            ? AdminPalette.success
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: active ? 1.3 : 1,
                      ),
                      boxShadow: active
                          ? <BoxShadow>[
                              BoxShadow(
                                color:
                                    Theme.of(context).shadowColor.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 9),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: active
                              ? AdminPalette.success
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: AdminMotion.fast,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: active
                                ? AdminPalette.success
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminVisualSelectMenuItem extends StatelessWidget {
  const _AdminVisualSelectMenuItem({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.32)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(
          color: selected ? AdminPalette.success : Colors.transparent,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: selected ? AdminPalette.success : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.texts});

  final String version;
  final _VisualAssetsTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.memory_rounded,
            size: 17,
            color: AdminPalette.success,
          ),
          const SizedBox(width: 8),
          Text(
            '${texts.version}: $version',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge({
    required this.environment,
    required this.texts,
  });

  final String environment;
  final _VisualAssetsTexts texts;

  @override
  Widget build(BuildContext context) {
    final bool live = environment == 'LIVE';
    final Color color = live ? AdminPalette.success : AdminPalette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            live ? Icons.cloud_done_rounded : Icons.science_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${texts.environment}: $environment',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentNotice extends StatelessWidget {
  const _EnvironmentNotice({required this.texts});

  final _VisualAssetsTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AdminPalette.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(
          color: AdminPalette.warning.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.science_rounded,
            color: AdminPalette.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texts.devNotice,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  const _PlatformSection({
    required this.title,
    required this.icon,
    required this.slots,
    required this.companyScope,
    required this.texts,
    required this.onUpload,
    required this.onHistory,
    this.onDelete,
    required this.environment,
  });

  final String title;
  final IconData icon;
  final List<AdminVisualAssetSlotPanel> slots;
  final bool companyScope;
  final _VisualAssetsTexts texts;
  final ValueChanged<AdminVisualAssetSlotPanel> onUpload;
  final ValueChanged<AdminVisualAssetSlotPanel> onHistory;
  final ValueChanged<AdminVisualAssetSlotPanel>? onDelete;
  final String environment;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 9),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${slots.length} ${texts.positions}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double cardWidth = width >= 1180
                ? (width - 2 * SixWebPageShell.sectionSpacing) / 3
                : width >= 760
                ? (width - SixWebPageShell.sectionSpacing) / 2
                : width;
            return Wrap(
              spacing: SixWebPageShell.sectionSpacing,
              runSpacing: SixWebPageShell.sectionSpacing,
              children: slots
                  .map(
                    (AdminVisualAssetSlotPanel slot) => SizedBox(
                      width: cardWidth,
                      child: _SlotCard(
                        slot: slot,
                        companyScope: companyScope,
                        texts: texts,
                        onUpload: () => onUpload(slot),
                        onHistory: () => onHistory(slot),
                        onDelete: onDelete != null &&
                                slot.current?.environment == environment
                            ? () => onDelete!(slot)
                            : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.companyScope,
    required this.texts,
    required this.onUpload,
    required this.onHistory,
    this.onDelete,
  });

  final AdminVisualAssetSlotPanel slot;
  final bool companyScope;
  final _VisualAssetsTexts texts;
  final VoidCallback onUpload;
  final VoidCallback onHistory;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return _VisualAssetsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    texts.slotTitle(context, slot),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _PlatformPill(slot.platform),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${slot.recommendedWidth} × ${slot.recommendedHeight} · '
              '${slot.displayMode}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _AssetPreview(
                    label: slot.current == null && slot.fallback != null
                        ? '${texts.current} · ${texts.globalDefault}'
                        : texts.current,
                    asset: slot.current ?? slot.fallback,
                    aspectRatio: slot.aspectRatio,
                    emptyText: companyScope
                        ? texts.noCompanyImage
                        : texts.noImage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AssetPreview(
                    label: texts.next,
                    asset: slot.next,
                    aspectRatio: slot.aspectRatio,
                    emptyText: texts.noSchedule,
                  ),
                ),
              ],
            ),
            if (slot.additionalScheduled > 0) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                '+ ${slot.additionalScheduled} ${texts.moreScheduled}',
                style: TextStyle(
                  color: AdminPalette.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (onDelete != null) ...<Widget>[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(AdminVisualAssetSettingsTexts(context).delete),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onUpload,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text(texts.addOrSchedule),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: texts.history,
                  onPressed: onHistory,
                  icon: Badge(
                    isLabelVisible: slot.historyCount > 0,
                    label: Text(slot.historyCount.toString()),
                    child: Icon(Icons.history_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({
    required this.label,
    required this.asset,
    required this.aspectRatio,
    required this.emptyText,
  });

  final String label;
  final AdminVisualAssetItem? asset;
  final double aspectRatio;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final AdminVisualAssetItem? item = asset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item == null || item.imageUrl.isEmpty
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment(
                      item.focalX * 2 - 1,
                      item.focalY * 2 - 1,
                    ),
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 7),
        if (item != null) ...<Widget>[
          _StatusLine(item),
          const SizedBox(height: 3),
          Text(
            item.activateAtUtc == null
                ? item.version
                : '${_formatDate(item.activateAtUtc!)} · ${item.timeZone}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          _AssetLinkRow(url: item.imageUrl),
        ],
      ],
    );
  }
}

class _AssetLinkRow extends StatelessWidget {
  const _AssetLinkRow({
    required this.url,
    this.compact = false,
  });

  final String url;
  final bool compact;

  Future<void> _open(BuildContext context) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_VisualAssetsTexts.of(context).openUrlFailed)),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_VisualAssetsTexts.of(context).urlCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: compact ? 8 : 10,
        right: 2,
        top: compact ? 4 : 6,
        bottom: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.link_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: url,
              child: SelectableText(
                url,
                maxLines: 1,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 32,
              height: 32,
            ),
            tooltip: _VisualAssetsTexts.of(context).openNewWindow,
            onPressed: () => _open(context),
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 16,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 32,
              height: 32,
            ),
            tooltip: _VisualAssetsTexts.of(context).copyUrl,
            onPressed: () => _copy(context),
            icon: Icon(
              Icons.content_copy_rounded,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.item);

  final AdminVisualAssetItem item;

  @override
  Widget build(BuildContext context) {
    final bool active = item.status == 'ATIVA';
    final bool scheduled = item.status == 'AGENDADA';
    final Color color = active
        ? Colors.green.shade700
        : scheduled
        ? Colors.orange.shade800
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: <Widget>[
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${_prettyCode(item.status)} · v${item.version}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        _AssetEnvironmentPill(item.environment),
      ],
    );
  }
}

class _AssetEnvironmentPill extends StatelessWidget {
  const _AssetEnvironmentPill(this.environment);

  final String environment;

  @override
  Widget build(BuildContext context) {
    final bool live = environment == 'LIVE';
    final Color color = live ? AdminPalette.success : AdminPalette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        environment,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _PlatformPill extends StatelessWidget {
  const _PlatformPill(this.platform);
  final String platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        platform,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UploadImageMetadata extends StatelessWidget {
  const _UploadImageMetadata({
    required this.fileSizeBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.recommendedWidth,
    required this.recommendedHeight,
    required this.platform,
    required this.dimensionReadFailed,
    required this.texts,
  });

  final int fileSizeBytes;
  final int? imageWidth;
  final int? imageHeight;
  final int recommendedWidth;
  final int recommendedHeight;
  final String platform;
  final bool dimensionReadFailed;
  final _VisualAssetsTexts texts;

  bool get _hasDimensions => imageWidth != null && imageHeight != null;

  bool get _exactMatch =>
      _hasDimensions &&
      imageWidth == recommendedWidth &&
      imageHeight == recommendedHeight;

  bool get _sameAspectRatio {
    if (!_hasDimensions ||
        imageWidth == 0 ||
        imageHeight == 0 ||
        recommendedWidth == 0 ||
        recommendedHeight == 0) {
      return false;
    }
    final double selected = imageWidth! / imageHeight!;
    final double recommended = recommendedWidth / recommendedHeight;
    return (selected - recommended).abs() < 0.002;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color stateColor = _exactMatch
        ? Colors.green.shade600
        : colors.tertiary;
    final IconData stateIcon = _exactMatch
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;

    final String selectedDimensions = _hasDimensions
        ? '${imageWidth!} × ${imageHeight!} px'
        : texts.dimensionUnavailable;

    final String message;
    if (dimensionReadFailed || !_hasDimensions) {
      message = texts.dimensionReadWarning;
    } else if (_exactMatch) {
      message = texts.dimensionIdeal;
    } else if (_sameAspectRatio) {
      message = texts.dimensionResizeWarning(
        recommendedWidth,
        recommendedHeight,
      );
    } else {
      message = texts.dimensionCropWarning(
        recommendedWidth,
        recommendedHeight,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(stateIcon, color: stateColor, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  texts.selectedImageInfo(
                    selectedDimensions,
                    _formatFileSize(fileSizeBytes),
                  ),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texts.recommendedImageInfo(
                    platform,
                    recommendedWidth,
                    recommendedHeight,
                  ),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadCropGuidePreview extends StatelessWidget {
  const _UploadCropGuidePreview({
    required this.bytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.recommendedWidth,
    required this.recommendedHeight,
    required this.focalX,
    required this.focalY,
    required this.texts,
  });

  final Uint8List bytes;
  final int? imageWidth;
  final int? imageHeight;
  final int recommendedWidth;
  final int recommendedHeight;
  final double focalX;
  final double focalY;
  final _VisualAssetsTexts texts;

  bool get _hasDimensions =>
      imageWidth != null &&
      imageHeight != null &&
      imageWidth! > 0 &&
      imageHeight! > 0 &&
      recommendedWidth > 0 &&
      recommendedHeight > 0;

  bool get _isLargerThanRecommended =>
      _hasDimensions &&
      imageWidth! >= recommendedWidth &&
      imageHeight! >= recommendedHeight &&
      (imageWidth! > recommendedWidth ||
          imageHeight! > recommendedHeight);

  bool get _sameAspectRatio {
    if (!_hasDimensions) return false;
    final double source = imageWidth! / imageHeight!;
    final double target = recommendedWidth / recommendedHeight;
    return (source - target).abs() < 0.002;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool showCropGuide =
        _isLargerThanRecommended && !_sameAspectRatio;
    final bool resizeOnly =
        _isLargerThanRecommended && _sameAspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_isLargerThanRecommended) ...<Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  resizeOnly
                      ? Icons.aspect_ratio_rounded
                      : Icons.crop_free_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resizeOnly
                        ? texts.cropGuideResizeOnly(
                            recommendedWidth,
                            recommendedHeight,
                          )
                        : texts.cropGuideExplanation(
                            recommendedWidth,
                            recommendedHeight,
                          ),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final double availableWidth =
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 720;
            final double sourceAspect =
                _hasDimensions
                    ? imageWidth! / imageHeight!
                    : recommendedWidth / recommendedHeight;
            final double naturalHeight =
                availableWidth / sourceAspect;
            final double previewHeight =
                naturalHeight.clamp(220.0, 430.0).toDouble();
            final Size viewport = Size(
              availableWidth,
              previewHeight,
            );

            final Size sourceSize = _hasDimensions
                ? Size(
                    imageWidth!.toDouble(),
                    imageHeight!.toDouble(),
                  )
                : Size(
                    recommendedWidth.toDouble(),
                    recommendedHeight.toDouble(),
                  );

            final FittedSizes fitted = applyBoxFit(
              BoxFit.contain,
              sourceSize,
              viewport,
            );
            final Rect imageRect = Alignment.center.inscribe(
              fitted.destination,
              Offset.zero & viewport,
            );

            final _NormalizedCrop crop = _computeNormalizedCrop();
            final Rect cropRect = Rect.fromLTWH(
              imageRect.left + crop.left * imageRect.width,
              imageRect.top + crop.top * imageRect.height,
              crop.width * imageRect.width,
              crop.height * imageRect.height,
            );

            return Container(
              height: previewHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    if (showCropGuide)
                      CustomPaint(
                        painter: _CropGuideOverlayPainter(
                          imageRect: imageRect,
                          cropRect: cropRect,
                          maskColor: Colors.black.withValues(
                            alpha: 0.48,
                          ),
                          borderColor: colors.primary,
                        ),
                      ),
                    if (resizeOnly)
                      CustomPaint(
                        painter: _CropGuideOverlayPainter(
                          imageRect: imageRect,
                          cropRect: imageRect,
                          maskColor: Colors.transparent,
                          borderColor: colors.primary,
                          drawMask: false,
                        ),
                      ),
                    if (_isLargerThanRecommended)
                      Positioned(
                        left: cropRect.left + 10,
                        top: cropRect.top + 10,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                (cropRect.width - 20)
                                    .clamp(120.0, 300.0)
                                    .toDouble(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: 0.94,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              resizeOnly
                                  ? texts.resizeOnlyBadge(
                                      recommendedWidth,
                                      recommendedHeight,
                                    )
                                  : texts.recommendedAreaBadge(
                                      recommendedWidth,
                                      recommendedHeight,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  _NormalizedCrop _computeNormalizedCrop() {
    if (!_hasDimensions || _sameAspectRatio) {
      return const _NormalizedCrop(
        left: 0,
        top: 0,
        width: 1,
        height: 1,
      );
    }

    final double sourceAspect = imageWidth! / imageHeight!;
    final double targetAspect =
        recommendedWidth / recommendedHeight;

    if (sourceAspect > targetAspect) {
      final double cropWidth =
          targetAspect / sourceAspect;
      final double maxLeft = 1.0 - cropWidth;
      final double desiredLeft =
          focalX - cropWidth / 2.0;
      return _NormalizedCrop(
        left: desiredLeft.clamp(0.0, maxLeft).toDouble(),
        top: 0,
        width: cropWidth,
        height: 1,
      );
    }

    final double cropHeight =
        sourceAspect / targetAspect;
    final double maxTop = 1.0 - cropHeight;
    final double desiredTop =
        focalY - cropHeight / 2.0;
    return _NormalizedCrop(
      left: 0,
      top: desiredTop.clamp(0.0, maxTop).toDouble(),
      width: 1,
      height: cropHeight,
    );
  }
}

class _CropGuideOverlayPainter extends CustomPainter {
  const _CropGuideOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.maskColor,
    required this.borderColor,
    this.drawMask = true,
  });

  final Rect imageRect;
  final Rect cropRect;
  final Color maskColor;
  final Color borderColor;
  final bool drawMask;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawMask) {
      final Paint maskPaint = Paint()..color = maskColor;
      final Path maskPath = Path()
        ..addRect(imageRect)
        ..addRRect(
          RRect.fromRectAndRadius(
            cropRect,
            const Radius.circular(10),
          ),
        )
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(maskPath, maskPaint);
    }

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cropRect,
        const Radius.circular(10),
      ),
      borderPaint,
    );

    final double handle = 18;
    final Paint handlePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final Rect r = cropRect.deflate(1.5);
    canvas.drawLine(
      Offset(r.left, r.top + handle),
      Offset(r.left, r.top),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.left, r.top),
      Offset(r.left + handle, r.top),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.right - handle, r.top),
      Offset(r.right, r.top),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.right, r.top),
      Offset(r.right, r.top + handle),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.left, r.bottom - handle),
      Offset(r.left, r.bottom),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.left, r.bottom),
      Offset(r.left + handle, r.bottom),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.right - handle, r.bottom),
      Offset(r.right, r.bottom),
      handlePaint,
    );
    canvas.drawLine(
      Offset(r.right, r.bottom),
      Offset(r.right, r.bottom - handle),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CropGuideOverlayPainter oldDelegate,
  ) {
    return imageRect != oldDelegate.imageRect ||
        cropRect != oldDelegate.cropRect ||
        maskColor != oldDelegate.maskColor ||
        borderColor != oldDelegate.borderColor ||
        drawMask != oldDelegate.drawMask;
  }
}

class _NormalizedCrop {
  const _NormalizedCrop({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class _UploadAssetDialog extends StatefulWidget {
  const _UploadAssetDialog({
    required this.service,
    required this.slot,
    required this.scope,
    required this.company,
    required this.segment,
    required this.subsegment,
  });

  final AdminVisualAssetsService service;
  final AdminVisualAssetSlotPanel slot;
  final String scope;
  final AdminVisualAssetCompany? company;
  final String? segment;
  final String? subsegment;

  @override
  State<_UploadAssetDialog> createState() => _UploadAssetDialogState();
}

class _UploadAssetDialogState extends State<_UploadAssetDialog> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _timeZoneController;

  XFile? _file;
  Uint8List? _bytes;
  int? _imageWidth;
  int? _imageHeight;
  bool _dimensionReadFailed = false;
  double _focalX = .5;
  double _focalY = .5;
  bool _schedule = false;
  bool _includeWithoutSubsegment = false;
  DateTime? _activateAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timeZoneController = TextEditingController(
      text: widget.company?.timeZone ?? 'America/Sao_Paulo',
    );
  }

  @override
  void dispose() {
    _timeZoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final Uint8List bytes = await file.readAsBytes();
    int? width;
    int? height;
    bool dimensionReadFailed = false;

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      try {
        final ui.FrameInfo frame = await codec.getNextFrame();
        width = frame.image.width;
        height = frame.image.height;
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    } catch (_) {
      dimensionReadFailed = true;
    }

    if (!mounted) return;
    setState(() {
      _file = file;
      _bytes = bytes;
      _imageWidth = width;
      _imageHeight = height;
      _dimensionReadFailed = dimensionReadFailed;
      _error = null;
    });
  }

  Future<void> _chooseDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _activateAt ?? now.add(const Duration(days: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _activateAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final XFile? file = _file;
    final Uint8List? bytes = _bytes;
    if (file == null || bytes == null) {
      setState(() => _error = _VisualAssetsTexts.of(context).chooseImage);
      return;
    }
    if (_schedule && _activateAt == null) {
      setState(() => _error = _VisualAssetsTexts.of(context).chooseActivation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.upload(
        slot: widget.slot.slot,
        scope: widget.scope,
        bytes: bytes,
        fileName: file.name,
        mimeType: _mime(file),
        focalX: _focalX,
        focalY: _focalY,
        companyId: widget.company?.id,
        segment: widget.segment,
        subsegment: widget.subsegment,
        includeWithoutSubsegment: _includeWithoutSubsegment,
        activateAtLocal: _schedule ? _activateAt : null,
        timeZone: widget.scope == 'GLOBAL'
            ? _timeZoneController.text.trim()
            : widget.company?.timeZone,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _mime(XFile file) {
    final String? mime = file.mimeType;
    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime!;
    }
    final String lower = file.name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    final Uint8List? bytes = _bytes;
    final bool globalSegmentWithoutSpecialty =
        widget.scope == 'GLOBAL' &&
        widget.segment != null &&
        widget.subsegment == null;

    return _VisualAssetsDialogTheme(
      child: AlertDialog(
        title: Text(texts.uploadTitle(texts.slotTitle(context, widget.slot))),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${widget.slot.recommendedWidth} × '
                '${widget.slot.recommendedHeight} · '
                '${widget.slot.platform}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: Icon(Icons.photo_library_outlined),
                label: Text(
                  _file == null ? texts.chooseImage : _file!.name,
                ),
              ),
              if (bytes != null) ...<Widget>[
                const SizedBox(height: 14),
                _UploadImageMetadata(
                  fileSizeBytes: bytes.lengthInBytes,
                  imageWidth: _imageWidth,
                  imageHeight: _imageHeight,
                  recommendedWidth: widget.slot.recommendedWidth,
                  recommendedHeight: widget.slot.recommendedHeight,
                  platform: widget.slot.platform,
                  dimensionReadFailed: _dimensionReadFailed,
                  texts: texts,
                ),
                const SizedBox(height: 14),
                _UploadCropGuidePreview(
                  bytes: bytes,
                  imageWidth: _imageWidth,
                  imageHeight: _imageHeight,
                  recommendedWidth: widget.slot.recommendedWidth,
                  recommendedHeight: widget.slot.recommendedHeight,
                  focalX: _focalX,
                  focalY: _focalY,
                  texts: texts,
                ),
                const SizedBox(height: 12),
                Text(texts.horizontalFocus),
                Slider(
                  value: _focalX,
                  onChanged: _saving
                      ? null
                      : (double value) => setState(() => _focalX = value),
                ),
                Text(texts.verticalFocus),
                Slider(
                  value: _focalY,
                  onChanged: _saving
                      ? null
                      : (double value) => setState(() => _focalY = value),
                ),
              ],
              const Divider(height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _schedule,
                onChanged: _saving
                    ? null
                    : (bool value) => setState(() => _schedule = value),
                title: Text(texts.schedule),
                subtitle: Text(texts.scheduleHelp),
              ),
              if (_schedule) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _chooseDateTime,
                        icon: Icon(Icons.event_rounded),
                        label: Text(
                          _activateAt == null
                              ? texts.chooseActivation
                              : _formatLocal(_activateAt!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _timeZoneController,
                        readOnly: widget.scope == 'EMPRESA',
                        decoration: InputDecoration(
                          labelText: texts.timeZone,
                          border: const OutlineInputBorder(),
                          helperText: widget.scope == 'EMPRESA'
                              ? texts.companyTimeZone
                              : texts.globalTimeZone,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (globalSegmentWithoutSpecialty) ...<Widget>[
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _includeWithoutSubsegment,
                  onChanged: _saving
                      ? null
                      : (bool? value) => setState(
                            () => _includeWithoutSubsegment = value == true,
                          ),
                  title: Text(texts.includeWithoutSpecialty),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
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
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(texts.cancel),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.save_rounded),
          label: Text(_schedule ? texts.saveSchedule : texts.publishNow),
        ),
      ],
      ),
    );
  }
}

class _AssetHistoryDialog extends StatefulWidget {
  const _AssetHistoryDialog({
    required this.service,
    required this.slot,
    required this.scope,
    required this.backendEnvironment,
    required this.company,
    required this.segment,
    required this.subsegment,
  });

  final AdminVisualAssetsService service;
  final AdminVisualAssetSlotPanel slot;
  final String scope;
  final String backendEnvironment;
  final AdminVisualAssetCompany? company;
  final String? segment;
  final String? subsegment;

  @override
  State<_AssetHistoryDialog> createState() => _AssetHistoryDialogState();
}

class _AssetHistoryDialogState extends State<_AssetHistoryDialog> {
  late Future<List<AdminVisualAssetItem>> _future;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminVisualAssetItem>> _load() {
    return widget.service.history(
      slot: widget.slot.slot,
      scope: widget.scope,
      companyId: widget.company?.id,
      segment: widget.segment,
      subsegment: widget.subsegment,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _archive(AdminVisualAssetItem item) async {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => _VisualAssetsDialogTheme(
            child: AlertDialog(
            title: Text(texts.archive),
            content: Text(texts.archiveConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(texts.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(texts.archive),
              ),
            ],
          ),
        ),
      ) ??
        false;
    if (!confirmed) return;
    await widget.service.archive(item.id);
    _changed = true;
    _reload();
  }

  Future<void> _reuse(AdminVisualAssetItem item) async {
    final _ReuseOptions? options = await showDialog<_ReuseOptions>(
      context: context,
      builder: (BuildContext context) => _ReuseDialog(
        company: widget.company,
        asset: item,
      ),
    );
    if (options == null) return;
    await widget.service.reuse(
      id: item.id,
      activateAtLocal: options.activateAt,
      timeZone: options.timeZone,
    );
    _changed = true;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    return _VisualAssetsDialogTheme(
      child: AlertDialog(
        title: Text('${texts.history} · ${texts.slotTitle(context, widget.slot)}'),
      content: SizedBox(
        width: 780,
        height: 520,
        child: FutureBuilder<List<AdminVisualAssetItem>>(
          future: _future,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<AdminVisualAssetItem>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline_rounded,
                title: texts.loadError,
                subtitle: _cleanError(snapshot.error!),
              );
            }
            final List<AdminVisualAssetItem> items =
                snapshot.data ?? const <AdminVisualAssetItem>[];
            if (items.isEmpty) {
              return _EmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: texts.noHistory,
                subtitle: texts.noHistorySubtitle,
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final AdminVisualAssetItem item = items[index];
                final bool editable =
                    item.environment == widget.backendEnvironment;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 58,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${_prettyCode(item.status)} · v${item.version}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AssetEnvironmentPill(item.environment),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${item.activateAtUtc == null ? '—' : _formatDate(item.activateAtUtc!)}'
                          ' · ${item.timeZone}'
                          '${item.migrated ? ' · Legacy seed' : ''}',
                        ),
                        const SizedBox(height: 6),
                        _AssetLinkRow(
                          url: item.imageUrl,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: <Widget>[
                      IconButton(
                        tooltip: editable
                            ? texts.reuse
                            : texts.readOnlyEnvironment(item.environment),
                        onPressed: editable ? () => _reuse(item) : null,
                        icon: Icon(Icons.replay_rounded),
                      ),
                      if (item.status != 'ARQUIVADA')
                        IconButton(
                          tooltip: editable
                              ? texts.archive
                              : texts.readOnlyEnvironment(item.environment),
                          onPressed: editable ? () => _archive(item) : null,
                          icon: Icon(Icons.archive_outlined),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, _changed),
          child: Text(texts.close),
        ),
      ],
      ),
    );
  }
}

class _ReuseDialog extends StatefulWidget {
  const _ReuseDialog({
    required this.company,
    required this.asset,
  });

  final AdminVisualAssetCompany? company;
  final AdminVisualAssetItem asset;

  @override
  State<_ReuseDialog> createState() => _ReuseDialogState();
}

class _ReuseDialogState extends State<_ReuseDialog> {
  late final TextEditingController _zone;
  bool _schedule = false;
  DateTime? _activateAt;

  @override
  void initState() {
    super.initState();
    _zone = TextEditingController(
      text: widget.company?.timeZone ??
          (widget.asset.timeZone == 'UTC'
              ? 'America/Sao_Paulo'
              : widget.asset.timeZone),
    );
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final DateTime now = DateTime.now();
    final DateTime initial = now.add(const Duration(days: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _activateAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);
    return _VisualAssetsDialogTheme(
      child: AlertDialog(
        title: Text(texts.reuse),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _schedule,
              onChanged: (bool value) => setState(() => _schedule = value),
              title: Text(texts.schedule),
            ),
            if (_schedule) ...<Widget>[
              OutlinedButton.icon(
                onPressed: _pick,
                icon: Icon(Icons.event_rounded),
                label: Text(
                  _activateAt == null
                      ? texts.chooseActivation
                      : _formatLocal(_activateAt!),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _zone,
                readOnly: widget.company != null,
                decoration: InputDecoration(
                  labelText: texts.timeZone,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(texts.cancel),
        ),
        FilledButton(
          onPressed: _schedule && _activateAt == null
              ? null
              : () => Navigator.pop(
                    context,
                    _ReuseOptions(
                      activateAt: _schedule ? _activateAt : null,
                      timeZone: _schedule ? _zone.text.trim() : null,
                    ),
                  ),
          child: Text(_schedule ? texts.saveSchedule : texts.publishNow),
        ),
      ],
      ),
    );
  }
}

class _ReuseOptions {
  const _ReuseOptions({this.activateAt, this.timeZone});
  final DateTime? activateAt;
  final String? timeZone;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(Icons.error_outline_rounded),
        title: Text(message),
        trailing: TextButton(
          onPressed: retry,
          child: const Text('Tentar novamente'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualAssetsTexts {
  const _VisualAssetsTexts(this.language);
  final String language;

  factory _VisualAssetsTexts.of(BuildContext context) =>
      _VisualAssetsTexts(Localizations.localeOf(context).languageCode);

  String _pick(String pt, String en, String es) =>
      language == 'en' ? en : language == 'es' ? es : pt;

  String slotTitle(BuildContext context, AdminVisualAssetSlotPanel slot) {
    final labels = <String, List<String>>{
      'WEB_DEVOLUCOES_HEADER': [
        'Web · Devoluções e trocas',
        'Web · Returns and exchanges',
        'Web · Devoluciones y cambios',
      ],
      'WEB_CAIXA_HEADER': ['Web · Caixa', 'Web · Cash register', 'Web · Caja'],
      'WEB_ASSISTENCIAS_HEADER': [
        'Web · Assistências técnicas',
        'Web · Technical assistance',
        'Web · Asistencias técnicas',
      ],
      'WEB_COMPRAS_HEADER': [
        'Web · Compras',
        'Web · Purchases',
        'Web · Compras',
      ],
      'WEB_RESERVAS_HEADER': [
        'Web · Reservas',
        'Web · Reservations',
        'Web · Reservas',
      ],
      'WEB_PRODUTOS_HEADER': [
        'Web · Produtos',
        'Web · Products',
        'Web · Productos',
      ],
      'WEB_ESTOQUE_HEADER': [
        'Web · Estoque',
        'Web · Inventory',
        'Web · Inventario',
      ],
      'WEB_DESEMPENHO_HEADER': [
        'Web · Desempenho',
        'Web · Performance',
        'Web · Desempeño',
      ],
      'WEB_AGENDA_FINANCEIRA_HEADER': [
        'Web · Agenda financeira',
        'Web · Financial agenda',
        'Web · Agenda financiera',
      ],
      'WEB_USUARIOS_SIXO_HEADER': [
        'Web · Usuários do Sixo',
        'Web · Sixo users',
        'Web · Usuarios de Sixo',
      ],
      'WEB_INICIO_HEADER': ['Web · Início', 'Web · Home', 'Web · Inicio'],
    }[slot.slot];
    return context.t(
      slot.labelKey,
      fallback: labels == null
          ? slot.labelFallback
          : _pick(labels[0], labels[1], labels[2]),
    );
  }

  String get checkingAccess => _pick(
        'Verificando acesso SUPER…',
        'Checking SUPER access…',
        'Verificando acceso SUPER…',
      );
  String get eyebrow =>
      _pick('Controle visual', 'Visual control', 'Control visual');
  String get title => _pick(
        'Imagens do SixApp',
        'SixApp images',
        'Imágenes de SixApp',
      );
  String get subtitle => _pick(
        'Gerencie as imagens atuais, programe campanhas futuras e acompanhe Web e Mobile em um único lugar.',
        'Manage current images, schedule future campaigns and track Web and Mobile in one place.',
        'Gestiona las imágenes actuales, programa campañas futuras y controla Web y Mobile en un solo lugar.',
      );
  String get global => _pick('Global', 'Global', 'Global');
  String get company => _pick('Comércio', 'Business', 'Comercio');
  String get segment => _pick('Segmento', 'Segment', 'Segmento');
  String get specialty => _pick('Especialidade', 'Specialty', 'Especialidad');
  String get globalDefault => _pick(
        'Padrão global',
        'Global default',
        'Predeterminado global',
      );
  String get noSpecialty => _pick(
        'Sem especialidade',
        'No specialty',
        'Sin especialidad',
      );
  String get version => _pick(
        'Versão global',
        'Global version',
        'Versión global',
      );
  String get environment => _pick('Ambiente', 'Environment', 'Ambiente');
  String get devNotice => _pick(
        'Você está no ambiente DEV. Uploads, programações, versão global e ativações feitas aqui ficam isolados da produção. Imagens LIVE podem aparecer apenas como referência/fallback e não podem ser alteradas por este backend.',
        'You are in DEV. Uploads, schedules, global version and activations made here are isolated from production. LIVE images may appear only as reference/fallback and cannot be changed by this backend.',
        'Estás en DEV. Las cargas, programaciones, versión global y activaciones realizadas aquí quedan aisladas de producción. Las imágenes LIVE pueden aparecer solo como referencia/fallback y no pueden modificarse desde este backend.',
      );
  String readOnlyEnvironment(String environment) => _pick(
        'Imagem $environment somente para referência neste ambiente',
        '$environment image is read-only in this environment',
        'Imagen $environment solo de referencia en este ambiente',
      );
  String get force =>
      _pick('Forçar atualização', 'Force refresh', 'Forzar actualización');
  String get forceTitle => force;
  String get forceDescription => _pick(
        'Isso gera uma nova assetsVersion e avisa imediatamente todos os clientes conectados. Imagens que não mudaram continuam aproveitando o cache.',
        'This generates a new assetsVersion and immediately notifies connected clients. Unchanged images keep using cache.',
        'Esto genera una nueva assetsVersion y avisa inmediatamente a los clientes conectados. Las imágenes sin cambios siguen usando la caché.',
      );
  String get forceSuccess => _pick(
        'Atualização publicada.',
        'Refresh published.',
        'Actualización publicada.',
      );
  String get current => _pick('Atual', 'Current', 'Actual');
  String get next => _pick('Próxima', 'Next', 'Próxima');
  String get positions => _pick('posições', 'positions', 'posiciones');
  String get noImage =>
      _pick('Ainda não existe imagem', 'No image yet', 'Aún no hay imagen');
  String get noCompanyImage => _pick(
        'Sem imagem própria. Usa global/fallback.',
        'No custom image. Uses global/fallback.',
        'Sin imagen propia. Usa global/fallback.',
      );
  String get noSchedule => _pick(
        'Nenhuma imagem futura',
        'No future image',
        'Ninguna imagen futura',
      );
  String get moreScheduled => _pick(
        'outras programadas',
        'more scheduled',
        'otras programadas',
      );
  String get addOrSchedule => _pick(
        'Trocar / programar',
        'Replace / schedule',
        'Cambiar / programar',
      );
  String get history => _pick('Histórico', 'History', 'Historial');
  String get chooseImage => _pick(
        'Escolha uma imagem JPEG, PNG ou WebP.',
        'Choose a JPEG, PNG or WebP image.',
        'Elige una imagen JPEG, PNG o WebP.',
      );
  String selectedImageInfo(String dimensions, String fileSize) => _pick(
        'Imagem selecionada: $dimensions · $fileSize',
        'Selected image: $dimensions · $fileSize',
        'Imagen seleccionada: $dimensions · $fileSize',
      );
  String recommendedImageInfo(
    String platform,
    int width,
    int height,
  ) => _pick(
        'Recomendado para $platform: $width × $height px',
        'Recommended for $platform: $width × $height px',
        'Recomendado para $platform: $width × $height px',
      );
  String get dimensionIdeal => _pick(
        'Dimensão ideal. Nenhum ajuste de tamanho será necessário.',
        'Ideal dimensions. No size adjustment will be required.',
        'Dimensión ideal. No será necesario ajustar el tamaño.',
      );
  String dimensionResizeWarning(int width, int height) => _pick(
        'A dimensão é diferente da recomendada, mas a proporção é compatível. A imagem será redimensionada para $width × $height.',
        'The dimensions differ from the recommendation, but the aspect ratio matches. The image will be resized to $width × $height.',
        'La dimensión difiere de la recomendada, pero la proporción es compatible. La imagen se redimensionará a $width × $height.',
      );
  String dimensionCropWarning(int width, int height) => _pick(
        'A dimensão e a proporção são diferentes da recomendada. A imagem será recortada e redimensionada para $width × $height. Use os controles de foco para escolher a área principal.',
        'The dimensions and aspect ratio differ from the recommendation. The image will be cropped and resized to $width × $height. Use the focus controls to choose the main area.',
        'La dimensión y la proporción difieren de la recomendada. La imagen se recortará y redimensionará a $width × $height. Usa los controles de enfoque para elegir el área principal.',
      );
  String get dimensionUnavailable => _pick(
        'dimensão não identificada',
        'dimensions unavailable',
        'dimensión no identificada',
      );
  String get dimensionReadWarning => _pick(
        'Não foi possível identificar a resolução desta imagem. O backend ainda fará a validação antes da publicação.',
        'The image resolution could not be detected. The backend will still validate it before publishing.',
        'No fue posible identificar la resolución de esta imagen. El backend aún la validará antes de publicarla.',
      );
  String cropGuideExplanation(int width, int height) => _pick(
        'A área destacada é o enquadramento que será publicado em $width × $height. Mova os controles de foco para escolher a região principal.',
        'The highlighted area is the framing that will be published at $width × $height. Move the focus controls to choose the main region.',
        'El área destacada es el encuadre que se publicará en $width × $height. Mueve los controles de enfoque para elegir la región principal.',
      );
  String cropGuideResizeOnly(int width, int height) => _pick(
        'A imagem é maior que o recomendado, mas já tem a proporção correta. Ela será reduzida para $width × $height sem corte.',
        'The image is larger than recommended but already has the correct aspect ratio. It will be reduced to $width × $height without cropping.',
        'La imagen es más grande que la recomendada, pero ya tiene la proporción correcta. Se reducirá a $width × $height sin recorte.',
      );
  String recommendedAreaBadge(int width, int height) => _pick(
        'Área recomendada · $width × $height',
        'Recommended area · $width × $height',
        'Área recomendada · $width × $height',
      );
  String resizeOnlyBadge(int width, int height) => _pick(
        'Sem corte · $width × $height',
        'No crop · $width × $height',
        'Sin recorte · $width × $height',
      );
  String uploadTitle(String slot) => _pick(
        'Nova imagem · $slot',
        'New image · $slot',
        'Nueva imagen · $slot',
      );
  String get horizontalFocus =>
      _pick('Foco horizontal', 'Horizontal focus', 'Foco horizontal');
  String get verticalFocus =>
      _pick('Foco vertical', 'Vertical focus', 'Foco vertical');
  String get schedule =>
      _pick('Programar ativação', 'Schedule activation', 'Programar activación');
  String get scheduleHelp => _pick(
        'Se desligado, a imagem entra em vigor agora.',
        'If disabled, the image goes live now.',
        'Si está desactivado, la imagen entra en vigor ahora.',
      );
  String get chooseActivation => _pick(
        'Escolher data e horário',
        'Choose date and time',
        'Elegir fecha y hora',
      );
  String get timeZone => 'Timezone';
  String get companyTimeZone => _pick(
        'Usa o fuso configurado no comércio.',
        'Uses the business configured timezone.',
        'Usa la zona horaria configurada del comercio.',
      );
  String get globalTimeZone => _pick(
        'IANA, por exemplo America/Sao_Paulo.',
        'IANA, for example America/Sao_Paulo.',
        'IANA, por ejemplo America/Sao_Paulo.',
      );
  String get includeWithoutSpecialty => _pick(
        'Usar também quando o comércio não tiver especialidade definida',
        'Also use when the business has no specialty set',
        'Usar también cuando el comercio no tenga especialidad definida',
      );
  String get cancel => _pick('Cancelar', 'Cancel', 'Cancelar');
  String get close => _pick('Fechar', 'Close', 'Cerrar');
  String get saveSchedule =>
      _pick('Salvar programação', 'Save schedule', 'Guardar programación');
  String get publishNow =>
      _pick('Publicar agora', 'Publish now', 'Publicar ahora');
  String get reuse => _pick('Reutilizar', 'Reuse', 'Reutilizar');
  String get archive => _pick('Arquivar', 'Archive', 'Archivar');
  String get archiveConfirm => _pick(
        'A imagem deixa de participar da resolução. O histórico e o arquivo serão preservados.',
        'The image will no longer participate in resolution. History and file will be preserved.',
        'La imagen dejará de participar en la resolución. Se conservarán el historial y el archivo.',
      );
  String get noHistory =>
      _pick('Sem histórico', 'No history', 'Sin historial');
  String get noHistorySubtitle => _pick(
        'Este contexto ainda não possui versões anteriores.',
        'This context has no previous versions yet.',
        'Este contexto aún no tiene versiones anteriores.',
      );
  String get loadError =>
      _pick('Falha ao carregar', 'Failed to load', 'Error al cargar');
  String get noCompanies => _pick(
        'Nenhum comércio disponível',
        'No business available',
        'Ningún comercio disponible',
      );
  String get noCompaniesSubtitle => _pick(
        'Cadastre ou ative um comércio antes de criar uma imagem específica.',
        'Create or activate a business before adding a custom image.',
        'Crea o activa un comercio antes de agregar una imagen específica.',
      );
  String get openNewWindow => _pick(
        'Abrir imagem em nova janela',
        'Open image in a new window',
        'Abrir imagen en una nueva ventana',
      );
  String get copyUrl => _pick('Copiar link', 'Copy link', 'Copiar enlace');
  String get urlCopied => _pick(
        'Link da imagem copiado.',
        'Image link copied.',
        'Enlace de la imagen copiado.',
      );
  String get openUrlFailed => _pick(
        'Não foi possível abrir a imagem.',
        'Could not open the image.',
        'No fue posible abrir la imagen.',
      );
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final double kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  final double mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 1 : 2)} MB';
}

String _prettyCode(String value) {
  final String normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ');
  if (normalized.isEmpty) return value;
  return normalized
      .split(' ')
      .where((String item) => item.isNotEmpty)
      .map(
        (String item) =>
            '${item.substring(0, 1).toUpperCase()}${item.substring(1)}',
      )
      .join(' ');
}

String _formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatLocal(DateTime value) => _formatDate(value);

String _displayName(String? email) {
  final String local = email?.split('@').first.trim() ?? '';
  if (local.isEmpty) return 'SUPER';
  return local
      .split(RegExp(r'[._-]+'))
      .where((String item) => item.isNotEmpty)
      .map(
        (String item) =>
            '${item.substring(0, 1).toUpperCase()}${item.substring(1)}',
      )
      .join(' ');
}

String _cleanError(Object error) {
  return error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '')
      .trim();
}
