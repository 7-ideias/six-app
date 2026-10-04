import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/admin_visual_assets_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/admin_visual_assets_models.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';
import '../admin/admin_visual_assets_catalog.dart';

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
          builder: (BuildContext context) => AlertDialog(
            title: Text(texts.forceTitle),
            content: Text(texts.forceDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(texts.cancel),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.sync_rounded),
                label: Text(texts.force),
              ),
            ],
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

  Future<void> _showHistory(AdminVisualAssetSlotPanel slot) async {
    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _AssetHistoryDialog(
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
        color: AdminPalette.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: content,
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
      child: content,
    );
  }

  Widget _loadingAccess(_VisualAssetsTexts texts) {
    final Widget loading = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AdminSurfaceCard(
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
                  style: const TextStyle(
                    color: AdminPalette.bodyText,
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
      return ColoredBox(color: AdminPalette.background, child: loading);
    }
    return Scaffold(backgroundColor: AdminPalette.background, body: loading);
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
                    style: const TextStyle(
                      color: AdminPalette.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texts.title,
                    style: const TextStyle(
                      color: AdminPalette.dark,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texts.subtitle,
                    style: const TextStyle(
                      color: AdminPalette.mutedText,
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
                  : const Icon(Icons.sync_rounded),
              label: Text(texts.force),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AdminSurfaceCard(
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
              ],
            ),
          ),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 14),
          _ErrorBanner(
            message: _error!,
            retry: () => _reload(loadCompanies: true),
          ),
        ],
        const SizedBox(height: 20),
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
          ),
          const SizedBox(height: 24),
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
          ),
        ],
      ],
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
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
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
                ? AdminPalette.dark
                : active
                    ? Colors.white
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AdminRadius.md),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: AdminPalette.shadow.withValues(alpha: 0.06),
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
                          ? Colors.white
                          : AdminPalette.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white
                            : AdminPalette.dark,
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
      color: Colors.white,
      elevation: 10,
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        side: const BorderSide(color: AdminPalette.border),
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
                      color: active ? Colors.white : AdminPalette.softSurface,
                      borderRadius: BorderRadius.circular(AdminRadius.lg),
                      border: Border.all(
                        color: active
                            ? AdminPalette.success
                            : AdminPalette.border,
                        width: active ? 1.3 : 1,
                      ),
                      boxShadow: active
                          ? <BoxShadow>[
                              BoxShadow(
                                color:
                                    AdminPalette.shadow.withValues(alpha: 0.08),
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
                              : AdminPalette.mutedText,
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
                                style: const TextStyle(
                                  color: AdminPalette.mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AdminPalette.dark,
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
                                : AdminPalette.mutedText,
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
        color: selected ? AdminPalette.activeGreen : Colors.transparent,
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
            color: selected ? AdminPalette.success : AdminPalette.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AdminPalette.dark,
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
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.memory_rounded,
            size: 17,
            color: AdminPalette.success,
          ),
          const SizedBox(width: 8),
          Text(
            '${texts.version}: $version',
            style: const TextStyle(
              color: AdminPalette.dark,
              fontWeight: FontWeight.w900,
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
  });

  final String title;
  final IconData icon;
  final List<AdminVisualAssetSlotPanel> slots;
  final bool companyScope;
  final _VisualAssetsTexts texts;
  final ValueChanged<AdminVisualAssetSlotPanel> onUpload;
  final ValueChanged<AdminVisualAssetSlotPanel> onHistory;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: AdminPalette.dark),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                color: AdminPalette.dark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${slots.length} ${texts.positions}',
              style: const TextStyle(color: AdminPalette.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double cardWidth = width >= 1180
                ? (width - 28) / 3
                : width >= 760
                ? (width - 14) / 2
                : width;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
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
  });

  final AdminVisualAssetSlotPanel slot;
  final bool companyScope;
  final _VisualAssetsTexts texts;
  final VoidCallback onUpload;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    slot.labelFallback,
                    style: const TextStyle(
                      color: AdminPalette.dark,
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
              style: const TextStyle(
                color: AdminPalette.mutedText,
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
                    label: texts.current,
                    asset: slot.current,
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
                style: const TextStyle(
                  color: AdminPalette.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
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
                    child: const Icon(Icons.history_rounded),
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
          style: const TextStyle(
            color: AdminPalette.mutedText,
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
                    color: AdminPalette.softSurface,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AdminPalette.mutedText,
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
                      color: AdminPalette.softSurface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
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
            style: const TextStyle(
              color: AdminPalette.mutedText,
              fontSize: 10,
            ),
          ),
        ],
      ],
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
        : AdminPalette.mutedText;
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
      ],
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
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Text(
        platform,
        style: const TextStyle(
          color: AdminPalette.mutedText,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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
    if (!mounted) return;
    setState(() {
      _file = file;
      _bytes = bytes;
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

    return AlertDialog(
      title: Text(texts.uploadTitle(widget.slot.labelFallback)),
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
                style: const TextStyle(color: AdminPalette.mutedText),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _file == null ? texts.chooseImage : _file!.name,
                ),
              ),
              if (bytes != null) ...<Widget>[
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: widget.slot.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      alignment: Alignment(
                        _focalX * 2 - 1,
                        _focalY * 2 - 1,
                      ),
                    ),
                  ),
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
                        icon: const Icon(Icons.event_rounded),
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
              : const Icon(Icons.save_rounded),
          label: Text(_schedule ? texts.saveSchedule : texts.publishNow),
        ),
      ],
    );
  }
}

class _AssetHistoryDialog extends StatefulWidget {
  const _AssetHistoryDialog({
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
          builder: (BuildContext context) => AlertDialog(
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
    return AlertDialog(
      title: Text('${texts.history} · ${widget.slot.labelFallback}'),
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
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  title: Text(
                    '${_prettyCode(item.status)} · v${item.version}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${item.activateAtUtc == null ? '—' : _formatDate(item.activateAtUtc!)}'
                    ' · ${item.timeZone}'
                    '${item.migrated ? ' · Legacy seed' : ''}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: <Widget>[
                      IconButton(
                        tooltip: texts.reuse,
                        onPressed: () => _reuse(item),
                        icon: const Icon(Icons.replay_rounded),
                      ),
                      if (item.status != 'ARQUIVADA')
                        IconButton(
                          tooltip: texts.archive,
                          onPressed: () => _archive(item),
                          icon: const Icon(Icons.archive_outlined),
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
    return AlertDialog(
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
                icon: const Icon(Icons.event_rounded),
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
        leading: const Icon(Icons.error_outline_rounded),
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
            Icon(icon, size: 42, color: AdminPalette.mutedText),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminPalette.dark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminPalette.mutedText),
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
  String get version => _pick('Versão global', 'Global version', 'Versión global');
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
